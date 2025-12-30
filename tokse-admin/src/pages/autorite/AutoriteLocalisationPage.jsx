import { format } from 'date-fns';
import { fr } from 'date-fns/locale';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import { MapPin, Navigation, Phone, User, Satellite } from 'lucide-react';
import { useEffect, useState } from 'react';
import { MapContainer, Marker, Popup, TileLayer } from 'react-leaflet';
import { useAuth } from '../../contexts/AuthContext';
import { supabase } from '../../lib/supabase';

// Fix pour les icônes Leaflet
delete L.Icon.Default.prototype._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png',
  iconUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png',
  shadowUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png',
});

// Icônes personnalisées pour les différents états
const createCustomIcon = (color) => {
  return L.divIcon({
    className: 'custom-marker',
    html: `<div style="background-color: ${color}; width: 30px; height: 30px; border-radius: 50% 50% 50% 0; transform: rotate(-45deg); border: 3px solid white; box-shadow: 0 2px 5px rgba(0,0,0,0.3);"><div style="transform: rotate(45deg); margin-top: 5px; font-size: 16px; text-align: center;">📍</div></div>`,
    iconSize: [30, 30],
    iconAnchor: [15, 30],
    popupAnchor: [0, -30],
  });
};

const enAttenteIcon = createCustomIcon('#EAB308'); // Jaune
const enCoursIcon = createCustomIcon('#3B82F6'); // Bleu

export const AutoriteLocalisationPage = () => {
  const { user } = useAuth();
  const [interventions, setInterventions] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selectedIntervention, setSelectedIntervention] = useState(null);
  
  // Pagination
  const [currentPage, setCurrentPage] = useState(1);
  const [itemsPerPage, setItemsPerPage] = useState(5);

  useEffect(() => {
    fetchInterventions();

    // Real-time updates toutes les 30 secondes
    const interval = setInterval(() => {
      fetchInterventions();
    }, 30000);

    // Real-time avec Supabase
    const channel = supabase
      .channel('signalements_updates')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'signalements' }, () => {
        fetchInterventions();
      })
      .subscribe();

    return () => {
      clearInterval(interval);
      supabase.removeChannel(channel);
    };
  }, [user]);

  const fetchInterventions = async () => {
    try {
      setLoading(true);
      console.log('🔍 [LOCALISATION] Fetching interventions...');
      
      const { data, error } = await supabase
        .from('signalements')
        .select(`
          *,
          assigned_user:users!signalements_assigned_to_fkey(id, nom, prenom, telephone, role)
        `)
        .in('etat', ['en_cours', 'en_attente'])
        .order('created_at', { ascending: false });

      if (error) {
        console.error('❌ [LOCALISATION] Error:', error);
        throw error;
      }
      
      console.log('✅ [LOCALISATION] Fetched interventions:', data?.length || 0);
      setInterventions(data || []);
    } catch (error) {
      console.error('❌ [LOCALISATION] Error fetching interventions:', error);
    } finally {
      setLoading(false);
    }
  };

  const getStatutBadge = (statut) => {
    switch (statut) {
      case 'en_attente':
        return <span className="px-3 py-1 rounded-full bg-yellow-100 text-yellow-700 text-xs font-medium">En attente</span>;
      case 'en_cours':
        return <span className="px-3 py-1 rounded-full bg-blue-100 text-blue-700 text-xs font-medium">En cours</span>;
      case 'resolu':
        return <span className="px-3 py-1 rounded-full bg-green-100 text-green-700 text-xs font-medium">Résolu</span>;
      default:
        return <span className="px-3 py-1 rounded-full bg-gray-100 text-gray-700 text-xs font-medium">{statut}</span>;
    }
  };

  const openInMaps = (lat, lng, address) => {
    // Google Maps
    const url = `https://www.google.com/maps/search/?api=1&query=${lat},${lng}`;
    window.open(url, '_blank');
  };

  // Calcul pagination
  const totalPages = Math.ceil(interventions.length / itemsPerPage);
  const startIndex = (currentPage - 1) * itemsPerPage;
  const endIndex = startIndex + itemsPerPage;
  const currentInterventions = interventions.slice(startIndex, endIndex);

  const goToPage = (page) => {
    setCurrentPage(Math.max(1, Math.min(page, totalPages)));
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  return (
    <div>
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900">Localisation des Interventions</h1>
        <p className="text-gray-600 mt-2">
          Suivi temps réel des interventions en cours et en attente
        </p>
      </div>

      {/* Stats rapides */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        <div className="bg-white p-6 rounded-xl shadow-sm">
          <p className="text-sm text-gray-600">Interventions actives</p>
          <p className="text-3xl font-bold text-blue-600 mt-2">{interventions.length}</p>
        </div>
        <div className="bg-white p-6 rounded-xl shadow-sm">
          <p className="text-sm text-gray-600">En cours</p>
          <p className="text-3xl font-bold text-green-600 mt-2">
            {interventions.filter((i) => i.etat === 'en_cours').length}
          </p>
        </div>
        <div className="bg-white p-6 rounded-xl shadow-sm">
          <p className="text-sm text-gray-600">En attente</p>
          <p className="text-3xl font-bold text-yellow-600 mt-2">
            {interventions.filter((i) => i.etat === 'en_attente').length}
          </p>
        </div>
      </div>

      {/* Carte interactive des interventions */}
      <div className="bg-white rounded-xl shadow-sm p-6 mb-6">
        <h2 className="text-lg font-bold text-gray-900 mb-4 flex items-center gap-2">
          <MapPin className="w-5 h-5 text-blue-600" />
          Carte des interventions
        </h2>
        <div className="relative rounded-lg overflow-hidden" style={{ height: '500px' }}>
          {interventions.length === 0 ? (
            <div className="bg-gray-100 h-full flex items-center justify-center">
              <div className="text-center">
                <MapPin className="w-16 h-16 mx-auto mb-4 text-gray-400" />
                <p className="text-gray-600 mb-2">Aucune intervention à afficher</p>
                <p className="text-sm text-gray-500">Les interventions actives apparaîtront ici</p>
              </div>
            </div>
          ) : (
            <>
              <MapContainer
                center={[
                  interventions.find(i => i.latitude && i.longitude)?.latitude || 12.6392,
                  interventions.find(i => i.latitude && i.longitude)?.longitude || -8.0029
                ]}
                zoom={13}
                style={{ height: '100%', width: '100%' }}
                scrollWheelZoom={true}
              >
                <TileLayer
                  attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
                  url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
                />
                
                {interventions
                  .filter(intervention => intervention.latitude && intervention.longitude)
                  .map((intervention) => (
                    <Marker
                      key={intervention.id}
                      position={[intervention.latitude, intervention.longitude]}
                      icon={intervention.etat === 'en_attente' ? enAttenteIcon : enCoursIcon}
                    >
                      <Popup>
                        <div className="p-2" style={{ minWidth: '250px' }}>
                          <h3 className="font-bold text-gray-900 mb-2">
                            {intervention.titre || 'Sans titre'}
                          </h3>
                          <div className="mb-2">
                            {intervention.etat === 'en_attente' ? (
                              <span className="px-2 py-1 rounded-full bg-yellow-100 text-yellow-700 text-xs font-medium">
                                En attente
                              </span>
                            ) : (
                              <span className="px-2 py-1 rounded-full bg-blue-100 text-blue-700 text-xs font-medium">
                                En cours
                              </span>
                            )}
                          </div>
                          <p className="text-sm text-gray-600 mb-2">
                            {intervention.description?.substring(0, 100)}
                            {intervention.description?.length > 100 ? '...' : ''}
                          </p>
                          <div className="text-xs text-gray-500 mb-2">
                            <p><strong>Catégorie:</strong> {intervention.categorie}</p>
                            <p><strong>Adresse:</strong> {intervention.adresse || 'Non spécifiée'}</p>
                            {intervention.assigned_user && (
                              <p><strong>Assigné à:</strong> {intervention.assigned_user.nom} {intervention.assigned_user.prenom}</p>
                            )}
                          </div>
                          <button
                            onClick={() => openInMaps(intervention.latitude, intervention.longitude, intervention.adresse)}
                            className="w-full mt-2 px-3 py-2 bg-blue-600 text-white text-xs rounded-lg hover:bg-blue-700"
                          >
                            Ouvrir dans Google Maps
                          </button>
                        </div>
                      </Popup>
                    </Marker>
                  ))}
              </MapContainer>
              
              {/* Overlay avec statistiques */}
              <div className="absolute top-4 right-4 bg-white rounded-lg shadow-lg p-3 z-[1000]">
                <p className="text-sm font-semibold text-gray-900 mb-2">
                  {interventions.filter(i => i.latitude && i.longitude).length} intervention(s) sur la carte
                </p>
                <div className="space-y-1">
                  <div className="flex items-center gap-2 text-xs">
                    <div className="w-3 h-3 rounded-full bg-yellow-500"></div>
                    <span>{interventions.filter(i => i.etat === 'en_attente').length} en attente</span>
                  </div>
                  <div className="flex items-center gap-2 text-xs">
                    <div className="w-3 h-3 rounded-full bg-blue-500"></div>
                    <span>{interventions.filter(i => i.etat === 'en_cours').length} en cours</span>
                  </div>
                </div>
              </div>
            </>
          )}
        </div>
        
        {/* Info sur la carte */}
        <div className="mt-4 p-4 bg-blue-50 border border-blue-200 rounded-lg">
          <p className="text-sm text-blue-800">
            💡 <span className="font-semibold">Astuce :</span> Cliquez sur les marqueurs pour voir les détails des interventions
          </p>
        </div>
      </div>

      {/* Liste des interventions */}
      <div className="bg-white rounded-xl shadow-sm overflow-hidden">
        <div className="p-6 border-b border-gray-200">
          <h2 className="text-lg font-bold text-gray-900">Interventions en temps réel</h2>
        </div>
        <div className="divide-y divide-gray-200">
          {interventions.length === 0 ? (
            <div className="p-12 text-center text-gray-500">
              <Navigation className="w-12 h-12 mx-auto mb-4 opacity-20" />
              <p>Aucune intervention active</p>
            </div>
          ) : (
            <>
            {currentInterventions.map((intervention) => (
              <div key={intervention.id} className="p-6 hover:bg-gray-50">
                <div className="flex items-start justify-between mb-4">
                  <div className="flex-1">
                    <div className="flex items-center gap-3 mb-2">
                      <h3 className="font-semibold text-gray-900">
                        {intervention.titre || 'Sans titre'}
                      </h3>
                      {getStatutBadge(intervention.etat)}
                    </div>
                    <p className="text-sm text-gray-600 mb-2">
                      {intervention.description?.substring(0, 150)}
                      {intervention.description?.length > 150 ? '...' : ''}
                    </p>
                    <div className="flex items-center gap-4 text-sm text-gray-500">
                      <span className="flex items-center gap-1">
                        <MapPin className="w-4 h-4" />
                        {intervention.adresse || 'Adresse non spécifiée'}
                      </span>
                      <span>
                        Catégorie: {intervention.categorie}
                      </span>
                    </div>
                  </div>
                </div>

                <div className="flex items-center justify-between pt-4 border-t border-gray-100">
                  {intervention.assigned_user ? (
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 bg-purple-100 rounded-full flex items-center justify-center">
                        <User className="w-5 h-5 text-purple-600" />
                      </div>
                      <div>
                        <p className="font-medium text-gray-900">
                          {intervention.assigned_user.nom} {intervention.assigned_user.prenom}
                        </p>
                        <div className="flex items-center gap-3 text-xs text-gray-500">
                          <span className="flex items-center gap-1">
                            <Phone className="w-3 h-3" />
                            {intervention.assigned_user.telephone || 'N/A'}
                          </span>
                          <span className="px-2 py-1 bg-blue-100 text-blue-700 rounded text-xs font-medium">
                            {intervention.assigned_user.role}
                          </span>
                        </div>
                      </div>
                    </div>
                  ) : (
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 bg-gray-100 rounded-full flex items-center justify-center">
                        <User className="w-5 h-5 text-gray-400" />
                      </div>
                      <div>
                        <p className="font-medium text-gray-500">Non assigné</p>
                      </div>
                    </div>
                  )}

                  <div className="flex items-center gap-2">
                    <span className="text-xs text-gray-500">
                      Démarré: {format(new Date(intervention.created_at), 'HH:mm', { locale: fr })}
                    </span>
                    {intervention.latitude && intervention.longitude && (
                      <button
                        onClick={() =>
                          openInMaps(
                            intervention.latitude,
                            intervention.longitude,
                            intervention.adresse
                          )
                        }
                        className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white text-sm rounded-lg hover:bg-blue-700"
                      >
                        <Navigation className="w-4 h-4" />
                        Voir sur la carte
                      </button>
                    )}
                  </div>
                </div>
              </div>
            ))}
            </>
          )}
        </div>

        {/* Pagination améliorée */}
        {interventions.length > 0 && (
          <div className="border-t border-gray-200 bg-gradient-to-r from-gray-50 to-white">
            <div className="flex items-center justify-between px-6 py-4">
              {/* Informations et sélecteur */}
              <div className="flex items-center gap-6">
                <div className="flex items-center gap-2">
                  <div className="text-sm text-gray-700 font-medium">
                    <span className="text-blue-600">{startIndex + 1}-{Math.min(endIndex, interventions.length)}</span>
                    <span className="text-gray-500"> sur </span>
                    <span className="text-blue-600">{interventions.length}</span>
                    <span className="text-gray-500"> intervention(s)</span>
                  </div>
                </div>
                
                <div className="h-6 w-px bg-gray-300"></div>
                
                <div className="flex items-center gap-2">
                  <label className="text-sm text-gray-600 font-medium">Afficher:</label>
                  <select
                    value={itemsPerPage}
                    onChange={(e) => {
                      setItemsPerPage(Number(e.target.value));
                      setCurrentPage(1);
                    }}
                    className="px-3 py-1.5 border border-gray-300 rounded-lg text-sm font-medium focus:ring-2 focus:ring-blue-500 focus:border-blue-500 bg-white cursor-pointer hover:border-blue-400 transition-colors"
                  >
                    <option value={5}>5 lignes</option>
                    <option value={10}>10 lignes</option>
                    <option value={20}>20 lignes</option>
                    <option value={50}>50 lignes</option>
                  </select>
                </div>
              </div>

              {/* Contrôles de navigation */}
              <div className="flex items-center gap-2">
                {/* Première page */}
                <button 
                  onClick={() => goToPage(1)} 
                  disabled={currentPage === 1} 
                  className="p-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 disabled:opacity-40 disabled:cursor-not-allowed transition-all hover:shadow-sm"
                  title="Première page"
                >
                  <span className="text-base">««</span>
                </button>
                
                {/* Page précédente */}
                <button 
                  onClick={() => goToPage(currentPage - 1)} 
                  disabled={currentPage === 1} 
                  className="px-3 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 disabled:opacity-40 disabled:cursor-not-allowed transition-all hover:shadow-sm flex items-center gap-1"
                  title="Page précédente"
                >
                  <span>‹</span>
                  <span className="hidden sm:inline">Précédent</span>
                </button>
                
                {/* Numéros de page */}
                <div className="flex items-center gap-1">
                  {Array.from({ length: Math.min(totalPages, 5) }, (_, i) => {
                    let page;
                    if (totalPages <= 5) {
                      page = i + 1;
                    } else if (currentPage <= 3) {
                      page = i + 1;
                    } else if (currentPage >= totalPages - 2) {
                      page = totalPages - 4 + i;
                    } else {
                      page = currentPage - 2 + i;
                    }
                    
                    const isActive = currentPage === page;
                    
                    return (
                      <button 
                        key={page} 
                        onClick={() => goToPage(page)} 
                        className={`min-w-[40px] px-3 py-2 text-sm rounded-lg font-medium transition-all ${
                          isActive 
                            ? 'bg-blue-600 text-white shadow-md hover:bg-blue-700' 
                            : 'text-gray-700 bg-white border border-gray-300 hover:bg-gray-50 hover:shadow-sm'
                        }`}
                      >
                        {page}
                      </button>
                    );
                  })}
                </div>

                {/* Page suivante */}
                <button 
                  onClick={() => goToPage(currentPage + 1)} 
                  disabled={currentPage === totalPages} 
                  className="px-3 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 disabled:opacity-40 disabled:cursor-not-allowed transition-all hover:shadow-sm flex items-center gap-1"
                  title="Page suivante"
                >
                  <span className="hidden sm:inline">Suivant</span>
                  <span>›</span>
                </button>
                
                {/* Dernière page */}
                <button 
                  onClick={() => goToPage(totalPages)} 
                  disabled={currentPage === totalPages} 
                  className="p-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 disabled:opacity-40 disabled:cursor-not-allowed transition-all hover:shadow-sm"
                  title="Dernière page"
                >
                  <span className="text-base">»»</span>
                </button>
              </div>
            </div>
            
            {/* Barre de progression */}
            <div className="px-6 pb-3">
              <div className="w-full bg-gray-200 rounded-full h-1.5">
                <div 
                  className="bg-blue-600 h-1.5 rounded-full transition-all duration-300"
                  style={{ width: `${(currentPage / totalPages) * 100}%` }}
                ></div>
              </div>
              <div className="flex justify-between mt-1">
                <span className="text-xs text-gray-500">Page {currentPage} sur {totalPages}</span>
                <span className="text-xs text-gray-500">{Math.round((currentPage / totalPages) * 100)}% parcouru</span>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Légende */}
      <div className="mt-6 bg-blue-50 rounded-xl p-6">
        <h3 className="font-semibold text-gray-900 mb-3">ℹ️ Informations</h3>
        <ul className="space-y-2 text-sm text-gray-700">
          <li>• Les interventions sont mises à jour automatiquement en temps réel</li>
          <li>• Cliquez sur "Voir sur la carte" pour ouvrir Google Maps avec la localisation exacte</li>
          <li>• Les opérateurs peuvent être contactés directement par téléphone si assignés</li>
          <li>• Statut "En cours" = Intervention en cours de traitement / "En attente" = En attente de prise en charge</li>
        </ul>
      </div>
    </div>
  );
};

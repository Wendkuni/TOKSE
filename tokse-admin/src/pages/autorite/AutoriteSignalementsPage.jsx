import { format } from 'date-fns';
import { fr } from 'date-fns/locale';
import {
  AlertTriangle,
  CheckCircle,
  Clock,
  Eye,
  FileText,
  Filter,
  MapPin,
  Search,
  UserCheck,
  X,
  XCircle
} from 'lucide-react';
import { useEffect, useState } from 'react';
import { useAuth } from '../../contexts/AuthContext';
import { supabase, getAudioPublicUrl } from '../../lib/supabase';

// Fonction pour mapper le role de l'utilisateur vers autorite_type
const getAutoriteType = (user) => {
  if (!user) return null;
  
  // Si autorite_type est déjà défini, l'utiliser
  if (user.autorite_type) return user.autorite_type;
  
  // Sinon, mapper le role vers autorite_type
  const roleMapping = {
    'police': 'police',
    'police_municipale': 'police',
    'hygiene': 'hygiene',
    'voirie': 'voirie',
    'environnement': 'environnement',
    'securite': 'securite',
    'mairie': 'mairie'
  };
  
  return roleMapping[user.role] || user.role;
};

export const AutoriteSignalementsPage = () => {
  const { user } = useAuth();
  const [signalements, setSignalements] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filters, setFilters] = useState({
    etat: '',
    categorie: '',
    search: '',
  });
  const [selectedSignalement, setSelectedSignalement] = useState(null);
  const [showDetailModal, setShowDetailModal] = useState(false);
  
  // Pagination
  const [currentPage, setCurrentPage] = useState(1);
  const [itemsPerPage, setItemsPerPage] = useState(5);

  useEffect(() => {
    fetchSignalements();

    // Real-time updates
    const channel = supabase
      .channel('autorite_signalements_updates')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'signalements' }, () => {
        fetchSignalements();
      })
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [user, filters]);

  const fetchSignalements = async () => {
    console.log('🚀 Début fetchSignalements...');
    const autoriteType = getAutoriteType(user);
    console.log('   - User autorite_type:', autoriteType);
    console.log('   - User ID:', user?.id);
    
    try {
      setLoading(true);
      
      // Récupérer TOUS les signalements d'abord pour diagnostic
      const { data: allData, error: allError } = await supabase
        .from('signalements')
        .select(`
          *,
          user:users!signalements_user_id_fkey(nom, prenom, email, telephone, created_at)
        `)
        .order('created_at', { ascending: false });
      
      console.log('📊 TOUS les signalements:', allData?.length || 0);
      console.log('   Détails:', allData);
      
      // Récupérer tous les signalements (nouvelle architecture sans autorite_type)
      let query = supabase
        .from('signalements')
        .select(`
          *,
          user:users!signalements_user_id_fkey(nom, prenom, email, telephone, created_at),
          assigned_user:users!signalements_assigned_to_fkey(nom, prenom, role)
        `)
        .order('created_at', { ascending: false });

      if (filters.etat) {
        query = query.eq('etat', filters.etat);
      }
      if (filters.categorie) {
        query = query.eq('categorie', filters.categorie);
      }

      const { data, error } = await query;
      
      console.log('📥 Réponse Supabase:');
      console.log('   - Error:', error);
      console.log('   - Data filtrée:', data?.length || 0);
      
      if (error) throw error;

      // Filtrage par recherche
      let filteredData = data || [];
      if (filters.search) {
        const searchLower = filters.search.toLowerCase();
        filteredData = filteredData.filter(
          (sig) =>
            sig.titre?.toLowerCase().includes(searchLower) ||
            sig.description?.toLowerCase().includes(searchLower) ||
            sig.adresse?.toLowerCase().includes(searchLower)
        );
      }

      console.log('✅ Signalements affichés:', filteredData.length);
      setSignalements(filteredData);
    } catch (error) {
      console.error('❌ Error fetching signalements:', error);
    } finally {
      setLoading(false);
    }
  };

  const updateSignalementStatus = async (signalementId, newEtat) => {
    try {
      const updateData = { 
        etat: newEtat, 
        updated_at: new Date().toISOString() 
      };
      
      // Si prise en charge, assigner à l'autorité
      if (newEtat === 'en_cours') {
        updateData.assigned_to = user?.id;
        updateData.locked = true;
      }
      
      // Si résolu, ajouter la date de résolution
      if (newEtat === 'resolu') {
        updateData.resolved_at = new Date().toISOString();
      }
      
      const { error } = await supabase
        .from('signalements')
        .update(updateData)
        .eq('id', signalementId);

      if (error) throw error;

      // Logger l'action
      await supabase.from('logs_activite').insert({
        type_action: 'modification_statut_signalement',
        autorite_id: user?.id,
        details: {
          signalement_id: signalementId,
          nouveau_statut: newEtat,
          timestamp: new Date().toISOString(),
        },
      });

      alert('✅ Statut mis à jour !');
      fetchSignalements();
      setShowDetailModal(false);
    } catch (error) {
      console.error('Error updating signalement status:', error);
      alert(`❌ Erreur: ${error.message}`);
    }
  };

  const getEtatBadge = (etat) => {
    switch (etat) {
      case 'en_attente':
        return (
          <span className="inline-flex items-center gap-1 px-3 py-1 rounded-full bg-yellow-100 text-yellow-700 text-xs font-medium">
            <Clock className="w-3 h-3" />
            En attente
          </span>
        );
      case 'en_cours':
        return (
          <span className="inline-flex items-center gap-1 px-3 py-1 rounded-full bg-blue-100 text-blue-700 text-xs font-medium">
            <UserCheck className="w-3 h-3" />
            En cours
          </span>
        );
      case 'resolu':
        return (
          <span className="inline-flex items-center gap-1 px-3 py-1 rounded-full bg-green-100 text-green-700 text-xs font-medium">
            <CheckCircle className="w-3 h-3" />
            Résolu
          </span>
        );
      default:
        return <span className="px-3 py-1 rounded-full bg-gray-100 text-gray-700 text-xs font-medium">{etat}</span>;
    }
  };

  const openDetailModal = (signalement) => {
    setSelectedSignalement(signalement);
    setShowDetailModal(true);
  };

  // Calcul pagination
  const totalPages = Math.ceil(signalements.length / itemsPerPage);
  const startIndex = (currentPage - 1) * itemsPerPage;
  const endIndex = startIndex + itemsPerPage;
  const currentSignalements = signalements.slice(startIndex, endIndex);

  const goToPage = (page) => {
    setCurrentPage(Math.max(1, Math.min(page, totalPages)));
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64 bg-gray-50">
        <div className="text-center">
          <div className="animate-spin rounded-full h-16 w-16 border-4 border-gray-200 border-t-blue-600"></div>
          <p className="text-gray-600 text-sm mt-4">
            Chargement des signalements...
          </p>
        </div>
      </div>
    );
  }

  return (
    <div className="flex flex-col h-screen overflow-hidden bg-gray-50">
      {/* Header */}
      <div className="flex-shrink-0 bg-white border-b border-gray-200 px-6 py-6">
        <div className="mb-6">
          <div className="flex items-center gap-4">
            <FileText className="w-10 h-10 text-gray-600" />
            <div>
              <h1 className="text-2xl font-bold text-gray-900">Gestion des signalements</h1>
              <p className="text-gray-600 text-sm mt-1">
                Prise en charge et suivi des interventions
              </p>
            </div>
          </div>
        </div>

        {/* Stats rapides */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
          <p className="text-gray-600 text-xs">Total</p>
          <p className="text-4xl font-bold text-gray-900 mt-2">{signalements.length}</p>
        </div>
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
          <p className="text-gray-600 text-xs">En attente</p>
          <p className="text-4xl font-bold text-gray-900 mt-2">
            {signalements.filter((s) => s.etat === 'en_attente').length}
          </p>
        </div>
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
          <p className="text-gray-600 text-xs">En cours</p>
          <p className="text-4xl font-bold text-gray-900 mt-2">
            {signalements.filter((s) => s.etat === 'en_cours').length}
          </p>
        </div>
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
          <p className="text-gray-600 text-xs">Résolus</p>
          <p className="text-4xl font-bold text-gray-900 mt-2">
            {signalements.filter((s) => s.etat === 'resolu').length}
          </p>
        </div>
      </div>

      {/* Filtres */}
      <div className="bg-white rounded-xl shadow-sm p-6 mb-6">
        <div className="flex items-center gap-2 mb-4">
          <Filter className="w-5 h-5 text-gray-600" />
          <h3 className="font-semibold text-gray-900">Filtres</h3>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-gray-400" />
            <input
              type="text"
              value={filters.search}
              onChange={(e) => setFilters({ ...filters, search: e.target.value })}
              placeholder="Rechercher..."
              className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
            />
          </div>
          <select
            value={filters.etat}
            onChange={(e) => setFilters({ ...filters, etat: e.target.value })}
            className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
          >
            <option value="">Tous les états</option>
            <option value="en_attente">En attente</option>
            <option value="en_cours">En cours</option>
            <option value="resolu">Résolu</option>
          </select>
          <select
            value={filters.categorie}
            onChange={(e) => setFilters({ ...filters, categorie: e.target.value })}
            className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
          >
            <option value="">Toutes les catégories</option>
            <option value="dechets">Déchets</option>
            <option value="route degradée">Route dégradée</option>
            <option value="polution">Pollution</option>
            <option value="autre">Autre</option>
          </select>
        </div>
      </div>

      </div>

      {/* Zone scrollable avec le tableau */}
      <div className="flex-1 overflow-auto px-6 pb-6">
        <div className="bg-white rounded-xl shadow-sm">
          <table className="w-full">
            <thead className="bg-gray-50 border-b-2 border-gray-200 sticky top-0 z-20 shadow-sm">
              <tr>
                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase bg-gray-50">Signalement</th>
                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase bg-gray-50">Catégorie</th>
                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase bg-gray-50">Utilisateur</th>
                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase bg-gray-50">Localisation</th>
                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase bg-gray-50">Statut</th>
                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase bg-gray-50">Date</th>
                <th className="px-6 py-4 text-right text-xs font-semibold text-gray-600 uppercase">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200 bg-white">
              {currentSignalements.map((sig) => (
                <tr key={sig.id} className="hover:bg-gray-50">
                  <td className="px-6 py-4">
                    <div className="flex items-start gap-3">
                      <AlertTriangle className="w-5 h-5 text-orange-500 mt-1" />
                      <div>
                        <div className="font-medium text-gray-900">{sig.titre}</div>
                        <div className="text-sm text-gray-600 mt-1">{sig.description?.substring(0, 100)}...</div>
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <span className="inline-flex items-center px-3 py-1 rounded-full text-xs font-medium bg-purple-100 text-purple-700">
                      {sig.categorie}
                    </span>
                  </td>
                  <td className="px-6 py-4">
                    {sig.user ? (
                      <div>
                        <div className="text-sm font-medium text-gray-900">
                          {sig.user.nom} {sig.user.prenom}
                        </div>
                        <div className="text-xs text-gray-500">{sig.user.telephone}</div>
                      </div>
                    ) : (
                      <span className="text-sm text-gray-400">N/A</span>
                    )}
                  </td>
                  <td className="px-6 py-4">
                    <span className="flex items-center gap-2 text-sm text-gray-600">
                      <MapPin className="w-4 h-4" />
                      {sig.adresse || 'Non spécifié'}
                    </span>
                  </td>
                  <td className="px-6 py-4">{getEtatBadge(sig.etat)}</td>
                  <td className="px-6 py-4">
                    <span className="text-sm text-gray-600">
                      {format(new Date(sig.created_at), 'dd MMM yyyy HH:mm', { locale: fr })}
                    </span>
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex items-center justify-end gap-2">
                      <button
                        onClick={() => openDetailModal(sig)}
                        className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
                        title="Voir détails"
                      >
                        <Eye className="w-4 h-4 text-gray-600" />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>

          {signalements.length === 0 && (
            <div className="text-center py-12 text-gray-500 bg-white">
              <FileText className="w-12 h-12 mx-auto mb-4 opacity-20" />
              <p>Aucun signalement trouvé</p>
            </div>
          )}

          {/* Pagination améliorée */}
          {signalements.length > 0 && (
            <div className="border-t border-gray-200 bg-gradient-to-r from-gray-50 to-white">
              <div className="flex items-center justify-between px-6 py-4">
                <div className="flex items-center gap-6">
                  <div className="flex items-center gap-2">
                    <div className="text-sm text-gray-700 font-medium">
                      <span className="text-blue-600">{startIndex + 1}-{Math.min(endIndex, signalements.length)}</span>
                      <span className="text-gray-500"> sur </span>
                      <span className="text-blue-600">{signalements.length}</span>
                      <span className="text-gray-500"> signalement(s)</span>
                    </div>
                  </div>
                  <div className="h-6 w-px bg-gray-300"></div>
                  <div className="flex items-center gap-2">
                    <label className="text-sm text-gray-600 font-medium">Afficher:</label>
                    <select value={itemsPerPage} onChange={(e) => { setItemsPerPage(Number(e.target.value)); setCurrentPage(1); }} className="px-3 py-1.5 border border-gray-300 rounded-lg text-sm font-medium focus:ring-2 focus:ring-blue-500 focus:border-blue-500 bg-white cursor-pointer hover:border-blue-400 transition-colors">
                      <option value={5}>5 lignes</option>
                      <option value={10}>10 lignes</option>
                      <option value={20}>20 lignes</option>
                      <option value={50}>50 lignes</option>
                    </select>
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  <button onClick={() => goToPage(1)} disabled={currentPage === 1} className="p-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 disabled:opacity-40 disabled:cursor-not-allowed transition-all hover:shadow-sm" title="Première page"><span className="text-base">««</span></button>
                  <button onClick={() => goToPage(currentPage - 1)} disabled={currentPage === 1} className="px-3 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 disabled:opacity-40 disabled:cursor-not-allowed transition-all hover:shadow-sm flex items-center gap-1" title="Page précédente"><span>‹</span><span className="hidden sm:inline">Précédent</span></button>
                  <div className="flex items-center gap-1">
                    {Array.from({ length: Math.min(totalPages, 5) }, (_, i) => {
                      let page;
                      if (totalPages <= 5) { page = i + 1; }
                      else if (currentPage <= 3) { page = i + 1; }
                      else if (currentPage >= totalPages - 2) { page = totalPages - 4 + i; }
                      else { page = currentPage - 2 + i; }
                      const isActive = currentPage === page;
                      return <button key={page} onClick={() => goToPage(page)} className={`min-w-[40px] px-3 py-2 text-sm rounded-lg font-medium transition-all ${isActive ? 'bg-blue-600 text-white shadow-md hover:bg-blue-700' : 'text-gray-700 bg-white border border-gray-300 hover:bg-gray-50 hover:shadow-sm'}`}>{page}</button>;
                    })}
                  </div>
                  <button onClick={() => goToPage(currentPage + 1)} disabled={currentPage === totalPages} className="px-3 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 disabled:opacity-40 disabled:cursor-not-allowed transition-all hover:shadow-sm flex items-center gap-1" title="Page suivante"><span className="hidden sm:inline">Suivant</span><span>›</span></button>
                  <button onClick={() => goToPage(totalPages)} disabled={currentPage === totalPages} className="p-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 disabled:opacity-40 disabled:cursor-not-allowed transition-all hover:shadow-sm" title="Dernière page"><span className="text-base">»»</span></button>
                </div>
              </div>
              <div className="px-6 pb-3">
                <div className="w-full bg-gray-200 rounded-full h-1.5">
                  <div className="bg-blue-600 h-1.5 rounded-full transition-all duration-300" style={{ width: `${(currentPage / totalPages) * 100}%` }}></div>
                </div>
                <div className="flex justify-between mt-1">
                  <span className="text-xs text-gray-500">Page {currentPage} sur {totalPages}</span>
                  <span className="text-xs text-gray-500">{Math.round((currentPage / totalPages) * 100)}% parcouru</span>
                </div>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Modal Détails */}
      {showDetailModal && selectedSignalement && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-xl max-w-3xl w-full max-h-[90vh] overflow-y-auto">
            <div className="p-6 border-b border-gray-200 flex justify-between items-start">
              <div>
                <h2 className="text-2xl font-bold text-gray-900">{selectedSignalement.titre}</h2>
                <p className="text-gray-600 mt-1">{getEtatBadge(selectedSignalement.etat)}</p>
              </div>
              <button
                onClick={() => setShowDetailModal(false)}
                className="p-2 text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                title="Fermer"
              >
                <X className="w-6 h-6" />
              </button>
            </div>
            <div className="p-6 space-y-6">
              {/* Informations de l'utilisateur */}
              <div className="bg-blue-50 rounded-lg p-4 border border-blue-200">
                <h3 className="font-semibold text-gray-900 mb-3 flex items-center gap-2">
                  <UserCheck className="w-5 h-5 text-blue-600" />
                  Informations de l'utilisateur
                </h3>
                <div className="flex items-start gap-4">
                  {/* Photo de profil */}
                  <div className="flex-shrink-0">
                    {selectedSignalement.user?.photo_url ? (
                      <img
                        src={selectedSignalement.user.photo_url}
                        alt="Photo de profil"
                        className="w-16 h-16 rounded-full object-cover border-2 border-blue-300"
                      />
                    ) : (
                      <div className="w-16 h-16 rounded-full bg-blue-200 flex items-center justify-center border-2 border-blue-300">
                        <UserCheck className="w-8 h-8 text-blue-600" />
                      </div>
                    )}
                  </div>
                  {/* Détails de l'utilisateur */}
                  <div className="flex-1 grid grid-cols-2 gap-3">
                    <div>
                      <p className="text-xs text-gray-500">Nom complet</p>
                      <p className="font-medium text-gray-900">
                        {selectedSignalement.user?.nom} {selectedSignalement.user?.prenom}
                      </p>
                    </div>
                    <div>
                      <p className="text-xs text-gray-500">Email</p>
                      <p className="font-medium text-gray-900">{selectedSignalement.user?.email || 'Non renseigné'}</p>
                    </div>
                    <div>
                      <p className="text-xs text-gray-500">Téléphone</p>
                      <p className="font-medium text-gray-900">{selectedSignalement.user?.telephone || 'Non renseigné'}</p>
                    </div>
                    <div>
                      <p className="text-xs text-gray-500">Membre depuis</p>
                      <p className="font-medium text-gray-900">
                        {selectedSignalement.user?.created_at 
                          ? format(new Date(selectedSignalement.user.created_at), 'dd/MM/yyyy', { locale: fr })
                          : 'N/A'}
                      </p>
                    </div>
                  </div>
                </div>
              </div>

              <div>
                <h3 className="font-semibold text-gray-900 mb-2">Description</h3>
                {/* Si audio présent, afficher le lecteur */}
                {selectedSignalement.audio_url ? (
                  <div className="space-y-2">
                    <div className="bg-blue-50 p-3 rounded-lg border border-blue-200">
                      <p className="text-xs text-blue-600 mb-2">🎙️ Enregistrement audio :</p>
                      <audio 
                        controls 
                        className="w-full"
                        style={{ height: '40px' }}
                        key={selectedSignalement.id}
                      >
                        <source src={getAudioPublicUrl(selectedSignalement.audio_url)} type="audio/mpeg" />
                        <source src={getAudioPublicUrl(selectedSignalement.audio_url)} type="audio/wav" />
                        <source src={getAudioPublicUrl(selectedSignalement.audio_url)} type="audio/ogg" />
                        Votre navigateur ne supporte pas la lecture audio.
                      </audio>
                      {selectedSignalement.audio_duration && (
                        <p className="text-xs text-gray-500 mt-1">
                          Durée : {Math.floor(selectedSignalement.audio_duration / 60)}:{String(selectedSignalement.audio_duration % 60).padStart(2, '0')}
                        </p>
                      )}
                    </div>
                    {selectedSignalement.description && (
                      <p className="text-sm text-gray-500 italic">+ Texte : {selectedSignalement.description}</p>
                    )}
                  </div>
                ) : (
                  <p className="text-gray-600">{selectedSignalement.description}</p>
                )}
              </div>
              
              <div>
                <h3 className="font-semibold text-gray-900 mb-2">Localisation</h3>
                <a
                  href={`https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(selectedSignalement.adresse || '')}`}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-blue-600 hover:text-blue-800 flex items-center gap-2 font-medium"
                >
                  <MapPin className="w-4 h-4" />
                  {selectedSignalement.adresse}
                  <span className="text-xs">(Ouvrir dans Google Maps)</span>
                </a>
                {selectedSignalement.latitude && selectedSignalement.longitude && (
                  <p className="text-xs text-gray-500 mt-1">
                    GPS: {selectedSignalement.latitude}, {selectedSignalement.longitude}
                  </p>
                )}
              </div>
              
              {selectedSignalement.photoUrl && (
                <div>
                  <h3 className="font-semibold text-gray-900 mb-2">Photo du signalement</h3>
                  <img
                    src={selectedSignalement.photoUrl}
                    alt="Signalement"
                    className="w-full rounded-lg border border-gray-200"
                  />
                </div>
              )}
              
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <h3 className="font-semibold text-gray-900 mb-2">Catégorie</h3>
                  <p className="text-gray-600">{selectedSignalement.categorie}</p>
                </div>
                <div>
                  <h3 className="font-semibold text-gray-900 mb-2">Date de création</h3>
                  <p className="text-gray-600">
                    {format(new Date(selectedSignalement.created_at), 'dd MMM yyyy HH:mm', { locale: fr })}
                  </p>
                </div>
              </div>

              {/* Actions */}
              <div className="flex gap-3">
                {selectedSignalement.etat === 'en_attente' && (
                  <button
                    onClick={() => updateSignalementStatus(selectedSignalement.id, 'en_cours')}
                    className="flex-1 px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 flex items-center justify-center gap-2"
                  >
                    <CheckCircle className="w-5 h-5" />
                    Prendre en charge
                  </button>
                )}
                {selectedSignalement.etat === 'en_cours' && (
                  <button
                    onClick={() => updateSignalementStatus(selectedSignalement.id, 'resolu')}
                    className="flex-1 px-6 py-3 bg-green-600 text-white rounded-lg hover:bg-green-700 flex items-center justify-center gap-2"
                  >
                    <CheckCircle className="w-5 h-5" />
                    Marquer comme résolu
                  </button>
                )}
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

import { format } from 'date-fns';
import { fr } from 'date-fns/locale';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import { Calendar, Filter, MapPin } from 'lucide-react';
import { useEffect, useState } from 'react';
import { MapContainer, Marker, Popup, TileLayer } from 'react-leaflet';
import MarkerClusterGroup from 'react-leaflet-cluster';
import { supabase, getAudioPublicUrl } from '../lib/supabase';

// Styles pour les clusters et animations NASA
const clusterStyles = `
  @keyframes pulse-ring {
    0% {
      transform: scale(1);
      opacity: 1;
    }
    100% {
      transform: scale(1.5);
      opacity: 0;
    }
  }
  
  @keyframes radar-ping {
    0% {
      transform: scale(1);
      opacity: 0.8;
    }
    50% {
      opacity: 0.4;
    }
    100% {
      transform: scale(2);
      opacity: 0;
    }
  }
  
  @keyframes cluster-glow {
    0%, 100% {
      box-shadow: 0 0 20px rgba(26, 115, 232, 0.6);
    }
    50% {
      box-shadow: 0 0 40px rgba(26, 115, 232, 1);
    }
  }

  .marker-cluster-small,
  .marker-cluster-medium,
  .marker-cluster-large {
    background-color: rgba(26, 115, 232, 0.3) !important;
    border: 4px solid white !important;
    animation: cluster-glow 2s ease-in-out infinite !important;
  }
  
  .marker-cluster-small div,
  .marker-cluster-medium div,
  .marker-cluster-large div {
    background-color: rgba(26, 115, 232, 0.95) !important;
    font-size: 24px !important;
    font-weight: 900 !important;
    color: white !important;
    width: 60px !important;
    height: 60px !important;
    display: flex !important;
    align-items: center !important;
    justify-content: center !important;
    text-shadow: 0 0 8px rgba(0, 0, 0, 0.5) !important;
    line-height: 60px !important;
  }
  
  .marker-cluster-small {
    width: 60px !important;
    height: 60px !important;
  }
  
  .marker-cluster-medium {
    width: 70px !important;
    height: 70px !important;
  }
  
  .marker-cluster-medium div {
    font-size: 28px !important;
    width: 70px !important;
    height: 70px !important;
    line-height: 70px !important;
  }
  
  .marker-cluster-large {
    width: 80px !important;
    height: 80px !important;
  }
  
  .marker-cluster-large div {
    font-size: 32px !important;
    width: 80px !important;
    height: 80px !important;
    line-height: 80px !important;
  }
`;

// Injecter les styles
if (typeof document !== 'undefined') {
  const styleEl = document.createElement('style');
  styleEl.innerHTML = clusterStyles;
  document.head.appendChild(styleEl);
}

// Fix Leaflet default marker icon issue
import iconRetina from 'leaflet/dist/images/marker-icon-2x.png';
import icon from 'leaflet/dist/images/marker-icon.png';
import iconShadow from 'leaflet/dist/images/marker-shadow.png';

delete L.Icon.Default.prototype._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl: iconRetina,
  iconUrl: icon,
  shadowUrl: iconShadow,
});

// Custom marker icons - NASA Style
const getMarkerIcon = (statut) => {
  const styles = {
    en_attente: { 
      color: '#f59e0b', 
      glow: 'rgba(245, 158, 11, 0.8)',
      symbol: '⚠️',
      ring: true
    },
    en_cours: { 
      color: '#3b82f6', 
      glow: 'rgba(59, 130, 246, 0.8)',
      symbol: '🔄',
      ring: true
    },
    resolu: { 
      color: '#10b981', 
      glow: 'rgba(16, 185, 129, 0.8)',
      symbol: '✓',
      ring: false
    },
  };

  const style = styles[statut] || { color: '#6b7280', glow: 'rgba(107, 114, 128, 0.5)', symbol: '📍', ring: false };

  return L.divIcon({
    html: `
      <div style="position: relative; width: 40px; height: 40px;">
        <!-- Main marker circle -->
        <div style="
          position: absolute;
          inset: 0;
          width: 40px;
          height: 40px;
          background: ${style.color};
          border-radius: 50%;
          border: 3px solid white;
          box-shadow: 0 0 20px ${style.glow};
          display: flex;
          align-items: center;
          justify-content: center;
          font-size: 18px;
          z-index: 2;
        ">${style.symbol}</div>
        
        ${style.ring ? `
          <!-- Pulsing ring animation -->
          <div style="
            position: absolute;
            inset: 0;
            width: 40px;
            height: 40px;
            border: 2px solid ${style.color};
            border-radius: 50%;
            animation: pulse-ring 2s cubic-bezier(0.455, 0.03, 0.515, 0.955) infinite;
            z-index: 1;
          "></div>
        ` : ''}
        
        <!-- Radar ping effect -->
        <div style="
          position: absolute;
          inset: 0;
          width: 40px;
          height: 40px;
          background: radial-gradient(circle, ${style.glow} 0%, transparent 70%);
          border-radius: 50%;
          animation: radar-ping 3s ease-out infinite;
          z-index: 0;
        "></div>
      </div>
    `,
    iconSize: [40, 40],
    iconAnchor: [20, 20],
  });
};

export const SignalementsMapPage = () => {
  const [signalements, setSignalements] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filterStatus, setFilterStatus] = useState('all');
  const [filterType, setFilterType] = useState('all');
  const [filterLocation, setFilterLocation] = useState('all');
  const [dateRange, setDateRange] = useState('all');

  useEffect(() => {
    fetchSignalements();

    // Real-time subscription
    const channel = supabase
      .channel('signalements_map_updates')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'signalements' }, () => {
        fetchSignalements();
      })
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [filterStatus, filterType, filterLocation, dateRange]);

  const fetchSignalements = async () => {
    try {
      setLoading(true);
      let query = supabase
        .from('signalements')
        .select(`
          *,
          user:user_id(nom, prenom, email, telephone)
        `)
        .not('latitude', 'is', null)
        .not('longitude', 'is', null)
        .order('created_at', { ascending: false });

      if (filterStatus !== 'all') {
        query = query.eq('etat', filterStatus);
      }

      if (filterType !== 'all') {
        query = query.eq('type_dechet', filterType);
      }

      if (filterLocation !== 'all') {
        query = query.ilike('adresse', `%${filterLocation}%`);
      }

      if (dateRange !== 'all') {
        const now = new Date();
        let startDate;
        
        switch (dateRange) {
          case 'today':
            startDate = new Date(now.setHours(0, 0, 0, 0));
            break;
          case 'week':
            startDate = new Date(now.setDate(now.getDate() - 7));
            break;
          case 'month':
            startDate = new Date(now.setMonth(now.getMonth() - 1));
            break;
        }

        if (startDate) {
          query = query.gte('created_at', startDate.toISOString());
        }
      }

      const { data, error } = await query;
      if (error) throw error;

      setSignalements(data || []);
    } catch (error) {
      console.error('Error fetching signalements:', error);
    } finally {
      setLoading(false);
    }
  };

  const getStatusLabel = (statut) => {
    const labels = {
      en_attente: 'En attente',
      en_cours: 'En cours',
      resolu: 'Résolu',
    };
    return labels[statut] || statut;
  };

  const getStatusColor = (statut) => {
    const colors = {
      en_attente: 'bg-orange-100 text-orange-700',
      en_cours: 'bg-blue-100 text-blue-700',
      resolu: 'bg-green-100 text-green-700',
    };
    return colors[statut] || 'bg-gray-100 text-gray-700';
  };

  // Center on Burkina Faso (centre du pays)
  const defaultCenter = [12.2383, -1.5616];
  const defaultZoom = 7;

  // Calculer les statistiques en temps réel
  const stats = {
    total: signalements.length,
    enAttente: signalements.filter(s => s.etat === 'en_attente').length,
    enCours: signalements.filter(s => s.etat === 'en_cours').length,
    resolu: signalements.filter(s => s.etat === 'resolu').length,
    today: signalements.filter(s => {
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      return new Date(s.created_at) >= today;
    }).length,
    responseRate: signalements.length > 0 
      ? ((signalements.filter(s => s.etat === 'resolu').length / signalements.length) * 100).toFixed(1)
      : 0
  };

  return (
    <div className="p-6">
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900">Carte des signalements</h1>
        <p className="text-gray-600 mt-2">Visualisation géographique en temps réel</p>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-3 lg:grid-cols-6 gap-4 mb-6">
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
          <div className="text-sm text-gray-600">Total</div>
          <div className="text-2xl font-bold text-gray-900">{stats.total}</div>
        </div>
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
          <div className="text-sm text-gray-600">En attente</div>
          <div className="text-2xl font-bold text-orange-600">{stats.enAttente}</div>
        </div>
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
          <div className="text-sm text-gray-600">En cours</div>
          <div className="text-2xl font-bold text-blue-600">{stats.enCours}</div>
        </div>
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
          <div className="text-sm text-gray-600">Résolus</div>
          <div className="text-2xl font-bold text-green-600">{stats.resolu}</div>
        </div>
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
          <div className="text-sm text-gray-600">Aujourd'hui</div>
          <div className="text-2xl font-bold text-purple-600">{stats.today}</div>
        </div>
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
          <div className="text-sm text-gray-600">Taux résolution</div>
          <div className="text-2xl font-bold text-cyan-600">{stats.responseRate}%</div>
        </div>
      </div>

      {/* Filters */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6 mb-6">
        <div className="flex items-center gap-2 mb-4">
          <Filter className="w-5 h-5 text-gray-600" />
          <h3 className="text-lg font-semibold text-gray-900">Filtres</h3>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Statut</label>
            <select
              value={filterStatus}
              onChange={(e) => setFilterStatus(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            >
              <option value="all">Tous les statuts</option>
              <option value="en_attente">En attente</option>
              <option value="en_cours">En cours</option>
              <option value="resolu">Résolu</option>
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Catégorie</label>
            <select
              value={filterType}
              onChange={(e) => setFilterType(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            >
              <option value="all">Toutes catégories</option>
              <option value="dechets">Déchets</option>
              <option value="route">Route</option>
              <option value="pollution">Pollution</option>
              <option value="autre">Autre</option>
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Localisation</label>
            <select
              value={filterLocation}
              onChange={(e) => setFilterLocation(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            >
              <option value="all">Toutes localisations</option>
              <option value="Ouagadougou">Ouagadougou</option>
              <option value="Bobo-Dioulasso">Bobo-Dioulasso</option>
              <option value="Koudougou">Koudougou</option>
              <option value="Banfora">Banfora</option>
              <option value="Ouahigouya">Ouahigouya</option>
              <option value="Kaya">Kaya</option>
              <option value="Fada N'Gourma">Fada N'Gourma</option>
              <option value="Dori">Dori</option>
              <option value="Gaoua">Gaoua</option>
              <option value="Dedougou">Dedougou</option>
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Période</label>
            <select
              value={dateRange}
              onChange={(e) => setDateRange(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            >
              <option value="all">Toute période</option>
              <option value="today">Aujourd'hui</option>
              <option value="week">7 derniers jours</option>
              <option value="month">30 derniers jours</option>
            </select>
          </div>
        </div>
      </div>

      {/* Map Container */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
        {loading ? (
          <div className="h-[700px] flex items-center justify-center bg-gray-50">
            <div className="text-center">
              <div className="relative w-16 h-16 mx-auto mb-4">
                <div className="absolute inset-0 border-4 border-gray-200 rounded-full"></div>
                <div className="absolute inset-0 border-4 border-t-blue-500 rounded-full animate-spin"></div>
              </div>
              <div className="text-gray-700 font-medium">Chargement de la carte...</div>
            </div>
          </div>
        ) : (
          <div className="relative">
            <MapContainer
              center={defaultCenter}
              zoom={defaultZoom}
              style={{ height: '700px', width: '100%' }}
              className="z-0"
            >
              <TileLayer
                url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
                attribution='&copy; Tokse'
              />
              <MarkerClusterGroup
                chunkedLoading
                maxClusterRadius={50}
              >
                {signalements.map((signalement) => (
                  <Marker
                    key={signalement.id}
                    position={[signalement.latitude, signalement.longitude]}
                    icon={getMarkerIcon(signalement.etat)}
                  >
                    <Popup maxWidth={400} className="custom-popup">
                      <div className="p-4 min-w-[350px]">
                        {/* En-tête avec titre et statut */}
                        <div className="mb-4 pb-3 border-b border-gray-200">
                          <div className="flex items-center gap-2 mb-2">
                            <MapPin className="w-5 h-5 text-blue-600" />
                            <h3 className="font-bold text-lg text-gray-900">{signalement.titre}</h3>
                          </div>
                          <span className={`inline-block text-xs px-3 py-1 rounded-full font-semibold ${getStatusColor(signalement.etat)}`}>
                            {getStatusLabel(signalement.etat)}
                          </span>
                        </div>

                        {/* Informations de l'utilisateur */}
                        {signalement.user && (
                          <div className="mb-4 p-3 bg-blue-50 rounded-lg border border-blue-200">
                            <p className="text-xs font-semibold text-blue-900 mb-2">👤 Utilisateur</p>
                            <div className="space-y-1">
                              <p className="text-sm font-medium text-gray-900">
                                {signalement.user.prenom} {signalement.user.nom}
                              </p>
                              {signalement.user.email && (
                                <p className="text-xs text-gray-600">📧 {signalement.user.email}</p>
                              )}
                              {signalement.user.telephone && (
                                <p className="text-xs text-gray-600">📱 {signalement.user.telephone}</p>
                              )}
                            </div>
                          </div>
                        )}
                        
                        {/* Description / Audio */}
                        <div className="mb-4">
                          <p className="text-xs font-semibold text-gray-700 mb-2">Description</p>
                          {signalement.audio_url ? (
                            <div className="space-y-2">
                              <div className="bg-blue-50 p-2 rounded-lg border border-blue-200">
                                <p className="text-xs text-blue-600 mb-1">🎙️ Audio :</p>
                                <audio 
                                  controls 
                                  className="w-full"
                                  style={{ 
                                    height: '36px',
                                    borderRadius: '8px'
                                  }}
                                  key={signalement.id}
                                >
                                  <source src={getAudioPublicUrl(signalement.audio_url)} type="audio/mpeg" />
                                  <source src={getAudioPublicUrl(signalement.audio_url)} type="audio/wav" />
                                  <source src={getAudioPublicUrl(signalement.audio_url)} type="audio/ogg" />
                                </audio>
                                {signalement.audio_duration && (
                                  <p className="text-xs text-gray-500 mt-1">
                                    Durée : {Math.floor(signalement.audio_duration / 60)}:{String(signalement.audio_duration % 60).padStart(2, '0')}
                                  </p>
                                )}
                              </div>
                              {signalement.description && (
                                <p className="text-sm text-gray-700 italic">+ Texte : {signalement.description}</p>
                              )}
                            </div>
                          ) : (
                            <p className="text-sm text-gray-700">{signalement.description}</p>
                          )}
                        </div>
                        
                        {/* Informations supplémentaires */}
                        <div className="space-y-2">
                          {signalement.type_dechet && (
                            <div className="flex items-center justify-between p-2 bg-gray-50 rounded">
                              <span className="text-xs text-gray-600">Catégorie :</span>
                              <span className="text-xs text-gray-900 font-semibold">
                                {signalement.type_dechet?.replace(/_/g, ' ')}
                              </span>
                            </div>
                          )}
                          
                          {signalement.adresse && (
                            <div className="p-2 bg-gray-50 rounded">
                              <span className="text-xs text-gray-600">📍 Localisation :</span>
                              <p className="text-xs text-gray-900 font-medium mt-1">{signalement.adresse}</p>
                            </div>
                          )}
                          
                          <div className="pt-2 border-t border-gray-200">
                            <span className="text-xs text-gray-500">
                              📅 {format(new Date(signalement.created_at), 'dd MMM yyyy • HH:mm', { locale: fr })}
                            </span>
                          </div>
                        </div>
                      </div>
                    </Popup>
                  </Marker>
                ))}
              </MarkerClusterGroup>
            </MapContainer>
          </div>
        )}
      </div>

      {/* Legend - NASA Style */}
      <div className="mt-6 bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Légende des marqueurs</h3>
        <div className="flex flex-wrap gap-8">
          <div className="flex items-center gap-3">
            <div className="relative w-10 h-10">
              <div className="absolute inset-0 w-10 h-10 bg-orange-500 rounded-full border-3 border-white shadow-lg" style={{ boxShadow: '0 0 20px rgba(245, 158, 11, 0.8)' }}></div>
              <div className="absolute inset-0 w-10 h-10 border-2 border-orange-500 rounded-full" style={{ animation: 'pulse-ring 2s cubic-bezier(0.455, 0.03, 0.515, 0.955) infinite' }}></div>
              <div className="absolute inset-0 flex items-center justify-center text-lg">⚠️</div>
            </div>
            <div>
              <div className="text-sm font-semibold text-gray-900">En attente</div>
              <div className="text-xs text-gray-600">Avec effet de pulsation</div>
            </div>
          </div>
          <div className="flex items-center gap-3">
            <div className="relative w-10 h-10">
              <div className="absolute inset-0 w-10 h-10 bg-blue-500 rounded-full border-3 border-white shadow-lg" style={{ boxShadow: '0 0 20px rgba(59, 130, 246, 0.8)' }}></div>
              <div className="absolute inset-0 w-10 h-10 border-2 border-blue-500 rounded-full" style={{ animation: 'pulse-ring 2s cubic-bezier(0.455, 0.03, 0.515, 0.955) infinite' }}></div>
              <div className="absolute inset-0 flex items-center justify-center text-lg">🔄</div>
            </div>
            <div>
              <div className="text-sm font-semibold text-gray-900">En cours</div>
              <div className="text-xs text-gray-600">Avec effet de pulsation</div>
            </div>
          </div>
          <div className="flex items-center gap-3">
            <div className="relative w-10 h-10">
              <div className="absolute inset-0 w-10 h-10 bg-green-500 rounded-full border-3 border-white shadow-lg" style={{ boxShadow: '0 0 20px rgba(16, 185, 129, 0.8)' }}></div>
              <div className="absolute inset-0 flex items-center justify-center text-lg font-bold text-white">✓</div>
            </div>
            <div>
              <div className="text-sm font-semibold text-gray-900">Résolu</div>
              <div className="text-xs text-gray-600">Mission accomplie</div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

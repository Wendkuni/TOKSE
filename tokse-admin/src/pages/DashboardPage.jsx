import {
    CheckCircle,
    Clock,
    FileText,
    MapPin,
    TrendingUp,
    UserCheck,
    Users,
} from 'lucide-react';
import { useEffect, useRef, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { supabase } from '../lib/supabase';
import { useAuth } from '../contexts/AuthContext';

export const DashboardPage = () => {
  const { user } = useAuth();
  const [stats, setStats] = useState({
    totalUsers: 0,
    totalCitoyens: 0,
    totalAutorites: 0,
    autoritesParRole: {},
    signalementsAujourdhui: 0,
    signalementsEnCours: 0,
    signalementsResolus: 0,
    totalSignalements: 0,
  });
  const [loading, setLoading] = useState(true);
  const [signalements, setSignalements] = useState([]);
  const navigate = useNavigate();

  useEffect(() => {
    fetchDashboardData();
  }, []);

  const fetchDashboardData = async () => {
    try {
      setLoading(true);

      // Exécuter toutes les requêtes en parallèle pour plus de rapidité
      const [
        { count: totalUsers },
        { count: totalCitoyens },
        { data: autorites },
        { count: signalementsAujourdhui },
        { count: signalementsEnCours },
        { count: signalementsResolus },
        { count: totalSignalements },
        { data: recentSignalements }
      ] = await Promise.all([
        // Fetch total users (excluant les agents créés par les autorités)
        supabase
          .from('users')
          .select('*', { count: 'exact', head: true })
          .eq('is_active', true)
          .neq('role', 'agent'),

        // Fetch citoyens
        supabase
          .from('users')
          .select('*', { count: 'exact', head: true })
          .eq('role', 'citizen')
          .eq('is_active', true),

        // Fetch authorities (excluant les agents)
        supabase
          .from('users')
          .select('role')
          .neq('role', 'citizen')
          .neq('role', 'admin')
          .neq('role', 'agent')
          .eq('is_active', true),

        // Fetch signalements d'aujourd'hui
        supabase
          .from('signalements')
          .select('*', { count: 'exact', head: true })
          .gte('created_at', new Date(new Date().setHours(0, 0, 0, 0)).toISOString()),

        // Fetch signalements en cours
        supabase
          .from('signalements')
          .select('*', { count: 'exact', head: true })
          .eq('etat', 'en_cours'),

        // Fetch signalements résolus
        supabase
          .from('signalements')
          .select('*', { count: 'exact', head: true })
          .eq('etat', 'resolu'),

        // Fetch total signalements
        supabase
          .from('signalements')
          .select('*', { count: 'exact', head: true }),

        // Fetch recent signalements
        supabase
          .from('signalements')
          .select('id, titre, latitude, longitude, etat, created_at')
          .order('created_at', { ascending: false })
          .limit(100)
      ]);

      const autoritesParRole = {};
      autorites?.forEach((auth) => {
        autoritesParRole[auth.role] = (autoritesParRole[auth.role] || 0) + 1;
      });

      setStats({
        totalUsers: totalUsers || 0,
        totalCitoyens: totalCitoyens || 0,
        totalAutorites: autorites?.length || 0,
        autoritesParRole,
        signalementsAujourdhui: signalementsAujourdhui || 0,
        signalementsEnCours: signalementsEnCours || 0,
        signalementsResolus: signalementsResolus || 0,
        totalSignalements: totalSignalements || 0,
      });

      setSignalements(recentSignalements || []);
    } catch (error) {
      console.error('Error fetching dashboard data:', error);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  const statCards = [
    {
      title: 'Total Utilisateurs',
      value: stats.totalUsers,
      icon: Users,
      color: 'bg-blue-500',
      change: '+12% ce mois',
    },
    {
      title: 'Utilisateurs',
      value: stats.totalCitoyens,
      icon: Users,
      color: 'bg-green-500',
      change: `${((stats.totalCitoyens / stats.totalUsers) * 100).toFixed(0)}% du total`,
    },
    {
      title: 'Opérateurs',
      value: stats.totalAutorites,
      icon: UserCheck,
      color: 'bg-purple-500',
      change: `${Object.keys(stats.autoritesParRole).length} rôles`,
    },
    {
      title: "Signalements aujourd'hui",
      value: stats.signalementsAujourdhui,
      icon: FileText,
      color: 'bg-orange-500',
      change: 'Dernières 24h',
    },
    {
      title: 'En cours',
      value: stats.signalementsEnCours,
      icon: Clock,
      color: 'bg-yellow-500',
      change: 'À traiter',
    },
    {
      title: 'Résolus',
      value: stats.signalementsResolus,
      icon: CheckCircle,
      color: 'bg-green-600',
      change: `${((stats.signalementsResolus / stats.totalSignalements) * 100).toFixed(0)}% du total`,
    },
  ];

  return (
    <div>
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900">Tableau de bord</h1>
        <p className="text-gray-600 mt-2">Vue d'ensemble de la plateforme TOKSE</p>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-8">
        {statCards.map((card, index) => (
          <div
            key={index}
            className="bg-white rounded-xl shadow-sm border border-gray-200 p-6 hover:shadow-md transition-shadow"
          >
            <div className="flex items-start justify-between">
              <div>
                <p className="text-sm font-medium text-gray-600 mb-1">{card.title}</p>
                <p className="text-3xl font-bold text-gray-900">{card.value}</p>
                <p className="text-sm text-gray-500 mt-2 flex items-center gap-1">
                  <TrendingUp className="w-4 h-4" />
                  {card.change}
                </p>
              </div>
              <div className={`${card.color} p-3 rounded-lg`}>
                <card.icon className="w-6 h-6 text-white" />
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Authorities by Role */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
        <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
          <h2 className="text-lg font-semibold text-gray-900 mb-4">Opérateurs par rôle</h2>
          {Object.keys(stats.autoritesParRole).length > 0 ? (
            <div className="space-y-3">
              {Object.entries(stats.autoritesParRole).map(([role, count]) => (
                <div
                  key={role}
                  className="flex items-center justify-between p-3 bg-gray-50 rounded-lg"
                >
                  <span className="font-medium text-gray-700 capitalize">
                    {role.replace(/_/g, ' ')}
                  </span>
                  <span className="text-2xl font-bold text-blue-600">{count}</span>
                </div>
              ))}
            </div>
          ) : (
            <p className="text-gray-500 text-center py-8">Aucun opérateur enregistré</p>
          )}
        </div>

        {/* Quick Actions */}
        {(() => {
          // Définir toutes les actions rapides avec leurs permissions
          const quickActions = [
            {
              title: 'Créer un opérateur',
              description: 'Ajouter un nouveau compte d\'opérateur',
              color: 'blue',
              path: '/dashboard/create-authority',
              permission: 'view_authorities', // Nécessite permission pour voir les opérateurs
            },
            {
              title: 'Voir les utilisateurs',
              description: 'Gérer utilisateurs et opérateurs',
              color: 'green',
              path: '/dashboard/users',
              permission: 'view_users', // Nécessite permission pour voir les utilisateurs
            },
            {
              title: 'Journal d\'activité',
              description: 'Consulter les logs système',
              color: 'purple',
              path: '/dashboard/logs',
              permission: 'view_logs', // Nécessite permission pour voir les logs
            },
          ];

          // Filtrer les actions selon les permissions
          const visibleActions = quickActions.filter(action => {
            // Super admin voit tout
            if (user?.role === 'super_admin') return true;
            // Vérifier si l'utilisateur a la permission requise
            return user?.permissions?.[action.permission] === true;
          });

          // Ne pas afficher la section si aucune action n'est visible
          if (visibleActions.length === 0) return null;

          return (
            <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
              <h2 className="text-lg font-semibold text-gray-900 mb-4">Actions rapides</h2>
              <div className="space-y-3">
                {visibleActions.map((action, index) => (
                  <button
                    key={index}
                    className={`w-full text-left p-4 bg-${action.color}-50 hover:bg-${action.color}-100 rounded-lg transition-colors border border-${action.color}-200`}
                    onClick={() => navigate(action.path)}
                  >
                    <p className={`font-semibold text-${action.color}-900`}>{action.title}</p>
                    <p className={`text-sm text-${action.color}-700 mt-1`}>{action.description}</p>
                  </button>
                ))}
              </div>
            </div>
          );
        })()}
      </div>

      {/* Map Preview */}
      <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-lg font-semibold text-gray-900 flex items-center gap-2">
            <MapPin className="w-5 h-5 text-blue-600" />
            Carte des signalements
          </h2>
          <div className="flex items-center gap-4">
            <span className="text-sm text-gray-600">{signalements.length} signalements</span>
            <button
              onClick={() => navigate('/dashboard/signalements')}
              className="text-sm font-medium text-blue-600 hover:text-blue-700 transition-colors"
            >
              Voir la carte complète →
            </button>
          </div>
        </div>
        <InteractiveMap signalements={signalements} />
      </div>
    </div>
  );
};

// Composant carte interactive
const InteractiveMap = ({ signalements }) => {
  const mapRef = useRef(null);
  const mapInstanceRef = useRef(null);

  useEffect(() => {
    // Vérifier que Leaflet est chargé
    if (typeof window === 'undefined' || !window.L) {
      // Charger Leaflet dynamiquement
      const link = document.createElement('link');
      link.rel = 'stylesheet';
      link.href = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.css';
      document.head.appendChild(link);

      const script = document.createElement('script');
      script.src = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.js';
      script.onload = initMap;
      document.head.appendChild(script);
    } else {
      initMap();
    }

    return () => {
      if (mapInstanceRef.current) {
        mapInstanceRef.current.remove();
        mapInstanceRef.current = null;
      }
    };
  }, [signalements]);

  const initMap = () => {
    if (!mapRef.current || mapInstanceRef.current) return;

    const L = window.L;
    if (!L) return;

    // Créer la carte centrée sur Abidjan
    const map = L.map(mapRef.current).setView([5.345317, -4.024429], 12);
    mapInstanceRef.current = map;

    // Ajouter les tuiles OpenStreetMap
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '© OpenStreetMap contributors',
      maxZoom: 19,
    }).addTo(map);

    // Définir les icônes personnalisées pour chaque état
    const getMarkerIcon = (etat) => {
      const colors = {
        en_attente: '#f39c12',
        en_cours: '#3498db',
        resolu: '#27ae60'
      };
      
      const color = colors[etat] || '#95a5a6';
      
      return L.divIcon({
        className: 'custom-marker',
        html: `<div style="background-color: ${color}; width: 24px; height: 24px; border-radius: 50%; border: 3px solid white; box-shadow: 0 2px 6px rgba(0,0,0,0.3);"></div>`,
        iconSize: [24, 24],
        iconAnchor: [12, 12],
      });
    };

    // Ajouter les marqueurs
    if (signalements && signalements.length > 0) {
      const bounds = [];
      
      signalements.forEach((sig) => {
        if (sig.latitude && sig.longitude) {
          const marker = L.marker([sig.latitude, sig.longitude], {
            icon: getMarkerIcon(sig.etat)
          }).addTo(map);

          // Popup avec infos du signalement
          const etatLabels = {
            en_attente: 'En attente',
            en_cours: 'En cours',
            resolu: 'Résolu'
          };
          
          marker.bindPopup(`
            <div style="min-width: 200px;">
              <h3 style="font-weight: bold; margin-bottom: 8px; color: #1a73e8;">${sig.titre || 'Signalement'}</h3>
              <div style="margin-bottom: 4px;">
                <span style="font-weight: 600;">État:</span> 
                <span style="padding: 2px 8px; border-radius: 4px; font-size: 12px; background-color: ${sig.etat === 'resolu' ? '#d4edda' : sig.etat === 'en_cours' ? '#d1ecf1' : '#fff3cd'}; color: ${sig.etat === 'resolu' ? '#155724' : sig.etat === 'en_cours' ? '#0c5460' : '#856404'};">
                  ${etatLabels[sig.etat] || sig.etat}
                </span>
              </div>
              <div style="font-size: 13px; color: #666; margin-top: 8px;">
                📅 ${new Date(sig.created_at).toLocaleDateString('fr-FR')}
              </div>
            </div>
          `);

          bounds.push([sig.latitude, sig.longitude]);
        }
      });

      // Ajuster la vue pour afficher tous les marqueurs
      if (bounds.length > 0) {
        map.fitBounds(bounds, { padding: [50, 50] });
      }
    }
  };

  return (
    <div>
      <div
        ref={mapRef}
        className="rounded-lg h-96 w-full border border-gray-200"
        style={{ zIndex: 0 }}
      />
      {signalements.length === 0 && (
        <div className="absolute inset-0 flex items-center justify-center bg-gray-50 rounded-lg">
          <div className="text-center">
            <MapPin className="w-12 h-12 text-gray-400 mx-auto mb-2" />
            <p className="text-gray-600">Aucun signalement à afficher</p>
          </div>
        </div>
      )}
    </div>
  );
};

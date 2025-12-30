import { format } from 'date-fns';
import { fr } from 'date-fns/locale';
import { Activity, AlertTriangle, CheckCircle, Clock, MapPin, TrendingUp, Users } from 'lucide-react';
import { useEffect, useState } from 'react';
import { useAuth } from '../../contexts/AuthContext';
import { supabase } from '../../lib/supabase';

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

export const AutoriteDashboardPage = () => {
  const { user } = useAuth();
  const [loading, setLoading] = useState(true);
  const [stats, setStats] = useState({
    signalementsTotal: 0,
    signalementsEnCours: 0,
    signalementsTraites: 0,
    signalementsEnAttente: 0,
    mesPrisesEnCharge: 0,
    tempsReponseAmoyen: 0,
  });
  const [recentSignalements, setRecentSignalements] = useState([]);
  const [mesPrisesEnCharge, setMesPrisesEnCharge] = useState([]);

  useEffect(() => {
    console.log('🔍 [DASHBOARD] User object:', user);
    console.log('🔍 [DASHBOARD] User autorite_type:', user?.autorite_type);
    console.log('🔍 [DASHBOARD] LocalStorage autoriteType:', localStorage.getItem('autoriteType'));
    
    fetchDashboardData();
    
    // Real-time updates
    const signalementChannel = supabase
      .channel('autorite_signalements')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'signalements' }, () => {
        fetchDashboardData();
      })
      .subscribe();

    return () => {
      supabase.removeChannel(signalementChannel);
    };
  }, [user]);

  const fetchDashboardData = async () => {
    try {
      setLoading(true);
      await Promise.all([
        fetchStats(),
        fetchRecentSignalements(),
        fetchMesPrisesEnCharge(),
      ]);
    } catch (error) {
      console.error('Error fetching dashboard data:', error);
    } finally {
      setLoading(false);
    }
  };

  const fetchStats = async () => {
    try {
      console.log('📊 [STATS] Fetching stats for user:', user);
      
      // Stats de TOUS les signalements (nouvelle architecture sans agents)
      const { data: signalements, error: sigError } = await supabase
        .from('signalements')
        .select('id, etat, created_at, resolved_at, assigned_to');

      console.log('📊 [STATS] Query error:', sigError);
      console.log('📊 [STATS] Signalements found:', signalements?.length || 0);
      console.log('📊 [STATS] Signalements data:', signalements);

      if (sigError) {
        console.error('📊 [STATS] Supabase error:', sigError);
        throw sigError;
      }

      const enAttente = signalements?.filter(s => s.etat === 'en_attente').length || 0;
      const enCours = signalements?.filter(s => s.etat === 'en_cours').length || 0;
      const traites = signalements?.filter(s => s.etat === 'resolu').length || 0;

      console.log('📊 [STATS] En attente:', enAttente, 'En cours:', enCours, 'Résolus:', traites);

      // Mes prises en charge (signalements assignés à moi)
      const { count: mesPrisesEnChargeCount, error: countError } = await supabase
        .from('signalements')
        .select('*', { count: 'exact', head: true })
        .eq('assigned_to', user?.id);

      if (countError) {
        console.error('📊 [STATS] Error counting prises en charge:', countError);
      }

      console.log('📊 [STATS] Mes prises en charge:', mesPrisesEnChargeCount);

      // Temps de réponse moyen (en heures) - basé sur resolved_at
      const signalementsTraites = signalements?.filter(s => s.etat === 'resolu' && s.resolved_at) || [];
      let tempsReponseTotal = 0;
      signalementsTraites.forEach(s => {
        const created = new Date(s.created_at);
        const resolved = new Date(s.resolved_at);
        tempsReponseTotal += (resolved - created) / (1000 * 60 * 60); // en heures
      });
      const tempsReponseAmoyen = signalementsTraites.length > 0 
        ? Math.round(tempsReponseTotal / signalementsTraites.length) 
        : 0;

      const newStats = {
        signalementsTotal: signalements?.length || 0,
        signalementsEnAttente: enAttente,
        signalementsEnCours: enCours,
        signalementsTraites: traites,
        mesPrisesEnCharge: mesPrisesEnChargeCount || 0,
        tempsReponseAmoyen,
      };

      console.log('📊 [STATS] Final stats:', newStats);
      setStats(newStats);
    } catch (error) {
      console.error('❌ [STATS] Error fetching stats:', error);
      console.error('❌ [STATS] Error details:', error.message, error.details, error.hint);
    }
  };

  const fetchRecentSignalements = async () => {
    try {
      console.log('📋 [RECENT] Fetching all recent signalements');
      
      // Récupérer les signalements récents (tous)
      const { data, error } = await supabase
        .from('signalements')
        .select(`
          *,
          user:users!signalements_user_id_fkey(nom, prenom, email)
        `)
        .order('created_at', { ascending: false })
        .limit(10);

      console.log('📋 [RECENT] Query error:', error);
      console.log('📋 [RECENT] Data found:', data?.length || 0);
      console.log('📋 [RECENT] Data:', data);

      if (error) throw error;
      setRecentSignalements(data || []);
    } catch (error) {
      console.error('Error fetching recent signalements:', error);
    }
  };

  const fetchMesPrisesEnCharge = async () => {
    try {
      const { data, error } = await supabase
        .from('signalements')
        .select(`
          *,
          user:users!signalements_user_id_fkey(nom, prenom)
        `)
        .eq('assigned_to', user?.id)
        .in('etat', ['en_cours', 'en_attente'])
        .order('created_at', { ascending: false })
        .limit(5);

      if (error) throw error;
      setMesPrisesEnCharge(data || []);
    } catch (error) {
      console.error('Error fetching mes prises en charge:', error);
    }
  };

  const getEtatBadge = (etat) => {
    switch (etat) {
      case 'en_attente':
        return <span className="px-3 py-1 rounded-full bg-yellow-100 text-yellow-700 text-xs font-medium">En attente</span>;
      case 'en_cours':
        return <span className="px-3 py-1 rounded-full bg-blue-100 text-blue-700 text-xs font-medium">En cours</span>;
      case 'resolu':
        return <span className="px-3 py-1 rounded-full bg-green-100 text-green-700 text-xs font-medium">Résolu</span>;
      default:
        return <span className="px-3 py-1 rounded-full bg-gray-100 text-gray-700 text-xs font-medium">{etat}</span>;
    }
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
        <h1 className="text-3xl font-bold text-gray-900">
          Tableau de bord - {getAutoriteType(user) || user?.role || 'Autorité'}
        </h1>
        <p className="text-gray-600 mt-2">
          Vue d'ensemble de vos signalements et interventions
        </p>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-8">
        <div className="bg-white p-6 rounded-xl shadow-sm border-l-4 border-blue-500">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Signalements en cours</p>
              <p className="text-3xl font-bold text-gray-900 mt-2">{stats.signalementsEnCours}</p>
              <p className="text-xs text-gray-500 mt-1">sur {stats.signalementsTotal} total</p>
            </div>
            <AlertTriangle className="w-12 h-12 text-blue-500 opacity-20" />
          </div>
        </div>

        <div className="bg-white p-6 rounded-xl shadow-sm border-l-4 border-green-500">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Signalements traités</p>
              <p className="text-3xl font-bold text-gray-900 mt-2">{stats.signalementsTraites}</p>
              <p className="text-xs text-gray-500 mt-1">
                {stats.signalementsTotal > 0 
                  ? `${Math.round((stats.signalementsTraites / stats.signalementsTotal) * 100)}% de résolution`
                  : '0% de résolution'
                }
              </p>
            </div>
            <CheckCircle className="w-12 h-12 text-green-500 opacity-20" />
          </div>
        </div>

        <div className="bg-white p-6 rounded-xl shadow-sm border-l-4 border-yellow-500">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Signalements en attente</p>
              <p className="text-3xl font-bold text-gray-900 mt-2">{stats.signalementsEnAttente}</p>
              <p className="text-xs text-gray-500 mt-1">à prendre en charge</p>
            </div>
            <Clock className="w-12 h-12 text-yellow-500 opacity-20" />
          </div>
        </div>

        <div className="bg-white p-6 rounded-xl shadow-sm border-l-4 border-purple-500">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Mes prises en charge</p>
              <p className="text-3xl font-bold text-gray-900 mt-2">{stats.mesPrisesEnCharge}</p>
              <p className="text-xs text-gray-500 mt-1">signalements assignés à moi</p>
            </div>
            <Users className="w-12 h-12 text-purple-500 opacity-20" />
          </div>
        </div>

        <div className="bg-white p-6 rounded-xl shadow-sm border-l-4 border-red-500">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Temps de réponse moyen</p>
              <p className="text-3xl font-bold text-gray-900 mt-2">{stats.tempsReponseAmoyen}h</p>
            </div>
            <Clock className="w-12 h-12 text-red-500 opacity-20" />
          </div>
        </div>

        <div className="bg-white p-6 rounded-xl shadow-sm border-l-4 border-indigo-500">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Performance</p>
              <p className="text-3xl font-bold text-gray-900 mt-2">
                {stats.signalementsTotal > 0 
                  ? Math.round((stats.signalementsTraites / stats.signalementsTotal) * 100)
                  : 0
                }%
              </p>
            </div>
            <TrendingUp className="w-12 h-12 text-indigo-500 opacity-20" />
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Signalements récents */}
        <div className="bg-white rounded-xl shadow-sm p-6">
          <h2 className="text-xl font-bold text-gray-900 mb-4">Signalements récents</h2>
          <div className="space-y-3">
            {recentSignalements.length === 0 ? (
              <p className="text-center text-gray-500 py-8">Aucun signalement</p>
            ) : (
              recentSignalements.map((sig) => (
                <div key={sig.id} className="border border-gray-200 rounded-lg p-4 hover:bg-gray-50">
                  <div className="flex items-start justify-between mb-2">
                    <div className="flex-1">
                      <h3 className="font-semibold text-gray-900">{sig.titre}</h3>
                      <p className="text-sm text-gray-600 mt-1">{sig.description?.substring(0, 100)}...</p>
                    </div>
                    {getEtatBadge(sig.etat)}
                  </div>
                  <div className="flex items-center gap-4 text-xs text-gray-500 mt-3">
                    <span className="flex items-center gap-1">
                      <MapPin className="w-3 h-3" />
                      {sig.adresse}
                    </span>
                    <span>{format(new Date(sig.created_at), 'dd MMM yyyy HH:mm', { locale: fr })}</span>
                  </div>
                </div>
              ))
            )}
          </div>
        </div>

        {/* Mes prises en charge */}
        <div className="bg-white rounded-xl shadow-sm p-6">
          <h2 className="text-xl font-bold text-gray-900 mb-4">Mes prises en charge</h2>
          <div className="space-y-3">
            {mesPrisesEnCharge.length === 0 ? (
              <p className="text-center text-gray-500 py-8">Aucune prise en charge</p>
            ) : (
              mesPrisesEnCharge.map((sig) => (
                <div key={sig.id} className="border border-gray-200 rounded-lg p-4 hover:bg-gray-50">
                  <div className="flex items-start justify-between mb-2">
                    <div className="flex-1">
                      <h3 className="font-semibold text-gray-900">{sig.titre}</h3>
                      <p className="text-sm text-gray-600 mt-1">{sig.description?.substring(0, 100)}...</p>
                    </div>
                    {getEtatBadge(sig.etat)}
                  </div>
                  <div className="flex items-center gap-4 text-xs text-gray-500 mt-3">
                    <span className="flex items-center gap-1">
                      <MapPin className="w-3 h-3" />
                      {sig.adresse}
                    </span>
                    <span>{format(new Date(sig.created_at), 'dd MMM yyyy HH:mm', { locale: fr })}</span>
                  </div>
                </div>
              ))
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

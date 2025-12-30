import { AlertCircle, CheckCircle, Clock, TrendingDown, TrendingUp, Users } from 'lucide-react';
import { useEffect, useState } from 'react';
import { Bar, BarChart, CartesianGrid, Cell, Legend, Line, LineChart, Pie, PieChart, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts';
import { supabase } from '../lib/supabase';

export const StatisticsPage = () => {
  const [stats, setStats] = useState({
    signalementsByCategory: [],
    signalementsByStatus: [],
    signalementsTrend: [],
    resolutionRate: 0,
    avgResponseTime: 0,
    topAuthorities: [],
  });
  const [loading, setLoading] = useState(true);
  const [period, setPeriod] = useState('month'); // week, month, year

  useEffect(() => {
    fetchStatistics();
  }, [period]);

  const fetchStatistics = async () => {
    try {
      setLoading(true);

      // Get date range
      const now = new Date();
      let startDate;
      
      switch (period) {
        case 'week':
          startDate = new Date();
          startDate.setDate(startDate.getDate() - 7);
          break;
        case 'month':
          startDate = new Date();
          startDate.setMonth(startDate.getMonth() - 1);
          break;
        case 'year':
          startDate = new Date();
          startDate.setFullYear(startDate.getFullYear() - 1);
          break;
        default:
          startDate = new Date();
          startDate.setMonth(startDate.getMonth() - 1);
      }

      console.log('📊 Période:', period, 'De:', startDate, 'À:', now);

      // Fetch signalements
      const { data: signalements, error } = await supabase
        .from('signalements')
        .select('*')
        .gte('created_at', startDate.toISOString());

      if (error) {
        console.error('❌ Erreur récupération signalements:', error);
        throw error;
      }

      console.log('📊 Signalements récupérés:', signalements?.length);

      // Calculate stats
      const byCategory = {};
      const byStatus = {
        en_attente: 0,
        en_cours: 0,
        resolu: 0,
      };

      signalements?.forEach((sig) => {
        // By category
        const category = sig.categorie || 'autre';
        byCategory[category] = (byCategory[category] || 0) + 1;
        
        // By status
        byStatus[sig.etat] = (byStatus[sig.etat] || 0) + 1;
      });

      // Format for charts
      const signalementsByCategory = Object.entries(byCategory).map(([name, value]) => ({
        name: name?.replace(/_/g, ' '),
        value,
      }));

      const signalementsByStatus = Object.entries(byStatus).map(([name, value]) => ({
        name: name === 'en_attente' ? 'En attente' : name === 'en_cours' ? 'En cours' : 'Résolu',
        value,
      }));

      // Calculate resolution rate
      const totalSignalements = signalements?.length || 0;
      const resolvedSignalements = byStatus.resolu || 0;
      const resolutionRate = totalSignalements > 0 
        ? ((resolvedSignalements / totalSignalements) * 100).toFixed(1)
        : 0;

      // Calculate average response time (basé sur resolved_at)
      let avgResponseTime = 0;
      const signalementsWithTime = signalements?.filter(s => s.etat === 'resolu' && s.resolved_at) || [];
      if (signalementsWithTime.length > 0) {
        let totalTime = 0;
        signalementsWithTime.forEach(sig => {
          const created = new Date(sig.created_at);
          const resolved = new Date(sig.resolved_at);
          totalTime += (resolved - created) / (1000 * 60 * 60); // en heures
        });
        avgResponseTime = Math.round(totalTime / signalementsWithTime.length);
      }

      console.log('📊 [STATS] Avg response time:', avgResponseTime, 'hours for', signalementsWithTime.length, 'signalements');

      // Trend data (signalements per day)
      const trendData = {};
      signalements?.forEach((sig) => {
        const date = new Date(sig.created_at).toLocaleDateString('fr-FR');
        trendData[date] = (trendData[date] || 0) + 1;
      });

      const signalementsTrend = Object.entries(trendData)
        .sort((a, b) => new Date(a[0]) - new Date(b[0]))
        .map(([date, count]) => ({ date, signalements: count }))
        .slice(-30); // Last 30 days

      // Top authorities (performances des autorités)
      console.log('📊 [STATS] Calculating authorities performance...');
      
      // 1. Filtrer les signalements résolus avec une autorité assignée
      const signalementsResolus = signalements?.filter(sig => sig.etat === 'resolu' && sig.assigned_to);
      console.log('📊 [STATS] Signalements résolus avec autorité:', signalementsResolus?.length);

      // 2. Grouper par assigned_to (autorité)
      const statsByAutorite = {};
      signalementsResolus?.forEach(sig => {
        if (!statsByAutorite[sig.assigned_to]) {
          statsByAutorite[sig.assigned_to] = {
            traites: 0,
            tempsTotal: 0,
          };
        }
        statsByAutorite[sig.assigned_to].traites += 1;
        
        // Calcul du temps de traitement (en heures)
        if (sig.created_at && sig.resolved_at) {
          const t1 = new Date(sig.created_at);
          const t2 = new Date(sig.resolved_at);
          const diffH = Math.abs(t2 - t1) / 36e5; // Convertir ms en heures
          statsByAutorite[sig.assigned_to].tempsTotal += diffH;
        }
      });

      console.log('📊 [STATS] Stats by autorite:', statsByAutorite);

      // 3. Récupérer toutes les autorités depuis la table users
      const { data: allAuthoritiesData, error: authError } = await supabase
        .from('users')
        .select('id, nom, prenom, role')
        .in('role', ['police', 'hygiene', 'voirie', 'environnement', 'securite', 'mairie']);

      if (authError) {
        console.error('❌ [STATS] Error fetching authorities:', authError);
      }

      console.log('📊 [STATS] All authorities:', allAuthoritiesData?.length);

      // 4. Construire le tableau final (toutes les autorités, même celles avec zéro signalement)
      const topAuthorities = (allAuthoritiesData || []).map((a) => {
        const stat = statsByAutorite[a.id] || { traites: 0, tempsTotal: 0 };
        return {
          nom: a.prenom ? `${a.prenom} ${a.nom}` : a.nom,
          role: a.role,
          traites: stat.traites,
          temps_moyen: stat.traites > 0 ? Math.round(stat.tempsTotal / stat.traites) : 0,
        };
      }).sort((a, b) => b.traites - a.traites);

      console.log('📊 [STATS] Top authorities:', topAuthorities);

      setStats({
        signalementsByCategory,
        signalementsByStatus,
        signalementsTrend,
        resolutionRate,
        avgResponseTime,
        topAuthorities,
      });
    } catch (error) {
      console.error('Error fetching statistics:', error);
    } finally {
      setLoading(false);
    }
  };

  const COLORS = ['#0088FE', '#00C49F', '#FFBB28', '#FF8042', '#8884D8', '#82CA9D'];

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64 bg-gray-50">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  return (
    <div className="bg-gray-50 min-h-screen p-6">
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 mb-8 p-6 flex items-center justify-between">
        <div className="flex items-center gap-4">
          <TrendingUp className="w-10 h-10 text-blue-600" />
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Statistiques</h1>
            <p className="text-gray-600 text-sm mt-1">
              Analyse détaillée des signalements et performances
            </p>
          </div>
        </div>
        <select
          value={period}
          onChange={(e) => setPeriod(e.target.value)}
          className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 bg-white"
        >
          <option value="week">7 derniers jours</option>
          <option value="month">30 derniers jours</option>
          <option value="year">12 derniers mois</option>
        </select>
      </div>

      {/* KPIs */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-sm text-gray-600">Taux résolution</h3>
            <TrendingUp className="w-6 h-6 text-blue-600" />
          </div>
          <p className="text-4xl font-bold text-gray-900">{stats.resolutionRate}%</p>
          <p className="text-sm text-gray-500 mt-2">Performance globale</p>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-sm text-gray-600">Temps réponse</h3>
            <Clock className="w-6 h-6 text-green-600" />
          </div>
          <p className="text-4xl font-bold text-gray-900">{stats.avgResponseTime}H</p>
          <p className="text-sm text-gray-500 mt-2">Moyenne</p>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-sm text-gray-600">En attente</h3>
            <AlertCircle className="w-6 h-6 text-orange-600" />
          </div>
          <p className="text-4xl font-bold text-gray-900">
            {stats.signalementsByStatus.find(s => s.name === 'En attente')?.value || 0}
          </p>
          <p className="text-sm text-gray-500 mt-2">À traiter</p>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-sm text-gray-600">Résolus</h3>
            <CheckCircle className="w-6 h-6 text-purple-600" />
          </div>
          <p className="text-4xl font-bold text-gray-900">
            {stats.signalementsByStatus.find(s => s.name === 'Résolu')?.value || 0}
          </p>
          <p className="text-sm text-gray-500 mt-2">Ce mois</p>
        </div>
      </div>

      {/* Charts Row 1 */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
        {/* Signalements by Status */}
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <h2 className="text-lg font-bold text-gray-900 mb-6">Répartition par statut</h2>
          <ResponsiveContainer width="100%" height={300}>
            <PieChart>
              <Pie
                data={stats.signalementsByStatus}
                cx="50%"
                cy="50%"
                labelLine={false}
                label={({ name, value, percent }) => `${name}: ${value} (${(percent * 100).toFixed(0)}%)`}
                outerRadius={100}
                fill="#8884d8"
                dataKey="value"
              >
                {stats.signalementsByStatus.map((entry, index) => (
                  <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                ))}
              </Pie>
              <Tooltip />
            </PieChart>
          </ResponsiveContainer>
        </div>

        {/* Signalements by Category */}
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <h2 className="text-lg font-bold text-gray-900 mb-6">Signalements par catégorie</h2>
          <ResponsiveContainer width="100%" height={300}>
            <BarChart data={stats.signalementsByCategory}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="name" angle={-45} textAnchor="end" height={100} />
              <YAxis />
              <Tooltip />
              <Bar dataKey="value" fill="#3b82f6" />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Trend Chart */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6 mb-8">
        <h2 className="text-lg font-bold text-gray-900 mb-6">
          Évolution des signalements
        </h2>
        <ResponsiveContainer width="100%" height={300}>
          <LineChart data={stats.signalementsTrend}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="date" />
            <YAxis />
            <Tooltip />
            <Legend />
            <Line type="monotone" dataKey="signalements" stroke="#3b82f6" strokeWidth={2} />
          </LineChart>
        </ResponsiveContainer>
      </div>

      {/* Top Authorities */}
      <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
        <h2 className="text-lg font-semibold text-gray-900 mb-6 flex items-center gap-2">
          <Users className="w-6 h-6 text-blue-600" />
          Performance des opérateurs
        </h2>
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50 border-b border-gray-200">
              <tr>
                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase">
                  Opérateur
                </th>
                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase">
                  Rôle
                </th>
                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase">
                  Signalements traités
                </th>
                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase">
                  Temps moyen (heures)
                </th>
                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase">
                  Performance
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {stats.topAuthorities.map((authority, index) => (
                <tr key={index} className="hover:bg-gray-50 transition-colors">
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 bg-blue-100 rounded-full flex items-center justify-center">
                        <span className="text-blue-600 font-semibold">{index + 1}</span>
                      </div>
                      <span className="font-medium text-gray-900">{authority.nom}</span>
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800 capitalize">
                      {authority.role}
                    </span>
                  </td>
                  <td className="px-6 py-4">
                    <span className="text-2xl font-bold text-blue-600">{authority.traites}</span>
                  </td>
                  <td className="px-6 py-4">
                    <span className="text-lg font-semibold text-gray-700">{authority.temps_moyen}h</span>
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-2">
                      {authority.traites === 0 ? (
                        <>
                          <TrendingDown className="w-5 h-5 text-red-600" />
                          <span className="text-red-700 font-medium">Faible</span>
                        </>
                      ) : authority.temps_moyen < 24 ? (
                        <>
                          <TrendingUp className="w-5 h-5 text-green-600" />
                          <span className="text-green-700 font-medium">Excellent</span>
                        </>
                      ) : (
                        <>
                          <TrendingDown className="w-5 h-5 text-orange-600" />
                          <span className="text-orange-700 font-medium">Moyen</span>
                        </>
                      )}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

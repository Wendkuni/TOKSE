import { Activity, AlertTriangle, Award, BarChart3, Calendar, CheckCircle, Clock, FileText, MapPin, TrendingDown, TrendingUp } from 'lucide-react';
import { useEffect, useState } from 'react';
import { Bar, BarChart, CartesianGrid, Cell, Legend, Line, LineChart, Pie, PieChart, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts';
import { useAuth } from '../../contexts/AuthContext';
import { supabase } from '../../lib/supabase';

export const AgentDashboardPage = () => {
  const { user } = useAuth();
  const [loading, setLoading] = useState(true);
  const [stats, setStats] = useState({
    total: 0,
    enAttente: 0,
    enCours: 0,
    resolus: 0,
    tempsMoyen: 0,
    tauxReussite: 0,
  });
  const [signalements, setSignalements] = useState([]);
  const [statsParZone, setStatsParZone] = useState([]);
  const [statsParType, setStatsParType] = useState([]);
  const [evolutionTemporelle, setEvolutionTemporelle] = useState([]);

  useEffect(() => {
    fetchData();
  }, [user]);

  const fetchData = async () => {
    try {
      setLoading(true);

      // Récupérer tous les signalements assignés à l'agent
      const { data: mesSignalements, error } = await supabase
        .from('signalements')
        .select('*')
        .eq('assigned_to', user?.id)
        .order('created_at', { ascending: false });

      if (error) throw error;

      setSignalements(mesSignalements || []);

      // Calculer les stats globales
      const total = mesSignalements?.length || 0;
      const enAttente = mesSignalements?.filter((s) => s.etat === 'en_attente').length || 0;
      const enCours = mesSignalements?.filter((s) => s.etat === 'en_cours').length || 0;
      const resolus = mesSignalements?.filter((s) => s.etat === 'resolu').length || 0;

      // Calculer le temps moyen d'intervention (en heures)
      const signalementsResolus = mesSignalements?.filter((s) => s.etat === 'resolu') || [];
      let tempsTotal = 0;
      signalementsResolus.forEach((s) => {
        const created = new Date(s.created_at);
        const updated = new Date(s.updated_at);
        tempsTotal += (updated - created) / (1000 * 60 * 60); // en heures
      });
      const tempsMoyen = signalementsResolus.length > 0 ? Math.round(tempsTotal / signalementsResolus.length) : 0;

      const tauxReussite = total > 0 ? Math.round((resolus / total) * 100) : 0;

      setStats({
        total,
        enAttente,
        enCours,
        resolus,
        tempsMoyen,
        tauxReussite,
      });

      // Grouper par zone (commune/secteur)
      const parZone = {};
      mesSignalements?.forEach((s) => {
        const zone = s.commune || 'Non spécifiée';
        if (!parZone[zone]) {
          parZone[zone] = 0;
        }
        parZone[zone]++;
      });
      const dataZones = Object.entries(parZone).map(([nom, count]) => ({
        nom,
        interventions: count,
      }));
      setStatsParZone(dataZones);

      // Grouper par type (catégorie)
      const parType = {};
      mesSignalements?.forEach((s) => {
        const type = s.categorie || 'Autre';
        if (!parType[type]) {
          parType[type] = 0;
        }
        parType[type]++;
      });
      const dataTypes = Object.entries(parType).map(([nom, value]) => ({
        nom,
        value,
      }));
      setStatsParType(dataTypes);

      // Évolution temporelle (7 derniers jours)
      const derniers7Jours = [];
      for (let i = 6; i >= 0; i--) {
        const date = new Date();
        date.setDate(date.getDate() - i);
        date.setHours(0, 0, 0, 0);
        
        const dateStr = date.toLocaleDateString('fr-FR', { day: '2-digit', month: 'short' });
        const countJour = mesSignalements?.filter((s) => {
          const createdDate = new Date(s.created_at);
          createdDate.setHours(0, 0, 0, 0);
          return createdDate.getTime() === date.getTime();
        }).length || 0;

        derniers7Jours.push({
          date: dateStr,
          interventions: countJour,
        });
      }
      setEvolutionTemporelle(derniers7Jours);
    } catch (error) {
      console.error('Error fetching data:', error);
    } finally {
      setLoading(false);
    }
  };

  const COLORS = ['#3b82f6', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6', '#ec4899'];

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-purple-600"></div>
      </div>
    );
  }

  return (
    <div>
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900">Tableau de bord</h1>
        <p className="text-gray-600 mt-2">
          Vue d'ensemble de vos interventions et performances
        </p>
      </div>

      {/* KPIs Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <div className="bg-white rounded-xl shadow-sm p-6">
          <div className="flex items-center justify-between mb-4">
            <div className="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center">
              <FileText className="w-6 h-6 text-blue-600" />
            </div>
            <span className="text-sm font-medium text-gray-500">Total</span>
          </div>
          <p className="text-3xl font-bold text-gray-900">{stats.total}</p>
          <p className="text-sm text-gray-600 mt-1">Signalements assignés</p>
        </div>

        <div className="bg-white rounded-xl shadow-sm p-6">
          <div className="flex items-center justify-between mb-4">
            <div className="w-12 h-12 bg-green-100 rounded-lg flex items-center justify-center">
              <CheckCircle className="w-6 h-6 text-green-600" />
            </div>
            <span className="text-sm font-medium text-gray-500">Résolus</span>
          </div>
          <p className="text-3xl font-bold text-gray-900">{stats.resolus}</p>
          <div className="flex items-center gap-2 mt-1">
            <div className="flex items-center text-green-600 text-sm font-medium">
              <TrendingUp className="w-4 h-4 mr-1" />
              {stats.tauxReussite}%
            </div>
            <span className="text-sm text-gray-600">Taux de réussite</span>
          </div>
        </div>

        <div className="bg-white rounded-xl shadow-sm p-6">
          <div className="flex items-center justify-between mb-4">
            <div className="w-12 h-12 bg-orange-100 rounded-lg flex items-center justify-center">
              <Activity className="w-6 h-6 text-orange-600" />
            </div>
            <span className="text-sm font-medium text-gray-500">En cours</span>
          </div>
          <p className="text-3xl font-bold text-gray-900">{stats.enCours}</p>
          <p className="text-sm text-gray-600 mt-1">Interventions actives</p>
        </div>

        <div className="bg-white rounded-xl shadow-sm p-6">
          <div className="flex items-center justify-between mb-4">
            <div className="w-12 h-12 bg-purple-100 rounded-lg flex items-center justify-center">
              <Clock className="w-6 h-6 text-purple-600" />
            </div>
            <span className="text-sm font-medium text-gray-500">Temps moyen</span>
          </div>
          <p className="text-3xl font-bold text-gray-900">{stats.tempsMoyen}h</p>
          <p className="text-sm text-gray-600 mt-1">Durée d'intervention</p>
        </div>
      </div>

      {/* Charts Row 1 */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
        {/* Répartition par état */}
        <div className="bg-white rounded-xl shadow-sm p-6">
          <h3 className="text-lg font-bold text-gray-900 mb-6 flex items-center gap-2">
            <BarChart3 className="w-5 h-5 text-purple-600" />
            Répartition par état
          </h3>
          <ResponsiveContainer width="100%" height={300}>
            <PieChart>
              <Pie
                data={[
                  { name: 'En attente', value: stats.enAttente },
                  { name: 'En cours', value: stats.enCours },
                  { name: 'Résolus', value: stats.resolus },
                ]}
                cx="50%"
                cy="50%"
                labelLine={false}
                label={({ name, percent }) => `${name}: ${(percent * 100).toFixed(0)}%`}
                outerRadius={100}
                fill="#8884d8"
                dataKey="value"
              >
                {[stats.enAttente, stats.enCours, stats.resolus].map((entry, index) => (
                  <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                ))}
              </Pie>
              <Tooltip />
            </PieChart>
          </ResponsiveContainer>
        </div>

        {/* Évolution temporelle */}
        <div className="bg-white rounded-xl shadow-sm p-6">
          <h3 className="text-lg font-bold text-gray-900 mb-6 flex items-center gap-2">
            <Calendar className="w-5 h-5 text-purple-600" />
            Évolution (7 derniers jours)
          </h3>
          <ResponsiveContainer width="100%" height={300}>
            <LineChart data={evolutionTemporelle}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="date" />
              <YAxis />
              <Tooltip />
              <Legend />
              <Line type="monotone" dataKey="interventions" stroke="#8b5cf6" strokeWidth={2} />
            </LineChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Charts Row 2 */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
        {/* Par zone */}
        <div className="bg-white rounded-xl shadow-sm p-6">
          <h3 className="text-lg font-bold text-gray-900 mb-6 flex items-center gap-2">
            <MapPin className="w-5 h-5 text-purple-600" />
            Interventions par zone
          </h3>
          <ResponsiveContainer width="100%" height={300}>
            <BarChart data={statsParZone}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="nom" />
              <YAxis />
              <Tooltip />
              <Legend />
              <Bar dataKey="interventions" fill="#3b82f6" />
            </BarChart>
          </ResponsiveContainer>
        </div>

        {/* Par type */}
        <div className="bg-white rounded-xl shadow-sm p-6">
          <h3 className="text-lg font-bold text-gray-900 mb-6 flex items-center gap-2">
            <AlertTriangle className="w-5 h-5 text-purple-600" />
            Interventions par type
          </h3>
          <ResponsiveContainer width="100%" height={300}>
            <PieChart>
              <Pie
                data={statsParType}
                cx="50%"
                cy="50%"
                labelLine={false}
                label={({ nom, percent }) => `${nom}: ${(percent * 100).toFixed(0)}%`}
                outerRadius={100}
                fill="#8884d8"
                dataKey="value"
              >
                {statsParType.map((entry, index) => (
                  <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                ))}
              </Pie>
              <Tooltip />
            </PieChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Insights / Alertes */}
      <div className="bg-gradient-to-r from-purple-50 to-blue-50 rounded-xl p-6 border border-purple-200">
        <h3 className="text-lg font-bold text-gray-900 mb-4 flex items-center gap-2">
          <Award className="w-5 h-5 text-purple-600" />
          Insights & Recommandations
        </h3>
        <div className="space-y-3">
          {stats.tempsMoyen > 24 && (
            <div className="flex items-start gap-3 bg-white rounded-lg p-4 border border-orange-200">
              <AlertTriangle className="w-5 h-5 text-orange-600 mt-0.5" />
              <div>
                <p className="font-medium text-gray-900">Temps d'intervention élevé</p>
                <p className="text-sm text-gray-600">
                  Votre temps moyen ({stats.tempsMoyen}h) dépasse 24h. Essayez de prioriser les interventions urgentes.
                </p>
              </div>
            </div>
          )}
          
          {stats.tauxReussite >= 80 && (
            <div className="flex items-start gap-3 bg-white rounded-lg p-4 border border-green-200">
              <Award className="w-5 h-5 text-green-600 mt-0.5" />
              <div>
                <p className="font-medium text-gray-900">Excellente performance !</p>
                <p className="text-sm text-gray-600">
                  Votre taux de réussite de {stats.tauxReussite}% est excellent. Continuez sur cette lancée !
                </p>
              </div>
            </div>
          )}

          {stats.enAttente > 5 && (
            <div className="flex items-start gap-3 bg-white rounded-lg p-4 border border-yellow-200">
              <Clock className="w-5 h-5 text-yellow-600 mt-0.5" />
              <div>
                <p className="font-medium text-gray-900">{stats.enAttente} signalements en attente</p>
                <p className="text-sm text-gray-600">
                  Pensez à prendre en charge ces signalements pour améliorer votre réactivité.
                </p>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

import { Award, AlertTriangle, TrendingUp, Clock, CheckCircle, Target, Zap } from 'lucide-react';
import { useEffect, useState } from 'react';
import { useAuth } from '../../contexts/AuthContext';
import { supabase } from '../../lib/supabase';

export const AgentPerformancePage = () => {
  const { user } = useAuth();
  const [loading, setLoading] = useState(true);
  const [signalements, setSignalements] = useState([]);
  const [performance, setPerformance] = useState({
    pointsForts: [],
    axesAmelioration: [],
    alertes: [],
    score: 0,
  });

  useEffect(() => {
    fetchData();
  }, [user]);

  const fetchData = async () => {
    try {
      setLoading(true);

      const { data, error } = await supabase
        .from('signalements')
        .select('*')
        .eq('assigned_to', user?.id)
        .order('created_at', { ascending: false });

      if (error) throw error;

      setSignalements(data || []);
      analyzePerformance(data || []);
    } catch (error) {
      console.error('Error fetching data:', error);
    } finally {
      setLoading(false);
    }
  };

  const analyzePerformance = (data) => {
    const pointsForts = [];
    const axesAmelioration = [];
    const alertes = [];
    let score = 0;

    const total = data.length;
    const resolus = data.filter((s) => s.etat === 'resolu').length;
    const enCours = data.filter((s) => s.etat === 'en_cours').length;
    const enAttente = data.filter((s) => s.etat === 'en_attente').length;

    const tauxReussite = total > 0 ? (resolus / total) * 100 : 0;

    // Calcul temps moyen
    const signalementsResolus = data.filter((s) => s.etat === 'resolu');
    let tempsTotal = 0;
    signalementsResolus.forEach((s) => {
      const created = new Date(s.created_at);
      const updated = new Date(s.updated_at);
      tempsTotal += (updated - created) / (1000 * 60 * 60);
    });
    const tempsMoyen = signalementsResolus.length > 0 ? tempsTotal / signalementsResolus.length : 0;

    // Points forts
    if (tauxReussite >= 80) {
      pointsForts.push({
        title: 'Excellent taux de réussite',
        description: `${tauxReussite.toFixed(0)}% de vos interventions sont résolues avec succès`,
        icon: Award,
        color: 'green',
      });
      score += 30;
    }

    if (tempsMoyen <= 24) {
      pointsForts.push({
        title: 'Réactivité exemplaire',
        description: `Temps moyen d'intervention de ${tempsMoyen.toFixed(0)}h (excellent)`,
        icon: Zap,
        color: 'blue',
      });
      score += 30;
    }

    if (enAttente <= 2) {
      pointsForts.push({
        title: 'Gestion proactive',
        description: 'Peu de signalements en attente, vous êtes bien organisé',
        icon: Target,
        color: 'purple',
      });
      score += 20;
    }

    // Axes d'amélioration
    if (tauxReussite < 60) {
      axesAmelioration.push({
        title: 'Taux de réussite à améliorer',
        description: `Actuellement à ${tauxReussite.toFixed(0)}%, visez au moins 70%`,
        suggestion: 'Assurez-vous de bien documenter chaque intervention et de suivre les protocoles',
        icon: TrendingUp,
        color: 'orange',
      });
    }

    if (tempsMoyen > 48) {
      axesAmelioration.push({
        title: 'Temps d\'intervention élevé',
        description: `${tempsMoyen.toFixed(0)}h en moyenne, essayez de réduire`,
        suggestion: 'Priorisez les interventions urgentes et optimisez vos déplacements',
        icon: Clock,
        color: 'yellow',
      });
    }

    if (enAttente > 5) {
      axesAmelioration.push({
        title: 'Signalements en attente',
        description: `${enAttente} signalements non pris en charge`,
        suggestion: 'Prenez en charge rapidement les nouveaux signalements pour améliorer votre réactivité',
        icon: AlertTriangle,
        color: 'red',
      });
    }

    // Alertes critiques
    const signalementsLongs = data.filter((s) => {
      if (s.etat !== 'en_cours') return false;
      const created = new Date(s.created_at);
      const now = new Date();
      const heures = (now - created) / (1000 * 60 * 60);
      return heures > 72;
    });

    if (signalementsLongs.length > 0) {
      alertes.push({
        type: 'warning',
        title: `${signalementsLongs.length} intervention(s) dépassent 72h`,
        message: 'Ces interventions nécessitent une attention urgente',
      });
    }

    if (enAttente > 10) {
      alertes.push({
        type: 'error',
        title: 'Trop de signalements en attente',
        message: `${enAttente} signalements attendent d'être pris en charge`,
      });
    }

    // Score final
    if (tauxReussite < 60) score -= 10;
    if (tempsMoyen > 48) score -= 10;
    if (enAttente > 5) score -= 10;

    score = Math.max(0, Math.min(100, score + 20)); // Base de 20 points

    setPerformance({
      pointsForts,
      axesAmelioration,
      alertes,
      score,
    });
  };

  const getScoreColor = (score) => {
    if (score >= 80) return 'text-green-600';
    if (score >= 60) return 'text-blue-600';
    if (score >= 40) return 'text-yellow-600';
    return 'text-red-600';
  };

  const getScoreBg = (score) => {
    if (score >= 80) return 'from-green-500 to-green-600';
    if (score >= 60) return 'from-blue-500 to-blue-600';
    if (score >= 40) return 'from-yellow-500 to-yellow-600';
    return 'from-red-500 to-red-600';
  };

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
        <h1 className="text-3xl font-bold text-gray-900">Performance & Insights</h1>
        <p className="text-gray-600 mt-2">
          Analysez vos forces et améliorez vos performances
        </p>
      </div>

      {/* Score global */}
      <div className={`bg-gradient-to-r ${getScoreBg(performance.score)} rounded-xl shadow-lg p-8 mb-8 text-white`}>
        <div className="flex items-center justify-between">
          <div>
            <p className="text-white/80 text-lg mb-2">Score de performance global</p>
            <div className="flex items-baseline gap-2">
              <p className="text-6xl font-bold">{performance.score}</p>
              <p className="text-2xl">/100</p>
            </div>
            <p className="mt-4 text-white/90">
              {performance.score >= 80 && '🎉 Performance excellente ! Continuez comme ça.'}
              {performance.score >= 60 && performance.score < 80 && '👍 Bonne performance, quelques axes d\'amélioration.'}
              {performance.score >= 40 && performance.score < 60 && '⚠️ Performance moyenne, plusieurs points à travailler.'}
              {performance.score < 40 && '🔴 Performance à améliorer de toute urgence.'}
            </p>
          </div>
          <div className="w-32 h-32 bg-white/20 rounded-full flex items-center justify-center">
            <Award className="w-16 h-16" />
          </div>
        </div>
      </div>

      {/* Alertes */}
      {performance.alertes.length > 0 && (
        <div className="space-y-4 mb-8">
          {performance.alertes.map((alerte, idx) => (
            <div
              key={idx}
              className={`rounded-xl p-6 border-2 ${
                alerte.type === 'error'
                  ? 'bg-red-50 border-red-200'
                  : 'bg-yellow-50 border-yellow-200'
              }`}
            >
              <div className="flex items-start gap-4">
                <AlertTriangle
                  className={`w-6 h-6 ${alerte.type === 'error' ? 'text-red-600' : 'text-yellow-600'}`}
                />
                <div className="flex-1">
                  <h3 className="font-bold text-gray-900 text-lg mb-1">{alerte.title}</h3>
                  <p className="text-gray-700">{alerte.message}</p>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Points forts */}
      <div className="mb-8">
        <h2 className="text-2xl font-bold text-gray-900 mb-6">💪 Vos points forts</h2>
        {performance.pointsForts.length > 0 ? (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {performance.pointsForts.map((point, idx) => {
              const Icon = point.icon;
              return (
                <div key={idx} className="bg-white rounded-xl shadow-sm p-6 border-2 border-green-200">
                  <div className={`w-12 h-12 bg-${point.color}-100 rounded-lg flex items-center justify-center mb-4`}>
                    <Icon className={`w-6 h-6 text-${point.color}-600`} />
                  </div>
                  <h3 className="font-bold text-gray-900 mb-2">{point.title}</h3>
                  <p className="text-gray-600 text-sm">{point.description}</p>
                </div>
              );
            })}
          </div>
        ) : (
          <div className="bg-gray-50 rounded-xl p-8 text-center">
            <p className="text-gray-600">Continuez vos interventions pour identifier vos points forts</p>
          </div>
        )}
      </div>

      {/* Axes d'amélioration */}
      <div>
        <h2 className="text-2xl font-bold text-gray-900 mb-6">🎯 Axes d'amélioration</h2>
        {performance.axesAmelioration.length > 0 ? (
          <div className="space-y-4">
            {performance.axesAmelioration.map((axe, idx) => {
              const Icon = axe.icon;
              return (
                <div key={idx} className="bg-white rounded-xl shadow-sm p-6 border-l-4 border-orange-500">
                  <div className="flex items-start gap-4">
                    <div className="w-12 h-12 bg-orange-100 rounded-lg flex items-center justify-center flex-shrink-0">
                      <Icon className="w-6 h-6 text-orange-600" />
                    </div>
                    <div className="flex-1">
                      <h3 className="font-bold text-gray-900 text-lg mb-2">{axe.title}</h3>
                      <p className="text-gray-700 mb-3">{axe.description}</p>
                      <div className="bg-blue-50 rounded-lg p-4 border border-blue-200">
                        <p className="text-sm font-medium text-blue-900 mb-1">💡 Suggestion :</p>
                        <p className="text-sm text-blue-800">{axe.suggestion}</p>
                      </div>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        ) : (
          <div className="bg-green-50 rounded-xl p-8 text-center border-2 border-green-200">
            <CheckCircle className="w-12 h-12 text-green-600 mx-auto mb-4" />
            <p className="text-green-800 font-medium">Aucun axe d'amélioration détecté ! Performance excellente 🎉</p>
          </div>
        )}
      </div>
    </div>
  );
};

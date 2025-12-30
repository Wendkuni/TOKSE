import { Mail, MapPin, Phone, Shield, User } from 'lucide-react';
import { useEffect, useState } from 'react';
import { useAuth } from '../../contexts/AuthContext';
import { supabase } from '../../lib/supabase';

export const AgentProfilePage = () => {
  const { user } = useAuth();
  const [loading, setLoading] = useState(true);
  const [stats, setStats] = useState({
    total: 0,
    resolus: 0,
    enCours: 0,
    tempsMoyen: 0,
    derniereIntervention: null,
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

      const total = data?.length || 0;
      const resolus = data?.filter((s) => s.etat === 'resolu').length || 0;
      const enCours = data?.filter((s) => s.etat === 'en_cours').length || 0;

      // Temps moyen
      const signalementsResolus = data?.filter((s) => s.etat === 'resolu') || [];
      let tempsTotal = 0;
      signalementsResolus.forEach((s) => {
        const created = new Date(s.created_at);
        const updated = new Date(s.updated_at);
        tempsTotal += (updated - created) / (1000 * 60 * 60);
      });
      const tempsMoyen = signalementsResolus.length > 0 ? Math.round(tempsTotal / signalementsResolus.length) : 0;

      const derniereIntervention = data && data.length > 0 ? data[0] : null;

      setStats({
        total,
        resolus,
        enCours,
        tempsMoyen,
        derniereIntervention,
      });
    } catch (error) {
      console.error('Error fetching data:', error);
    } finally {
      setLoading(false);
    }
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
        <h1 className="text-3xl font-bold text-gray-900">Mon profil</h1>
        <p className="text-gray-600 mt-2">
          Informations personnelles et statistiques
        </p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Carte profil */}
        <div className="lg:col-span-1">
          <div className="bg-white rounded-xl shadow-sm p-8">
            <div className="flex flex-col items-center">
              <div className="w-24 h-24 bg-gradient-to-br from-purple-500 to-purple-700 rounded-full flex items-center justify-center mb-4">
                <User className="w-12 h-12 text-white" />
              </div>
              <h2 className="text-2xl font-bold text-gray-900 text-center">
                {user?.prenom} {user?.nom}
              </h2>
              <p className="text-purple-600 font-medium mt-1">Agent de terrain</p>

              <div className="w-full mt-8 space-y-4">
                <div className="flex items-center gap-3 text-gray-700">
                  <Mail className="w-5 h-5 text-gray-400" />
                  <span className="text-sm">{user?.email || 'Non renseigné'}</span>
                </div>
                <div className="flex items-center gap-3 text-gray-700">
                  <Phone className="w-5 h-5 text-gray-400" />
                  <span className="text-sm">{user?.telephone || 'Non renseigné'}</span>
                </div>
                {user?.secteur && (
                  <div className="flex items-center gap-3 text-gray-700">
                    <MapPin className="w-5 h-5 text-gray-400" />
                    <span className="text-sm">Secteur: {user.secteur}</span>
                  </div>
                )}
                <div className="flex items-center gap-3 text-gray-700">
                  <Shield className="w-5 h-5 text-gray-400" />
                  <span className="text-sm capitalize">{user?.role || 'Agent'}</span>
                </div>
              </div>
            </div>
          </div>

          {/* Badges */}
          <div className="bg-white rounded-xl shadow-sm p-6 mt-6">
            <h3 className="font-bold text-gray-900 mb-4">🏆 Badges & Accomplissements</h3>
            <div className="space-y-3">
              {stats.resolus >= 50 && (
                <div className="flex items-center gap-3 bg-yellow-50 rounded-lg p-3">
                  <div className="w-10 h-10 bg-yellow-500 rounded-full flex items-center justify-center text-white font-bold">
                    50
                  </div>
                  <div>
                    <p className="font-medium text-gray-900">Expert</p>
                    <p className="text-xs text-gray-600">50+ interventions résolues</p>
                  </div>
                </div>
              )}
              {stats.tempsMoyen <= 24 && stats.resolus >= 10 && (
                <div className="flex items-center gap-3 bg-blue-50 rounded-lg p-3">
                  <div className="w-10 h-10 bg-blue-500 rounded-full flex items-center justify-center text-white">
                    ⚡
                  </div>
                  <div>
                    <p className="font-medium text-gray-900">Éclair</p>
                    <p className="text-xs text-gray-600">Interventions rapides</p>
                  </div>
                </div>
              )}
              {stats.resolus >= 100 && (
                <div className="flex items-center gap-3 bg-purple-50 rounded-lg p-3">
                  <div className="w-10 h-10 bg-purple-500 rounded-full flex items-center justify-center text-white font-bold">
                    100
                  </div>
                  <div>
                    <p className="font-medium text-gray-900">Centurion</p>
                    <p className="text-xs text-gray-600">100+ interventions résolues</p>
                  </div>
                </div>
              )}
              {stats.resolus < 10 && (
                <p className="text-gray-500 text-sm text-center py-4">
                  Continuez vos interventions pour débloquer des badges !
                </p>
              )}
            </div>
          </div>
        </div>

        {/* Statistiques détaillées */}
        <div className="lg:col-span-2 space-y-6">
          {/* Stats cards */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="bg-gradient-to-br from-blue-500 to-blue-600 rounded-xl shadow-sm p-6 text-white">
              <p className="text-blue-100 mb-2">Total interventions</p>
              <p className="text-4xl font-bold">{stats.total}</p>
            </div>
            <div className="bg-gradient-to-br from-green-500 to-green-600 rounded-xl shadow-sm p-6 text-white">
              <p className="text-green-100 mb-2">Interventions résolues</p>
              <p className="text-4xl font-bold">{stats.resolus}</p>
            </div>
            <div className="bg-gradient-to-br from-orange-500 to-orange-600 rounded-xl shadow-sm p-6 text-white">
              <p className="text-orange-100 mb-2">En cours actuellement</p>
              <p className="text-4xl font-bold">{stats.enCours}</p>
            </div>
            <div className="bg-gradient-to-br from-purple-500 to-purple-600 rounded-xl shadow-sm p-6 text-white">
              <p className="text-purple-100 mb-2">Temps moyen</p>
              <p className="text-4xl font-bold">{stats.tempsMoyen}h</p>
            </div>
          </div>

          {/* Dernière intervention */}
          {stats.derniereIntervention && (
            <div className="bg-white rounded-xl shadow-sm p-6">
              <h3 className="font-bold text-gray-900 mb-4">📍 Dernière intervention</h3>
              <div className="space-y-3">
                <div>
                  <p className="text-sm text-gray-600">Titre</p>
                  <p className="font-medium text-gray-900">
                    {stats.derniereIntervention.titre || 'Sans titre'}
                  </p>
                </div>
                <div>
                  <p className="text-sm text-gray-600">Catégorie</p>
                  <p className="font-medium text-gray-900">{stats.derniereIntervention.categorie}</p>
                </div>
                <div>
                  <p className="text-sm text-gray-600">Adresse</p>
                  <p className="font-medium text-gray-900">{stats.derniereIntervention.adresse || 'N/A'}</p>
                </div>
                <div>
                  <p className="text-sm text-gray-600">Date</p>
                  <p className="font-medium text-gray-900">
                    {new Date(stats.derniereIntervention.created_at).toLocaleString('fr-FR')}
                  </p>
                </div>
                <div>
                  <p className="text-sm text-gray-600">État</p>
                  {stats.derniereIntervention.etat === 'resolu' && (
                    <span className="inline-block px-3 py-1 rounded-full bg-green-100 text-green-700 text-sm font-medium">
                      Résolu
                    </span>
                  )}
                  {stats.derniereIntervention.etat === 'en_cours' && (
                    <span className="inline-block px-3 py-1 rounded-full bg-blue-100 text-blue-700 text-sm font-medium">
                      En cours
                    </span>
                  )}
                  {stats.derniereIntervention.etat === 'en_attente' && (
                    <span className="inline-block px-3 py-1 rounded-full bg-yellow-100 text-yellow-700 text-sm font-medium">
                      En attente
                    </span>
                  )}
                </div>
              </div>
            </div>
          )}

          {/* Informations complémentaires */}
          <div className="bg-white rounded-xl shadow-sm p-6">
            <h3 className="font-bold text-gray-900 mb-4">ℹ️ Informations compte</h3>
            <div className="space-y-3 text-sm">
              <div className="flex justify-between py-2 border-b border-gray-100">
                <span className="text-gray-600">ID Agent</span>
                <span className="font-mono text-gray-900">{user?.id?.substring(0, 8)}...</span>
              </div>
              <div className="flex justify-between py-2 border-b border-gray-100">
                <span className="text-gray-600">Type de compte</span>
                <span className="font-medium text-gray-900 capitalize">{user?.role || 'Agent'}</span>
              </div>
              <div className="flex justify-between py-2">
                <span className="text-gray-600">Compte créé le</span>
                <span className="font-medium text-gray-900">
                  {user?.created_at ? new Date(user.created_at).toLocaleDateString('fr-FR') : 'N/A'}
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

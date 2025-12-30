import { MapPin, Navigation, TrendingDown, TrendingUp } from 'lucide-react';
import { useEffect, useState } from 'react';
import { useAuth } from '../../contexts/AuthContext';
import { supabase } from '../../lib/supabase';

export const AgentMapPage = () => {
  const { user } = useAuth();
  const [loading, setLoading] = useState(true);
  const [signalements, setSignalements] = useState([]);
  const [selectedZone, setSelectedZone] = useState(null);
  const [statsParZone, setStatsParZone] = useState([]);

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
        .not('latitude', 'is', null)
        .not('longitude', 'is', null)
        .order('created_at', { ascending: false });

      if (error) throw error;

      setSignalements(data || []);

      // Grouper par zone avec stats
      const parZone = {};
      data?.forEach((s) => {
        const zone = s.commune || 'Non spécifiée';
        if (!parZone[zone]) {
          parZone[zone] = {
            nom: zone,
            total: 0,
            resolus: 0,
            tempsTotal: 0,
            coords: [],
          };
        }
        parZone[zone].total++;
        if (s.etat === 'resolu') {
          parZone[zone].resolus++;
          const created = new Date(s.created_at);
          const updated = new Date(s.updated_at);
          parZone[zone].tempsTotal += (updated - created) / (1000 * 60 * 60);
        }
        if (s.latitude && s.longitude) {
          parZone[zone].coords.push({ lat: s.latitude, lng: s.longitude, etat: s.etat });
        }
      });

      const zones = Object.values(parZone).map((z) => ({
        ...z,
        tempsMoyen: z.resolus > 0 ? Math.round(z.tempsTotal / z.resolus) : 0,
        tauxReussite: z.total > 0 ? Math.round((z.resolus / z.total) * 100) : 0,
      }));

      setStatsParZone(zones);
    } catch (error) {
      console.error('Error fetching data:', error);
    } finally {
      setLoading(false);
    }
  };

  const getEtatColor = (etat) => {
    switch (etat) {
      case 'resolu':
        return 'bg-green-500';
      case 'en_cours':
        return 'bg-blue-500';
      case 'en_attente':
        return 'bg-yellow-500';
      default:
        return 'bg-gray-500';
    }
  };

  const getEtatBadge = (etat) => {
    switch (etat) {
      case 'resolu':
        return <span className="px-3 py-1 rounded-full bg-green-100 text-green-700 text-xs font-medium">Résolu</span>;
      case 'en_cours':
        return <span className="px-3 py-1 rounded-full bg-blue-100 text-blue-700 text-xs font-medium">En cours</span>;
      case 'en_attente':
        return <span className="px-3 py-1 rounded-full bg-yellow-100 text-yellow-700 text-xs font-medium">En attente</span>;
      default:
        return <span className="px-3 py-1 rounded-full bg-gray-100 text-gray-700 text-xs font-medium">{etat}</span>;
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
        <h1 className="text-3xl font-bold text-gray-900">Carte analytique</h1>
        <p className="text-gray-600 mt-2">
          Analyse géographique de vos interventions et zones à risque
        </p>
      </div>

      {/* Stats globales */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-6">
        <div className="bg-white rounded-xl shadow-sm p-6">
          <p className="text-sm text-gray-600">Total interventions</p>
          <p className="text-3xl font-bold text-gray-900 mt-2">{signalements.length}</p>
        </div>
        <div className="bg-white rounded-xl shadow-sm p-6">
          <p className="text-sm text-gray-600">Zones couvertes</p>
          <p className="text-3xl font-bold text-gray-900 mt-2">{statsParZone.length}</p>
        </div>
        <div className="bg-white rounded-xl shadow-sm p-6">
          <p className="text-sm text-gray-600">Zone la plus active</p>
          <p className="text-lg font-bold text-gray-900 mt-2">
            {statsParZone.length > 0 ? statsParZone.sort((a, b) => b.total - a.total)[0].nom : 'N/A'}
          </p>
        </div>
      </div>

      {/* Carte simplifiée */}
      <div className="bg-white rounded-xl shadow-sm p-6 mb-6">
        <h2 className="text-lg font-bold text-gray-900 mb-4 flex items-center gap-2">
          <MapPin className="w-5 h-5 text-purple-600" />
          Heatmap des interventions
        </h2>
        <div className="bg-gray-100 rounded-lg p-12 text-center relative" style={{ minHeight: '400px' }}>
          <div className="absolute inset-0 flex items-center justify-center">
            <div className="grid grid-cols-4 gap-6">
              {signalements.slice(0, 16).map((sig, idx) => (
                <div
                  key={sig.id}
                  className={`w-12 h-12 ${getEtatColor(sig.etat)} rounded-full opacity-60 hover:opacity-100 transition-opacity cursor-pointer`}
                  title={`${sig.titre || 'Sans titre'} - ${sig.commune}`}
                  style={{
                    transform: `scale(${sig.etat === 'resolu' ? 0.7 : 1})`,
                  }}
                />
              ))}
            </div>
          </div>
          <MapPin className="w-16 h-16 mx-auto mb-4 text-gray-400" />
          <p className="text-gray-600 mb-2">
            Visualisation des {signalements.length} interventions
          </p>
          <div className="flex items-center justify-center gap-6 text-sm text-gray-600 mt-4">
            <div className="flex items-center gap-2">
              <div className="w-4 h-4 bg-yellow-500 rounded-full"></div>
              <span>En attente</span>
            </div>
            <div className="flex items-center gap-2">
              <div className="w-4 h-4 bg-blue-500 rounded-full"></div>
              <span>En cours</span>
            </div>
            <div className="flex items-center gap-2">
              <div className="w-4 h-4 bg-green-500 rounded-full"></div>
              <span>Résolu</span>
            </div>
          </div>
        </div>
      </div>

      {/* Statistiques par zone */}
      <div className="bg-white rounded-xl shadow-sm overflow-hidden">
        <div className="p-6 border-b border-gray-200">
          <h2 className="text-lg font-bold text-gray-900">Analyse par zone</h2>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase">Zone</th>
                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase">Total</th>
                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase">Résolus</th>
                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase">Taux réussite</th>
                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase">Temps moyen</th>
                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase">Performance</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {statsParZone.map((zone) => (
                <tr key={zone.nom} className="hover:bg-gray-50">
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-2">
                      <MapPin className="w-4 h-4 text-gray-400" />
                      <span className="font-medium text-gray-900">{zone.nom}</span>
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <span className="font-semibold text-gray-900">{zone.total}</span>
                  </td>
                  <td className="px-6 py-4">
                    <span className="text-green-600 font-medium">{zone.resolus}</span>
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-2">
                      <div className="w-full bg-gray-200 rounded-full h-2 max-w-[100px]">
                        <div
                          className="bg-purple-600 h-2 rounded-full"
                          style={{ width: `${zone.tauxReussite}%` }}
                        ></div>
                      </div>
                      <span className="text-sm font-medium text-gray-700">{zone.tauxReussite}%</span>
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <span className="text-gray-700">{zone.tempsMoyen}h</span>
                  </td>
                  <td className="px-6 py-4">
                    {zone.tauxReussite >= 75 ? (
                      <div className="flex items-center gap-1 text-green-600 text-sm font-medium">
                        <TrendingUp className="w-4 h-4" />
                        Excellent
                      </div>
                    ) : zone.tauxReussite >= 50 ? (
                      <span className="text-yellow-600 text-sm font-medium">Moyen</span>
                    ) : (
                      <div className="flex items-center gap-1 text-red-600 text-sm font-medium">
                        <TrendingDown className="w-4 h-4" />
                        À améliorer
                      </div>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Insights */}
      <div className="mt-6 bg-purple-50 rounded-xl p-6 border border-purple-200">
        <h3 className="font-semibold text-gray-900 mb-3">💡 Insights géographiques</h3>
        <ul className="space-y-2 text-sm text-gray-700">
          {statsParZone.length > 0 && (
            <>
              <li>
                • Zone la plus sollicitée :{' '}
                <strong>{statsParZone.sort((a, b) => b.total - a.total)[0].nom}</strong> ({statsParZone[0].total}{' '}
                interventions)
              </li>
              <li>
                • Meilleur taux de réussite :{' '}
                <strong>
                  {statsParZone.sort((a, b) => b.tauxReussite - a.tauxReussite)[0].nom}
                </strong>{' '}
                ({statsParZone.sort((a, b) => b.tauxReussite - a.tauxReussite)[0].tauxReussite}%)
              </li>
              {statsParZone.filter((z) => z.tempsMoyen > 48).length > 0 && (
                <li className="text-orange-700">
                  ⚠️ {statsParZone.filter((z) => z.tempsMoyen > 48).length} zone(s) avec un temps d'intervention
                  supérieur à 48h
                </li>
              )}
            </>
          )}
        </ul>
      </div>
    </div>
  );
};

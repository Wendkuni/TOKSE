import { format } from 'date-fns';
import { fr } from 'date-fns/locale';
import { Activity, BarChart3, Edit, FileText, Filter, TrendingUp, UserPlus, UserX } from 'lucide-react';
import { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';

export const ActivityLogsPage = () => {
  const [logs, setLogs] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState('all');
  const [actionTypes, setActionTypes] = useState([]);
  
  // Pagination
  const [currentPage, setCurrentPage] = useState(1);
  const [itemsPerPage, setItemsPerPage] = useState(5);

  useEffect(() => {
    fetchLogs();
    fetchActionTypes();
    // Real-time subscription
    const channel = supabase
      .channel('logs_updates')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'logs_activite' }, () => {
        fetchLogs();
        fetchActionTypes();
      })
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [filter]);

  const fetchActionTypes = async () => {
    try {
      const { data, error } = await supabase
        .from('logs_activite')
        .select('type_action');
      if (error) throw error;
      const types = Array.from(new Set((data || []).map((log) => log.type_action))).filter(Boolean);
      setActionTypes(types);
    } catch (error) {
      console.error('Error fetching action types:', error);
    }
  };

  const fetchLogs = async () => {
    try {
      setLoading(true);
      let query = supabase
        .from('logs_activite')
        .select(`
          *,
          utilisateur_cible:users!logs_activite_utilisateur_cible_id_fkey(nom, prenom, email),
          autorite:users!logs_activite_autorite_id_fkey(nom, prenom, email)
        `)
        .order('created_at', { ascending: false })
        .limit(100);

      if (filter !== 'all') {
        query = query.eq('type_action', filter);
      }

      const { data, error } = await query;
      if (error) {
        console.error('Erreur Supabase:', error);
        // Fallback : requête sans jointures si ça échoue
        const { data: basicData, error: basicError } = await supabase
          .from('logs_activite')
          .select('*')
          .order('created_at', { ascending: false })
          .limit(100);
        
        if (basicError) throw basicError;
        setLogs(basicData || []);
        return;
      }

      setLogs(data || []);
    } catch (error) {
      console.error('Error fetching logs:', error);
      setLogs([]);
    } finally {
      setLoading(false);
    }
  };

  const getActionIcon = (type) => {
    switch (type) {
      case 'desactivation_compte':
        return <UserX className="w-5 h-5 text-red-600" />;
      case 'reactivation_compte':
        return <UserPlus className="w-5 h-5 text-green-600" />;
      case 'creation_autorite':
        return <UserPlus className="w-5 h-5 text-blue-600" />;
      case 'modification_role':
        return <Edit className="w-5 h-5 text-orange-600" />;
      case 'traitement_signalement':
        return <FileText className="w-5 h-5 text-purple-600" />;
      default:
        return <Activity className="w-5 h-5 text-gray-600" />;
    }
  };

  const getActionColor = (type) => {
    switch (type) {
      case 'desactivation_compte':
        return 'bg-red-100 text-red-700';
      case 'reactivation_compte':
        return 'bg-green-100 text-green-700';
      case 'creation_autorite':
        return 'bg-blue-100 text-blue-700';
      case 'modification_role':
        return 'bg-orange-100 text-orange-700';
      case 'traitement_signalement':
        return 'bg-purple-100 text-purple-700';
      default:
        return 'bg-gray-100 text-gray-700';
    }
  };

  const getActionLabel = (type) => {
    const labels = {
      desactivation_compte: 'Désactivation de compte',
      reactivation_compte: 'Réactivation de compte',
      creation_autorite: 'Création d\'autorité',
      modification_role: 'Modification de rôle',
      traitement_signalement: 'Traitement de signalement',
    };
    return labels[type] || type;
  };

  // Calcul pagination
  const totalPages = Math.ceil(logs.length / itemsPerPage);
  const startIndex = (currentPage - 1) * itemsPerPage;
  const endIndex = startIndex + itemsPerPage;
  const currentLogs = logs.slice(startIndex, endIndex);

  const goToPage = (page) => {
    setCurrentPage(Math.max(1, Math.min(page, totalPages)));
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto mb-4"></div>
          <p className="text-gray-600">Chargement des logs d'activité...</p>
        </div>
      </div>
    );
  }

  return (
    <div>
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900">Journal d'activité</h1>
        <p className="text-gray-600 mt-2">Suivi de toutes les actions administratives</p>
      </div>

      {/* Statistics Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
        <div className="bg-gradient-to-br from-blue-500 to-blue-600 rounded-xl p-5 text-white shadow-lg">
          <div className="flex items-center justify-between mb-2">
            <BarChart3 className="w-8 h-8 opacity-80" />
            <span className="text-2xl font-bold">{logs.length}</span>
          </div>
          <p className="text-sm font-medium opacity-90">Total d'activités</p>
          <p className="text-xs opacity-75 mt-1">Toutes périodes</p>
        </div>
        
        <div className="bg-gradient-to-br from-green-500 to-green-600 rounded-xl p-5 text-white shadow-lg">
          <div className="flex items-center justify-between mb-2">
            <UserPlus className="w-8 h-8 opacity-80" />
            <span className="text-2xl font-bold">
              {logs.filter(l => l.type_action === 'creation_autorite' || l.type_action === 'reactivation_compte').length}
            </span>
          </div>
          <p className="text-sm font-medium opacity-90">Créations/Activations</p>
          <p className="text-xs opacity-75 mt-1">Comptes gérés</p>
        </div>
        
        <div className="bg-gradient-to-br from-orange-500 to-orange-600 rounded-xl p-5 text-white shadow-lg">
          <div className="flex items-center justify-between mb-2">
            <Edit className="w-8 h-8 opacity-80" />
            <span className="text-2xl font-bold">
              {logs.filter(l => l.type_action === 'modification_role').length}
            </span>
          </div>
          <p className="text-sm font-medium opacity-90">Modifications</p>
          <p className="text-xs opacity-75 mt-1">Rôles changés</p>
        </div>
        
        <div className="bg-gradient-to-br from-purple-500 to-purple-600 rounded-xl p-5 text-white shadow-lg">
          <div className="flex items-center justify-between mb-2">
            <TrendingUp className="w-8 h-8 opacity-80" />
            <span className="text-2xl font-bold">
              {logs.filter(l => new Date(l.created_at) > new Date(Date.now() - 24*60*60*1000)).length}
            </span>
          </div>
          <p className="text-sm font-medium opacity-90">Dernières 24h</p>
          <p className="text-xs opacity-75 mt-1">Activité récente</p>
        </div>
      </div>

      {/* Filters */}
      <div className="mb-6 flex items-center gap-4">
        <div className="flex items-center gap-2 text-gray-700">
          <Filter className="w-5 h-5" />
          <span className="font-medium">Filtrer par :</span>
        </div>
        <div className="flex gap-2 flex-wrap">
          <button
            key="all"
            onClick={() => setFilter('all')}
            className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
              filter === 'all'
                ? 'bg-blue-600 text-white'
                : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
            }`}
          >
            Tout
          </button>
          {actionTypes.map((type) => (
            <button
              key={type}
              onClick={() => setFilter(type)}
              className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
                filter === type
                  ? 'bg-blue-600 text-white'
                  : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
              }`}
            >
              {getActionLabel(type)}
            </button>
          ))}
        </div>
      </div>

      {/* Logs List */}
      {loading ? (
        <div className="flex items-center justify-center h-64">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
        </div>
      ) : (
        <div className="bg-white rounded-xl shadow-sm border border-gray-200">
          <div className="divide-y divide-gray-200">
            {currentLogs.map((log) => (
              <div key={log.id} className="p-6 hover:bg-gray-50 transition-colors">
                <div className="flex items-start gap-4">
                  <div className={`p-3 rounded-lg ${getActionColor(log.type_action)}`}>
                    {getActionIcon(log.type_action)}
                  </div>
                  <div className="flex-1">
                    <div className="flex items-start justify-between">
                      <div>
                        <h3 className="font-semibold text-gray-900">
                          {getActionLabel(log.type_action)}
                        </h3>
                        <p className="text-sm text-gray-600 mt-1">
                          {log.utilisateur_cible && (
                            <>
                              Utilisateur concerné : <span className="font-medium">{log.utilisateur_cible.prenom} {log.utilisateur_cible.nom}</span>
                              {' '}({log.utilisateur_cible.email})
                              {log.utilisateur_cible.role && (
                                <span className="ml-2 px-2 py-0.5 bg-blue-100 text-blue-700 text-xs rounded">
                                  Rôle : {log.utilisateur_cible.role === 'admin' ? 'Administrateur' : log.utilisateur_cible.role === 'autorite' ? 'Autorité' : 'Citoyen'}
                                </span>
                              )}
                            </>
                          )}
                          {log.autorite && (
                            <>
                              {' | '}Effectué par : <span className="font-medium">{log.autorite.prenom} {log.autorite.nom}</span>
                            </>
                          )}
                        </p>
                        {log.details && (
                          <div className="mt-2 p-3 bg-gray-50 rounded-lg">
                            <ul className="text-sm text-gray-700 space-y-1">
                              {typeof log.details === 'object' && log.details !== null
                                ? Object.entries(log.details).map(([key, value]) => {
                                    // Traduire les clés techniques en français
                                    const labelMap = {
                                      timestamp: 'Date et heure',
                                      action: 'Action',
                                      old_permissions: 'Anciennes permissions',
                                      new_permissions: 'Nouvelles permissions',
                                      modifications: 'Modifications',
                                      email: 'Email',
                                      nom: 'Nom',
                                      prenom: 'Prénom',
                                      permissions: 'Permissions',
                                      ancien_etat: 'Ancien état',
                                      nouvel_etat: 'Nouvel état',
                                    };
                                    
                                    const label = labelMap[key] || key.replace(/_/g, ' ');
                                    
                                    // Formatter la valeur selon son type
                                    let displayValue;
                                    if (key === 'timestamp' && typeof value === 'string') {
                                      // Formatter la date en français
                                      try {
                                        displayValue = format(new Date(value), 'dd MMM yyyy à HH:mm', { locale: fr });
                                      } catch {
                                        displayValue = value;
                                      }
                                    } else if (Array.isArray(value)) {
                                      // Afficher les tableaux comme liste
                                      displayValue = value.length > 0 ? value.join(', ') : 'Aucune';
                                    } else if (typeof value === 'object' && value !== null) {
                                      // Cas spécial pour les modifications et permissions (objets avec booléens)
                                      if (key === 'modifications') {
                                        // Ne montrer QUE les champs modifiés (true)
                                        const champsModifies = Object.entries(value)
                                          .filter(([k, v]) => v === true)
                                          .map(([k]) => {
                                            const labels = {
                                              nom: 'Nom',
                                              prenom: 'Prénom',
                                              email: 'Email',
                                              telephone: 'Téléphone',
                                              password: 'Mot de passe',
                                              role: 'Rôle',
                                              secteur: 'Secteur',
                                              permissions: 'Permissions'
                                            };
                                            return labels[k] || k;
                                          });
                                        
                                        displayValue = champsModifies.length > 0 
                                          ? champsModifies.join(', ')
                                          : 'Aucun champ modifié';
                                      } else if (key === 'permissions' || key === 'old_permissions' || key === 'new_permissions') {
                                        // Ne montrer QUE les permissions accordées (true)
                                        const permissionsAccordees = Object.entries(value)
                                          .filter(([k, v]) => v === true)
                                          .map(([k]) => {
                                            const permissionLabels = {
                                              view_logs: 'Voir les logs',
                                              view_users: 'Voir les utilisateurs',
                                              export_data: 'Exporter les données',
                                              manage_users: 'Gérer les utilisateurs',
                                              manage_admins: 'Gérer les administrateurs',
                                              view_statistics: 'Voir les statistiques',
                                              view_authorities: 'Voir les autorités',
                                              view_signalements: 'Voir les signalements',
                                              manage_authorities: 'Gérer les autorités',
                                              manage_signalements: 'Gérer les signalements'
                                            };
                                            return permissionLabels[k] || k.replace(/_/g, ' ');
                                          });
                                        
                                        displayValue = permissionsAccordees.length > 0 
                                          ? permissionsAccordees.join(', ')
                                          : 'Aucune permission';
                                      } else {
                                        // Afficher les autres objets sous forme lisible
                                        displayValue = (
                                          <div className="ml-4 mt-1">
                                            {Object.entries(value).map(([k, v]) => {
                                              const fieldLabels = {
                                                nom: 'Nom',
                                                prenom: 'Prénom',
                                                email: 'Email',
                                                telephone: 'Téléphone',
                                                role: 'Rôle',
                                                secteur: 'Secteur'
                                              };
                                              return (
                                                <div key={k} className="text-xs">
                                                  <span className="font-medium">{fieldLabels[k] || k.replace(/_/g, ' ')} :</span> {String(v)}
                                                </div>
                                              );
                                            })}
                                          </div>
                                        );
                                      }
                                    } else if (typeof value === 'boolean') {
                                      // Traduire les booléens en français
                                      displayValue = value ? 'Oui' : 'Non';
                                    } else {
                                      displayValue = String(value);
                                    }
                                    
                                    return (
                                      <li key={key}>
                                        <span className="font-medium">{label} :</span> {displayValue}
                                      </li>
                                    );
                                  })
                                : <li>{String(log.details)}</li>
                              }
                            </ul>
                          </div>
                        )}
                      </div>
                      <span className="text-sm text-gray-500 whitespace-nowrap ml-4">
                        {format(new Date(log.created_at), 'dd MMM yyyy HH:mm', { locale: fr })}
                      </span>
                    </div>
                  </div>
                </div>
              </div>
            ))}
          </div>
          {logs.length === 0 && (
            <div className="text-center py-12">
              <Activity className="w-12 h-12 text-gray-400 mx-auto mb-3" />
              <p className="text-gray-600">Aucune activité enregistrée</p>
            </div>
          )}

          {/* Pagination améliorée */}
          {logs.length > 0 && (
            <div className="border-t border-gray-200 bg-gradient-to-r from-gray-50 to-white">
              <div className="flex items-center justify-between px-6 py-4">
                {/* Informations et sélecteur */}
                <div className="flex items-center gap-6">
                  <div className="flex items-center gap-2">
                    <div className="text-sm text-gray-700 font-medium">
                      <span className="text-blue-600">{startIndex + 1}-{Math.min(endIndex, logs.length)}</span>
                      <span className="text-gray-500"> sur </span>
                      <span className="text-blue-600">{logs.length}</span>
                      <span className="text-gray-500"> log(s)</span>
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
                  <button 
                    onClick={() => goToPage(1)} 
                    disabled={currentPage === 1} 
                    className="p-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 disabled:opacity-40 disabled:cursor-not-allowed transition-all hover:shadow-sm"
                    title="Première page"
                  >
                    <span className="text-base">««</span>
                  </button>
                  
                  <button 
                    onClick={() => goToPage(currentPage - 1)} 
                    disabled={currentPage === 1} 
                    className="px-3 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 disabled:opacity-40 disabled:cursor-not-allowed transition-all hover:shadow-sm flex items-center gap-1"
                    title="Page précédente"
                  >
                    <span>‹</span>
                    <span className="hidden sm:inline">Précédent</span>
                  </button>
                  
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

                  <button 
                    onClick={() => goToPage(currentPage + 1)} 
                    disabled={currentPage === totalPages} 
                    className="px-3 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 disabled:opacity-40 disabled:cursor-not-allowed transition-all hover:shadow-sm flex items-center gap-1"
                    title="Page suivante"
                  >
                    <span className="hidden sm:inline">Suivant</span>
                    <span>›</span>
                  </button>
                  
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
      )}
    </div>
  );
};

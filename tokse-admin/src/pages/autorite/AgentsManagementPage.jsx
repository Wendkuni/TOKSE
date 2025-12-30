import { format } from 'date-fns';
import { fr } from 'date-fns/locale';
import { AlertTriangle, Ban, CheckCircle, Edit2, Eye, EyeOff, MapPin, Phone, Plus, Trash2, UserCheck, UserX, Satellite, Radio, X } from 'lucide-react';
import { useEffect, useState } from 'react';
import { AlertDialog, ConfirmDialog } from '../../components/Dialog';
import { useAuth } from '../../contexts/AuthContext';
import { supabase } from '../../lib/supabase';

export const AgentsManagementPage = () => {
  const { user } = useAuth();
  const [agents, setAgents] = useState([]);
  const [orphanAgents, setOrphanAgents] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [showEditModal, setShowEditModal] = useState(false);
  const [selectedAgent, setSelectedAgent] = useState(null);
  const [formData, setFormData] = useState({
    email: '',
    password: '',
    nom: '',
    prenom: '',
    telephone: '',
    secteur: '',
  });
  const [dialog, setDialog] = useState({ type: null, isOpen: false, title: '', message: '', onConfirm: null });
  const [showPassword, setShowPassword] = useState(false);
  
  // Pagination
  const [currentPage, setCurrentPage] = useState(1);
  const [itemsPerPage, setItemsPerPage] = useState(5);

  useEffect(() => {
    console.log('🔍 useEffect - User connecté:', user);
    console.log('   - User ID:', user?.id);
    console.log('   - User role:', user?.role);
    console.log('   - User email:', user?.email);
    fetchAgents();
    fetchOrphanAgents();
  }, [user]);

  const fetchAgents = async () => {
    console.log('🚀 Début fetchAgents...');
    console.log('   - Recherche agents avec autorite_id:', user?.id);
    
    try {
      setLoading(true);
      const { data, error } = await supabase
        .from('users')
        .select('*, password')
        .eq('role', 'agent')
        .eq('autorite_id', user?.id)
        .order('created_at', { ascending: false });

      console.log('📥 Réponse Supabase:');
      console.log('   - Error:', error);
      console.log('   - Data:', data);
      
      if (error) throw error;
      
      console.log('📊 Agents récupérés:', data?.length || 0);
      console.log('   - Actifs:', data?.filter(a => a.is_active).length || 0);
      console.log('   - Inactifs:', data?.filter(a => !a.is_active).length || 0);
      console.log('   - Détails agents:', data);
      
      setAgents(data || []);
      setCurrentPage(1);
    } catch (error) {
      console.error('❌ Error fetching agents:', error);
    } finally {
      setLoading(false);
      console.log('✅ fetchAgents terminé');
    }
  };

  // Calcul pagination
  const totalPages = Math.ceil(agents.length / itemsPerPage);
  const startIndex = (currentPage - 1) * itemsPerPage;
  const endIndex = startIndex + itemsPerPage;
  const currentAgents = agents.slice(startIndex, endIndex);

  const goToPage = (page) => {
    setCurrentPage(Math.max(1, Math.min(page, totalPages)));
  };

  const fetchOrphanAgents = async () => {
    try {
      const response = await fetch('http://localhost:4000/api/get-orphan-agents');
      const data = await response.json();
      if (data.success) {
        setOrphanAgents(data.orphans || []);
      }
    } catch (error) {
      console.error('Error fetching orphan agents:', error);
    }
  };

  const deleteOrphanAgent = async (userId, email) => {
    setDialog({
      type: 'confirm',
      isOpen: true,
      title: 'Supprimer l\'agent orphelin',
      message: `Voulez-vous vraiment supprimer l'agent orphelin ${email} ?`,
      dialogType: 'danger',
      onConfirm: () => executeDeleteOrphan(userId)
    });
  };

  const executeDeleteOrphan = async (userId) => {
    
    try {
      const response = await fetch('http://localhost:4000/api/delete-orphan-agent', {
        method: 'DELETE',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ userId }),
      });

      const data = await response.json();
      if (data.success) {
        setDialog({ type: 'alert', isOpen: true, title: 'Succès', message: 'Agent orphelin supprimé avec succès', dialogType: 'success' });
        fetchOrphanAgents();
      } else {
        throw new Error(data.error || 'Erreur lors de la suppression');
      }
    } catch (error) {
      console.error('Error deleting orphan agent:', error);
      setDialog({ type: 'alert', isOpen: true, title: 'Erreur', message: 'Erreur lors de la suppression: ' + error.message, dialogType: 'error' });
    }
  };

  const deleteAllOrphans = async () => {
    setDialog({
      type: 'confirm',
      isOpen: true,
      title: 'Supprimer tous les agents orphelins',
      message: `Voulez-vous vraiment supprimer TOUS les ${orphanAgents.length} agents orphelins ?`,
      dialogType: 'danger',
      onConfirm: executeDeleteAllOrphans
    });
  };

  const executeDeleteAllOrphans = async () => {
    
    try {
      const response = await fetch('http://localhost:4000/api/delete-all-orphan-agents', {
        method: 'DELETE',
        headers: {
          'Content-Type': 'application/json',
        },
      });

      const data = await response.json();
      if (data.success) {
        setDialog({ type: 'alert', isOpen: true, title: 'Succès', message: `${data.deleted} agent(s) orphelin(s) supprimé(s) avec succès!`, dialogType: 'success' });
        fetchOrphanAgents();
      } else {
        throw new Error(data.error || 'Erreur lors de la suppression');
      }
    } catch (error) {
      console.error('Error deleting all orphan agents:', error);
      setDialog({ type: 'alert', isOpen: true, title: 'Erreur', message: 'Erreur lors de la suppression: ' + error.message, dialogType: 'error' });
    }
  };

  const createAgent = async (e) => {
    e.preventDefault();
    try {
      console.log('🚀 [CREATE_AGENT] Appel API backend pour créer agent...');
      
      // Utiliser l'API backend qui crée l'agent avec email confirmé automatiquement
      const response = await fetch('http://localhost:4000/api/create-agent', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: formData.email,
          password: formData.password,
          nom: formData.nom,
          prenom: formData.prenom,
          telephone: formData.telephone,
          secteur: formData.secteur,
          autorite_id: user?.id,
          autorite_type: user?.autorite_type,
        }),
      });

      const data = await response.json();
      
      if (!data.success) {
        throw new Error(data.error || 'Erreur lors de la création de l\'agent');
      }

      console.log('✅ [CREATE_AGENT] Agent créé avec succès:', data.agent_id);
      alert('✅ Agent créé avec succès ! Il peut se connecter immédiatement.');
      setShowCreateModal(false);
      resetForm();
      fetchAgents();
    } catch (error) {
      console.error('❌ [CREATE_AGENT] Erreur:', error);
      alert(`❌ Erreur: ${error.message}`);
    }
  };

  const updateAgent = async (e) => {
    e.preventDefault();
    try {
      // Si le mot de passe a changé, utiliser l'API backend
      if (formData.password !== selectedAgent.password) {
        const response = await fetch('http://localhost:4000/api/update-agent-password', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            userId: selectedAgent.id,
            newPassword: formData.password
          })
        });

        const data = await response.json();
        if (!data.success) {
          throw new Error(data.error || 'Erreur lors de la mise à jour du mot de passe');
        }
      }

      const { error } = await supabase
        .from('users')
        .update({
          nom: formData.nom,
          prenom: formData.prenom,
          telephone: formData.telephone,
          secteur: formData.secteur,
        })
        .eq('id', selectedAgent.id);

      if (error) throw error;

      // Logger l'action
      await supabase.from('logs_activite').insert({
        type_action: 'modification_agent',
        autorite_id: user?.id,
        utilisateur_cible_id: selectedAgent.id,
        details: {
          old_data: {
            nom: selectedAgent.nom,
            prenom: selectedAgent.prenom,
            telephone: selectedAgent.telephone,
            secteur: selectedAgent.secteur,
          },
          new_data: {
            nom: formData.nom,
            prenom: formData.prenom,
            telephone: formData.telephone,
            secteur: formData.secteur,
          },
          timestamp: new Date().toISOString(),
        },
      });

      alert('✅ Agent mis à jour !');
      setShowEditModal(false);
      fetchAgents();
    } catch (error) {
      console.error('Error updating agent:', error);
      alert(`❌ Erreur: ${error.message}`);
    }
  };

  const toggleAgentStatus = async (agentId, currentStatus) => {
    setDialog({
      type: 'confirm',
      isOpen: true,
      title: currentStatus ? 'Désactiver l\'agent' : 'Activer l\'agent',
      message: `Êtes-vous sûr de vouloir ${currentStatus ? 'désactiver' : 'activer'} cet agent ?`,
      dialogType: 'warning',
      onConfirm: () => executeToggleStatus(agentId, currentStatus)
    });
  };

  const executeToggleStatus = async (agentId, currentStatus) => {

    try {
      const { error } = await supabase
        .from('users')
        .update({ is_active: !currentStatus })
        .eq('id', agentId);

      if (error) throw error;

      // Logger l'action
      await supabase.from('logs_activite').insert({
        type_action: currentStatus ? 'desactivation_agent' : 'reactivation_agent',
        autorite_id: user?.id,
        utilisateur_cible_id: agentId,
        details: {
          action: currentStatus ? 'Agent désactivé' : 'Agent réactivé',
          timestamp: new Date().toISOString(),
        },
      });

      setDialog({ type: 'alert', isOpen: true, title: 'Succès', message: `Agent ${!currentStatus ? 'activé' : 'désactivé'} avec succès`, dialogType: 'success' });
      fetchAgents();
    } catch (error) {
      console.error('Error toggling agent status:', error);
      setDialog({ type: 'alert', isOpen: true, title: 'Erreur', message: error.message, dialogType: 'error' });
    }
  };

  const deleteAgent = async (agentId) => {
    setDialog({
      type: 'confirm',
      isOpen: true,
      title: 'Supprimer l\'agent',
      message: 'ATTENTION: Êtes-vous sûr de vouloir SUPPRIMER définitivement cet agent ? Cette action est irréversible.',
      dialogType: 'danger',
      onConfirm: () => executeDeleteAgent(agentId)
    });
  };

  const executeDeleteAgent = async (agentId) => {

    try {
      const { error } = await supabase.from('users').delete().eq('id', agentId);

      if (error) throw error;

      // Logger l'action
      await supabase.from('logs_activite').insert({
        type_action: 'suppression_agent',
        autorite_id: user?.id,
        utilisateur_cible_id: agentId,
        details: {
          action: 'Agent supprimé définitivement',
          timestamp: new Date().toISOString(),
        },
      });

      alert('✅ Agent supprimé');
      fetchAgents();
    } catch (error) {
      console.error('Error deleting agent:', error);
      alert(`❌ Erreur: ${error.message}`);
    }
  };

  const resetForm = () => {
    setFormData({
      email: '',
      password: '',
      nom: '',
      prenom: '',
      telephone: '',
      secteur: '',
    });
  };

  const openEditModal = (agent) => {
    setSelectedAgent(agent);
    setFormData({
      email: agent.email,
      password: agent.password || '',
      nom: agent.nom,
      prenom: agent.prenom,
      telephone: agent.telephone || '',
      secteur: agent.secteur || '',
    });
    setShowPassword(false);
    setShowEditModal(true);
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
      <div className="mb-8 flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Gestion des Agents</h1>
          <p className="text-gray-600 mt-2">Créer et superviser les agents terrain</p>
        </div>
        <button
          onClick={() => setShowCreateModal(true)}
          className="flex items-center gap-2 bg-blue-600 text-white px-6 py-3 rounded-lg hover:bg-blue-700 transition-colors"
        >
          <Plus className="w-5 h-5" />
          Créer un agent
        </button>
      </div>

      {/* Alerte Agents Orphelins */}
      {orphanAgents.length > 0 && (
        <div className="bg-red-50 border-2 border-red-200 rounded-xl p-6 mb-6">
          <div className="flex items-start gap-4">
            <div className="flex-shrink-0">
              <AlertTriangle className="w-8 h-8 text-red-600" />
            </div>
            <div className="flex-1">
              <div className="flex items-center justify-between mb-2">
                <h3 className="text-lg font-bold text-red-900">
                  ⚠️ Agents orphelins détectés ({orphanAgents.length})
                </h3>
                <button
                  onClick={deleteAllOrphans}
                  className="px-6 py-2 bg-red-700 text-white rounded-lg hover:bg-red-800 transition-colors flex items-center gap-2 font-semibold"
                >
                  <Trash2 className="w-5 h-5" />
                  Supprimer tout ({orphanAgents.length})
                </button>
              </div>
              <p className="text-sm text-red-700 mb-4">
                Ces agents ont été créés dans l'authentification mais n'ont pas été enregistrés dans la base de données. 
                Ils doivent être supprimés pour pouvoir recréer ces comptes.
              </p>
              <div className="space-y-3">
                {orphanAgents.map((orphan) => (
                  <div key={orphan.id} className="bg-white rounded-lg p-4 flex items-center justify-between border border-red-200">
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 rounded-full bg-red-100 flex items-center justify-center">
                        <UserX className="w-5 h-5 text-red-600" />
                      </div>
                      <div>
                        <div className="font-medium text-gray-900">{orphan.email}</div>
                        <div className="text-xs text-gray-500">
                          Créé le {format(new Date(orphan.created_at), 'dd/MM/yyyy à HH:mm', { locale: fr })}
                        </div>
                        {orphan.user_metadata?.nom && (
                          <div className="text-xs text-gray-600">
                            {orphan.user_metadata.nom} {orphan.user_metadata.prenom}
                          </div>
                        )}
                      </div>
                    </div>
                    <button
                      onClick={() => deleteOrphanAgent(orphan.id, orphan.email)}
                      className="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors flex items-center gap-2"
                    >
                      <Trash2 className="w-4 h-4" />
                      Supprimer
                    </button>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Zone fixe en haut */}
      <div className="flex-shrink-0 bg-gray-50 border-b border-gray-200 px-6 py-6">
        {/* Stats rapides */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="bg-white p-6 rounded-xl shadow-sm">
          <p className="text-sm text-gray-600">Total agents</p>
          <p className="text-3xl font-bold text-gray-900 mt-2">{agents.length}</p>
        </div>
        <div className="bg-white p-6 rounded-xl shadow-sm">
          <p className="text-sm text-gray-600">Agents actifs</p>
          <p className="text-3xl font-bold text-green-600 mt-2">
            {agents.filter(a => a.is_active).length}
          </p>
        </div>
        <div className="bg-white p-6 rounded-xl shadow-sm">
          <p className="text-sm text-gray-600">Agents inactifs</p>
          <p className="text-3xl font-bold text-red-600 mt-2">
            {agents.filter(a => !a.is_active).length}
          </p>
        </div>
      </div>

      </div>

      {/* Zone scrollable avec le tableau */}
      <div className="flex-1 overflow-auto px-6 pb-6">
        <div className="bg-white rounded-xl shadow-sm">
          <table className="w-full">
            <thead className="bg-gray-50 border-b-2 border-gray-200 sticky top-0 z-20 shadow-sm">
              <tr>
                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase bg-gray-50">Agent</th>
                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase bg-gray-50">Contact</th>
                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase bg-gray-50">Secteur</th>
                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase bg-gray-50">Statut</th>
                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase bg-gray-50">Date création</th>
                <th className="px-6 py-4 text-right text-xs font-semibold text-gray-600 uppercase bg-gray-50">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200 bg-white">
              {currentAgents.map((agent) => (
                <tr key={agent.id} className="hover:bg-gray-50">
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 rounded-full bg-purple-100 flex items-center justify-center">
                        <UserCheck className="w-5 h-5 text-purple-600" />
                      </div>
                      <div>
                        <div className="font-medium text-gray-900">
                          {agent.nom} {agent.prenom}
                        </div>
                        <div className="text-xs text-gray-500">{agent.email}</div>
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <span className="flex items-center gap-2 text-sm text-gray-600">
                      <Phone className="w-4 h-4" />
                      {agent.telephone || 'N/A'}
                    </span>
                  </td>
                  <td className="px-6 py-4">
                    <span className="flex items-center gap-2 text-sm text-gray-600">
                      <MapPin className="w-4 h-4" />
                      {agent.secteur || 'Non défini'}
                    </span>
                  </td>
                  <td className="px-6 py-4">
                    {agent.is_active ? (
                      <span className="inline-flex items-center gap-1 px-3 py-1 rounded-full bg-green-100 text-green-700 text-xs font-medium">
                        <CheckCircle className="w-3 h-3" />
                        Actif
                      </span>
                    ) : (
                      <span className="inline-flex items-center gap-1 px-3 py-1 rounded-full bg-red-100 text-red-700 text-xs font-medium">
                        <Ban className="w-3 h-3" />
                        Inactif
                      </span>
                    )}
                  </td>
                  <td className="px-6 py-4">
                    <span className="text-sm text-gray-600">
                      {format(new Date(agent.created_at), 'dd MMM yyyy', { locale: fr })}
                    </span>
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex items-center justify-end gap-2">
                      <button
                        onClick={() => openEditModal(agent)}
                        className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
                        title="Modifier"
                      >
                        <Edit2 className="w-4 h-4 text-gray-600" />
                      </button>
                      <button
                        onClick={() => toggleAgentStatus(agent.id, agent.is_active)}
                        className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
                        title={agent.is_active ? 'Désactiver' : 'Activer'}
                      >
                        {agent.is_active ? (
                          <EyeOff className="w-4 h-4 text-gray-600" />
                        ) : (
                          <Eye className="w-4 h-4 text-gray-600" />
                        )}
                      </button>
                      <button
                        onClick={() => deleteAgent(agent.id)}
                        className="p-2 hover:bg-red-50 rounded-lg transition-colors"
                        title="Supprimer"
                      >
                        <Trash2 className="w-4 h-4 text-red-600" />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>

          {agents.length === 0 && (
            <div className="text-center py-12 bg-white">
              <UserCheck className="w-12 h-12 mx-auto mb-4 text-gray-300" />
              <p className="text-gray-900 font-semibold mb-2">Aucun agent trouvé</p>
              <p className="text-sm text-gray-600 mb-4">
                Votre ID d'autorité: <span className="font-mono bg-gray-100 px-2 py-1 rounded">{user?.id || 'Non défini'}</span>
              </p>
              <p className="text-xs text-gray-500">
                Vérifiez la console du navigateur (F12) pour plus de détails
              </p>
            </div>
          )}

          {/* Pagination améliorée */}
          {agents.length > 0 && (
            <div className="border-t border-gray-200 bg-gradient-to-r from-gray-50 to-white">
              <div className="flex items-center justify-between px-6 py-4">
                <div className="flex items-center gap-6">
                  <div className="flex items-center gap-2">
                    <div className="text-sm text-gray-700 font-medium">
                      <span className="text-blue-600">{startIndex + 1}-{Math.min(endIndex, agents.length)}</span>
                      <span className="text-gray-500"> sur </span>
                      <span className="text-blue-600">{agents.length}</span>
                      <span className="text-gray-500"> agent(s)</span>
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

      {/* Modal Créer Agent */}
      {showCreateModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-xl max-w-xl w-full">
            <div className="p-6 border-b border-gray-200 flex items-center justify-between">
              <h2 className="text-2xl font-bold text-gray-900">Créer un agent</h2>
              <button
                onClick={() => {
                  setShowCreateModal(false);
                  resetForm();
                }}
                className="p-2 text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                title="Fermer"
              >
                <X className="w-6 h-6" />
              </button>
            </div>
            <form onSubmit={createAgent} className="p-6 space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Nom</label>
                  <input
                    type="text"
                    required
                    value={formData.nom}
                    onChange={(e) => setFormData({ ...formData, nom: e.target.value })}
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Prénom</label>
                  <input
                    type="text"
                    required
                    value={formData.prenom}
                    onChange={(e) => setFormData({ ...formData, prenom: e.target.value })}
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                  />
                </div>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Email</label>
                <input
                  type="email"
                  required
                  value={formData.email}
                  onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Mot de passe</label>
                <input
                  type="password"
                  required
                  minLength="8"
                  value={formData.password}
                  onChange={(e) => setFormData({ ...formData, password: e.target.value })}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Téléphone</label>
                <input
                  type="tel"
                  value={formData.telephone}
                  onChange={(e) => setFormData({ ...formData, telephone: e.target.value })}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Secteur</label>
                <input
                  type="text"
                  value={formData.secteur}
                  onChange={(e) => setFormData({ ...formData, secteur: e.target.value })}
                  placeholder="Ex: Centre-ville, Zone industrielle..."
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                />
              </div>

              <div className="flex gap-3 pt-4">
                <button
                  type="button"
                  onClick={() => {
                    setShowCreateModal(false);
                    resetForm();
                  }}
                  className="flex-1 px-6 py-3 border border-gray-300 rounded-lg hover:bg-gray-50"
                >
                  Annuler
                </button>
                <button type="submit" className="flex-1 px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700">
                  Créer l'agent
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Modal Modifier Agent */}
      {showEditModal && selectedAgent && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-xl max-w-xl w-full">
            <div className="p-6 border-b border-gray-200 flex items-center justify-between">
              <h2 className="text-2xl font-bold text-gray-900">
                Modifier - {selectedAgent.nom} {selectedAgent.prenom}
              </h2>
              <button
                onClick={() => {
                  setShowEditModal(false);
                  setSelectedAgent(null);
                  resetForm();
                }}
                className="p-2 text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                title="Fermer"
              >
                <X className="w-6 h-6" />
              </button>
            </div>
            <form onSubmit={updateAgent} className="p-6 space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Nom</label>
                  <input
                    type="text"
                    required
                    value={formData.nom}
                    onChange={(e) => setFormData({ ...formData, nom: e.target.value })}
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Prénom</label>
                  <input
                    type="text"
                    required
                    value={formData.prenom}
                    onChange={(e) => setFormData({ ...formData, prenom: e.target.value })}
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                  />
                </div>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Téléphone</label>
                <input
                  type="tel"
                  value={formData.telephone}
                  onChange={(e) => setFormData({ ...formData, telephone: e.target.value })}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Mot de passe</label>
                <div className="relative">
                  <input
                    type={showPassword ? 'text' : 'password'}
                    minLength="8"
                    value={formData.password}
                    onChange={(e) => setFormData({ ...formData, password: e.target.value })}
                    placeholder="Modifier le mot de passe"
                    className="w-full px-4 py-2 pr-12 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                  />
                  {formData.password && (
                    <button
                      type="button"
                      onClick={() => setShowPassword(!showPassword)}
                      className="absolute right-3 top-1/2 transform -translate-y-1/2 p-1 text-gray-600 hover:bg-gray-100 rounded transition-colors"
                      title={showPassword ? 'Masquer' : 'Afficher'}
                    >
                      {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                    </button>
                  )}
                </div>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Secteur</label>
                <input
                  type="text"
                  value={formData.secteur}
                  onChange={(e) => setFormData({ ...formData, secteur: e.target.value })}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                />
              </div>

              <div className="flex gap-3 pt-4">
                <button
                  type="button"
                  onClick={() => setShowEditModal(false)}
                  className="flex-1 px-6 py-3 border border-gray-300 rounded-lg hover:bg-gray-50"
                >
                  Annuler
                </button>
                <button type="submit" className="flex-1 px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700">
                  Enregistrer
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Dialogs de confirmation et d'alerte */}
      {dialog.type === 'confirm' && (
        <ConfirmDialog
          isOpen={dialog.isOpen}
          onClose={() => setDialog({ ...dialog, isOpen: false })}
          onConfirm={dialog.onConfirm}
          title={dialog.title}
          message={dialog.message}
          type={dialog.dialogType}
        />
      )}
      {dialog.type === 'alert' && (
        <AlertDialog
          isOpen={dialog.isOpen}
          onClose={() => setDialog({ ...dialog, isOpen: false })}
          title={dialog.title}
          message={dialog.message}
          type={dialog.dialogType}
        />
      )}
    </div>
  );
};

import { format } from 'date-fns';
import { fr } from 'date-fns/locale';
import { AlertCircle, Ban, CheckCircle, Edit2, Eye, EyeOff, FileText, Save, Search, Shield, UserCheck, Users, X } from 'lucide-react';
import { useEffect, useState } from 'react';
import { AlertDialog, ConfirmDialog } from '../components/Dialog';
import { supabase, getAudioPublicUrl } from '../lib/supabase';

export const UsersPage = () => {
  const [activeTab, setActiveTab] = useState('utilisateurs');
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedUser, setSelectedUser] = useState(null);
  const [isEditing, setIsEditing] = useState(false);
  const [editForm, setEditForm] = useState({});
  const [showPassword, setShowPassword] = useState(false);
  const [isSaving, setIsSaving] = useState(false);
  const [dialog, setDialog] = useState({ type: null, isOpen: false, title: '', message: '', onConfirm: null });
  
  // Pagination
  const [currentPage, setCurrentPage] = useState(1);
  const [itemsPerPage, setItemsPerPage] = useState(5);

  useEffect(() => {
    fetchUsers();
  }, [activeTab]);

  const fetchUsers = async () => {
    try {
      setLoading(true);
      
      let query = supabase.from('users').select('*').order('created_at', { ascending: false });

      if (activeTab === 'utilisateurs') {
        query = query.eq('role', 'citizen');
      } else {
        // Panel admin ne doit voir que les opérateurs (pas les utilisateurs, ni les admins, ni les agents)
        query = query.neq('role', 'citizen').neq('role', 'admin').neq('role', 'agent');
      }

      const { data, error } = await query;
      if (error) throw error;

      setUsers(data || []);
      setCurrentPage(1);
    } catch (error) {
      console.error('Error fetching users:', error);
    } finally {
      setLoading(false);
    }
  };

  const viewUserProfile = async (userId) => {
    try {
      const { data: user, error: userError } = await supabase
        .from('users')
        .select('*')
        .eq('id', userId)
        .single();

      if (userError) throw userError;

      const { data: signalements, error: sigError } = await supabase
        .from('signalements')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', { ascending: false });

      if (sigError) throw sigError;

      // Récupérer les signalements résolus par cette autorité (si c'est une autorité)
      let resolvedSignalements = [];
      let interventions = [];
      if (user.role !== 'citizen' && user.role !== 'admin') {
        // Signalements résolus par cette autorité (utiliser assigned_to car c'est l'autorité qui résout)
        const { data: resolvedData, error: resolvedError } = await supabase
          .from('signalements')
          .select('*')
          .eq('assigned_to', userId)
          .eq('etat', 'resolu')
          .not('resolved_at', 'is', null)
          .order('resolved_at', { ascending: false });

        if (!resolvedError) {
          resolvedSignalements = resolvedData || [];
        } else {
          console.error('Erreur chargement signalements résolus:', resolvedError);
        }

        // Interventions de cette autorité
        const { data: interventionsData, error: interventionsError } = await supabase
          .from('interventions')
          .select(`
            *,
            signalement:signalements(titre, description)
          `)
          .eq('autorite_id', userId)
          .order('created_at', { ascending: false });

        if (!interventionsError) {
          interventions = interventionsData || [];
        } else {
          console.error('Erreur chargement interventions:', interventionsError);
        }
      }

      const userData = { 
        ...user, 
        signalements: signalements || [], 
        resolvedSignalements: resolvedSignalements,
        interventions: interventions
      };
      setSelectedUser(userData);
      setEditForm(userData);
      setIsEditing(false);
      setShowPassword(false);
    } catch (error) {
      console.error('Error fetching user profile:', error);
    }
  };

  const updateAuthority = async () => {
    try {
      setIsSaving(true);

      // Utiliser l'API backend pour mettre à jour (gère aussi Supabase Auth)
      const response = await fetch('http://localhost:4000/api/update-authority', {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          id: selectedUser.id,
          nom: editForm.nom,
          prenom: editForm.prenom,
          email: editForm.email,
          telephone: editForm.telephone,
          role: editForm.role,
          autorite_type: editForm.autorite_type,
          secteur: editForm.secteur,
          password: editForm.password || undefined, // N'envoyer que si défini
        }),
      });

      const result = await response.json();

      if (!response.ok) {
        throw new Error(result.error || 'Erreur lors de la mise à jour');
      }

      // Afficher un avertissement si l'auth a échoué mais user est à jour
      if (result.warning) {
        setDialog({ type: 'alert', isOpen: true, title: 'Avertissement', message: result.warning, dialogType: 'warning' });
      }

      // Log activity
      const { data: { user: currentUser } } = await supabase.auth.getUser();
      const { error: logError } = await supabase.from('logs_activite').insert({
        type_action: 'modification_autorite',
        autorite_id: currentUser?.id, // ID de l'admin connecté
        utilisateur_cible_id: selectedUser.id,
        details: {
          action: 'Informations autorité modifiées',
          modifications: {
            nom: editForm.nom !== selectedUser.nom,
            prenom: editForm.prenom !== selectedUser.prenom,
            email: editForm.email !== selectedUser.email,
            telephone: editForm.telephone !== selectedUser.telephone,
            role: editForm.role !== selectedUser.role,
            secteur: editForm.secteur !== selectedUser.secteur,
            password: !!editForm.password,
          },
          timestamp: new Date().toISOString(),
        },
      });

      if (logError) {
        console.warn('Log error (non-blocking):', logError);
      }

      setDialog({ type: 'alert', isOpen: true, title: 'Succès', message: "Opérateur modifié avec succès !", dialogType: 'success' });
      setIsEditing(false);
      fetchUsers();
      viewUserProfile(selectedUser.id); // Refresh data
    } catch (error) {
      console.error('Error updating authority:', error);
      setDialog({ type: 'alert', isOpen: true, title: 'Erreur', message: 'Erreur lors de la modification: ' + error.message, dialogType: 'error' });
    } finally {
      setIsSaving(false);
    }
  };

  const toggleUserStatus = async (userId, currentStatus) => {
    try {
      const { error } = await supabase
        .from('users')
        .update({ is_active: !currentStatus })
        .eq('id', userId);

      if (error) throw error;

      // Log activity
      const { data: { user: currentUser2 } } = await supabase.auth.getUser();
      await supabase.from('logs_activite').insert({
        type_action: currentStatus ? 'desactivation_compte' : 'reactivation_compte',
        autorite_id: currentUser2?.id,
        utilisateur_cible_id: userId,
        details: {
          action: currentStatus ? 'Compte désactivé' : 'Compte réactivé',
          timestamp: new Date().toISOString(),
        },
      });

      setDialog({ type: 'alert', isOpen: true, title: 'Succès', message: `Opérateur ${!currentStatus ? "activé" : "désactivé"} avec succès`, dialogType: 'success' });
      fetchUsers();
      if (selectedUser?.id === userId) {
        setSelectedUser(null);
      }
    } catch (error) {
      console.error('Error toggling user status:', error);
      setDialog({ type: 'alert', isOpen: true, title: 'Erreur', message: 'Erreur lors de la modification du statut', dialogType: 'error' });
    }
  };

  const filteredUsers = users.filter(
    (user) =>
      user.nom?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      user.prenom?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      user.email?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      user.telephone?.includes(searchTerm)
  );

  // Calcul pagination
  const totalPages = Math.ceil(filteredUsers.length / itemsPerPage);
  const startIndex = (currentPage - 1) * itemsPerPage;
  const endIndex = startIndex + itemsPerPage;
  const currentUsers = filteredUsers.slice(startIndex, endIndex);

  const goToPage = (page) => {
    setCurrentPage(Math.max(1, Math.min(page, totalPages)));
  };

  return (
    <div className="flex flex-col h-screen overflow-hidden">
      {/* Zone fixe en haut */}
      <div className="flex-shrink-0 bg-white border-b border-gray-200 px-6 py-6">
        <div className="mb-6">
          <h1 className="text-3xl font-bold text-gray-900">Gestion des utilisateurs</h1>
          <p className="text-gray-600 mt-2">Consulter et gérer les comptes utilisateurs</p>
        </div>

      {/* Tabs */}
      <div className="flex gap-4 mb-6 border-b border-gray-200">
        <button
          onClick={() => setActiveTab('utilisateurs')}
          className={`pb-4 px-6 font-semibold transition-colors relative ${
            activeTab === 'utilisateurs'
              ? 'text-blue-600'
              : 'text-gray-600 hover:text-gray-900'
          }`}
        >
          <div className="flex items-center gap-2">
            <Users className="w-5 h-5" />
            <span>UTILISATEURS</span>
          </div>
          {activeTab === 'utilisateurs' && (
            <div className="absolute bottom-0 left-0 right-0 h-0.5 bg-blue-600"></div>
          )}
        </button>
        <button
          onClick={() => setActiveTab('operateurs')}
          className={`pb-4 px-6 font-semibold transition-colors relative ${
            activeTab === 'operateurs'
              ? 'text-blue-600'
              : 'text-gray-600 hover:text-gray-900'
          }`}
        >
          <div className="flex items-center gap-2">
            <Shield className="w-5 h-5" />
            <span>OPÉRATEURS</span>
          </div>
          {activeTab === 'operateurs' && (
            <div className="absolute bottom-0 left-0 right-0 h-0.5 bg-blue-600"></div>
          )}
        </button>
      </div>

        {/* Search */}
        <div>
          <div className="relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
            <input
              type="text"
              value={searchTerm}
              onChange={(e) => {
                setSearchTerm(e.target.value);
                setCurrentPage(1);
              }}
              placeholder="Rechercher par nom, email, téléphone..."
              className="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            />
          </div>
        </div>
      </div>

      {/* Zone scrollable avec le tableau */}
      <div className="flex-1 overflow-auto px-6 pb-6">
        {loading ? (
        <div className="flex items-center justify-center h-64">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
        </div>
      ) : (
          <div className="bg-white rounded-xl shadow-sm">
            <table className="w-full">
              <thead className="bg-gray-50 border-b-2 border-gray-200 sticky top-0 z-20 shadow-sm">
                <tr>
                  <th className="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase bg-gray-50">
                    {activeTab === 'operateurs' ? 'Opérateur' : 'Utilisateur'}
                  </th>
                  <th className="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase bg-gray-50">
                    Contact
                  </th>
                  {activeTab === 'operateurs' && (
                    <th className="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase bg-gray-50">
                      Rôle
                    </th>
                  )}
                  <th className="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase bg-gray-50">
                    Statut
                  </th>
                  <th className="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase bg-gray-50">
                    Inscrit le
                  </th>
                  <th className="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase bg-gray-50">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200 bg-white">
                {currentUsers.map((user) => (
                <tr key={user.id} className="hover:bg-gray-50 transition-colors">
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 bg-blue-100 rounded-full flex items-center justify-center">
                        <span className="text-blue-600 font-semibold">
                          {user.prenom?.charAt(0)}{user.nom?.charAt(0)}
                        </span>
                      </div>
                      <div>
                        <p className="font-medium text-gray-900">
                          {user.prenom} {user.nom}
                        </p>
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <p className="text-sm text-gray-900">{user.email}</p>
                    <p className="text-sm text-gray-500">{user.telephone}</p>
                  </td>
                  {activeTab === 'operateurs' && (
                    <td className="px-6 py-4">
                      <span className="inline-flex items-center px-3 py-1 rounded-full text-xs font-medium bg-purple-100 text-purple-700 capitalize">
                        {user.role?.replace(/_/g, ' ')}
                      </span>
                    </td>
                  )}
                  <td className="px-6 py-4">
                    {user.is_active ? (
                      <span className="inline-flex items-center gap-1 px-3 py-1 rounded-full text-xs font-medium bg-green-100 text-green-700">
                        <CheckCircle className="w-3 h-3" />
                        Actif
                      </span>
                    ) : (
                      <span className="inline-flex items-center gap-1 px-3 py-1 rounded-full text-xs font-medium bg-red-100 text-red-700">
                        <AlertCircle className="w-3 h-3" />
                        Désactivé
                      </span>
                    )}
                  </td>
                  <td className="px-6 py-4 text-sm text-gray-600">
                    {format(new Date(user.created_at), 'dd MMM yyyy', { locale: fr })}
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-2">
                      <button
                        onClick={() => viewUserProfile(user.id)}
                        className="p-2 text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                        title="Voir le profil"
                      >
                        <Eye className="w-4 h-4" />
                      </button>
                      <button
                        onClick={() => toggleUserStatus(user.id, user.is_active)}
                        className={`p-2 rounded-lg transition-colors ${
                          user.is_active
                            ? 'text-red-600 hover:bg-red-50'
                            : 'text-green-600 hover:bg-green-50'
                        }`}
                        title={user.is_active ? 'Désactiver' : 'Réactiver'}
                      >
                        {user.is_active ? <Ban className="w-4 h-4" /> : <CheckCircle className="w-4 h-4" />}
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          
          {filteredUsers.length === 0 && (
            <div className="text-center py-12 bg-white">
              <Users className="w-12 h-12 text-gray-400 mx-auto mb-3" />
              <p className="text-gray-600">Aucun utilisateur trouvé</p>
            </div>
          )}

          {/* Pagination améliorée */}
          {filteredUsers.length > 0 && (
            <div className="border-t border-gray-200 bg-gradient-to-r from-gray-50 to-white">
              <div className="flex items-center justify-between px-6 py-4">
                {/* Informations et sélecteur */}
                <div className="flex items-center gap-6">
                  <div className="flex items-center gap-2">
                    <div className="text-sm text-gray-700 font-medium">
                      <span className="text-blue-600">{startIndex + 1}-{Math.min(endIndex, filteredUsers.length)}</span>
                      <span className="text-gray-500"> sur </span>
                      <span className="text-blue-600">{filteredUsers.length}</span>
                      <span className="text-gray-500"> utilisateur(s)</span>
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

      {/* User Profile Modal */}
      {selectedUser && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-xl max-w-3xl w-full max-h-[90vh] overflow-y-auto">
            {/* En-tête du modal */}
            <div className="p-6 border-b border-gray-200 flex justify-between items-start">
              <div>
                <h2 className="text-2xl font-bold text-gray-900">
                  {selectedUser.prenom} {selectedUser.nom}
                </h2>
                <div className="flex items-center gap-2 mt-2">
                  <span className={`inline-flex items-center gap-1 px-3 py-1 rounded-full text-xs font-medium ${
                    selectedUser.is_active 
                      ? 'bg-green-100 text-green-700' 
                      : 'bg-red-100 text-red-700'
                  }`}>
                    {selectedUser.is_active ? (
                      <><CheckCircle className="w-3 h-3" /> Actif</>
                    ) : (
                      <><AlertCircle className="w-3 h-3" /> Désactivé</>
                    )}
                  </span>
                  <span className="px-3 py-1 rounded-full text-xs font-medium bg-purple-100 text-purple-700 capitalize">
                    {selectedUser.role === 'citizen' ? 'Utilisateur' : 'Opérateur'}
                  </span>
                </div>
              </div>
              <div className="flex items-center gap-2">
                {selectedUser.role !== 'citizen' && !isEditing && (
                  <button
                    onClick={() => setIsEditing(true)}
                    className="flex items-center gap-2 px-4 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors"
                  >
                    <Edit2 className="w-4 h-4" />
                    Modifier
                  </button>
                )}
                <button
                  onClick={() => setSelectedUser(null)}
                  className="p-2 text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                  title="Fermer"
                >
                  <X className="w-6 h-6" />
                </button>
              </div>
            </div>

            <div className="p-6 space-y-6">
              {/* Informations du compte */}
              <div className="bg-blue-50 rounded-lg p-4 border border-blue-200">
                <h3 className="font-semibold text-gray-900 mb-3 flex items-center gap-2">
                  {selectedUser.role !== 'citizen' ? (
                    <Shield className="w-5 h-5 text-blue-600" />
                  ) : (
                    <UserCheck className="w-5 h-5 text-blue-600" />
                  )}
                  Informations du compte
                </h3>
                
                {isEditing ? (
                  // Edit Mode
                  <div className="space-y-4">
                    <div className="grid grid-cols-2 gap-4">
                      <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">
                          Prénom *
                        </label>
                        <input
                          type="text"
                          value={editForm.prenom || ''}
                          onChange={(e) => setEditForm({ ...editForm, prenom: e.target.value })}
                          className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-transparent"
                          required
                        />
                      </div>
                      <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">
                          Nom *
                        </label>
                        <input
                          type="text"
                          value={editForm.nom || ''}
                          onChange={(e) => setEditForm({ ...editForm, nom: e.target.value })}
                          className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-transparent"
                          required
                        />
                      </div>
                    </div>

                    <div className="grid grid-cols-2 gap-4">
                      <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">
                          Email *
                        </label>
                        <input
                          type="email"
                          value={editForm.email || ''}
                          onChange={(e) => setEditForm({ ...editForm, email: e.target.value })}
                          className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-transparent"
                          required
                        />
                      </div>
                      <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">
                          Téléphone *
                        </label>
                        <input
                          type="tel"
                          value={editForm.telephone || ''}
                          onChange={(e) => setEditForm({ ...editForm, telephone: e.target.value })}
                          className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-transparent"
                          required
                        />
                      </div>
                    </div>

                    <div className="grid grid-cols-2 gap-4">
                      <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">
                          Type d&apos;opérateur *
                        </label>
                        <select
                          value={editForm.role || ''}
                          onChange={(e) => setEditForm({ ...editForm, role: e.target.value })}
                          className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-transparent"
                          required
                        >
                          <option value="autorite_locale">Opérateur Local</option>
                          <option value="autorite_regionale">Opérateur Régional</option>
                          <option value="autorite_nationale">Opérateur National</option>
                        </select>
                      </div>
                      <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">
                          Secteur
                        </label>
                        <input
                          type="text"
                          value={editForm.secteur || ''}
                          onChange={(e) => setEditForm({ ...editForm, secteur: e.target.value })}
                          className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-transparent"
                          placeholder="Ex: Koumassi, Yopougon..."
                        />
                      </div>
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">
                        Nouveau mot de passe (laisser vide pour ne pas modifier)
                      </label>
                      <div className="relative">
                        <input
                          type={showPassword ? 'text' : 'password'}
                          value={editForm.password || ''}
                          onChange={(e) => setEditForm({ ...editForm, password: e.target.value })}
                          className="w-full px-3 py-2 pr-10 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-transparent"
                          placeholder="Minimum 6 caractères"
                          minLength={6}
                        />
                        <button
                          type="button"
                          onClick={() => setShowPassword(!showPassword)}
                          className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-500 hover:text-gray-700"
                        >
                          {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                        </button>
                      </div>
                      <p className="text-xs text-gray-500 mt-1">
                        {editForm.password && editForm.password.length < 6 && (
                          <span className="text-red-600">Le mot de passe doit contenir au moins 6 caractères</span>
                        )}
                      </p>
                    </div>
                  </div>
                ) : (
                  // View Mode - Avec photo de profil et grille
                  <div className="flex items-start gap-4">
                    {/* Photo de profil */}
                    <div className="flex-shrink-0">
                      {selectedUser.photo_url ? (
                        <img
                          src={selectedUser.photo_url}
                          alt="Photo de profil"
                          className="w-16 h-16 rounded-full object-cover border-2 border-blue-300"
                        />
                      ) : (
                        <div className="w-16 h-16 rounded-full bg-blue-200 flex items-center justify-center border-2 border-blue-300">
                          {selectedUser.role !== 'citizen' ? (
                            <Shield className="w-8 h-8 text-blue-600" />
                          ) : (
                            <UserCheck className="w-8 h-8 text-blue-600" />
                          )}
                        </div>
                      )}
                    </div>
                    
                    {/* Détails de l'utilisateur */}
                    <div className="flex-1 grid grid-cols-2 gap-3">
                      <div>
                        <p className="text-xs text-gray-500">Nom complet</p>
                        <p className="font-medium text-gray-900">
                          {selectedUser.prenom} {selectedUser.nom}
                        </p>
                      </div>
                      <div>
                        <p className="text-xs text-gray-500">Email</p>
                        <p className="font-medium text-gray-900">{selectedUser.email}</p>
                      </div>
                      <div>
                        <p className="text-xs text-gray-500">Téléphone</p>
                        <p className="font-medium text-gray-900">{selectedUser.telephone}</p>
                      </div>
                      <div>
                        <p className="text-xs text-gray-500">Membre depuis</p>
                        <p className="font-medium text-gray-900">
                          {format(new Date(selectedUser.created_at), 'dd/MM/yyyy', { locale: fr })}
                        </p>
                      </div>
                      {selectedUser.role !== 'citizen' && selectedUser.autorite_type && (
                        <div>
                          <p className="text-xs text-gray-500">Type d&apos;opérateur</p>
                          <p className="font-medium text-gray-900 capitalize">{selectedUser.autorite_type?.replace(/_/g, ' ')}</p>
                        </div>
                      )}
                      {selectedUser.secteur && (
                        <div>
                          <p className="text-xs text-gray-500">Secteur</p>
                          <p className="font-medium text-gray-900">{selectedUser.secteur}</p>
                        </div>
                      )}
                    </div>
                  </div>
                )}
              </div>

              {/* Mot de passe - Section séparée pour les opérateurs */}
              {selectedUser.role !== 'citizen' && !isEditing && (
                <div>
                  <h3 className="font-semibold text-gray-900 mb-2">Mot de passe</h3>
                  <div className="flex items-center gap-2">
                    <div className="flex-1 px-3 py-2 bg-gray-50 border border-gray-200 rounded-lg font-mono text-sm">
                      {selectedUser.password ? (
                        showPassword ? selectedUser.password : '••••••••••••'
                      ) : (
                        <span className="text-gray-400 italic">Non défini</span>
                      )}
                    </div>
                    {selectedUser.password && (
                      <button
                        onClick={() => setShowPassword(!showPassword)}
                        className="p-2 text-gray-600 hover:bg-gray-100 rounded-lg transition-colors"
                        title={showPassword ? 'Masquer' : 'Afficher'}
                      >
                        {showPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
                      </button>
                    )}
                  </div>
                </div>
              )}

              {/* Signalements résolus par cet opérateur */}
              {selectedUser.role !== 'citizen' && selectedUser.resolvedSignalements && (
                <div className="bg-green-50 rounded-lg p-4 border border-green-200">
                  <h3 className="font-semibold text-gray-900 mb-3 flex items-center gap-2">
                    <CheckCircle className="w-5 h-5 text-green-600" />
                    Signalements résolus ({selectedUser.resolvedSignalements.length})
                  </h3>
                  {selectedUser.resolvedSignalements.length > 0 ? (
                    <div className="space-y-3">
                      {selectedUser.resolvedSignalements.map((sig) => (
                        <div key={sig.id} className="p-3 bg-white rounded-lg border border-green-300">
                          <div className="flex items-start justify-between gap-3">
                            <div className="flex-1">
                              <p className="font-medium text-gray-900">{sig.titre}</p>
                              <p className="text-sm text-gray-600 mt-1 line-clamp-2">{sig.description}</p>
                              {sig.photo_url && (
                                <img 
                                  src={sig.photo_url} 
                                  alt="Photo du signalement"
                                  className="mt-2 w-32 h-32 object-cover rounded-lg cursor-pointer hover:opacity-90 transition"
                                  onClick={() => window.open(sig.photo_url, '_blank')}
                                />
                              )}
                            </div>
                            <div className="text-right flex-shrink-0">
                              <span className="inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-700">
                                <CheckCircle className="w-3 h-3" /> Résolu
                              </span>
                              <p className="text-xs text-gray-500 mt-2">
                                {format(new Date(sig.resolved_at), 'dd MMM yyyy', { locale: fr })}
                              </p>
                              {sig.note_resolution && (
                                <p className="text-xs text-gray-600 mt-1 italic">"{sig.note_resolution}"</p>
                              )}
                            </div>
                          </div>
                        </div>
                      ))}
                    </div>
                  ) : (
                    <p className="text-gray-500 text-center py-4 bg-white rounded-lg">Aucun signalement résolu</p>
                  )}
                </div>
              )}

              {/* Interventions */}
              {selectedUser.role !== 'citizen' && selectedUser.interventions && (
                <div className="bg-orange-50 rounded-lg p-4 border border-orange-200">
                  <h3 className="font-semibold text-gray-900 mb-3 flex items-center gap-2">
                    <AlertCircle className="w-5 h-5 text-orange-600" />
                    Interventions ({selectedUser.interventions.length})
                  </h3>
                  {selectedUser.interventions.length > 0 ? (
                    <div className="space-y-2">
                      {selectedUser.interventions.map((intervention) => {
                        const duration = intervention.debut_intervention && intervention.fin_intervention
                          ? Math.round((new Date(intervention.fin_intervention) - new Date(intervention.debut_intervention)) / 1000 / 60)
                          : null;
                        
                        return (
                          <div key={intervention.id} className="p-3 bg-white rounded-lg border border-orange-300">
                            <div className="flex items-start justify-between gap-3">
                              <div className="flex-1">
                                <p className="font-medium text-gray-900">
                                  {intervention.signalement?.titre || 'Signalement'}
                                </p>
                                {intervention.notes && (
                                  <p className="text-sm text-gray-600 mt-1">{intervention.notes}</p>
                                )}
                                <div className="mt-2 space-y-1">
                                  {intervention.debut_intervention && (
                                    <p className="text-xs text-gray-500">
                                      Début: {format(new Date(intervention.debut_intervention), 'dd MMM yyyy à HH:mm', { locale: fr })}
                                    </p>
                                  )}
                                  {intervention.fin_intervention && (
                                    <p className="text-xs text-gray-500">
                                      Fin: {format(new Date(intervention.fin_intervention), 'dd MMM yyyy à HH:mm', { locale: fr })}
                                    </p>
                                  )}
                                  {duration !== null && (
                                    <p className="text-xs font-medium text-orange-600">
                                      Durée: {duration} min{duration > 1 ? 's' : ''}
                                    </p>
                                  )}
                                </div>
                              </div>
                              <div className="flex-shrink-0">
                                <span className={`inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium ${
                                  intervention.etat === 'termine' ? 'bg-green-100 text-green-700' :
                                  intervention.etat === 'en_cours' ? 'bg-yellow-100 text-yellow-700' :
                                  intervention.etat === 'annule' ? 'bg-red-100 text-red-700' :
                                  'bg-gray-100 text-gray-700'
                                }`}>
                                  {intervention.etat === 'termine' ? 'Terminé' :
                                   intervention.etat === 'en_cours' ? 'En cours' :
                                   intervention.etat === 'annule' ? 'Annulé' :
                                   'En attente'}
                                </span>
                              </div>
                            </div>
                          </div>
                        );
                      })}
                    </div>
                  ) : (
                    <p className="text-gray-500 text-center py-4 bg-white rounded-lg">Aucune intervention enregistrée</p>
                  )}
                </div>
              )}

              {/* Historique des signalements - uniquement pour les utilisateurs */}
              {selectedUser.role === 'citizen' && (
                <div className="bg-purple-50 rounded-lg p-4 border border-purple-200">
                  <h3 className="font-semibold text-gray-900 mb-3 flex items-center gap-2">
                    <FileText className="w-5 h-5 text-purple-600" />
                    Historique des signalements ({selectedUser.signalements?.length || 0})
                  </h3>
                  {selectedUser.signalements?.length > 0 ? (
                  <div className="space-y-3">
                    {selectedUser.signalements.map((sig) => (
                      <div key={sig.id} className={`p-3 bg-white rounded-lg border ${sig.deleted_by_user ? 'border-red-400 bg-red-50' : 'border-purple-300'}`}>
                        {/* Étiquette de suppression par l'utilisateur */}
                        {sig.deleted_by_user && (
                          <div className="mb-2 p-2 bg-red-100 rounded-lg border border-red-300">
                            <p className="text-xs font-semibold text-red-700">🗑️ Supprimé par l'utilisateur</p>
                            {sig.deleted_at && (
                              <p className="text-xs text-red-600">
                                Le {format(new Date(sig.deleted_at), 'dd MMM yyyy à HH:mm', { locale: fr })}
                              </p>
                            )}
                          </div>
                        )}
                        <div className="flex items-start justify-between gap-3">
                          <div className="flex-1">
                            <p className={`font-medium ${sig.deleted_by_user ? 'text-gray-500 line-through' : 'text-gray-900'}`}>{sig.titre}</p>
                            <p className={`text-sm mt-1 ${sig.deleted_by_user ? 'text-gray-400' : 'text-gray-600'}`}>{sig.description}</p>
                            
                            {/* Photo du signalement */}
                            {sig.photo_url && (
                              <div className="mt-3">
                                <img 
                                  src={sig.photo_url} 
                                  alt="Photo du signalement"
                                  className="w-full max-w-md h-48 object-cover rounded-lg shadow-md cursor-pointer hover:opacity-90 transition"
                                  onClick={() => window.open(sig.photo_url, '_blank')}
                                  title="Cliquer pour voir en grand"
                                />
                              </div>
                            )}
                            
                            {/* Lecteur audio */}
                            {sig.audio_url && (
                              <div className="mt-3 bg-purple-50 p-3 rounded-lg border border-purple-200">
                                <p className="text-xs text-purple-600 mb-2">🎤 Enregistrement audio :</p>
                                <audio 
                                  controls 
                                  className="w-full"
                                  style={{ height: '40px' }}
                                  key={sig.id}
                                >
                                  <source src={getAudioPublicUrl(sig.audio_url)} type="audio/mpeg" />
                                  <source src={getAudioPublicUrl(sig.audio_url)} type="audio/wav" />
                                  <source src={getAudioPublicUrl(sig.audio_url)} type="audio/ogg" />
                                  Votre navigateur ne supporte pas la lecture audio.
                                </audio>
                                {sig.audio_duration && (
                                  <p className="text-xs text-gray-500 mt-1">
                                    Durée : {Math.floor(sig.audio_duration / 60)}:{String(sig.audio_duration % 60).padStart(2, '0')}
                                  </p>
                                )}
                              </div>
                            )}
                          </div>
                          
                          <div className="flex flex-col items-end gap-2 flex-shrink-0">
                            {/* Badge supprimé par l'utilisateur */}
                            {sig.deleted_by_user && (
                              <span className="inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium bg-red-100 text-red-700 border border-red-300">
                                🗑️ Supprimé
                              </span>
                            )}
                            <span className={`inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium ${
                              sig.etat === 'resolu' ? 'bg-green-100 text-green-700' :
                              sig.etat === 'en_cours' ? 'bg-yellow-100 text-yellow-700' :
                              'bg-gray-100 text-gray-700'
                            }`}>
                              {sig.etat === 'resolu' ? 'Résolu' :
                               sig.etat === 'en_cours' ? 'En cours' :
                               'En attente'}
                            </span>
                            <p className="text-xs text-gray-500">
                              {format(new Date(sig.created_at), 'dd MMM yyyy', { locale: fr })}
                            </p>
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>
                ) : (
                  <p className="text-gray-500 text-center py-4 bg-white rounded-lg">Aucun signalement</p>
                )}
                </div>
              )}
            </div>

            <div className="p-6 border-t border-gray-200 flex justify-between">
              <div className="flex gap-3">
                {isEditing ? (
                  <>
                    <button
                      onClick={() => {
                        setIsEditing(false);
                        setEditForm(selectedUser);
                      }}
                      className="px-6 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 transition-colors flex items-center gap-2"
                    >
                      <X className="w-4 h-4" />
                      Annuler
                    </button>
                    <button
                      onClick={updateAuthority}
                      disabled={isSaving}
                      className="px-6 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors flex items-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed"
                    >
                      <Save className="w-4 h-4" />
                      {isSaving ? 'Enregistrement...' : 'Enregistrer'}
                    </button>
                  </>
                ) : (
                  <button
                    onClick={() => setSelectedUser(null)}
                    className="px-6 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 transition-colors"
                  >
                    Fermer
                  </button>
                )}
              </div>
            </div>
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

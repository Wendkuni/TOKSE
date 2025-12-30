import { format } from 'date-fns';
import { fr } from 'date-fns/locale';
import { Ban, CheckCircle, Eye, EyeOff, Lock, Plus, Shield, Trash2, UserCheck, UserCog, X } from 'lucide-react';
import { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';

export const AdminManagementPage = () => {
  const [admins, setAdmins] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [showPermissionsModal, setShowPermissionsModal] = useState(false);
  const [selectedAdmin, setSelectedAdmin] = useState(null);
  const [currentUser, setCurrentUser] = useState(null);
  
  // Pagination
  const [currentPage, setCurrentPage] = useState(1);
  const [itemsPerPage, setItemsPerPage] = useState(5);
  
  const [formData, setFormData] = useState({
    email: '',
    password: '',
    nom: '',
    prenom: '',
    permissions: {
      view_users: true,
      manage_users: false,
      view_authorities: true,
      manage_authorities: false,
      view_signalements: true,
      manage_signalements: false,
      view_logs: true,
      manage_admins: false,
      view_statistics: true,
      export_data: false,
    },
  });

  useEffect(() => {
    fetchAdmins();
    fetchCurrentUser();
  }, []);

  const fetchCurrentUser = async () => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (user) {
        const { data: userData } = await supabase
          .from('users')
          .select('*')
          .eq('id', user.id)
          .single();
        setCurrentUser(userData);
      }
    } catch (error) {
      console.error('Error fetching current user:', error);
    }
  };

  const fetchAdmins = async () => {
    try {
      setLoading(true);
      const { data, error } = await supabase
        .from('users')
        .select('*')
        .in('role', ['admin', 'super_admin'])
        .order('created_at', { ascending: false });

      if (error) throw error;
      setAdmins(data || []);
      setCurrentPage(1);
    } catch (error) {
      console.error('Error fetching admins:', error);
    } finally {
      setLoading(false);
    }
  };

  // Calcul pagination
  const totalPages = Math.ceil(admins.length / itemsPerPage);
  const startIndex = (currentPage - 1) * itemsPerPage;
  const endIndex = startIndex + itemsPerPage;
  const currentAdmins = admins.slice(startIndex, endIndex);

  const goToPage = (page) => {
    setCurrentPage(Math.max(1, Math.min(page, totalPages)));
  };

  const createAdmin = async (e) => {
    e.preventDefault();
    
    // Vérifier les permissions
    if (currentUser?.role !== 'super_admin' && !currentUser?.permissions?.manage_admins) {
      alert('❌ Vous n\'avez pas la permission de créer des administrateurs.');
      return;
    }
    
    try {
      // 1. Créer l'utilisateur Auth
      const { data: authData, error: authError } = await supabase.auth.signUp({
        email: formData.email,
        password: formData.password,
        options: {
          data: {
            nom: formData.nom,
            prenom: formData.prenom,
          },
        },
      });

      if (authError) throw authError;

      // 2. Créer le profil admin avec permissions
      const { error: profileError } = await supabase.from('users').insert({
        id: authData.user.id,
        email: formData.email,
        nom: formData.nom,
        prenom: formData.prenom,
        role: 'admin', // Les admins créés sont toujours 'admin', pas 'super_admin'
        permissions: formData.permissions,
        is_active: true,
      });

      if (profileError) throw profileError;

      // 3. Logger l'action
      const { data: currentUserAuth } = await supabase.auth.getUser();
      await supabase.from('logs_activite').insert({
        type_action: 'creation_admin',
        autorite_id: currentUserAuth.user.id,
        utilisateur_cible_id: authData.user.id,
        details: {
          admin_createur: `${currentUser?.nom} ${currentUser?.prenom}`,
          email: formData.email,
          nom: formData.nom,
          prenom: formData.prenom,
          permissions: formData.permissions,
          timestamp: new Date().toISOString(),
        },
      });

      alert('✅ Administrateur créé avec succès !');
      setShowCreateModal(false);
      resetForm();
      fetchAdmins();
    } catch (error) {
      console.error('Error creating admin:', error);
      alert(`❌ Erreur: ${error.message}`);
    }
  };

  const updatePermissions = async () => {
    // Vérifier les permissions
    if (currentUser?.role !== 'super_admin' && !currentUser?.permissions?.manage_admins) {
      alert('❌ Vous n\'avez pas la permission de modifier les permissions.');
      return;
    }
    
    // Empêcher de modifier un super_admin si on n'est pas super_admin
    if (selectedAdmin?.role === 'super_admin' && currentUser?.role !== 'super_admin') {
      alert('❌ Seul un super administrateur peut modifier les permissions d\'un super administrateur.');
      return;
    }
    
    try {
      const { error } = await supabase
        .from('users')
        .update({ permissions: formData.permissions })
        .eq('id', selectedAdmin.id);

      if (error) throw error;

      // Logger l'action
      const { data: currentUserAuth } = await supabase.auth.getUser();
      await supabase.from('logs_activite').insert({
        type_action: 'modification_permissions',
        autorite_id: currentUserAuth.user.id,
        utilisateur_cible_id: selectedAdmin.id,
        details: {
          admin_modificateur: `${currentUser?.nom} ${currentUser?.prenom}`,
          admin_cible: `${selectedAdmin?.nom} ${selectedAdmin?.prenom}`,
          old_permissions: selectedAdmin.permissions,
          new_permissions: formData.permissions,
          timestamp: new Date().toISOString(),
        },
      });

      alert('✅ Permissions mises à jour !');
      setShowPermissionsModal(false);
      fetchAdmins();
    } catch (error) {
      console.error('Error updating permissions:', error);
      alert(`❌ Erreur: ${error.message}`);
    }
  };

  const toggleAdminStatus = async (adminId, currentStatus) => {
    // Trouver l'admin ciblé
    const targetAdmin = admins.find(a => a.id === adminId);
    
    // Vérifier les permissions
    if (currentUser?.role !== 'super_admin' && !currentUser?.permissions?.manage_admins) {
      alert('❌ Vous n\'avez pas la permission de modifier le statut des administrateurs.');
      return;
    }
    
    // Empêcher de modifier un super_admin si on n'est pas super_admin
    if (targetAdmin?.role === 'super_admin' && currentUser?.role !== 'super_admin') {
      alert('❌ Seul un super administrateur peut modifier le statut d\'un super administrateur.');
      return;
    }
    
    if (!confirm(`Êtes-vous sûr de vouloir ${currentStatus ? 'désactiver' : 'activer'} cet administrateur ?`)) {
      return;
    }

    try {
      const { error } = await supabase
        .from('users')
        .update({ is_active: !currentStatus })
        .eq('id', adminId);

      if (error) throw error;

      // Logger l'action
      const { data: currentUserAuth } = await supabase.auth.getUser();
      await supabase.from('logs_activite').insert({
        type_action: currentStatus ? 'desactivation_admin' : 'reactivation_admin',
        autorite_id: currentUserAuth.user.id,
        utilisateur_cible_id: adminId,
        details: {
          admin_modificateur: `${currentUser?.nom} ${currentUser?.prenom}`,
          admin_cible: `${targetAdmin?.nom} ${targetAdmin?.prenom}`,
          action: currentStatus ? 'Admin désactivé' : 'Admin réactivé',
          timestamp: new Date().toISOString(),
        },
      });

      fetchAdmins();
    } catch (error) {
      console.error('Error toggling admin status:', error);
      alert(`❌ Erreur: ${error.message}`);
    }
  };

  const deleteAdmin = async (adminId) => {
    // Trouver l'admin ciblé
    const targetAdmin = admins.find(a => a.id === adminId);
    
    // Vérifier les permissions
    if (currentUser?.role !== 'super_admin' && !currentUser?.permissions?.manage_admins) {
      alert('❌ Vous n\'avez pas la permission de supprimer des administrateurs.');
      return;
    }
    
    // Empêcher de supprimer un super_admin si on n'est pas super_admin
    if (targetAdmin?.role === 'super_admin' && currentUser?.role !== 'super_admin') {
      alert('❌ Seul un super administrateur peut supprimer un super administrateur.');
      return;
    }
    
    // Empêcher de se supprimer soi-même
    if (adminId === currentUser?.id) {
      alert('❌ Vous ne pouvez pas supprimer votre propre compte.');
      return;
    }
    
    if (!confirm('⚠️ ATTENTION: Êtes-vous sûr de vouloir SUPPRIMER définitivement cet administrateur ?')) {
      return;
    }

    try {
      const { error } = await supabase.from('users').delete().eq('id', adminId);

      if (error) throw error;

      // Logger l'action
      const { data: currentUserAuth } = await supabase.auth.getUser();
      await supabase.from('logs_activite').insert({
        type_action: 'suppression_admin',
        autorite_id: currentUserAuth.user.id,
        utilisateur_cible_id: adminId,
        details: {
          admin_modificateur: `${currentUser?.nom} ${currentUser?.prenom}`,
          admin_supprime: `${targetAdmin?.nom} ${targetAdmin?.prenom}`,
          action: 'Admin supprimé définitivement',
          timestamp: new Date().toISOString(),
        },
      });

      alert('✅ Administrateur supprimé');
      fetchAdmins();
    } catch (error) {
      console.error('Error deleting admin:', error);
      alert(`❌ Erreur: ${error.message}`);
    }
  };

  const resetForm = () => {
    setFormData({
      email: '',
      password: '',
      nom: '',
      prenom: '',
      permissions: {
        view_users: true,
        manage_users: false,
        view_authorities: true,
        manage_authorities: false,
        view_signalements: true,
        manage_signalements: false,
        view_logs: true,
        manage_admins: false,
        view_statistics: true,
        export_data: false,
      },
    });
  };

  const openPermissionsModal = (admin) => {
    setSelectedAdmin(admin);
    setFormData((prev) => ({
      ...prev,
      permissions: admin.permissions || prev.permissions,
    }));
    setShowPermissionsModal(true);
  };

  const getPermissionLabel = (key) => {
    const labels = {
      view_users: 'Voir les utilisateurs',
      manage_users: 'Gérer les utilisateurs',
      view_authorities: 'Voir les autorités',
      manage_authorities: 'Gérer les autorités',
      view_signalements: 'Voir les signalements',
      manage_signalements: 'Gérer les signalements',
      view_logs: 'Voir les logs',
      manage_admins: 'Gérer les admins',
      view_statistics: 'Voir les statistiques',
      export_data: 'Exporter les données',
    };
    return labels[key] || key;
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64 bg-gray-50">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  return (
    <div className="flex flex-col h-screen overflow-hidden bg-gray-50">
      {/* Header */}
      <div className="flex-shrink-0 bg-white rounded-lg shadow-sm border border-gray-200 px-6 py-6 mb-6">
        <div className="flex justify-between items-center">
          <div className="flex items-center gap-4">
            <Shield className="w-10 h-10 text-blue-600" />
            <div>
              <h1 className="text-2xl font-bold text-gray-900">Gestion des administrateurs</h1>
              <p className="text-gray-600 text-sm mt-1">
                Créer et gérer les comptes administrateurs avec permissions
              </p>
            </div>
          </div>
          <button
            onClick={() => setShowCreateModal(true)}
            className="flex items-center gap-2 bg-blue-600 text-white px-6 py-3 rounded-lg hover:bg-blue-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
            disabled={currentUser?.role !== 'super_admin' && !currentUser?.permissions?.manage_admins}
            title={currentUser?.role !== 'super_admin' && !currentUser?.permissions?.manage_admins ? 'Vous n\'avez pas la permission de créer des administrateurs' : ''}
          >
            <Plus className="w-5 h-5" />
            <span>Créer un admin</span>
          </button>
        </div>
      </div>

      {/* Zone scrollable avec le tableau */}
      <div className="flex-1 overflow-auto px-6 pb-6">
        <div className="bg-white rounded-xl shadow-sm">
          <table className="w-full">
            <thead className="bg-gray-50 border-b-2 border-gray-200 sticky top-0 z-20 shadow-sm">
              <tr>
                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase bg-gray-50">Admin</th>
                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase bg-gray-50">Email</th>
                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase bg-gray-50">Permissions</th>
                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase bg-gray-50">Statut</th>
                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase bg-gray-50">Date création</th>
                <th className="px-6 py-4 text-right text-xs font-semibold text-gray-600 uppercase">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200 bg-white">
              {currentAdmins.map((admin) => (
                <tr key={admin.id} className="hover:bg-gray-50">
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 rounded-full bg-blue-100 flex items-center justify-center">
                        <Shield className="w-5 h-5 text-blue-600" />
                      </div>
                      <div>
                        <div className="flex items-center gap-2">
                          <span className="font-medium text-gray-900">
                            {admin.nom} {admin.prenom}
                          </span>
                          {admin.role === 'super_admin' && (
                            <span className="inline-flex items-center px-2 py-0.5 rounded text-xs font-semibold bg-purple-100 text-purple-800">
                              Super Admin
                            </span>
                          )}
                        </div>
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <span className="text-sm text-gray-600">{admin.email}</span>
                  </td>
                  <td className="px-6 py-4">
                    <button
                      onClick={() => openPermissionsModal(admin)}
                      className="text-sm text-blue-600 hover:text-blue-800 flex items-center gap-1"
                      disabled={admin.role === 'super_admin' && currentUser?.role !== 'super_admin'}
                      title={admin.role === 'super_admin' && currentUser?.role !== 'super_admin' ? 'Seul un super admin peut modifier les permissions d\'un super admin' : ''}
                    >
                      <Lock className="w-4 h-4" />
                      Gérer
                    </button>
                  </td>
                  <td className="px-6 py-4">
                    {admin.is_active ? (
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
                      {format(new Date(admin.created_at), 'dd MMM yyyy', { locale: fr })}
                    </span>
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex items-center justify-end gap-2">
                      <button
                        onClick={() => toggleAdminStatus(admin.id, admin.is_active)}
                        className="p-2 hover:bg-gray-100 rounded-lg transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                        title={admin.is_active ? 'Désactiver' : 'Activer'}
                        disabled={
                          (admin.role === 'super_admin' && currentUser?.role !== 'super_admin') ||
                          (currentUser?.role !== 'super_admin' && !currentUser?.permissions?.manage_admins)
                        }
                      >
                        {admin.is_active ? (
                          <EyeOff className="w-4 h-4 text-gray-600" />
                        ) : (
                          <Eye className="w-4 h-4 text-gray-600" />
                        )}
                      </button>
                      <button
                        onClick={() => deleteAdmin(admin.id)}
                        className="p-2 hover:bg-red-50 rounded-lg transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                        title="Supprimer"
                        disabled={
                          admin.id === currentUser?.id ||
                          (admin.role === 'super_admin' && currentUser?.role !== 'super_admin') ||
                          (currentUser?.role !== 'super_admin' && !currentUser?.permissions?.manage_admins)
                        }
                      >
                        <Trash2 className="w-4 h-4 text-red-600" />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>

          {/* Pagination améliorée */}
          {admins.length > 0 && (
            <div className="border-t border-gray-200 bg-gradient-to-r from-gray-50 to-white">
              <div className="flex items-center justify-between px-6 py-4">
                <div className="flex items-center gap-6">
                  <div className="flex items-center gap-2">
                    <div className="text-sm text-gray-700 font-medium">
                      <span className="text-blue-600">{startIndex + 1}-{Math.min(endIndex, admins.length)}</span>
                      <span className="text-gray-500"> sur </span>
                      <span className="text-blue-600">{admins.length}</span>
                      <span className="text-gray-500"> admin(s)</span>
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

      {/* Modal Créer Admin */}
      {showCreateModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-xl max-w-2xl w-full max-h-[90vh] overflow-y-auto">
            <div className="p-6 border-b border-gray-200 flex items-center justify-between">
              <h2 className="text-2xl font-bold text-gray-900">Créer un administrateur</h2>
              <button
                onClick={() => setShowCreateModal(false)}
                className="p-2 text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                title="Fermer"
              >
                <X className="w-6 h-6" />
              </button>
            </div>
            <form onSubmit={createAdmin} className="p-6 space-y-6">
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
                <p className="text-xs text-gray-500 mt-1">Minimum 8 caractères</p>
              </div>

              {/* Permissions */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-3">Permissions</label>
                <div className="space-y-2 bg-gray-50 p-4 rounded-lg">
                  {Object.entries(formData.permissions).map(([key, value]) => (
                    <label key={key} className="flex items-center gap-3 cursor-pointer">
                      <input
                        type="checkbox"
                        checked={value}
                        onChange={(e) =>
                          setFormData({
                            ...formData,
                            permissions: { ...formData.permissions, [key]: e.target.checked },
                          })
                        }
                        className="w-4 h-4 text-blue-600 rounded"
                      />
                      <span className="text-sm text-gray-700">{getPermissionLabel(key)}</span>
                    </label>
                  ))}
                </div>
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
                  Créer l'admin
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Modal Permissions */}
      {showPermissionsModal && selectedAdmin && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-xl max-w-lg w-full">
            <div className="p-6 border-b border-gray-200 flex items-center justify-between">
              <h2 className="text-2xl font-bold text-gray-900">
                Permissions - {selectedAdmin.nom} {selectedAdmin.prenom}
              </h2>
              <button
                onClick={() => setShowPermissionsModal(false)}
                className="p-2 text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                title="Fermer"
              >
                <X className="w-6 h-6" />
              </button>
            </div>
            <div className="p-6">
              <div className="space-y-2 bg-gray-50 p-4 rounded-lg">
                {Object.entries(formData.permissions).map(([key, value]) => (
                  <label key={key} className="flex items-center gap-3 cursor-pointer">
                    <input
                      type="checkbox"
                      checked={value}
                      onChange={(e) =>
                        setFormData({
                          ...formData,
                          permissions: { ...formData.permissions, [key]: e.target.checked },
                        })
                      }
                      className="w-4 h-4 text-blue-600 rounded"
                    />
                    <span className="text-sm text-gray-700">{getPermissionLabel(key)}</span>
                  </label>
                ))}
              </div>

              <div className="flex gap-3 mt-6">
                <button
                  onClick={() => setShowPermissionsModal(false)}
                  className="flex-1 px-6 py-3 border border-gray-300 rounded-lg hover:bg-gray-50"
                >
                  Annuler
                </button>
                <button
                  onClick={updatePermissions}
                  className="flex-1 px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
                >
                  Enregistrer
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

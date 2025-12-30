import {
    Activity,
    BarChart3,
    Bell,
    ChevronLeft,
    ChevronRight,
    FileText,
    LayoutDashboard,
    LogOut,
    Search,
    Settings,
    UserCog,
    UserPlus,
    Users,
} from 'lucide-react';
import { useState } from 'react';
import { NavLink, Outlet, useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';

export const DashboardLayout = () => {
  const { signOut, user } = useAuth();
  const navigate = useNavigate();
  const [isSidebarOpen, setIsSidebarOpen] = useState(true);

  const handleSignOut = async () => {
    try {
      await signOut();
      navigate('/login');
    } catch (error) {
      console.error('Error signing out:', error);
    }
  };

  const navItems = [
    { to: '/dashboard', icon: LayoutDashboard, label: 'Tableau de bord', end: true, permission: null }, // Toujours visible
    { to: '/dashboard/users', icon: Users, label: 'Utilisateurs', permission: 'view_users' },
    { to: '/dashboard/signalements', icon: FileText, label: 'Signalements', permission: 'view_signalements' },
    { to: '/dashboard/logs', icon: Activity, label: "Journal d'activité", permission: 'view_logs' },
    { to: '/dashboard/admins', icon: UserCog, label: 'Gestion Admins', permission: 'manage_admins' },
    { to: '/dashboard/audit', icon: Search, label: 'Audit Système', permission: 'view_logs' },
    { to: '/dashboard/create-authority', icon: UserPlus, label: 'Créer opérateur', permission: 'manage_authorities' },
    { to: '/dashboard/notifications', icon: Bell, label: 'Notifications', permission: null }, // Toujours visible
    { to: '/dashboard/statistics', icon: BarChart3, label: 'Statistiques', permission: 'view_statistics' },
  ];

  // Filtrer les items selon les permissions
  const visibleNavItems = navItems.filter(item => {
    // Si pas de permission requise, toujours visible
    if (!item.permission) return true;
    
    // Super admin voit tout
    if (user?.role === 'super_admin') return true;
    
    // Vérifier la permission spécifique
    return user?.permissions?.[item.permission] === true;
  });

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Sidebar */}
      <aside className={`fixed left-0 top-0 h-full bg-white border-r border-gray-200 shadow-sm flex flex-col transition-all duration-300 ${
        isSidebarOpen ? 'w-64' : 'w-0'
      }`}>
        <div className={`${isSidebarOpen ? 'block' : 'hidden'}`}>
          <div className="p-6 border-b border-gray-200">
            <h1 className="text-2xl font-bold text-blue-600">TOKSE Admin</h1>
            <p className="text-sm text-gray-600 mt-1">Panneau d'administration</p>
          </div>

          <nav className="flex-1 p-4 space-y-1 overflow-y-auto" style={{ maxHeight: 'calc(100vh - 280px)' }}>
          {visibleNavItems.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              end={item.end}
              className={({ isActive }) =>
                `flex items-center gap-3 px-4 py-3 rounded-lg transition-colors ${
                  isActive
                    ? 'bg-blue-50 text-blue-600 font-semibold'
                    : 'text-gray-700 hover:bg-gray-50'
                }`
              }
            >
              <item.icon className="w-5 h-5" />
              <span>{item.label}</span>
            </NavLink>
          ))}
        </nav>

        <div className="p-4 border-t border-gray-200 bg-white">
          <div className="flex items-center gap-3 mb-3 px-4">
            <div className="w-10 h-10 bg-blue-600 rounded-full flex items-center justify-center flex-shrink-0">
              <span className="text-white font-semibold">
                {user?.email?.charAt(0).toUpperCase()}
              </span>
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-sm font-medium text-gray-900 truncate">{user?.email}</p>
              <p className="text-xs text-gray-500">Administrateur</p>
            </div>
          </div>
          
          <NavLink
            to="/dashboard/profile"
            className={({ isActive }) =>
              `flex items-center gap-3 px-4 py-3 rounded-lg transition-colors ${
                isActive
                  ? 'bg-blue-50 text-blue-600'
                  : 'text-gray-700 hover:bg-gray-50'
              }`
            }
          >
            <Settings className="w-5 h-5" />
            <span>Mon profil</span>
          </NavLink>

          <button
            onClick={handleSignOut}
            className="w-full flex items-center gap-3 px-4 py-3 text-red-600 hover:bg-red-50 rounded-lg transition-colors"
          >
            <LogOut className="w-5 h-5" />
            <span>Déconnexion</span>
          </button>
        </div>
        </div>
      </aside>

      {/* Toggle Button */}
      <button
        onClick={() => setIsSidebarOpen(!isSidebarOpen)}
        className="fixed top-4 bg-white border border-gray-300 p-2 rounded-full shadow-lg hover:bg-gray-50 transition-all duration-300 z-50"
        style={{ left: isSidebarOpen ? '256px' : '16px' }}
      >
        {isSidebarOpen ? (
          <ChevronLeft className="w-5 h-5 text-gray-700" />
        ) : (
          <ChevronRight className="w-5 h-5 text-gray-700" />
        )}
      </button>

      {/* Main content */}
      <main className={`p-8 transition-all duration-300 ${isSidebarOpen ? 'ml-64' : 'ml-0'}`}>
        <Outlet />
      </main>
    </div>
  );
};

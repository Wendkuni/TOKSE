import {
  Activity,
  BarChart3,
  ChevronLeft,
  ChevronRight,
  FileText,
  LayoutDashboard,
  LogOut,
  MapPin,
  Settings,
  TrendingUp,
  Users,
} from 'lucide-react';
import { useState } from 'react';
import { NavLink, Outlet, useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';

export const AutoriteDashboardLayout = () => {
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
    { to: '/autorite', icon: LayoutDashboard, label: 'Tableau de bord', end: true },
    { to: '/autorite/signalements', icon: FileText, label: 'Signalements' },
    { to: '/autorite/localisation', icon: MapPin, label: 'Localisation' },
    { to: '/autorite/rapports', icon: TrendingUp, label: 'Rapports' },
    { to: '/autorite/statistiques', icon: BarChart3, label: 'Statistiques' },
  ];

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Sidebar */}
      <aside className={`fixed left-0 top-0 h-full bg-white border-r border-gray-200 shadow-sm flex flex-col transition-all duration-300 ${
        isSidebarOpen ? 'w-64' : 'w-0'
      }`}>
        <div className={`flex flex-col h-full ${isSidebarOpen ? 'block' : 'hidden'}`}>
          <div className="p-6 border-b border-gray-200">
            <h1 className="text-2xl font-bold text-purple-600">TOKSE Opérateur</h1>
            <p className="text-sm text-gray-600 mt-1">Panneau de gestion</p>
          </div>

          <nav className="flex-1 p-4 space-y-1 overflow-y-auto">
          {navItems.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              end={item.end}
              className={({ isActive }) =>
                `flex items-center gap-3 px-4 py-3 rounded-lg transition-colors ${
                  isActive
                    ? 'bg-purple-50 text-purple-600 font-semibold'
                    : 'text-gray-700 hover:bg-gray-50'
                }`
              }
            >
              <item.icon className="w-5 h-5" />
              <span>{item.label}</span>
            </NavLink>
          ))}
        </nav>

        <div className="p-4 border-t border-gray-200">
          <div className="flex items-center gap-3 mb-3 px-4">
            <div className="w-10 h-10 bg-purple-600 rounded-full flex items-center justify-center">
              <span className="text-white font-semibold">
                {user?.nom?.charAt(0).toUpperCase() || 'A'}
              </span>
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-sm font-medium text-gray-900 truncate">
                {user?.nom} {user?.prenom}
              </p>
              <p className="text-xs text-gray-500 capitalize">{user?.autorite_type || 'Opérateur'}</p>
            </div>
          </div>
          
          <NavLink
            to="/autorite/profil"
            className={({ isActive }) =>
              `flex items-center gap-3 px-4 py-3 rounded-lg transition-colors ${
                isActive
                  ? 'bg-purple-50 text-purple-600'
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

import { Activity, BarChart3, FileText, Home, LogOut, Map, User } from 'lucide-react';
import { Link, Outlet, useLocation, useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';

export const AgentLayout = () => {
  const { user, signOut } = useAuth();
  const location = useLocation();
  const navigate = useNavigate();

  const handleLogout = async () => {
    await signOut();
    navigate('/login');
  };

  const navigation = [
    { name: 'Tableau de bord', path: '/agent/dashboard', icon: Home },
    { name: 'Carte analytique', path: '/agent/map', icon: Map },
    { name: 'Rapports', path: '/agent/reports', icon: FileText },
    { name: 'Performance', path: '/agent/performance', icon: BarChart3 },
    { name: 'Mon profil', path: '/agent/profile', icon: User },
  ];

  const isActive = (path) => location.pathname === path;

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Sidebar */}
      <div className="fixed inset-y-0 left-0 w-64 bg-gradient-to-b from-purple-700 to-purple-900 text-white">
        <div className="p-6">
          <h1 className="text-2xl font-bold">TOKSE Agent</h1>
          <p className="text-sm text-purple-200 mt-1">Portail Analytique</p>
        </div>

        {/* User Info */}
        <div className="px-6 py-4 bg-purple-800/50">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-purple-500 rounded-full flex items-center justify-center">
              <User className="w-6 h-6" />
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-sm font-semibold truncate">
                {user?.prenom} {user?.nom}
              </p>
              <p className="text-xs text-purple-200">Agent de terrain</p>
            </div>
          </div>
        </div>

        {/* Navigation */}
        <nav className="mt-6 px-3">
          {navigation.map((item) => {
            const Icon = item.icon;
            return (
              <Link
                key={item.path}
                to={item.path}
                className={`flex items-center gap-3 px-4 py-3 rounded-lg mb-1 transition-colors ${
                  isActive(item.path)
                    ? 'bg-purple-600 text-white'
                    : 'text-purple-100 hover:bg-purple-800/50'
                }`}
              >
                <Icon className="w-5 h-5" />
                <span className="font-medium">{item.name}</span>
              </Link>
            );
          })}
        </nav>

        {/* Logout Button */}
        <div className="absolute bottom-0 left-0 right-0 p-4">
          <button
            onClick={handleLogout}
            className="w-full flex items-center gap-3 px-4 py-3 rounded-lg bg-red-600 hover:bg-red-700 transition-colors"
          >
            <LogOut className="w-5 h-5" />
            <span className="font-medium">Déconnexion</span>
          </button>
        </div>
      </div>

      {/* Main Content */}
      <div className="ml-64 p-8">
        <Outlet />
      </div>
    </div>
  );
};

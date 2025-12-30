import { AlertCircle, BarChart3, Eye, EyeOff, Lock, Mail, MapPin, Shield, Users } from 'lucide-react';
import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';

export const LoginPage = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const { signIn } = useAuth();
  const navigate = useNavigate();

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      await signIn(email, password);
      
      // Récupérer le rôle depuis localStorage (défini dans signIn)
      const role = localStorage.getItem('admin_role');
      
      // Rediriger selon le rôle
      if (role === 'admin' || role === 'super_admin') {
        navigate('/dashboard');
      } else if (role === 'autorite') {
        navigate('/autorite');
      } else if (role === 'agent') {
        navigate('/agent/dashboard');
      } else {
        throw new Error('Rôle non reconnu');
      }
    } catch (err) {
      setError(err.message || 'Erreur de connexion. Vérifiez vos identifiants.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex">
      {/* Left Side - Branding */}
      <div className="hidden lg:flex lg:w-1/2 bg-gradient-to-br from-blue-600 via-blue-700 to-blue-900 p-12 flex-col justify-between relative overflow-hidden">
        {/* Background Pattern */}
        <div className="absolute inset-0 opacity-10">
          <div className="absolute top-0 left-0 w-96 h-96 bg-white rounded-full -translate-x-1/2 -translate-y-1/2"></div>
          <div className="absolute bottom-0 right-0 w-96 h-96 bg-white rounded-full translate-x-1/2 translate-y-1/2"></div>
        </div>

        {/* Logo & Title */}
        <div className="relative z-10">
          <div className="flex items-center gap-6 mb-8">
            <img 
              src="/tokse_logo.png" 
              alt="TOKSE Logo" 
              className="w-32 h-32 object-contain drop-shadow-2xl"
            />
            <div>
              <h1 className="text-6xl font-bold text-white mb-2">TOKSE</h1>
              <p className="text-blue-200 text-xl">Espace Administrateurs & Opérateurs</p>
            </div>
          </div>
          
          <div className="mt-12 space-y-4">
            <h2 className="text-3xl font-bold text-white mb-6">
              Plateforme de Gestion Utilisateurs
            </h2>
            <p className="text-blue-100 text-lg leading-relaxed">
              Connectez-vous en tant qu'administrateur système ou opérateur 
              pour gérer les signalements, coordonner les équipes et améliorer la qualité de vie.
            </p>
          </div>
        </div>

        {/* Features */}
        <div className="relative z-10 grid grid-cols-2 gap-6">
          <div className="bg-white/10 backdrop-blur-lg rounded-xl p-6 border border-white/20">
            <MapPin className="w-8 h-8 text-white mb-3" />
            <h3 className="text-white font-semibold text-lg mb-2">Carte Interactive</h3>
            <p className="text-blue-100 text-sm">Visualisez tous les signalements en temps réel</p>
          </div>
          
          <div className="bg-white/10 backdrop-blur-lg rounded-xl p-6 border border-white/20">
            <Shield className="w-8 h-8 text-white mb-3" />
            <h3 className="text-white font-semibold text-lg mb-2">Gestion Opérateurs</h3>
            <p className="text-blue-100 text-sm">Créez et gérez les comptes d'opérateurs</p>
          </div>
          
          <div className="bg-white/10 backdrop-blur-lg rounded-xl p-6 border border-white/20">
            <BarChart3 className="w-8 h-8 text-white mb-3" />
            <h3 className="text-white font-semibold text-lg mb-2">Statistiques</h3>
            <p className="text-blue-100 text-sm">Analyses détaillées et KPIs de performance</p>
          </div>
          
          <div className="bg-white/10 backdrop-blur-lg rounded-xl p-6 border border-white/20">
            <Users className="w-8 h-8 text-white mb-3" />
            <h3 className="text-white font-semibold text-lg mb-2">Utilisateurs</h3>
            <p className="text-blue-100 text-sm">Gestion complète des utilisateurs et opérateurs</p>
          </div>
        </div>

        {/* Footer */}
        <div className="relative z-10 text-blue-200 text-sm text-center mt-12">
          <p>© 2025 TOKSE - Crafted And Developed By <span className="text-white font-semibold">AMIR TECH</span></p>
        </div>
      </div>

      {/* Right Side - Login Form */}
      <div className="flex-1 flex items-center justify-center p-8 bg-gray-50">
        <div className="w-full max-w-md">
          {/* Mobile Logo */}
          <div className="lg:hidden text-center mb-8">
            <div className="inline-flex items-center gap-4 mb-4">
              <img 
                src="/tokse_logo.png" 
                alt="TOKSE Logo" 
                className="w-20 h-20 object-contain"
              />
              <div className="text-left">
                <h1 className="text-3xl font-bold text-gray-900">TOKSE</h1>
                <p className="text-gray-600 text-sm">Espace Administrateurs & Opérateurs</p>
              </div>
            </div>
          </div>

          <div className="bg-white p-8 rounded-2xl shadow-xl border border-gray-200">
            <div className="mb-8">
              <h2 className="text-2xl font-bold text-gray-900 mb-2">Connexion</h2>
              <p className="text-gray-600">Administrateurs & Opérateurs - Accédez au panneau de contrôle</p>
            </div>

            {error && (
              <div className="mb-6 p-4 bg-red-50 border border-red-200 rounded-lg flex items-start gap-3">
                <AlertCircle className="w-5 h-5 text-red-600 flex-shrink-0 mt-0.5" />
                <p className="text-red-700 text-sm">{error}</p>
              </div>
            )}

            <form onSubmit={handleSubmit} className="space-y-5">
              <div>
                <label htmlFor="email" className="block text-sm font-semibold text-gray-700 mb-2">
                  Adresse email
                </label>
                <div className="relative">
                  <Mail className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
                  <input
                    id="email"
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    className="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors"
                    placeholder="votre-email@tokse.com"
                    required
                  />
                </div>
              </div>

              <div>
                <label htmlFor="password" className="block text-sm font-semibold text-gray-700 mb-2">
                  Mot de passe
                </label>
                <div className="relative">
                  <Lock className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
                  <input
                    id="password"
                    type={showPassword ? "text" : "password"}
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    className="w-full pl-10 pr-10 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors"
                    placeholder="••••••••"
                    required
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword((v) => !v)}
                    className="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-400 hover:text-gray-700 focus:outline-none"
                    tabIndex={-1}
                  >
                    {showPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
                  </button>
                </div>
              </div>

              <button
                type="submit"
                disabled={loading}
                className="w-full bg-blue-600 text-white py-3.5 rounded-lg font-semibold hover:bg-blue-700 focus:ring-4 focus:ring-blue-300 transition-all disabled:opacity-50 disabled:cursor-not-allowed shadow-lg hover:shadow-xl"
              >
                {loading ? (
                  <span className="flex items-center justify-center gap-2">
                    <svg className="animate-spin h-5 w-5" viewBox="0 0 24 24">
                      <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none" />
                      <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                    </svg>
                    Connexion en cours...
                  </span>
                ) : (
                  'Se connecter'
                )}
              </button>
            </form>

            <div className="mt-6 text-center">
              <p className="text-sm text-gray-500">
                Accès réservé aux administrateurs et opérateurs locaux
              </p>
            </div>
          </div>

          {/* Mobile Features */}
          <div className="lg:hidden mt-8 grid grid-cols-2 gap-4">
            <div className="bg-white p-4 rounded-xl shadow border border-gray-200">
              <MapPin className="w-6 h-6 text-blue-600 mb-2" />
              <h3 className="font-semibold text-sm text-gray-900">Carte</h3>
              <p className="text-xs text-gray-600">Signalements temps réel</p>
            </div>
            
            <div className="bg-white p-4 rounded-xl shadow border border-gray-200">
              <Shield className="w-6 h-6 text-blue-600 mb-2" />
              <h3 className="font-semibold text-sm text-gray-900">Opérateurs</h3>
              <p className="text-xs text-gray-600">Gestion des comptes</p>
            </div>
            
            <div className="bg-white p-4 rounded-xl shadow border border-gray-200">
              <BarChart3 className="w-6 h-6 text-blue-600 mb-2" />
              <h3 className="font-semibold text-sm text-gray-900">Stats</h3>
              <p className="text-xs text-gray-600">Analyses & KPIs</p>
            </div>
            
            <div className="bg-white p-4 rounded-xl shadow border border-gray-200">
              <Users className="w-6 h-6 text-blue-600 mb-2" />
              <h3 className="font-semibold text-sm text-gray-900">Utilisateurs</h3>
              <p className="text-xs text-gray-600">Gestion complète</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

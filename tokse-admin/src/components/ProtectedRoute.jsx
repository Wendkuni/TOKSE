import { Navigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';

export const ProtectedRoute = ({ children, requiredRole }) => {
  const { user, userRole, loading } = useAuth();

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  if (!user) {
    return <Navigate to="/login" replace />;
  }

  // Vérifier le rôle requis
  if (requiredRole) {
    // Si on demande 'admin', accepter aussi 'super_admin'
    const isAuthorized = 
      userRole === requiredRole || 
      (requiredRole === 'admin' && userRole === 'super_admin');
    
    if (!isAuthorized) {
      // Rediriger vers l'interface appropriée
      if (userRole === 'admin' || userRole === 'super_admin') {
        return <Navigate to="/dashboard" replace />;
      } else if (userRole === 'autorite') {
        return <Navigate to="/autorite" replace />;
      } else if (userRole === 'agent') {
        return <Navigate to="/agent/dashboard" replace />;
      }
      return <Navigate to="/login" replace />;
    }
  }

  return children;
};

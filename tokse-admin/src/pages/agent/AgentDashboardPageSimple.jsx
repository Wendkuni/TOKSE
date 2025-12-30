import { useAuth } from '../../contexts/AuthContext';

export const AgentDashboardPageSimple = () => {
  const { user } = useAuth();

  return (
    <div className="p-8">
      <h1 className="text-3xl font-bold text-gray-900 mb-4">Dashboard Agent - Test</h1>
      <div className="bg-white rounded-lg shadow p-6">
        <p className="text-lg mb-2">Bienvenue, {user?.prenom} {user?.nom}!</p>
        <p className="text-gray-600">Email: {user?.email}</p>
        <p className="text-gray-600">ID: {user?.id}</p>
        <p className="text-gray-600">Rôle: {user?.role}</p>
        
        <div className="mt-6 p-4 bg-green-50 border border-green-200 rounded">
          <p className="text-green-800 font-medium">✓ Le dashboard agent s'affiche correctement!</p>
        </div>
      </div>
    </div>
  );
};

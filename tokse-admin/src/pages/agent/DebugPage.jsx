import { useEffect, useState } from 'react';
import { useAuth } from '../../contexts/AuthContext';
import { supabase } from '../../lib/supabase';

export const DebugPage = () => {
  const { user, userRole, isAdmin } = useAuth();
  const [dbUser, setDbUser] = useState(null);
  const [signalements, setSignalements] = useState([]);
  const [error, setError] = useState(null);

  useEffect(() => {
    const fetchDebugInfo = async () => {
      try {
        // Récupérer les infos de l'utilisateur depuis la BDD
        const { data: userData, error: userError } = await supabase
          .from('users')
          .select('*')
          .eq('id', user?.id)
          .single();

        if (userError) throw userError;
        setDbUser(userData);

        // Récupérer les signalements assignés
        const { data: sigData, error: sigError } = await supabase
          .from('signalements')
          .select('*')
          .eq('assigned_to', user?.id);

        if (sigError) throw sigError;
        setSignalements(sigData || []);
      } catch (err) {
        setError(err.message);
      }
    };

    if (user?.id) {
      fetchDebugInfo();
    }
  }, [user]);

  return (
    <div className="p-8">
      <h1 className="text-3xl font-bold mb-6">Page de Debug</h1>

      {/* Auth Context Info */}
      <div className="bg-white rounded-lg shadow p-6 mb-6">
        <h2 className="text-xl font-bold mb-4 text-blue-600">Auth Context</h2>
        <div className="space-y-2 font-mono text-sm">
          <p><strong>User ID:</strong> {user?.id || 'null'}</p>
          <p><strong>Email:</strong> {user?.email || 'null'}</p>
          <p><strong>User Role (context):</strong> {userRole || 'null'}</p>
          <p><strong>Is Admin:</strong> {isAdmin ? 'true' : 'false'}</p>
          <p><strong>LocalStorage Role:</strong> {localStorage.getItem('admin_role') || 'null'}</p>
        </div>
      </div>

      {/* Database User Info */}
      <div className="bg-white rounded-lg shadow p-6 mb-6">
        <h2 className="text-xl font-bold mb-4 text-green-600">Database User</h2>
        {dbUser ? (
          <div className="space-y-2 font-mono text-sm">
            <p><strong>ID:</strong> {dbUser.id}</p>
            <p><strong>Email:</strong> {dbUser.email}</p>
            <p><strong>Nom:</strong> {dbUser.nom}</p>
            <p><strong>Prénom:</strong> {dbUser.prenom}</p>
            <p><strong>Role:</strong> <span className="bg-yellow-100 px-2 py-1 rounded">{dbUser.role}</span></p>
            <p><strong>Téléphone:</strong> {dbUser.telephone}</p>
            <p><strong>Commune:</strong> {dbUser.commune}</p>
            <p><strong>Created At:</strong> {dbUser.created_at}</p>
          </div>
        ) : (
          <p className="text-cyan-400 font-mono tracking-wider">CHARGEMENT...</p>
        )}
      </div>

      {/* Signalements Assignés */}
      <div className="bg-white rounded-lg shadow p-6 mb-6">
        <h2 className="text-xl font-bold mb-4 text-purple-600">
          Signalements Assignés ({signalements.length})
        </h2>
        {signalements.length > 0 ? (
          <div className="space-y-4">
            {signalements.map((sig) => (
              <div key={sig.id} className="border-l-4 border-purple-500 pl-4 py-2">
                <p><strong>ID:</strong> {sig.id}</p>
                <p><strong>Titre:</strong> {sig.titre}</p>
                <p><strong>État:</strong> <span className="bg-blue-100 px-2 py-1 rounded">{sig.etat}</span></p>
                <p><strong>Type:</strong> {sig.type}</p>
                <p><strong>Commune:</strong> {sig.commune}</p>
                <p><strong>Created:</strong> {new Date(sig.created_at).toLocaleString()}</p>
              </div>
            ))}
          </div>
        ) : (
          <p className="text-gray-500">Aucun signalement assigné à cet agent</p>
        )}
      </div>

      {/* Errors */}
      {error && (
        <div className="bg-red-50 border border-red-200 rounded-lg p-6">
          <h2 className="text-xl font-bold mb-2 text-red-600">Erreur</h2>
          <p className="text-red-700">{error}</p>
        </div>
      )}
    </div>
  );
};

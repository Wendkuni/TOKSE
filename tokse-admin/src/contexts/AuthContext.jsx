import { createContext, useContext, useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';

const AuthContext = createContext({});

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const [isAdmin, setIsAdmin] = useState(false);
  const [userRole, setUserRole] = useState(null); // 'admin', 'autorite' ou 'agent'

  useEffect(() => {
    // Chargement instantané depuis le cache
    const cachedUser = localStorage.getItem('admin_user');
    const cachedRole = localStorage.getItem('admin_role');
    
    if (cachedUser && cachedRole) {
      try {
        const parsedUser = JSON.parse(cachedUser);
        setUser(parsedUser);
        setUserRole(cachedRole);
        setIsAdmin(cachedRole === 'admin' || cachedRole === 'super_admin');
        setLoading(false);
      } catch (error) {
        console.error('Erreur parsing cache:', error);
      }
    }

    // Vérification session en parallèle (ne bloque pas l'UI)
    supabase.auth.getSession().then(({ data: { session } }) => {
      if (session?.user) {
        setUser(session.user);
        localStorage.setItem('admin_user', JSON.stringify(session.user));
        
        // Si pas de cache, vérifier le rôle
        if (!cachedRole) {
          checkUserRole(session.user);
        } else {
          // Vérification silencieuse en background
          checkUserRole(session.user, true);
        }
      } else {
        if (!cachedUser) {
          setLoading(false);
        }
        localStorage.removeItem('admin_user');
        localStorage.removeItem('admin_role');
      }
    });

    // Listen for auth changes
    const { data: { subscription } } = supabase.auth.onAuthStateChange((event, session) => {
      if (event === 'SIGNED_OUT') {
        setUser(null);
        setIsAdmin(false);
        setUserRole(null);
        setLoading(false);
        localStorage.removeItem('admin_role');
        localStorage.removeItem('admin_user');
      } else if (event === 'SIGNED_IN' && session?.user) {
        setUser(session.user);
        localStorage.setItem('admin_user', JSON.stringify(session.user));
        checkUserRole(session.user);
      }
    });

    return () => subscription.unsubscribe();
  }, []);

  const checkUserRole = async (user, skipLoadingUpdate = false) => {
    if (!user) {
      setIsAdmin(false);
      setUserRole(null);
      setLoading(false);
      return;
    }

    try {
      const { data, error } = await supabase
        .from('users')
        .select('role, autorite_type, nom, prenom')
        .eq('id', user.id)
        .single();

      if (error) throw error;
      
      const role = data?.role;
      // Autoriser admin, super_admin, autorites ET agents
      const isCitizen = role === 'citizen' || role === 'citoyen';
      const isValidUser = !isCitizen;
      
      // Normaliser le rôle pour la navigation (admin, super_admin, autorite ou agent)
      let normalizedRole;
      if (role === 'admin' || role === 'super_admin') {
        normalizedRole = role; // Conserver super_admin tel quel
      } else if (role === 'agent') {
        normalizedRole = 'agent';
      } else {
        normalizedRole = 'autorite';
      }
      
      setUserRole(normalizedRole);
      setIsAdmin(role === 'admin' || role === 'super_admin');
      setUser({ ...user, ...data });
      
      // Mettre en cache le rôle pour un chargement instantané
      if (isValidUser) {
        localStorage.setItem('admin_role', normalizedRole);
        localStorage.setItem('admin_user', JSON.stringify({ ...user, ...data }));
      } else {
        localStorage.removeItem('admin_role');
        localStorage.removeItem('admin_user');
      }
    } catch (error) {
      console.error('Error checking user role:', error);
      setIsAdmin(false);
      setUserRole(null);
      localStorage.removeItem('admin_role');
      localStorage.removeItem('admin_user');
    } finally {
      if (!skipLoadingUpdate) {
        setLoading(false);
      }
    }
  };

  const signIn = async (email, password) => {
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });

    if (error) throw error;

    // Check if user is admin or autorite
    const { data: userData, error: userError } = await supabase
      .from('users')
      .select('role, autorite_type, nom, prenom, permissions')
      .eq('id', data.user.id)
      .single();

    if (userError) throw userError;

    // Autoriser admin, super_admin, autorités ET agents
    const role = userData.role;
    const isAdmin = role === 'admin' || role === 'super_admin';
    const isCitizen = role === 'citizen' || role === 'citoyen';
    
    // Refuser uniquement les citoyens
    const isAllowedRole = !isCitizen;
    
    if (!isAllowedRole) {
      await supabase.auth.signOut();
      throw new Error('Accès refusé. Seuls les administrateurs, autorités et agents peuvent se connecter.');
    }

    // Définir l'état utilisateur et mettre en cache
    const fullUser = { ...data.user, ...userData };
    setIsAdmin(userData.role === 'admin' || userData.role === 'super_admin');
    
    // Normaliser le rôle
    let normalizedRole;
    if (userData.role === 'admin' || userData.role === 'super_admin') {
      normalizedRole = userData.role; // Conserver 'super_admin' tel quel
    } else if (userData.role === 'agent') {
      normalizedRole = 'agent';
    } else {
      normalizedRole = 'autorite';
    }
    
    setUserRole(normalizedRole);
    setUser(fullUser);
    localStorage.setItem('admin_role', normalizedRole);
    localStorage.setItem('admin_user', JSON.stringify(fullUser));

    return data;
  };

  const signOut = async () => {
    const { error } = await supabase.auth.signOut();
    if (error) throw error;
    setUser(null);
    setIsAdmin(false);
    setUserRole(null);
    localStorage.removeItem('admin_role');
    localStorage.removeItem('admin_user');
  };

  const value = {
    user,
    userRole, // 'admin', 'autorite' ou 'agent'
    isAdmin,
    loading,
    signIn,
    signOut,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};

import { supabase } from './supabase';

// ============= INSCRIPTION AVEC OTP =============

export async function signUpWithPhone(phone: string, nom: string, prenom: string) {
  try {
    console.log('Début inscription:', { phone, nom, prenom });

    // Envoyer OTP par SMS au numéro de téléphone
    const { error } = await supabase.auth.signInWithOtp({
      phone: phone,
      options: {
        shouldCreateUser: true,
      }
    });

    if (error) {
      console.error('Erreur envoi OTP:', error);
      throw error;
    }

    console.log('OTP envoyé par SMS à:', phone);
    return {
      success: true,
      message: `Un code OTP a été envoyé par SMS à ${phone}.`,
      phone,
      nom,
      prenom,
    };
  } catch (error) {
    console.error('Erreur signUpWithPhone:', error);
    throw error;
  }
}

export async function verifyOtp(phone: string, token: string, nom: string, prenom: string) {
  try {
    console.log('Vérification OTP:', { phone, token });

    // Vérifier le OTP reçu par SMS
    const { data, error } = await supabase.auth.verifyOtp({
      phone: phone,
      token: token,
      type: 'sms',
    });

    if (error) {
      console.error('Erreur vérification OTP:', error);
      throw error;
    }

    if (data.user) {
      console.log('OTP vérifié, utilisateur:', data.user.id);

      // Créer ou mettre à jour l'entrée dans la table users
      await upsertUser(data.user.id, phone, nom, prenom);

      // Sauvegarder l'ID utilisateur dans AsyncStorage
      if (typeof window !== 'undefined') {
        const AsyncStorage = await import('@react-native-async-storage/async-storage').then(m => m.default);
        await AsyncStorage.setItem('tokse_user_id', data.user.id);
        console.log('ID utilisateur sauvegardé dans AsyncStorage après inscription');
      }

      return {
        success: true,
        user: data.user,
      };
    }

    throw new Error('Impossible de vérifier le OTP');
  } catch (error) {
    console.error('Erreur verifyOtp:', error);
    throw error;
  }
}

// ============= CONNEXION AVEC NUMÉRO (Simple - Sans OTP) - CITOYENS =============

export async function signInWithPhone(phone: string) {
  try {
    console.log('Connexion directe avec téléphone:', phone);

    // Vérifier si l'utilisateur existe dans la table users avec role 'citizen'
    const { data: existingUser, error: queryError } = await supabase
      .from('users')
      .select('id, telephone, role')
      .eq('telephone', phone)
      .eq('role', 'citizen')
      .maybeSingle();

    if (queryError) {
      console.error('Erreur vérification utilisateur:', JSON.stringify(queryError, null, 2));
      throw new Error(`Erreur base de données: ${queryError.message || 'Erreur inconnue'}`);
    }

    if (!existingUser) {
      console.log('Citoyen non trouvé pour le téléphone:', phone);
      throw new Error('Utilisateur non trouvé. Créez un compte d\'abord.');
    }

    console.log('Citoyen trouvé:', existingUser.id);

    // Sauvegarder l'ID utilisateur et le type dans AsyncStorage
    if (typeof window !== 'undefined') {
      const AsyncStorage = await import('@react-native-async-storage/async-storage').then(m => m.default);
      await AsyncStorage.setItem('tokse_user_id', existingUser.id);
      await AsyncStorage.setItem('tokse_user_type', 'citizen');
      console.log('ID utilisateur et type sauvegardés dans AsyncStorage');
    }

    return {
      success: true,
      message: `Connexion réussie !`,
      userId: existingUser.id,
      userType: 'citizen',
      phone,
    };
  } catch (error: any) {
    console.error('Erreur signInWithPhone:', error?.message || error);
    throw error;
  }
}

// ============= CONNEXION AGENT (Username + Password) - AVEC SUPABASE AUTH =============

export async function signInAgent(username: string, password: string) {
  try {
    console.log('Connexion agent avec username:', username);

    // Étape 1: Authentifier avec Supabase Auth
    const { data: authData, error: authError } = await supabase.auth.signInWithPassword({
      email: username,
      password: password,
    });

    if (authError) {
      console.error('Erreur authentification Supabase:', authError.message);
      throw new Error('Identifiants incorrects.');
    }

    if (!authData.user) {
      throw new Error('Authentification échouée.');
    }

    console.log('Authentification réussie pour:', authData.user.id);

    // Étape 2: Vérifier que c'est bien un agent dans la table users
    const { data: agent, error: queryError } = await supabase
      .from('users')
      .select('id, nom, prenom, email, telephone, secteur, autorite_id, autorite_type, is_active, role')
      .eq('id', authData.user.id)
      .eq('role', 'agent')
      .maybeSingle();

    if (queryError) {
      console.error('Erreur vérification agent:', JSON.stringify(queryError, null, 2));
      // Déconnecter l'utilisateur si ce n'est pas un agent
      await supabase.auth.signOut();
      throw new Error(`Erreur base de données: ${queryError.message || 'Erreur inconnue'}`);
    }

    if (!agent) {
      console.log('Utilisateur trouvé mais ce n\'est pas un agent');
      // Déconnecter si ce n'est pas un agent
      await supabase.auth.signOut();
      throw new Error('Accès non autorisé. Cet espace est réservé aux agents de terrain.');
    }

    if (!agent.is_active) {
      console.log('Agent désactivé:', agent.id);
      await supabase.auth.signOut();
      throw new Error('Votre compte agent est désactivé. Contactez votre autorité.');
    }

    console.log('Agent vérifié:', agent.id, '-', agent.prenom, agent.nom);

    // Étape 3: Sauvegarder les données dans AsyncStorage
    if (typeof window !== 'undefined') {
      const AsyncStorage = await import('@react-native-async-storage/async-storage').then(m => m.default);
      await AsyncStorage.setItem('tokse_user_id', agent.id);
      await AsyncStorage.setItem('tokse_user_type', 'agent');
      await AsyncStorage.setItem('tokse_agent_data', JSON.stringify(agent));
      await AsyncStorage.setItem('tokse_auth_token', authData.session?.access_token || '');
      console.log('Données agent et token sauvegardés dans AsyncStorage');
    }

    return {
      success: true,
      message: `Bienvenue ${agent.prenom} ${agent.nom}`,
      userId: agent.id,
      userType: 'agent',
      agent,
      session: authData.session,
    };
  } catch (error: any) {
    console.error('Erreur signInAgent:', error?.message || error);
    throw error;
  }
}

// ============= GESTION UTILISATEUR =============

export async function upsertUser(userId: string, phone: string, nom: string, prenom: string) {
  try {
    const { error } = await supabase
      .from('users')
      .upsert({
        id: userId,
        telephone: phone,
        nom: nom,
        prenom: prenom,
        email: `${phone}@tokse.app`, // Email virtuel basé sur le téléphone
        role: 'citizen', // ← Tous les nouveaux utilisateurs sont citoyens par défaut
      });

    if (error) {
      console.error('Erreur upsert user:', error);
      // Ne pas bloquer si l'upsert échoue
      return false;
    }

    console.log('Utilisateur créé/mis à jour:', userId);
    return true;
  } catch (error) {
    console.error('Erreur upsertUser:', error);
    return false;
  }
}

export async function getCurrentUser() {
  try {
    // 1. Vérifier d'abord s'il y a une session Supabase
    const { data: { user } } = await supabase.auth.getUser();
    if (user) {
      console.log('Utilisateur trouvé via Supabase Auth:', user.id);
      // Récupérer le rôle depuis la table users
      const { data: userData, error: userErr } = await supabase
        .from('users')
        .select('id, telephone, email, nom, prenom, role, photo_profile')
        .eq('id', user.id)
        .maybeSingle();

      if (userErr) {
        console.error('Erreur récupération user depuis DB:', userErr);
        return user;
      }

      if (userData) {
        return { ...user, ...userData };
      }
      return user;
    }

    // 2. Si pas de session, vérifier AsyncStorage (pour connexion directe)
    if (typeof window !== 'undefined') {
      const AsyncStorage = await import('@react-native-async-storage/async-storage').then(m => m.default);
      const savedUserId = await AsyncStorage.getItem('tokse_user_id');
      
      if (savedUserId) {
          console.log('Utilisateur trouvé via AsyncStorage:', savedUserId);
          // Valider et récupérer l'utilisateur depuis la table users (avec rôle)
          const { data: existingUser, error: userErr } = await supabase
            .from('users')
            .select('id, telephone, email, nom, prenom, role, photo_profile')
            .eq('id', savedUserId)
            .maybeSingle();

          if (userErr) {
            console.error('Erreur récupération user depuis DB:', userErr);
            return null;
          }

          if (existingUser) {
            return existingUser as any;
          }
        }
    }

    console.log('Aucun utilisateur trouvé');
    return null;
  } catch (error) {
    console.error('Erreur getCurrentUser:', error);
    return null;
  }
}

export async function signOut() {
  try {
    // Nettoyer AsyncStorage
    if (typeof window !== 'undefined') {
      const AsyncStorage = await import('@react-native-async-storage/async-storage').then(m => m.default);
      await AsyncStorage.removeItem('tokse_user_id');
      console.log('ID utilisateur supprimé de AsyncStorage');
    }

    // Déconnecter de Supabase
    const { error } = await supabase.auth.signOut();
    if (error) throw error;

    console.log('Déconnexion réussie');
  } catch (error) {
    console.error('Erreur signOut:', error);
    throw error;
  }
}

// ============= ANCIEN CODE (POUR BACKWARD COMPATIBILITY) =============

export async function signInAnonymously() {
  try {
    // Vérifier si déjà connecté
    const { data: { session } } = await supabase.auth.getSession();
    
    if (session) {
      console.log('Déjà connecté:', session.user.id);
      await ensureUserExists(session.user.id, session.user.email || '');
      return session.user;
    }

    // Créer un utilisateur anonyme
    const email = `anonymous_${Date.now()}@tokse.app`;
    const password = Math.random().toString(36).slice(-12);

    const { data, error } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: {
          role: 'citizen',
        }
      }
    });

    if (error) throw error;

    if (data.user) {
      console.log('Utilisateur anonyme créé:', data.user.id);
      await ensureUserExists(data.user.id, email);
    }

    return data.user;
  } catch (error) {
    console.error('Erreur signInAnonymously:', error);
    throw error;
  }
}

async function ensureUserExists(userId: string, email: string) {
  try {
    const { data: existingUser } = await supabase
      .from('users')
      .select('id')
      .eq('id', userId)
      .maybeSingle();

    if (existingUser) {
      console.log('Utilisateur existe déjà');
      return;
    }

    const { error } = await supabase
      .from('users')
      .insert({
        id: userId,
        email: email,
        role: 'citizen',
      });

    if (error && error.code !== '23505') {
      console.error('Erreur création user:', error);
    } else {
      console.log('Utilisateur créé');
    }
  } catch (error) {
    console.error('Erreur ensureUserExists:', error);
  }
}

// ============= CRÉER COMPTE AUTORITÉ (Admin only) =============

export async function createAuthorityUser(phone: string, nom: string, prenom: string) {
  try {
    console.log('Création compte autorité:', { phone, nom, prenom });

    // Créer un utilisateur avec OTP (même flux que citoyen)
    const { error: otpError } = await supabase.auth.signInWithOtp({
      phone: phone,
      options: {
        shouldCreateUser: true,
      }
    });

    if (otpError) {
      console.error('Erreur envoi OTP autorité:', otpError);
      throw otpError;
    }

    // Temporairement, créer l'entrée dans users avec role = 'autorite'
    // (Note: l'OTP devra être vérifié par l'autorité ensuite)
    const { data: { user }, error: authError } = await supabase.auth.getUser();
    
    if (!authError && user) {
      // Créer/mettre à jour l'utilisateur avec role = 'autorite'
      const { error: upsertError } = await supabase
        .from('users')
        .upsert({
          id: user.id,
          telephone: phone,
          nom: nom,
          prenom: prenom,
          email: `${phone}@tokse.app`,
          role: 'autorite', // ← Important : autorité
        });

      if (upsertError) {
        console.error('Erreur création autorité:', upsertError);
        throw upsertError;
      }

      console.log('Compte autorité créé:', user.id);
      return {
        success: true,
        message: `Compte autorité créé pour ${nom} ${prenom}. Un OTP a été envoyé au ${phone}.`,
        userId: user.id,
      };
    }

    throw new Error('Impossible de récupérer l\'utilisateur');
  } catch (error) {
    console.error('Erreur createAuthorityUser:', error);
    throw error;
  }
}

// ============= SUPPRESSION DE COMPTE =============

export async function requestAccountDeletion() {
  try {
    const user = await getCurrentUser();
    if (!user) throw new Error('Utilisateur non authentifié');

    // Créer une demande de suppression avec date d'expiration (48h)
    const deletionDate = new Date(Date.now() + 48 * 60 * 60 * 1000); // 48h plus tard

    const { error } = await supabase
      .from('deletion_requests')
      .insert({
        user_id: user.id,
        requested_at: new Date().toISOString(),
        deletion_scheduled_for: deletionDate.toISOString(),
        status: 'pending',
      });

    if (error) {
      console.error('Erreur création demande suppression:', error);
      throw error;
    }

    console.log('Demande de suppression créée, expire le:', deletionDate);
    return {
      success: true,
      deletionDate: deletionDate,
      message: `Votre compte sera supprimé le ${deletionDate.toLocaleDateString('fr-FR')} à ${deletionDate.toLocaleTimeString('fr-FR')}`,
    };
  } catch (error) {
    console.error('Erreur requestAccountDeletion:', error);
    throw error;
  }
}

export async function cancelAccountDeletion() {
  try {
    const user = await getCurrentUser();
    if (!user) throw new Error('Utilisateur non authentifié');

    const { error } = await supabase
      .from('deletion_requests')
      .update({ status: 'cancelled' })
      .eq('user_id', user.id)
      .eq('status', 'pending');

    if (error) {
      console.error('Erreur annulation suppression:', error);
      throw error;
    }

    console.log('Demande de suppression annulée');
    return { success: true };
  } catch (error) {
    console.error('Erreur cancelAccountDeletion:', error);
    throw error;
  }
}

export async function checkDeletionRequest() {
  try {
    const user = await getCurrentUser();
    if (!user) return null;

    const { data, error } = await supabase
      .from('deletion_requests')
      .select('*')
      .eq('user_id', user.id)
      .eq('status', 'pending')
      .single();

    if (error && error.code !== 'PGRST116') {
      console.error('Erreur vérification demande suppression:', error);
    }

    return data || null;
  } catch (error) {
    console.error('Erreur checkDeletionRequest:', error);
    return null;
  }
}
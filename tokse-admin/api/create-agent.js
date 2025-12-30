// API pour créer un agent avec l'API Admin de Supabase
// L'agent pourra se connecter immédiatement sans confirmation d'email
import { createClient } from '@supabase/supabase-js';
import express from 'express';

const router = express.Router();

router.post('/', async (req, res) => {
  const { email, password, nom, prenom, telephone, secteur, autorite_id, autorite_type } = req.body;

  const supabaseUrl = process.env.VITE_SUPABASE_URL || process.env.SUPABASE_URL;
  const supabaseServiceKey = process.env.SUPABASE_SERVICE_KEY;

  if (!supabaseUrl || !supabaseServiceKey) {
    return res.status(500).json({ 
      success: false, 
      error: 'Missing Supabase service credentials' 
    });
  }

  const supabase = createClient(supabaseUrl, supabaseServiceKey);

  try {
    console.log('🚀 [CREATE_AGENT] Création agent avec email:', email);

    // 1. Créer l'utilisateur Auth avec l'API Admin (email confirmé automatiquement)
    const { data: authData, error: authError } = await supabase.auth.admin.createUser({
      email: email,
      password: password,
      email_confirm: true, // ✅ Email confirmé automatiquement
      user_metadata: {
        nom: nom,
        prenom: prenom,
      },
    });

    if (authError) {
      console.error('❌ [CREATE_AGENT] Erreur Auth:', authError);
      return res.status(400).json({ 
        success: false, 
        error: authError.message 
      });
    }

    if (!authData.user) {
      return res.status(400).json({ 
        success: false, 
        error: 'Échec de la création du compte Auth' 
      });
    }

    console.log('✅ [CREATE_AGENT] Auth créé:', authData.user.id);

    // 2. Créer le profil agent dans la table users
    const { error: profileError } = await supabase.from('users').insert({
      id: authData.user.id,
      email: email,
      password: password,
      nom: nom,
      prenom: prenom,
      telephone: telephone || null,
      role: 'agent',
      autorite_id: autorite_id,
      autorite_type: autorite_type || null,
      secteur: secteur || null,
      is_active: true,
    });

    if (profileError) {
      console.error('❌ [CREATE_AGENT] Erreur profil:', profileError);
      // Supprimer l'utilisateur Auth si la création du profil échoue
      await supabase.auth.admin.deleteUser(authData.user.id);
      return res.status(400).json({ 
        success: false, 
        error: profileError.message 
      });
    }

    console.log('✅ [CREATE_AGENT] Profil créé');

    // 3. Logger l'action
    await supabase.from('logs_activite').insert({
      type_action: 'creation_agent',
      autorite_id: autorite_id,
      utilisateur_cible_id: authData.user.id,
      details: {
        nom: nom,
        prenom: prenom,
        email: email,
        secteur: secteur,
        timestamp: new Date().toISOString(),
      },
    });

    console.log('✅ [CREATE_AGENT] Agent créé avec succès - Peut se connecter immédiatement');

    return res.json({
      success: true,
      message: 'Agent créé avec succès',
      agent_id: authData.user.id,
    });
  } catch (error) {
    console.error('❌ [CREATE_AGENT] Erreur:', error);
    return res.status(500).json({ 
      success: false, 
      error: error.message 
    });
  }
});

export default router;

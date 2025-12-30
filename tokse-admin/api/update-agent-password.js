import express from 'express';
import { createClient } from '@supabase/supabase-js';

const router = express.Router();

router.post('/', async (req, res) => {
  try {
    const { userId, newPassword } = req.body;

    if (!userId || !newPassword) {
      return res.status(400).json({
        success: false,
        error: 'userId et newPassword sont requis'
      });
    }
    
    // Créer le client Supabase ici avec les bonnes variables d'environnement
    const supabaseUrl = process.env.VITE_SUPABASE_URL || process.env.SUPABASE_URL;
    const supabaseServiceKey = process.env.SUPABASE_SERVICE_KEY;
    
    if (!supabaseUrl || !supabaseServiceKey) {
      return res.status(500).json({
        success: false,
        error: 'Configuration Supabase manquante'
      });
    }
    
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    if (newPassword.length < 8) {
      return res.status(400).json({
        success: false,
        error: 'Le mot de passe doit contenir au moins 8 caractères'
      });
    }

    // Mettre à jour le password dans Supabase Auth
    const { data: authData, error: authError } = await supabase.auth.admin.updateUserById(
      userId,
      { password: newPassword }
    );

    if (authError) {
      console.error('❌ Erreur auth:', authError);
      throw authError;
    }

    // Mettre à jour le password dans la table users
    const { error: dbError } = await supabase
      .from('users')
      .update({ password: newPassword })
      .eq('id', userId);

    if (dbError) {
      console.error('❌ Erreur DB:', dbError);
      throw dbError;
    }

    console.log('✅ Password mis à jour pour l\'agent:', userId);

    res.json({
      success: true,
      message: 'Mot de passe mis à jour avec succès'
    });

  } catch (error) {
    console.error('❌ Erreur update-agent-password:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Erreur lors de la mise à jour du mot de passe'
    });
  }
});

export default router;

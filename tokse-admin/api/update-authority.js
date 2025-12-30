// API de mise à jour d'une autorité via la clé service Supabase
import { createClient } from '@supabase/supabase-js';
import express from 'express';

const router = express.Router();

router.put('/', async (req, res) => {
  const supabaseUrl = process.env.VITE_SUPABASE_URL || process.env.SUPABASE_URL;
  const supabaseServiceKey = process.env.SUPABASE_SERVICE_KEY;
  
  if (!supabaseUrl || !supabaseServiceKey) {
    return res.status(500).json({ error: 'Missing Supabase service credentials' });
  }
  
  const supabase = createClient(supabaseUrl, supabaseServiceKey);
  
  try {
    const { id, nom, prenom, email, telephone, role, autorite_type, secteur, password } = req.body;
    
    if (!id || !email || !nom || !prenom) {
      return res.status(400).json({ error: 'Champs obligatoires manquants (id, email, nom, prenom)' });
    }

    // Mettre à jour la table users
    const updateData = {
      nom,
      prenom,
      email,
      telephone,
      role,
      autorite_type,
      secteur,
    };

    // Ajouter le password si fourni
    if (password && password.length >= 6) {
      updateData.password = password;
    }

    const { error: userError } = await supabase
      .from('users')
      .update(updateData)
      .eq('id', id);
    
    if (userError) {
      console.error('Erreur mise à jour users:', userError);
      return res.status(400).json({ error: userError.message });
    }

    // Si un nouveau mot de passe est fourni, mettre à jour Supabase Auth
    if (password && password.length >= 6) {
      const { error: authError } = await supabase.auth.admin.updateUserById(id, {
        email,
        password,
      });
      
      if (authError) {
        console.error('Erreur mise à jour Auth:', authError);
        // Ne pas échouer complètement si l'auth échoue
        return res.status(200).json({ 
          success: true, 
          warning: 'Utilisateur mis à jour mais erreur Auth: ' + authError.message 
        });
      }
    }

    res.status(200).json({ success: true, message: 'Autorité mise à jour avec succès' });
  } catch (err) {
    console.error('Erreur serveur:', err);
    res.status(500).json({ error: err.message });
  }
});

export default router;

// API d'insertion d'une autorité via la clé service Supabase (ne déconnecte pas l'admin)
import { createClient } from '@supabase/supabase-js';
import express from 'express';

const router = express.Router();


router.post('/', async (req, res) => {
  const supabaseUrl = process.env.VITE_SUPABASE_URL || process.env.SUPABASE_URL;
  const supabaseServiceKey = process.env.SUPABASE_SERVICE_KEY;
  if (!supabaseUrl || !supabaseServiceKey) {
    return res.status(500).json({ error: 'Missing Supabase service credentials' });
  }
  const supabase = createClient(supabaseUrl, supabaseServiceKey);
  try {
    const { nom, prenom, email, numero_telephone, role, zone_intervention, password } = req.body;
    if (!email || !password || !nom || !prenom || !numero_telephone || !role) {
      return res.status(400).json({ error: 'Champs obligatoires manquants' });
    }

    // Créer l'utilisateur dans Supabase Auth (sans impacter la session admin)
    const { data: userData, error: authError } = await supabase.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
    });
    if (authError) return res.status(400).json({ error: authError.message });

    // Insérer dans la table users
    const { error: userError } = await supabase.from('users').insert({
      id: userData.user.id,
      nom,
      prenom,
      email,
      telephone: numero_telephone,
      role,
      zone_intervention,
      est_actif: true,
    });
    if (userError) return res.status(400).json({ error: userError.message });

    res.status(201).json({ success: true, userId: userData.user.id });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

export default router;

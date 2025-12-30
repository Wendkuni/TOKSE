// API pour supprimer les agents orphelins
import { createClient } from '@supabase/supabase-js';
import express from 'express';

const router = express.Router();

router.delete('/', async (req, res) => {
  const supabaseUrl = process.env.VITE_SUPABASE_URL || process.env.SUPABASE_URL;
  const supabaseServiceKey = process.env.SUPABASE_SERVICE_KEY;
  
  if (!supabaseUrl || !supabaseServiceKey) {
    return res.status(500).json({ error: 'Missing Supabase service credentials' });
  }
  
  const supabase = createClient(supabaseUrl, supabaseServiceKey);
  
  try {
    const { userId } = req.body;
    
    if (!userId) {
      return res.status(400).json({ error: 'userId requis' });
    }
    
    // Supprimer l'utilisateur de Auth
    const { error } = await supabase.auth.admin.deleteUser(userId);
    
    if (error) throw error;
    
    res.status(200).json({ 
      success: true, 
      message: 'Agent orphelin supprimé avec succès' 
    });
  } catch (err) {
    console.error('Erreur serveur:', err);
    res.status(500).json({ error: err.message });
  }
});

export default router;

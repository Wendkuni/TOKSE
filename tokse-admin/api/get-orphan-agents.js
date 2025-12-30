// API pour récupérer les agents orphelins (dans Auth mais pas dans users)
import { createClient } from '@supabase/supabase-js';
import express from 'express';

const router = express.Router();

router.get('/', async (req, res) => {
  const supabaseUrl = process.env.VITE_SUPABASE_URL || process.env.SUPABASE_URL;
  const supabaseServiceKey = process.env.SUPABASE_SERVICE_KEY;
  
  if (!supabaseUrl || !supabaseServiceKey) {
    return res.status(500).json({ error: 'Missing Supabase service credentials' });
  }
  
  const supabase = createClient(supabaseUrl, supabaseServiceKey);
  
  try {
    // 1. Récupérer tous les users de la table users
    const { data: dbUsers, error: dbError } = await supabase
      .from('users')
      .select('id');
    
    if (dbError) throw dbError;
    
    const dbUserIds = new Set(dbUsers.map(u => u.id));
    
    // 2. Récupérer tous les utilisateurs Auth
    const { data: authData, error: authError } = await supabase.auth.admin.listUsers();
    
    if (authError) throw authError;
    
    // 3. Trouver les orphelins (dans Auth mais pas dans users)
    const orphans = authData.users.filter(authUser => !dbUserIds.has(authUser.id));
    
    // 4. Formater la réponse
    const formattedOrphans = orphans.map(user => ({
      id: user.id,
      email: user.email,
      created_at: user.created_at,
      metadata: user.user_metadata,
    }));
    
    res.status(200).json({ 
      success: true, 
      orphans: formattedOrphans,
      count: formattedOrphans.length 
    });
  } catch (err) {
    console.error('Erreur serveur:', err);
    res.status(500).json({ error: err.message });
  }
});

export default router;

CD // API pour supprimer TOUS les agents orphelins en une seule fois
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
    
    console.log(`🗑️  Suppression de ${orphans.length} agents orphelins...`);
    
    // 4. Supprimer chaque orphelin
    const deleteResults = [];
    for (const orphan of orphans) {
      try {
        const { error: deleteError } = await supabase.auth.admin.deleteUser(orphan.id);
        if (deleteError) {
          deleteResults.push({ id: orphan.id, email: orphan.email, success: false, error: deleteError.message });
        } else {
          deleteResults.push({ id: orphan.id, email: orphan.email, success: true });
          console.log(`  ✅ Supprimé: ${orphan.email}`);
        }
      } catch (err) {
        deleteResults.push({ id: orphan.id, email: orphan.email, success: false, error: err.message });
        console.error(`  ❌ Erreur pour ${orphan.email}:`, err.message);
      }
    }
    
    const successCount = deleteResults.filter(r => r.success).length;
    const failCount = deleteResults.filter(r => !r.success).length;
    
    res.status(200).json({ 
      success: true,
      message: `${successCount} agents orphelins supprimés avec succès`,
      totalOrphans: orphans.length,
      deleted: successCount,
      failed: failCount,
      results: deleteResults
    });
  } catch (err) {
    console.error('Erreur serveur:', err);
    res.status(500).json({ error: err.message });
  }
});

export default router;

import { createClient } from '@supabase/supabase-js';
import { readFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Charger les variables d'environnement
const SUPABASE_URL = 'https://xabqjsqcwyrasvwpxddq.supabase.co';
const SUPABASE_SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhhYnFqc3Fjd3lyYXN2d3B4ZGRxIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2Mjc3NjM5MCwiZXhwIjoyMDc4MzUyMzkwfQ.LWM4nHext-Psf6mp0-2M4upfHEAazNkbxrZZrw_GevY';

// Créer le client Supabase avec la service key
const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

async function runMigration() {
  try {
    console.log('🚀 Exécution de la migration SUPER ADMIN...\n');

    // Lire le fichier SQL
    const migrationPath = join(__dirname, '../../MIGRATION_SUPER_ADMIN.sql');
    const sql = readFileSync(migrationPath, 'utf-8');

    // Diviser en requêtes individuelles (ignorer commentaires et lignes vides)
    const queries = sql
      .split(';')
      .map(q => q.trim())
      .filter(q => q.length > 0 && !q.startsWith('--') && !q.startsWith('/*'));

    let successCount = 0;
    let errorCount = 0;

    // Exécuter chaque requête
    for (let i = 0; i < queries.length; i++) {
      const query = queries[i] + ';';
      
      // Ignorer les commentaires multi-lignes et DO blocks
      if (query.startsWith('/*') || query.includes('DO $$')) {
        console.log(`⏭️  Ignoré: commentaire/DO block`);
        continue;
      }

      try {
        const { error } = await supabase.rpc('exec_sql', { sql_query: query });
        
        if (error) {
          console.error(`❌ Erreur sur requête ${i + 1}:`, error.message);
          errorCount++;
        } else {
          console.log(`✅ Requête ${i + 1} exécutée`);
          successCount++;
        }
      } catch (err) {
        console.error(`❌ Exception sur requête ${i + 1}:`, err.message);
        errorCount++;
      }
    }

    console.log(`\n📊 Résumé:`);
    console.log(`   ✅ Succès: ${successCount}`);
    console.log(`   ❌ Erreurs: ${errorCount}`);

    // Vérifier que la migration a fonctionné
    console.log('\n🔍 Vérification...');
    
    const { data: admins, error: adminError } = await supabase
      .from('users')
      .select('id, email, role, permissions')
      .eq('role', 'admin');

    if (adminError) {
      console.error('❌ Erreur lors de la vérification:', adminError);
    } else {
      console.log(`✅ Nombre d'admins trouvés: ${admins.length}`);
      admins.forEach(admin => {
        console.log(`   - ${admin.email} (permissions: ${admin.permissions ? 'OUI' : 'NON'})`);
      });
    }

    console.log('\n✅ Migration terminée !');

  } catch (error) {
    console.error('❌ Erreur fatale:', error);
    process.exit(1);
  }
}

runMigration();

// Script pour supprimer tous les agents orphelins
import fetch from 'node-fetch';

console.log('🗑️  Suppression de tous les agents orphelins...\n');

fetch('http://localhost:4000/api/delete-all-orphan-agents', {
  method: 'DELETE',
  headers: {
    'Content-Type': 'application/json',
  },
})
  .then(res => res.json())
  .then(data => {
    if (data.success) {
      console.log('\n✅ SUCCÈS!');
      console.log(`━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`);
      console.log(`📊 Total d'agents orphelins: ${data.totalOrphans}`);
      console.log(`✅ Supprimés avec succès: ${data.deleted}`);
      console.log(`❌ Échecs: ${data.failed}`);
      console.log(`━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n`);
      
      if (data.results && data.results.length > 0) {
        console.log('Détails:');
        data.results.forEach((result, index) => {
          const icon = result.success ? '✅' : '❌';
          console.log(`  ${icon} ${result.email}${result.error ? ` - ${result.error}` : ''}`);
        });
      }
    } else {
      console.error('❌ Erreur:', data.error);
    }
  })
  .catch(err => {
    console.error('❌ Erreur de connexion:', err.message);
    console.error('\n⚠️  Assurez-vous que le serveur backend tourne sur http://localhost:4000');
  });

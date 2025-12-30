# 🚀 GUIDE DE DÉPLOIEMENT SQL - INTERFACE AUTORITÉ

## Étape 1 : Accéder au SQL Editor de Supabase

1. Ouvrir votre projet Supabase : https://supabase.com/dashboard
2. Sélectionner votre projet **TOKSE**
3. Dans le menu latéral, cliquer sur **SQL Editor** (icône 📝)

## Étape 2 : Copier la migration SQL

1. Ouvrir le fichier `MIGRATION_AUTHORITY_INTERFACE.sql` dans ce dossier
2. **Copier tout le contenu** (188 lignes)

## Étape 3 : Exécuter la migration

1. Dans le SQL Editor, cliquer sur **New Query**
2. **Coller** le contenu copié
3. Cliquer sur **Run** (ou Ctrl+Enter)
4. Attendre la confirmation : ✅ **Success. No rows returned**

## Étape 4 : Vérifier l'installation

Exécuter cette requête de vérification :

```sql
-- Vérifier les nouvelles colonnes
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'signalements' 
  AND column_name IN ('assigned_to', 'locked', 'photo_apres', 'note_resolution', 'resolved_at');

-- Vérifier les fonctions RPC
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_name IN ('take_charge_signalement', 'resolve_signalement');

-- Vérifier la vue
SELECT table_name 
FROM information_schema.views 
WHERE table_name = 'authority_stats';

-- Vérifier la table d'audit
SELECT table_name 
FROM information_schema.tables 
WHERE table_name = 'authority_actions';
```

**Résultat attendu :**
- 5 colonnes dans signalements ✅
- 2 fonctions RPC ✅
- 1 vue authority_stats ✅
- 1 table authority_actions ✅

## Étape 5 : Tester les fonctions RPC

```sql
-- Test 1 : Créer un utilisateur autorité de test
INSERT INTO users (telephone, nom, prenom, role, zone_intervention)
VALUES ('+22670123456', 'Ouédraogo', 'Jean', 'police', 'Secteur 15 Ouaga')
RETURNING id;

-- Noter l'ID retourné (example: 'abc123...')

-- Test 2 : Prendre en charge un signalement
SELECT take_charge_signalement(
  'ID_DU_SIGNALEMENT'::uuid,
  'ID_AUTORITE'::uuid
);
```

## ⚠️ ATTENTION : Erreurs possibles

### Erreur : "column already exists"
**Solution :** Certaines colonnes existent déjà, c'est normal. La migration utilise `ADD COLUMN IF NOT EXISTS`.

### Erreur : "function already exists"
**Solution :** La migration utilise `CREATE OR REPLACE FUNCTION`, ça va écraser l'ancienne version.

### Erreur : "permission denied"
**Solution :** Vérifier que vous êtes connecté en tant qu'administrateur du projet Supabase.

## ✅ Confirmation finale

Si aucune erreur n'apparaît, la migration est réussie ! Vous pouvez maintenant :
1. ✅ Tester l'interface Autorité dans l'app Flutter
2. ✅ Les boutons "Prendre en charge" fonctionneront
3. ✅ Les stats seront calculées automatiquement
4. ✅ L'audit log enregistrera toutes les actions

---

**Prochaine étape :** Implémenter les appels RPC dans le code Flutter (Tâche 2)

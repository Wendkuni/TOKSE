# 🔍 DEBUG - Problème de création d'autorité

## 🚨 Symptômes
- Quand je crée une autorité, je suis redirigé vers la page de connexion admin
- L'autorité n'apparaît pas dans la liste des utilisateurs
- Rien ne se passe

## ✅ Solutions à tester

### Solution 1 : Vérifier les logs dans la console

1. **Ouvrir le dashboard admin** : http://localhost:3000/admin
2. **Ouvrir la console du navigateur** :
   - Chrome/Edge : Appuyez sur `F12` ou `Ctrl+Shift+I`
   - Firefox : Appuyez sur `F12`
3. **Aller dans l'onglet "Console"**
4. **Essayer de créer une autorité**
5. **Observer les logs** :

```
🔵 [DÉBUT] handleSubmitForm
📞 [CRÉATION] Données: {nom: "...", prenom: "...", ...}
🔵 [DB] createAuthorityDirect appelé avec: {...}
📋 [DB] Role mappé: police
📤 [DB] Insertion des données: {...}
✅ [DB] Utilisateur créé: [...]
✅ [SUCCÈS] Résultat: {...}
```

**Si vous voyez une erreur ❌**, notez exactement le message.

---

### Solution 2 : Vérifier la connexion Supabase

**Problème possible :** Les credentials Supabase sont incorrects ou expirés.

1. Aller dans `admin-dashboard/adminAuth.js`
2. Vérifier les lignes 3-4 :

```javascript
const SUPABASE_URL = 'https://waqjrylccobvzybsfsmr.supabase.co';
const SUPABASE_KEY = 'eyJhbGciOi...'; // Très long token
```

3. **Vérifier sur Supabase Dashboard** :
   - Aller sur https://supabase.com/dashboard
   - Sélectionner votre projet TOKSE
   - Aller dans **Settings** → **API**
   - Copier :
     - **Project URL** → SUPABASE_URL
     - **anon public key** → SUPABASE_KEY

4. **Remplacer dans `adminAuth.js`** si différent

---

### Solution 3 : Vérifier les RLS (Row Level Security)

**Problème possible :** Supabase bloque l'insertion à cause des politiques de sécurité.

**Test rapide dans Supabase SQL Editor :**

```sql
-- Vérifier les politiques RLS sur la table users
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies
WHERE tablename = 'users';
```

**Si vous voyez des politiques restrictives, désactivez temporairement RLS :**

```sql
-- TEMPORAIRE : Désactiver RLS pour tester
ALTER TABLE users DISABLE ROW LEVEL SECURITY;

-- Essayer de créer une autorité depuis le dashboard

-- PUIS RÉACTIVER :
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
```

**Solution permanente : Ajouter une politique pour les insertions :**

```sql
-- Créer une politique qui autorise les insertions pour tout le monde (anon key)
CREATE POLICY "Allow insert for authenticated users" ON users
FOR INSERT
TO authenticated, anon
WITH CHECK (true);
```

---

### Solution 4 : Tester l'insertion directement en SQL

**Dans Supabase SQL Editor, exécuter :**

```sql
-- Test d'insertion manuelle
INSERT INTO users (telephone, nom, prenom, role, zone_intervention, email)
VALUES (
  '+22670999999',
  'Test',
  'Autorité',
  'police',
  'maire',
  'test@tokse.local'
)
RETURNING *;
```

**Résultats possibles :**

✅ **Si ça marche** : Le problème vient du dashboard (permissions JS)
❌ **Si erreur "violates row-level security policy"** : Problème RLS (voir Solution 3)
❌ **Si erreur "duplicate key"** : Le téléphone existe déjà, changer le numéro
❌ **Si erreur "column does not exist"** : La structure de la table n'est pas à jour

---

### Solution 5 : Vérifier la structure de la table

```sql
-- Vérifier les colonnes de la table users
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'users'
ORDER BY ordinal_position;
```

**Colonnes requises :**
- ✅ `id` (uuid, NOT NULL)
- ✅ `telephone` (text, NOT NULL, UNIQUE)
- ✅ `nom` (text, NOT NULL)
- ✅ `prenom` (text, NOT NULL)
- ✅ `role` (text, NOT NULL)
- ✅ `email` (text, nullable)
- ✅ `zone_intervention` (text, nullable)
- ✅ `created_at` (timestamp, DEFAULT now())

**Si une colonne manque, créer la migration :**

```sql
-- Ajouter zone_intervention si elle n'existe pas
ALTER TABLE users ADD COLUMN IF NOT EXISTS zone_intervention TEXT;

-- Ajouter created_at si elle n'existe pas
ALTER TABLE users ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Ajouter updated_at si elle n'existe pas
ALTER TABLE users ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
```

---

### Solution 6 : Vérifier les contraintes UNIQUE

**Problème possible :** Le téléphone existe déjà dans la base.

```sql
-- Vérifier si le téléphone existe déjà
SELECT id, telephone, nom, prenom, role
FROM users
WHERE telephone = '+22670123456'; -- Remplacer par votre numéro de test
```

**Si une ligne existe :**

```sql
-- Option A : Supprimer l'ancien
DELETE FROM users WHERE telephone = '+22670123456';

-- Option B : Utiliser un autre numéro de test
-- Dans le dashboard, essayer avec +22670000001, +22670000002, etc.
```

---

### Solution 7 : Forcer le rafraîchissement du dashboard

Parfois le cache du navigateur cause des problèmes.

1. **Vider le cache** : `Ctrl+Shift+Delete` → Cocher "Cookies" et "Cache" → Tout effacer
2. **Rafraîchir** : `Ctrl+F5` (hard refresh)
3. **Réessayer**

---

## 📋 CHECKLIST DE DEBUG

Cochez au fur et à mesure :

- [ ] **Étape 1** : Console ouverte, logs visibles
- [ ] **Étape 2** : SUPABASE_URL et SUPABASE_KEY corrects
- [ ] **Étape 3** : RLS désactivé temporairement OU politique d'insertion ajoutée
- [ ] **Étape 4** : Insertion SQL manuelle fonctionne
- [ ] **Étape 5** : Toutes les colonnes requises existent
- [ ] **Étape 6** : Pas de téléphone en doublon
- [ ] **Étape 7** : Cache navigateur vidé

---

## 🎯 Test final après corrections

1. Ouvrir http://localhost:3000/admin
2. S'authentifier avec le code admin
3. Aller dans **"Créer Autorité"**
4. Remplir :
   - Prénom : `Jean`
   - Nom : `Ouédraogo`
   - Téléphone : `+22670000001`
   - Position : `👷 Agent municipal`
5. Cliquer **"Créer l'autorité"**
6. **Observer dans la console** : devrait voir `✅ [SUCCÈS]`
7. **Aller dans "Utilisateurs"** → Cliquer **🔄 Rafraîchir**
8. ✅ **L'autorité doit apparaître** dans la liste

---

## 💡 Si rien ne fonctionne

Envoyez-moi :
1. Les logs complets de la console (screenshot ou copier-coller)
2. Le résultat de la requête SQL de vérification des colonnes
3. Le résultat de la requête SQL de vérification des politiques RLS

Je pourrai alors identifier le problème exact.

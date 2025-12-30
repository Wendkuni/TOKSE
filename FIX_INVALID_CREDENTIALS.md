# 🚨 ERREUR: Invalid Login Credentials

## Diagnostic Rapide

L'erreur `invalid login credentials, statusCode: 400` signifie que **Supabase Auth refuse la connexion**.

## ✅ Solutions Rapides

### Solution 1 : Créer un Agent de Test Propre

1. **Lance le serveur backend admin** :
```bash
cd tokse-admin
node server.js
```

2. **Ouvre l'interface admin** : http://localhost:5173

3. **Connecte-toi comme autorité**

4. **Va dans "Gestion des Agents"** → **"Créer un agent"**

5. **Remplis les infos** :
   - Email: `test.agent@tokse.app`
   - Password: `Agent123!` (minimum 6 caractères)
   - Nom: `Test`
   - Prénom: `Agent`
   - Téléphone: `0123456789` (optionnel)
   - Secteur: `Centre-ville` (optionnel)

6. **Après création, confirme l'email dans Supabase** :
   - Va sur le dashboard Supabase
   - SQL Editor
   - Exécute :
   ```sql
   UPDATE auth.users
   SET email_confirmed_at = NOW()
   WHERE email = 'test.agent@tokse.app';
   ```

7. **Teste la connexion** sur l'app mobile avec :
   - Email: `test.agent@tokse.app`
   - Password: `Agent123!`

### Solution 2 : Corriger un Agent Existant

Si tu as déjà créé un agent mais qu'il ne peut pas se connecter :

**Exécute ce script SQL dans Supabase** :

```sql
-- Remplace 'ton_email@example.com' par l'email de ton agent

-- 1. Confirmer l'email
UPDATE auth.users
SET email_confirmed_at = NOW(),
    confirmation_token = NULL
WHERE email = 'ton_email@example.com';

-- 2. Activer le compte
UPDATE users
SET is_active = true,
    role = 'agent'
WHERE email = 'ton_email@example.com';

-- 3. Vérifier
SELECT 
  u.email,
  u.role,
  u.is_active,
  au.email_confirmed_at,
  CASE 
    WHEN au.email_confirmed_at IS NULL THEN '❌ Email non confirmé'
    WHEN u.is_active = false THEN '❌ Compte désactivé'
    WHEN u.role != 'agent' THEN '❌ Pas un agent'
    ELSE '✅ OK - Prêt'
  END as statut
FROM users u
LEFT JOIN auth.users au ON u.id = au.id
WHERE u.email = 'ton_email@example.com';
```

### Solution 3 : Réinitialiser le Mot de Passe

Si le mot de passe est oublié/incorrect :

**Méthode A : Via l'interface admin**
1. Connecte-toi à l'interface admin TOKSE
2. "Gestion des Agents" → Trouve l'agent → Modifier
3. Entre un nouveau mot de passe
4. Sauvegarde

**Méthode B : Via l'API backend**
```bash
curl -X POST http://localhost:4000/api/update-agent-password \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "ID_DE_LAGENT",
    "newPassword": "NouveauMotDePasse123!"
  }'
```

## 🔍 Vérifications Importantes

Pour qu'un agent puisse se connecter, **TOUS** ces critères doivent être vrais :

### Dans `auth.users` :
- ✅ L'utilisateur existe
- ✅ `email_confirmed_at` est NON NULL (email confirmé)
- ✅ Le mot de passe est correct

### Dans la table `users` :
- ✅ L'utilisateur existe avec le même `id`
- ✅ `role` = `'agent'`
- ✅ `is_active` = `true`
- ✅ `autorite_id` est renseigné

## 🧪 Test Complet

Exécute cette requête pour vérifier un agent :

```sql
SELECT 
  u.id,
  u.email,
  u.role,
  u.is_active,
  u.nom,
  u.prenom,
  u.autorite_id,
  au.email as auth_email,
  au.email_confirmed_at as email_confirme,
  au.last_sign_in_at as derniere_connexion,
  CASE 
    WHEN au.id IS NULL THEN '❌ ERREUR: Absent de auth.users'
    WHEN au.email_confirmed_at IS NULL THEN '❌ Email non confirmé'
    WHEN u.is_active = false THEN '❌ Compte désactivé'
    WHEN u.role != 'agent' THEN '❌ Pas un agent (rôle: ' || u.role || ')'
    WHEN u.autorite_id IS NULL THEN '⚠️ Pas d''autorité assignée'
    ELSE '✅ TOUT EST OK - Peut se connecter'
  END as diagnostic
FROM users u
LEFT JOIN auth.users au ON u.id = au.id
WHERE u.email = 'TON_EMAIL@example.com'; -- Remplace ici
```

## 🎯 Checklist de Dépannage

1. [ ] L'agent existe dans `auth.users`
2. [ ] L'email est confirmé (`email_confirmed_at` non NULL)
3. [ ] L'agent existe dans la table `users` avec le même `id`
4. [ ] `role` = `'agent'`
5. [ ] `is_active` = `true`
6. [ ] Tu utilises le bon email
7. [ ] Tu utilises le bon mot de passe
8. [ ] Le mot de passe fait minimum 6 caractères

## 📱 Après la Correction

1. **Relance l'app Flutter**
2. **Essaie de te connecter**
3. **Regarde les logs** dans la console (cherche `[AGENT_LOGIN]`)
4. **Tu devrais voir** :
   ```
   ✅ [AGENT_LOGIN] Auth réussie - User ID: xxx
   ✅ [AGENT_LOGIN] Vérifications OK - Connexion acceptée
   🚀 [AGENT_LOGIN] Navigation vers /authority-home
   ```

## 🆘 Toujours Bloqué ?

Partage-moi :
1. L'email que tu utilises pour te connecter
2. Le résultat de la requête SQL de vérification ci-dessus
3. Les logs de la console Flutter

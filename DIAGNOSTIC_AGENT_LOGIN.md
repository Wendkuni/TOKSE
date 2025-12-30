# 🔧 Diagnostic - Problème Connexion Agent

## ✅ Corrections Apportées

1. **Ajout de logs détaillés** dans l'écran de connexion agent Flutter
2. **Correction création agent** : désactivation de la confirmation email obligatoire
3. **Ajout de vérifications** lors de la création d'un agent Auth

## 🔍 Comment Diagnostiquer le Problème

### Étape 1 : Vérifier l'état de l'agent dans Supabase

Connecte-toi à ton dashboard Supabase et exécute cette requête SQL :

```sql
-- Vérifier si l'agent existe dans la table users
SELECT 
  id,
  email,
  role,
  is_active,
  nom,
  prenom,
  autorite_id,
  created_at
FROM users
WHERE email = 'EMAIL_DE_TON_AGENT@example.com';

-- Vérifier si l'agent existe dans auth.users
SELECT 
  id,
  email,
  email_confirmed_at,
  last_sign_in_at,
  created_at
FROM auth.users
WHERE email = 'EMAIL_DE_TON_AGENT@example.com';
```

### Étape 2 : Vérifier les Critères de Connexion

Pour qu'un agent puisse se connecter, il DOIT respecter TOUS ces critères :

✅ **Dans auth.users** :
- L'utilisateur doit exister
- `email_confirmed_at` doit être NON NULL (confirmé)
- Le mot de passe doit être correct

✅ **Dans la table users** :
- L'utilisateur doit exister avec le même `id`
- `role` = 'agent'
- `is_active` = true
- `autorite_id` doit être renseigné

### Étape 3 : Problèmes Courants et Solutions

#### ❌ Problème 1 : Email non confirmé
**Symptôme** : `email_confirmed_at` est NULL dans auth.users

**Solution** :
```sql
-- Forcer la confirmation d'email pour l'agent
UPDATE auth.users
SET email_confirmed_at = NOW()
WHERE email = 'EMAIL_DE_TON_AGENT@example.com';
```

#### ❌ Problème 2 : Agent désactivé
**Symptôme** : `is_active` = false dans users

**Solution** :
```sql
-- Réactiver l'agent
UPDATE users
SET is_active = true
WHERE email = 'EMAIL_DE_TON_AGENT@example.com';
```

#### ❌ Problème 3 : Rôle incorrect
**Symptôme** : `role` != 'agent' dans users

**Solution** :
```sql
-- Corriger le rôle
UPDATE users
SET role = 'agent'
WHERE email = 'EMAIL_DE_TON_AGENT@example.com';
```

#### ❌ Problème 4 : Mot de passe oublié/incorrect

**Solution via l'interface admin** :
1. Va dans l'interface admin TOKSE
2. Section "Gestion des Agents"
3. Modifie l'agent et réinitialise le mot de passe

**OU** 

**Solution via API** :
```bash
# Appeler l'API de réinitialisation de mot de passe
curl -X POST http://localhost:4000/api/update-agent-password \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "ID_DE_LAGENT",
    "newPassword": "NouveauMotDePasse123!"
  }'
```

#### ❌ Problème 5 : Agent orphelin (dans auth mais pas dans users)
**Symptôme** : L'agent existe dans auth.users mais pas dans la table users

**Solution** : Supprimer et recréer l'agent correctement depuis l'interface admin

### Étape 4 : Tester la Connexion

1. **Lance l'application Flutter**
```bash
cd Tokse_Project
flutter run
```

2. **Regarde les logs dans la console**
- Les nouveaux logs commencent par `[AGENT_LOGIN]`
- Ils te diront exactement où le problème se situe

3. **Messages à surveiller** :
```
✅ [AGENT_LOGIN] Auth réussie → L'authentification Supabase fonctionne
❌ [AGENT_LOGIN] Rôle incorrect → Le compte n'est pas un agent
❌ [AGENT_LOGIN] Compte désactivé → L'agent est désactivé
```

## 🚀 Créer un Nouvel Agent Proprement

Si tu veux créer un nouvel agent de test :

1. **Va dans l'interface admin TOKSE** (tokse-admin)
2. **Lance le serveur backend** :
   ```bash
   cd tokse-admin
   node server.js
   ```
3. **Connecte-toi comme autorité**
4. **Va dans "Gestion des Agents"**
5. **Clique sur "Créer un agent"**
6. **Remplis les informations** :
   - Email : utilisateur@example.com
   - Mot de passe : minimum 6 caractères (ex: Agent123!)
   - Nom et prénom
   - Téléphone (optionnel)
   - Secteur (optionnel)

7. **Après création, confirme l'email manuellement dans Supabase** :
```sql
UPDATE auth.users
SET email_confirmed_at = NOW()
WHERE email = 'utilisateur@example.com';
```

## 📱 Test de Connexion Mobile

Maintenant, depuis l'app mobile Flutter :

1. Sur l'écran de sélection de profil, choisis **"Je suis un Agent"**
2. Entre l'email et le mot de passe de l'agent
3. Regarde les logs dans la console pour voir où ça bloque
4. Si la connexion réussit, tu seras redirigé vers `/authority-home`

## 🆘 Besoin d'Aide ?

Si le problème persiste :
1. Copie les logs de la console Flutter (ceux avec `[AGENT_LOGIN]`)
2. Copie le résultat des requêtes SQL ci-dessus
3. Partage-les pour un diagnostic plus précis

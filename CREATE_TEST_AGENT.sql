-- ============================================
-- Script pour créer un agent de test fonctionnel
-- ============================================

-- ÉTAPE 1: Créer l'utilisateur dans auth.users
-- IMPORTANT: Tu dois exécuter cette requête via l'API Supabase Admin ou l'interface
-- Car on ne peut pas créer directement dans auth.users via SQL

-- MAIS on peut vérifier et corriger un agent existant :

-- ============================================
-- CORRIGER UN AGENT EXISTANT QUI NE PEUT PAS SE CONNECTER
-- ============================================

-- 1. Confirmer l'email de l'agent (si non confirmé)
UPDATE auth.users
SET email_confirmed_at = NOW(),
    confirmation_token = NULL
WHERE email = 'agent@test.com'; -- Remplace par l'email de ton agent

-- 2. Vérifier et activer l'agent dans la table users
UPDATE users
SET is_active = true,
    role = 'agent'
WHERE email = 'agent@test.com'; -- Remplace par l'email de ton agent

-- 3. Vérifier que tout est OK
SELECT 
  'auth.users' as source,
  id,
  email,
  email_confirmed_at,
  created_at
FROM auth.users
WHERE email = 'agent@test.com'

UNION ALL

SELECT 
  'users' as source,
  id,
  email,
  email_confirmed_at,
  created_at
FROM users
WHERE email = 'agent@test.com';

-- ============================================
-- SI L'AGENT N'EXISTE PAS DU TOUT
-- ============================================

-- Tu dois le créer via l'interface admin TOKSE
-- 1. Lance le serveur backend : cd tokse-admin && node server.js
-- 2. Connecte-toi comme autorité
-- 3. Va dans "Gestion des Agents"
-- 4. Clique sur "Créer un agent"
-- 5. Remplis les informations :
--    Email: agent@test.com
--    Password: Agent123! (minimum 6 caractères)
--    Nom: Test
--    Prénom: Agent
--    Secteur: Centre-ville (optionnel)

-- Puis exécute ce script pour confirmer l'email :
UPDATE auth.users
SET email_confirmed_at = NOW()
WHERE email = 'agent@test.com';

-- ============================================
-- VÉRIFICATIONS FINALES
-- ============================================

-- Vérifier que l'agent peut se connecter
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
  CASE 
    WHEN au.email_confirmed_at IS NULL THEN '❌ Email non confirmé'
    WHEN u.is_active = false THEN '❌ Compte désactivé'
    WHEN u.role != 'agent' THEN '❌ Pas un agent'
    ELSE '✅ Prêt à se connecter'
  END as statut
FROM users u
LEFT JOIN auth.users au ON u.id = au.id
WHERE u.email = 'agent@test.com';

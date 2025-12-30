-- ============================================================================
-- DIAGNOSTIC: Vérifier l'utilisateur et les permissions
-- ============================================================================

-- 1. Vérifier l'utilisateur dans auth.users
SELECT 
  id,
  email,
  created_at,
  confirmed_at,
  last_sign_in_at
FROM auth.users
WHERE id = '9e6d4042-811f-482d-97a9-921508999953';

-- 2. Vérifier l'utilisateur dans la table users (public)
SELECT 
  id,
  email,
  nom,
  prenom,
  role,
  created_at
FROM users
WHERE id = '9e6d4042-811f-482d-97a9-921508999953';

-- 3. Compter TOUS les signalements dans la base (sans RLS)
SELECT COUNT(*) as total_signalements
FROM signalements;

-- 4. Compter les signalements de cet utilisateur spécifique
SELECT COUNT(*) as mes_signalements
FROM signalements
WHERE user_id = '9e6d4042-811f-482d-97a9-921508999953';

-- 5. Voir les 5 derniers signalements de cet utilisateur
SELECT 
  id,
  titre,
  categorie,
  etat,
  user_id,
  created_at
FROM signalements
WHERE user_id = '9e6d4042-811f-482d-97a9-921508999953'
ORDER BY created_at DESC
LIMIT 5;

-- 6. Vérifier les politiques actuelles
SELECT 
  policyname,
  cmd,
  roles,
  permissive
FROM pg_policies
WHERE tablename = 'signalements'
ORDER BY cmd;

-- ============================================================================
-- INSTRUCTIONS:
-- 1. Exécutez ce script dans Supabase SQL Editor
-- 2. Envoyez-moi TOUS les résultats
-- 3. Je pourrai alors identifier le problème exact
-- ============================================================================

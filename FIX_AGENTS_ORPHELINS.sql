-- ============================================
-- SOLUTION COMPLÈTE POUR LES AGENTS ORPHELINS
-- Date: 2025-12-19
-- ============================================

-- ÉTAPE 1: SUPPRIMER LA CONTRAINTE (OBLIGATOIRE)
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check;

-- ÉTAPE 2a: SUPPRIMER les comptes Auth orphelins
-- Remplacez les emails par ceux de vos agents qui ont échoué
DELETE FROM auth.users 
WHERE email IN (
  'agent1@example.com',  -- REMPLACER par les vrais emails
  'agent2@example.com',
  'agent3@example.com'
) 
AND id NOT IN (SELECT id FROM users);

-- ÉTAPE 2b: OU RÉCUPÉRER les comptes orphelins (si vous voulez les garder)
-- Décommentez et adaptez cette requête si besoin
/*
INSERT INTO users (id, email, nom, prenom, telephone, role, is_active)
SELECT 
  id,
  email,
  raw_user_meta_data->>'nom',
  raw_user_meta_data->>'prenom',
  '+225XXXXXXXX',
  'agent',
  true
FROM auth.users
WHERE email IN ('agent1@example.com', 'agent2@example.com')
AND id NOT IN (SELECT id FROM users);
*/

-- ============================================
-- FIN
-- ============================================

DO $$
BEGIN
  RAISE NOTICE '✅ Contrainte supprimée';
  RAISE NOTICE '✅ Comptes orphelins nettoyés';
  RAISE NOTICE 'Vous pouvez maintenant recréer vos agents sans problème';
END $$;

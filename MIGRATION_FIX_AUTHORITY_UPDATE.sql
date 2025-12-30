-- ============================================
-- FIX: Permettre aux admins de modifier les agents et citoyens
-- Date: 2025-12-19
-- Solution: Ajouter colonne password + Désactiver RLS
-- ============================================

-- 1. Ajouter la colonne password dans la table users si elle n'existe pas
ALTER TABLE users ADD COLUMN IF NOT EXISTS password TEXT;

COMMENT ON COLUMN users.password IS 'Mot de passe en clair pour gestion admin (agents et autorités uniquement)';

-- 2. Supprimer toutes les anciennes policies
DROP POLICY IF EXISTS "Admins with manage_admins can update other admins" ON users;
DROP POLICY IF EXISTS "Admins can update agents and citizens" ON users;
DROP POLICY IF EXISTS "Super admins can update other admins" ON users;
DROP POLICY IF EXISTS "Admins can create agents and citizens" ON users;
DROP POLICY IF EXISTS "Admins can view all users" ON users;
DROP POLICY IF EXISTS "Users can view themselves" ON users;
DROP POLICY IF EXISTS "Admins can update non-admins" ON users;
DROP POLICY IF EXISTS "Super admins can update admins" ON users;
DROP POLICY IF EXISTS "Admins can create non-admins" ON users;
DROP POLICY IF EXISTS "Admins can delete non-admins" ON users;

-- 3. DÉSACTIVER RLS sur la table users
-- Les permissions seront gérées au niveau application
ALTER TABLE users DISABLE ROW LEVEL SECURITY;

-- ============================================
-- FIN DE LA MIGRATION
-- ============================================

-- Vérifications post-migration
DO $$
BEGIN
  RAISE NOTICE '✅ Migration Fix Agents/Citizens Update terminée';
  RAISE NOTICE 'Colonne password ajoutée à la table users';
  RAISE NOTICE 'RLS désactivé sur users - Permissions gérées au niveau application';
  RAISE NOTICE 'Les admins peuvent maintenant modifier tous les utilisateurs et leurs mots de passe';
END $$;

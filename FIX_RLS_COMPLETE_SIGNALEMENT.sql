-- ============================================================================
-- FIX COMPLET: Nettoyage et recréation des politiques RLS pour signalements
-- ============================================================================
-- Ce script supprime TOUTES les anciennes politiques et recrée un ensemble
-- propre et fonctionnel de politiques RLS

-- 1. SUPPRIMER TOUTES LES ANCIENNES POLITIQUES
DROP POLICY IF EXISTS "Authenticated users can create signalements" ON signalements;
DROP POLICY IF EXISTS "Citoyens peuvent créer signalements" ON signalements;
DROP POLICY IF EXISTS "Users can insert signalements" ON signalements;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON signalements;

DROP POLICY IF EXISTS "Anyone can view public signalements" ON signalements;
DROP POLICY IF EXISTS "Authorities can view all signalements" ON signalements;
DROP POLICY IF EXISTS "Autorités peuvent lire tous les signalements" ON signalements;
DROP POLICY IF EXISTS "Users can view own signalements" ON signalements;
DROP POLICY IF EXISTS "Autorités lecture par type" ON signalements;
DROP POLICY IF EXISTS "Autorités peuvent lire leurs signalements" ON signalements;

DROP POLICY IF EXISTS "Authorities can update signalements" ON signalements;
DROP POLICY IF EXISTS "Autorités peuvent modifier signalements" ON signalements;

-- 2. ACTIVER RLS sur la table
ALTER TABLE signalements ENABLE ROW LEVEL SECURITY;

-- 3. CRÉER LES NOUVELLES POLITIQUES PROPRES

-- ✅ INSERT: Tous les utilisateurs authentifiés peuvent créer des signalements
CREATE POLICY "authenticated_insert_signalements"
ON signalements
FOR INSERT
TO authenticated
WITH CHECK (
  user_id = auth.uid()
);

-- ✅ SELECT: Les autorités voient tous les signalements, les citoyens voient les leurs
CREATE POLICY "authenticated_select_signalements"
ON signalements
FOR SELECT
TO authenticated
USING (
  -- Les autorités peuvent voir tous les signalements
  EXISTS (
    SELECT 1 FROM users
    WHERE users.id = auth.uid()
    AND users.role IN ('police', 'hygiene', 'voirie', 'environnement', 'securite', 'mairie', 'admin', 'super_admin')
  )
  OR
  -- Les citoyens peuvent voir leurs propres signalements
  user_id = auth.uid()
);

-- ✅ UPDATE: Seules les autorités peuvent modifier les signalements
CREATE POLICY "authorities_update_signalements"
ON signalements
FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE users.id = auth.uid()
    AND users.role IN ('police', 'hygiene', 'voirie', 'environnement', 'securite', 'mairie', 'admin', 'super_admin')
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM users
    WHERE users.id = auth.uid()
    AND users.role IN ('police', 'hygiene', 'voirie', 'environnement', 'securite', 'mairie', 'admin', 'super_admin')
  )
);

-- 4. VÉRIFIER LES POLITIQUES FINALES
SELECT 
  policyname,
  cmd,
  roles,
  CASE 
    WHEN qual IS NULL THEN 'N/A'
    ELSE LEFT(qual, 100) || '...'
  END as using_clause,
  CASE 
    WHEN with_check IS NULL THEN 'N/A'
    ELSE LEFT(with_check, 100) || '...'
  END as with_check_clause
FROM pg_policies
WHERE tablename = 'signalements'
ORDER BY cmd, policyname;

-- ============================================================================
-- RÉSULTAT ATTENDU:
-- Vous devriez voir EXACTEMENT 3 politiques avec role {authenticated}:
-- 1. authenticated_insert_signalements (INSERT) - Tous les authentifiés
-- 2. authenticated_select_signalements (SELECT) - Autorités + propres signalements
-- 3. authorities_update_signalements (UPDATE) - Autorités uniquement
-- ============================================================================

-- ============================================================================
-- INSTRUCTIONS:
-- 1. Copiez tout ce code
-- 2. Allez dans Supabase Dashboard > SQL Editor
-- 3. Collez et exécutez ce script
-- 4. Vérifiez que vous voyez exactement 3 politiques
-- 5. Testez la création d'un signalement dans l'application mobile
-- 6. Le signalement devrait être créé sans erreur !
-- ============================================================================

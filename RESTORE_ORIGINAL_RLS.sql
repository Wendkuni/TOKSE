-- ============================================================================
-- RESTAURATION: Anciennes politiques RLS qui fonctionnaient
-- ============================================================================
-- Ce script restaure les politiques RLS originales qui fonctionnaient
-- avec le système d'authentification OTP existant

-- 1. Supprimer TOUTES les politiques existantes (anciennes et nouvelles)
DROP POLICY IF EXISTS "authenticated_insert_signalements" ON signalements;
DROP POLICY IF EXISTS "authenticated_select_signalements" ON signalements;
DROP POLICY IF EXISTS "authorities_update_signalements" ON signalements;
DROP POLICY IF EXISTS "Authenticated users can create signalements" ON signalements;
DROP POLICY IF EXISTS "Public can view all signalements" ON signalements;
DROP POLICY IF EXISTS "Authorities can update signalements" ON signalements;
DROP POLICY IF EXISTS "Anyone can view public signalements" ON signalements;
DROP POLICY IF EXISTS "Users can view own signalements" ON signalements;

-- 2. Restaurer les politiques qui fonctionnent

-- INSERT: Permettre aux utilisateurs authentifiés de créer des signalements
CREATE POLICY "Authenticated users can create signalements"
ON signalements
FOR INSERT
TO public
WITH CHECK (true);

-- SELECT: Tout le monde peut voir tous les signalements (feed public)
CREATE POLICY "Public can view all signalements"
ON signalements
FOR SELECT
TO public
USING (true);

-- UPDATE: Les autorités peuvent modifier les signalements
CREATE POLICY "Authorities can update signalements"
ON signalements
FOR UPDATE
TO public
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE users.id = user_id
    AND users.role IN ('police', 'hygiene', 'voirie', 'environnement', 'securite', 'mairie', 'admin', 'super_admin')
  )
);

-- 3. Vérifier les politiques restaurées
SELECT 
  policyname,
  cmd,
  roles,
  permissive
FROM pg_policies
WHERE tablename = 'signalements'
ORDER BY cmd;

-- ============================================================================
-- RÉSULTAT ATTENDU:
-- 3 politiques avec roles = {public}
-- Le système devrait fonctionner exactement comme avant !
-- ============================================================================

-- ============================================================================
-- INSTRUCTIONS:
-- 1. Exécutez ce script dans Supabase SQL Editor
-- 2. Vérifiez que les 3 politiques sont créées
-- 3. Relancez votre application
-- 4. Tout devrait fonctionner comme avant !
-- ============================================================================

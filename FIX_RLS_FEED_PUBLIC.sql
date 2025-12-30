-- ============================================================================
-- FIX: Permettre à TOUS les utilisateurs de voir TOUS les signalements
-- ============================================================================
-- Ce script modifie la politique SELECT pour créer un feed public où
-- tout le monde peut voir tous les signalements

-- 1. Supprimer l'ancienne politique SELECT restrictive
DROP POLICY IF EXISTS "authenticated_select_signalements" ON signalements;

-- 2. Créer une nouvelle politique SELECT pour un feed PUBLIC
CREATE POLICY "authenticated_select_signalements"
ON signalements
FOR SELECT
TO authenticated
USING (
  -- TOUS les utilisateurs authentifiés peuvent voir TOUS les signalements
  true
);

-- 3. Vérifier que la nouvelle politique est créée
SELECT 
  policyname,
  cmd,
  roles,
  permissive,
  qual
FROM pg_policies
WHERE tablename = 'signalements'
ORDER BY cmd;

-- ============================================================================
-- RÉSULTAT ATTENDU:
-- La politique "authenticated_select_signalements" devrait avoir qual = true
-- Cela signifie que TOUS les utilisateurs authentifiés peuvent voir
-- TOUS les signalements (feed public comme Facebook, Twitter, etc.)
-- ============================================================================

-- ============================================================================
-- INSTRUCTIONS:
-- 1. Exécutez ce script dans Supabase SQL Editor
-- 2. Vérifiez que la politique est créée avec qual = true
-- 3. Rechargez votre application mobile
-- 4. Vous devriez maintenant voir TOUS les 20 signalements !
-- 5. Vous devriez pouvoir créer de nouveaux signalements
-- ============================================================================

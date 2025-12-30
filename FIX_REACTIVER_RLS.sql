-- ============================================================================
-- FIX: Réactiver RLS et vérifier que tout fonctionne
-- ============================================================================

-- 1. RÉACTIVER RLS sur la table signalements
ALTER TABLE signalements ENABLE ROW LEVEL SECURITY;

-- 2. Vérifier que RLS est bien activé
SELECT 
  'RLS Status' as info,
  relrowsecurity as rls_enabled
FROM pg_class
WHERE relname = 'signalements';

-- 3. Vérifier les politiques actuelles
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
-- - rls_enabled devrait être TRUE
-- - Vous devriez voir 3 politiques avec {authenticated}
-- ============================================================================

-- ============================================================================
-- INSTRUCTIONS:
-- 1. Exécutez ce script dans Supabase SQL Editor
-- 2. Vérifiez que RLS est TRUE
-- 3. Rechargez votre application mobile
-- 4. Les signalements devraient maintenant être visibles
-- 5. Vous devriez pouvoir créer de nouveaux signalements
-- ============================================================================

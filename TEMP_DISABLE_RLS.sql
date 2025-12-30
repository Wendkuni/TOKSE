-- ============================================================================
-- FIX TEMPORAIRE: Désactiver RLS pour voir les signalements
-- ============================================================================
-- ⚠️ ATTENTION: Ce script désactive temporairement RLS pour diagnostic
-- NE PAS UTILISER EN PRODUCTION !

-- Désactiver temporairement RLS pour voir tous les signalements
ALTER TABLE signalements DISABLE ROW LEVEL SECURITY;

-- Vérifier
SELECT 
  'RLS Status' as info,
  relrowsecurity as rls_enabled
FROM pg_class
WHERE relname = 'signalements';

-- Compter les signalements maintenant visibles
SELECT COUNT(*) as total_visible
FROM signalements;

-- ============================================================================
-- APRÈS AVOIR VU LES SIGNALEMENTS, RÉACTIVER RLS:
-- ALTER TABLE signalements ENABLE ROW LEVEL SECURITY;
-- ============================================================================

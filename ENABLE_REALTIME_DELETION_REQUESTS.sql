-- ============================================
-- ACTIVER REALTIME POUR account_deletion_requests
-- Pour que les changements soient visibles instantanément dans le panel admin
-- Date: 2025-12-30
-- ============================================

-- 1. Activer la réplication pour la table account_deletion_requests
ALTER PUBLICATION supabase_realtime ADD TABLE account_deletion_requests;

-- 2. Vérifier que la réplication est activée
SELECT * FROM pg_publication_tables WHERE pubname = 'supabase_realtime';

-- 3. Message de succès
SELECT 'Realtime activé pour account_deletion_requests!' AS message;

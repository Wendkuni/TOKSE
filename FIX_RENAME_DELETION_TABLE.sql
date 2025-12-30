-- ============================================
-- FIX: Renommer deletion_requests en account_deletion_requests
-- Pour correspondre au code Flutter
-- Date: 2025-12-30
-- ============================================

-- 1. Renommer la table si elle existe sous l'ancien nom
DO $$
BEGIN
  IF EXISTS (SELECT FROM pg_tables WHERE tablename = 'deletion_requests') THEN
    ALTER TABLE deletion_requests RENAME TO account_deletion_requests;
    RAISE NOTICE 'Table renommée: deletion_requests -> account_deletion_requests';
  ELSE
    RAISE NOTICE 'Table deletion_requests n''existe pas, rien à renommer';
  END IF;
END $$;

-- 2. Renommer les index
DO $$
BEGIN
  IF EXISTS (SELECT FROM pg_indexes WHERE indexname = 'idx_deletion_requests_user_id') THEN
    ALTER INDEX idx_deletion_requests_user_id RENAME TO idx_account_deletion_requests_user_id;
  END IF;
  
  IF EXISTS (SELECT FROM pg_indexes WHERE indexname = 'idx_deletion_requests_status') THEN
    ALTER INDEX idx_deletion_requests_status RENAME TO idx_account_deletion_requests_status;
  END IF;
  
  IF EXISTS (SELECT FROM pg_indexes WHERE indexname = 'idx_deletion_requests_deletion_date') THEN
    ALTER INDEX idx_deletion_requests_deletion_date RENAME TO idx_account_deletion_requests_deletion_date;
  END IF;
  
  IF EXISTS (SELECT FROM pg_indexes WHERE indexname = 'idx_unique_pending_per_user') THEN
    ALTER INDEX idx_unique_pending_per_user RENAME TO idx_unique_pending_deletion_per_user;
  END IF;
END $$;

-- 3. Vérification
SELECT 
  'Table correctement renommée!' as status,
  tablename,
  schemaname
FROM pg_tables 
WHERE tablename = 'account_deletion_requests';

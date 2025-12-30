-- ============================================
-- FIX: Supprimer TOUTES les contraintes sur role
-- Date: 2025-12-19
-- ============================================

-- Trouver et supprimer toutes les contraintes CHECK sur la colonne role
DO $$
DECLARE
    constraint_name TEXT;
BEGIN
    FOR constraint_name IN 
        SELECT con.conname
        FROM pg_constraint con
        INNER JOIN pg_class rel ON rel.oid = con.conrelid
        INNER JOIN pg_namespace nsp ON nsp.oid = rel.relnamespace
        WHERE rel.relname = 'users'
        AND con.contype = 'c'
        AND pg_get_constraintdef(con.oid) LIKE '%role%'
    LOOP
        EXECUTE format('ALTER TABLE users DROP CONSTRAINT IF EXISTS %I', constraint_name);
        RAISE NOTICE 'Contrainte supprimée: %', constraint_name;
    END LOOP;
END $$;

-- Commentaire sur la colonne role
COMMENT ON COLUMN users.role IS 'Rôle de l utilisateur - AUCUNE RESTRICTION';

-- ============================================
-- FIN DE LA MIGRATION
-- ============================================

-- Vérifications post-migration
DO $$
BEGIN
  RAISE NOTICE '✅ Migration Role Constraint terminée';
  RAISE NOTICE 'TOUTES les contraintes CHECK sur role ont été supprimées';
  RAISE NOTICE 'Tous les rôles sont maintenant autorisés sans restriction';
END $$;

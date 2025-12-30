-- ============================================
-- FIX DÉFINITIF: Supprimer la contrainte users_role_check
-- Date: 2025-12-19
-- ============================================

-- Étape 1: Afficher toutes les contraintes CHECK sur la table users
DO $$
DECLARE
    constraint_record RECORD;
BEGIN
    RAISE NOTICE '📋 Contraintes CHECK existantes sur la table users:';
    RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
    
    FOR constraint_record IN
        SELECT conname, pg_get_constraintdef(oid) as definition
        FROM pg_constraint
        WHERE conrelid = 'users'::regclass
        AND contype = 'c'
    LOOP
        RAISE NOTICE 'Contrainte: % | Définition: %', constraint_record.conname, constraint_record.definition;
    END LOOP;
    
    RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
END $$;

-- Étape 2: Supprimer TOUTES les contraintes CHECK qui mentionnent 'role'
DO $$
DECLARE
    constraint_record RECORD;
BEGIN
    FOR constraint_record IN
        SELECT conname
        FROM pg_constraint
        WHERE conrelid = 'users'::regclass
        AND contype = 'c'
        AND pg_get_constraintdef(oid) ILIKE '%role%'
    LOOP
        EXECUTE format('ALTER TABLE users DROP CONSTRAINT IF EXISTS %I CASCADE', constraint_record.conname);
        RAISE NOTICE '✅ Contrainte supprimée: %', constraint_record.conname;
    END LOOP;
END $$;

-- Étape 3: Vérifier que toutes les contraintes ont été supprimées
DO $$
DECLARE
    constraint_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO constraint_count
    FROM pg_constraint
    WHERE conrelid = 'users'::regclass
    AND contype = 'c'
    AND pg_get_constraintdef(oid) ILIKE '%role%';
    
    IF constraint_count = 0 THEN
        RAISE NOTICE '✅ SUCCÈS: Toutes les contraintes sur role ont été supprimées!';
    ELSE
        RAISE WARNING '⚠️  ATTENTION: Il reste encore % contrainte(s) sur role', constraint_count;
    END IF;
END $$;

-- Étape 4: Créer une NOUVELLE contrainte qui INCLUT tous les rôles nécessaires
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_valid CASCADE;
ALTER TABLE users ADD CONSTRAINT users_role_valid 
    CHECK (role IN (
        'citizen',
        'citoyen', 
        'agent',
        'admin',
        'autorite',
        'police_municipale',
        'mairie',
        'hygiene',
        'voirie',
        'environnement',
        'securite'
    ));

-- Étape 5: Afficher le résultat final
DO $$
DECLARE
    constraint_record RECORD;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🎉 MIGRATION TERMINÉE';
    RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
    RAISE NOTICE '✅ Anciennes contraintes supprimées';
    RAISE NOTICE '✅ Nouvelle contrainte créée avec tous les rôles valides';
    RAISE NOTICE '';
    RAISE NOTICE '📋 Nouvelle contrainte:';
    
    FOR constraint_record IN
        SELECT conname, pg_get_constraintdef(oid) as definition
        FROM pg_constraint
        WHERE conrelid = 'users'::regclass
        AND contype = 'c'
        AND conname = 'users_role_valid'
    LOOP
        RAISE NOTICE '   Nom: %', constraint_record.conname;
        RAISE NOTICE '   Définition: %', constraint_record.definition;
    END LOOP;
    
    RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
END $$;

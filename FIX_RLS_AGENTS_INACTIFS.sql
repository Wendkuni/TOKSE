-- ============================================
-- FIX RAPIDE: Désactiver RLS et voir TOUS les agents
-- Date: 2025-12-19
-- ============================================

-- 1. Désactiver RLS sur users
ALTER TABLE users DISABLE ROW LEVEL SECURITY;

-- 2. Supprimer TOUTES les politiques RLS existantes
DO $$
DECLARE
    policy_record RECORD;
BEGIN
    FOR policy_record IN
        SELECT policyname
        FROM pg_policies
        WHERE tablename = 'users'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON users', policy_record.policyname);
        RAISE NOTICE '✅ Politique supprimée: %', policy_record.policyname;
    END LOOP;
END $$;

-- 3. Vérifier le résultat
SELECT 
    'RLS Status' as info,
    CASE 
        WHEN rowsecurity THEN '❌ RLS est ACTIF (problème!)'
        ELSE '✅ RLS est DÉSACTIVÉ (bon!)'
    END as status
FROM pg_tables
WHERE tablename = 'users';

-- 4. Compter les agents par statut
SELECT 
    'Agents par statut' as info,
    is_active,
    COUNT(*) as nombre,
    string_agg(nom || ' ' || prenom, ', ') as liste_agents
FROM users
WHERE role = 'agent'
GROUP BY is_active;

-- 5. Lister TOUS les agents avec détails
SELECT 
    id,
    nom,
    prenom,
    email,
    is_active,
    CASE 
        WHEN is_active THEN '✅ Actif'
        ELSE '❌ Inactif'
    END as statut,
    autorite_id,
    created_at
FROM users
WHERE role = 'agent'
ORDER BY is_active DESC, created_at DESC;

-- 6. Message de confirmation
DO $$
BEGIN
    RAISE NOTICE '🎉 Migration terminée!';
    RAISE NOTICE 'RLS désactivé sur la table users';
    RAISE NOTICE 'Tous les agents (actifs et inactifs) devraient maintenant être visibles';
END $$;

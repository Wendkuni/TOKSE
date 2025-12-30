-- ============================================
-- DIAGNOSTIC: Vérifier pourquoi les agents inactifs disparaissent
-- Date: 2025-12-19
-- ============================================

-- 1. Vérifier l'état de RLS sur la table users
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables
WHERE tablename = 'users';

-- 2. Lister toutes les politiques RLS sur users (si RLS est actif)
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE tablename = 'users'
ORDER BY policyname;

-- 3. Vérifier s'il y a des triggers qui pourraient supprimer les agents inactifs
SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement,
    action_timing
FROM information_schema.triggers
WHERE event_object_table = 'users'
ORDER BY trigger_name;

-- 4. Compter les agents par statut
SELECT 
    is_active,
    COUNT(*) as nombre_agents,
    string_agg(DISTINCT nom || ' ' || prenom, ', ') as agents
FROM users
WHERE role = 'agent'
GROUP BY is_active;

-- 5. Afficher TOUS les agents (actifs et inactifs)
SELECT 
    id,
    nom,
    prenom,
    email,
    role,
    is_active,
    autorite_id,
    created_at
FROM users
WHERE role = 'agent'
ORDER BY created_at DESC;

-- 6. Vérifier s'il y a une vue ou table matérialisée qui filtre
SELECT 
    viewname,
    definition
FROM pg_views
WHERE viewname LIKE '%agent%' OR viewname LIKE '%user%';

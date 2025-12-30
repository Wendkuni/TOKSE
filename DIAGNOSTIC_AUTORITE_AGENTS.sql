-- ============================================
-- DIAGNOSTIC: Pourquoi aucun agent n'apparaît dans l'interface
-- Date: 2025-12-19
-- ============================================

-- 1. Lister TOUTES les autorités
SELECT 
    '🔍 AUTORITÉS' as section,
    id,
    nom,
    prenom,
    email,
    role,
    autorite_type
FROM users
WHERE role IN ('admin', 'autorite', 'police_municipale', 'mairie', 'hygiene', 'voirie', 'environnement', 'securite')
ORDER BY created_at DESC;

-- 2. Lister TOUS les agents avec leur autorite_id
SELECT 
    '👥 AGENTS' as section,
    id,
    nom,
    prenom,
    email,
    is_active,
    autorite_id,
    CASE 
        WHEN autorite_id IS NULL THEN '❌ PAS D''AUTORITÉ ASSOCIÉE'
        ELSE '✅ Autorité: ' || autorite_id
    END as association
FROM users
WHERE role = 'agent'
ORDER BY created_at DESC;

-- 3. Vérifier les associations agents <-> autorités
SELECT 
    '🔗 ASSOCIATIONS' as section,
    a.email as autorite_email,
    a.nom || ' ' || a.prenom as autorite_nom,
    COUNT(u.id) as nombre_agents,
    string_agg(u.nom || ' ' || u.prenom || ' (' || CASE WHEN u.is_active THEN 'Actif' ELSE 'Inactif' END || ')', ', ') as liste_agents
FROM users a
LEFT JOIN users u ON u.autorite_id = a.id AND u.role = 'agent'
WHERE a.role IN ('autorite', 'police_municipale', 'mairie', 'hygiene', 'voirie', 'environnement', 'securite')
GROUP BY a.id, a.email, a.nom, a.prenom
ORDER BY nombre_agents DESC;

-- 4. Agents SANS autorité (orphelins de base de données)
SELECT 
    '⚠️ AGENTS SANS AUTORITÉ' as section,
    id,
    nom,
    prenom,
    email,
    is_active
FROM users
WHERE role = 'agent' AND autorite_id IS NULL;

-- 5. Statistiques générales
SELECT 
    '📊 STATISTIQUES' as section,
    'Total autorités' as type,
    COUNT(*) as nombre
FROM users
WHERE role IN ('autorite', 'police_municipale', 'mairie', 'hygiene', 'voirie', 'environnement', 'securite')
UNION ALL
SELECT 
    '📊 STATISTIQUES' as section,
    'Total agents' as type,
    COUNT(*) as nombre
FROM users
WHERE role = 'agent'
UNION ALL
SELECT 
    '📊 STATISTIQUES' as section,
    'Agents actifs' as type,
    COUNT(*) as nombre
FROM users
WHERE role = 'agent' AND is_active = true
UNION ALL
SELECT 
    '📊 STATISTIQUES' as section,
    'Agents inactifs' as type,
    COUNT(*) as nombre
FROM users
WHERE role = 'agent' AND is_active = false
UNION ALL
SELECT 
    '📊 STATISTIQUES' as section,
    'Agents sans autorité' as type,
    COUNT(*) as nombre
FROM users
WHERE role = 'agent' AND autorite_id IS NULL;

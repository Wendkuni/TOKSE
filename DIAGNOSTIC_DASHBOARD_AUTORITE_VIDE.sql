-- ===============================================
-- DIAGNOSTIC: Tableau de bord Autorité vide
-- Date: 2025-12-22
-- ===============================================

-- 🔍 ÉTAPE 1: Vérifier les autorités existantes
-- Objectif: Voir si des autorités existent et quel est leur role
SELECT 
    '👮 AUTORITÉS' as section,
    id,
    nom,
    prenom,
    email,
    role,
    autorite_type,
    zone_intervention,
    created_at
FROM users
WHERE role IN ('police', 'police_municipale', 'mairie', 'hygiene', 'voirie', 'environnement', 'securite', 'autorite')
ORDER BY created_at DESC;

-- 🔍 ÉTAPE 2: Vérifier TOUS les signalements
-- Objectif: Voir combien de signalements existent et leur autorite_type
SELECT 
    '📋 TOUS LES SIGNALEMENTS' as section,
    COUNT(*) as total,
    COUNT(CASE WHEN autorite_type IS NULL THEN 1 END) as sans_autorite,
    COUNT(CASE WHEN autorite_type IS NOT NULL THEN 1 END) as avec_autorite
FROM signalements;

-- 🔍 ÉTAPE 3: Répartition par autorite_type
-- Objectif: Voir les valeurs de autorite_type utilisées
SELECT 
    '📊 RÉPARTITION autorite_type' as section,
    COALESCE(autorite_type, 'NULL') as autorite_type,
    COUNT(*) as nombre
FROM signalements
GROUP BY autorite_type
ORDER BY nombre DESC;

-- 🔍 ÉTAPE 4: Derniers signalements avec détails
-- Objectif: Voir les valeurs exactes de autorite_type
SELECT 
    '📝 DERNIERS SIGNALEMENTS' as section,
    id,
    titre,
    categorie,
    etat,
    autorite_type,
    created_at
FROM signalements
ORDER BY created_at DESC
LIMIT 10;

-- 🔍 ÉTAPE 5: Tester une requête comme le fait le code
-- Objectif: Simuler ce que fait AutoriteDashboardPage
-- REMPLACEZ 'police' par le role de votre autorité de test
DO $$
DECLARE
    test_autorite_type TEXT := 'police'; -- CHANGEZ ICI selon votre autorité
    result_count INTEGER;
BEGIN
    -- Compter les signalements pour ce type d'autorité
    SELECT COUNT(*) INTO result_count
    FROM signalements
    WHERE autorite_type = test_autorite_type;
    
    RAISE NOTICE '🎯 Signalements pour autorite_type=% : %', test_autorite_type, result_count;
END $$;

-- ===============================================
-- 💡 SOLUTIONS POSSIBLES
-- ===============================================

-- SI aucun signalement n'a de autorite_type défini:
-- Il faut assigner automatiquement un autorite_type aux signalements

-- Solution temporaire pour les tests:
-- UPDATE signalements 
-- SET autorite_type = 'police' 
-- WHERE autorite_type IS NULL;

-- OU définir un autorite_type par défaut basé sur la catégorie:
-- UPDATE signalements 
-- SET autorite_type = CASE 
--     WHEN categorie = 'securite' THEN 'police'
--     WHEN categorie = 'proprete' THEN 'hygiene'
--     WHEN categorie = 'infrastructure' THEN 'voirie'
--     WHEN categorie = 'environnement' THEN 'environnement'
--     ELSE 'mairie'
-- END
-- WHERE autorite_type IS NULL;

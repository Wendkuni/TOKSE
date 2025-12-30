-- ============================================
-- VÉRIFICATION: Colonnes etat vs statut
-- Date: 2025-12-19
-- ============================================

-- 1. Vérifier la structure de la table signalements
SELECT 
    column_name,
    data_type
FROM information_schema.columns
WHERE table_name = 'signalements'
AND column_name IN ('etat', 'statut')
ORDER BY column_name;

-- 2. Vérifier la structure de la table interventions
SELECT 
    column_name,
    data_type
FROM information_schema.columns
WHERE table_name = 'interventions'
AND column_name IN ('etat', 'statut')
ORDER BY column_name;

-- 3. Valeurs possibles pour signalements.etat
SELECT DISTINCT etat, COUNT(*) as nombre
FROM signalements
GROUP BY etat
ORDER BY nombre DESC;

-- 4. Si la colonne statut existe aussi (problème!)
SELECT DISTINCT statut, COUNT(*) as nombre
FROM signalements
WHERE statut IS NOT NULL
GROUP BY statut
ORDER BY nombre DESC;

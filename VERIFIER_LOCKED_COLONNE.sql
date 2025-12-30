-- ============================================================================
-- VÉRIFICATION RAPIDE: Est-ce que la colonne locked existe ?
-- ============================================================================

-- 1. Vérifier si la colonne locked existe dans la table signalements
SELECT 
    column_name, 
    data_type, 
    column_default,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'signalements' 
  AND column_name = 'locked';

-- SI AUCUN RÉSULTAT → La colonne n'existe pas, vous devez exécuter la migration !
-- SI 1 RÉSULTAT → La colonne existe, vérifiez les données:

-- 2. Voir les signalements assignés avec leur valeur locked
SELECT 
    id,
    titre,
    etat,
    assigned_to,
    locked,
    created_at
FROM signalements
WHERE assigned_to IS NOT NULL
ORDER BY created_at DESC
LIMIT 10;

-- 3. Compter les signalements par valeur de locked
SELECT 
    locked,
    COUNT(*) as nombre
FROM signalements
WHERE assigned_to IS NOT NULL
GROUP BY locked;

-- ============================================================================
-- INTERPRÉTATION:
-- ============================================================================
-- 
-- Si la requête 1 ne retourne RIEN:
--   → La colonne locked n'existe pas
--   → Vous DEVEZ exécuter le fichier: MIGRATION_COMPLETE_LOCKED_SYSTEM.sql
-- 
-- Si la requête 1 retourne une ligne:
--   → La colonne existe
--   → Regardez les requêtes 2 et 3 pour voir les valeurs locked
--   → Tous les anciens signalements devraient avoir locked=false
--   → Les nouveaux signalements pris en charge auront locked=true
-- 
-- ============================================================================

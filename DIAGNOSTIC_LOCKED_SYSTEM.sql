-- ============================================================================
-- SCRIPT DE DIAGNOSTIC: Vérifier la configuration du système locked
-- ============================================================================

-- 1. Vérifier que la colonne locked existe
SELECT column_name, data_type, column_default, is_nullable
FROM information_schema.columns
WHERE table_name = 'signalements' 
  AND column_name = 'locked';

-- Si aucun résultat, la colonne n'existe pas !

-- 2. Vérifier les index
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'signalements'
  AND indexname LIKE '%locked%';

-- 3. Vérifier que la fonction take_charge_signalement existe
SELECT routine_name, routine_type, data_type as return_type
FROM information_schema.routines
WHERE routine_name = 'take_charge_signalement';

-- 4. Voir tous les signalements assignés avec leur état locked
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

-- 5. Compter les signalements par état et locked
SELECT 
  etat,
  locked,
  COUNT(*) as count
FROM signalements
WHERE assigned_to IS NOT NULL
GROUP BY etat, locked
ORDER BY etat, locked;

-- 6. Vérifier les buckets de storage
SELECT id, name, public, file_size_limit
FROM storage.buckets
WHERE name IN ('signalement-audios', 'signalements-photos');

-- ============================================================================
-- INTERPRÉTATION DES RÉSULTATS:
-- ============================================================================
-- 
-- Requête 1: Doit retourner une ligne avec:
--   column_name = 'locked'
--   data_type = 'boolean'
--   column_default = 'false'
--
-- Requête 2: Doit retourner au moins un index
--
-- Requête 3: Doit retourner une ligne avec:
--   routine_name = 'take_charge_signalement'
--   routine_type = 'FUNCTION'
--
-- Requête 4: Doit montrer les signalements avec leur état locked
--
-- Requête 5: Doit montrer la distribution des signalements
--
-- Requête 6: Doit montrer les deux buckets
--   - signalement-audios (pour les audios)
--   - signalements-photos (pour les images)

-- ============================================================================
-- SCRIPT COMPLET: Configuration de la prise en charge manuelle des signalements
-- Date: 2025-12-20
-- Description: Ajoute la colonne locked et corrige la fonction take_charge_signalement
-- ============================================================================

-- ============================================================================
-- PARTIE 1: AJOUT DE LA COLONNE LOCKED
-- ============================================================================

-- 1.1 Ajouter la colonne locked
ALTER TABLE signalements 
ADD COLUMN IF NOT EXISTS locked BOOLEAN DEFAULT FALSE NOT NULL;

-- 1.2 Ajouter un commentaire pour documenter la colonne
COMMENT ON COLUMN signalements.locked IS 
'Indique si le signalement a été pris en charge par l''agent assigné. FALSE = assigné mais pas encore pris en charge, TRUE = pris en charge activement';

-- 1.3 Créer un index pour optimiser les requêtes sur locked
CREATE INDEX IF NOT EXISTS idx_signalements_locked ON signalements(locked);

-- 1.4 Créer un index composite pour les requêtes d'agents
CREATE INDEX IF NOT EXISTS idx_signalements_assigned_locked 
ON signalements(assigned_to, locked) 
WHERE assigned_to IS NOT NULL;

-- 1.5 Mettre à jour les signalements existants déjà en cours
UPDATE signalements 
SET locked = TRUE 
WHERE etat = 'en_cours' AND assigned_to IS NOT NULL;

-- ============================================================================
-- PARTIE 2: FONCTION DE PRISE EN CHARGE
-- ============================================================================

-- 2.1 Suppression de l'ancienne fonction s'il y a un conflit
DROP FUNCTION IF EXISTS take_charge_signalement(UUID, UUID);

-- 2.2 Recréation de la fonction avec les bonnes colonnes
CREATE OR REPLACE FUNCTION take_charge_signalement(
  signalement_id UUID,
  authority_id UUID
)
RETURNS JSON AS $$
DECLARE
  result JSON;
  current_locked BOOLEAN;
  current_assigned_to UUID;
BEGIN
  -- Récupérer l'état actuel du signalement
  SELECT locked, assigned_to 
  INTO current_locked, current_assigned_to
  FROM signalements 
  WHERE id = signalement_id;
  
  -- Vérifier si le signalement existe
  IF NOT FOUND THEN
    RETURN json_build_object(
      'success', FALSE,
      'message', 'Signalement introuvable'
    );
  END IF;
  
  -- Vérifier si le signalement est déjà verrouillé par une autre autorité
  IF current_locked = TRUE AND current_assigned_to != authority_id THEN
    RETURN json_build_object(
      'success', FALSE,
      'message', 'Signalement déjà pris en charge par une autre autorité'
    );
  END IF;
  
  -- Mettre à jour le signalement
  UPDATE signalements
  SET 
    etat = 'en_cours',
    assigned_to = authority_id,
    locked = TRUE,
    updated_at = NOW()
  WHERE id = signalement_id
  RETURNING json_build_object(
    'success', TRUE,
    'message', 'Signalement pris en charge avec succès',
    'signalement_id', id,
    'assigned_to', assigned_to,
    'etat', etat,
    'locked', locked
  ) INTO result;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- PARTIE 3: VÉRIFICATIONS
-- ============================================================================

-- 3.1 Vérifier la structure de la table
SELECT 
  column_name, 
  data_type, 
  column_default, 
  is_nullable
FROM information_schema.columns
WHERE table_name = 'signalements' 
  AND column_name IN ('locked', 'assigned_to', 'etat')
ORDER BY ordinal_position;

-- 3.2 Vérifier les signalements par état locked
SELECT 
  locked,
  etat,
  COUNT(*) as count
FROM signalements
WHERE assigned_to IS NOT NULL
GROUP BY locked, etat
ORDER BY locked, etat;

-- 3.3 Vérifier que la fonction existe
SELECT 
  routine_name,
  routine_type,
  data_type as return_type
FROM information_schema.routines
WHERE routine_name = 'take_charge_signalement';

-- ============================================================================
-- FIN DU SCRIPT
-- ============================================================================

-- Instructions d'utilisation:
-- 1. Ouvrez votre dashboard Supabase
-- 2. Allez dans SQL Editor
-- 3. Copiez et exécutez ce script complet
-- 4. Vérifiez les résultats des requêtes de vérification
-- 5. Relancez votre application Flutter

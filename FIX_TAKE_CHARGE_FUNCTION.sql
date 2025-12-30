-- Correction de la fonction take_charge_signalement
-- Cette fonction doit utiliser les bonnes colonnes de la table signalements

-- Suppression de l'ancienne fonction s'il y a un conflit
DROP FUNCTION IF EXISTS take_charge_signalement(UUID, UUID);

-- Recréation de la fonction avec les bonnes colonnes
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
    locked = TRUE
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

-- Vérification : Afficher la structure de la table signalements pour s'assurer que la colonne locked existe
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'signalements' 
  AND column_name IN ('locked', 'assigned_to', 'etat')
ORDER BY ordinal_position;

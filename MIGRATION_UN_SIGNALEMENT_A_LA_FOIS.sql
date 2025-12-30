-- ============================================================================
-- MISE À JOUR: Empêcher la prise en charge de plusieurs signalements
-- ============================================================================

-- Supprimer l'ancienne fonction
DROP FUNCTION IF EXISTS take_charge_signalement(UUID, UUID);

-- Créer la nouvelle fonction avec vérification
CREATE OR REPLACE FUNCTION take_charge_signalement(
  signalement_id UUID,
  authority_id UUID
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  existing_mission_count INT;
  result JSON;
BEGIN
  -- Vérifier si l'agent a déjà un signalement en cours (locked=true et etat != 'resolu')
  SELECT COUNT(*) INTO existing_mission_count
  FROM signalements
  WHERE assigned_to = authority_id
    AND locked = true
    AND etat IN ('en_cours', 'en_attente');
  
  -- Si l'agent a déjà une mission en cours, refuser
  IF existing_mission_count > 0 THEN
    result := json_build_object(
      'success', false,
      'message', 'Vous avez déjà une mission en cours. Veuillez la terminer avant d''en prendre une nouvelle.'
    );
    RETURN result;
  END IF;
  
  -- Vérifier que le signalement est bien assigné à cet agent
  IF NOT EXISTS (
    SELECT 1 FROM signalements 
    WHERE id = signalement_id 
    AND assigned_to = authority_id
  ) THEN
    result := json_build_object(
      'success', false,
      'message', 'Ce signalement ne vous est pas assigné'
    );
    RETURN result;
  END IF;
  
  -- Vérifier que le signalement n'est pas déjà pris en charge
  IF EXISTS (
    SELECT 1 FROM signalements 
    WHERE id = signalement_id 
    AND locked = true
  ) THEN
    result := json_build_object(
      'success', false,
      'message', 'Ce signalement est déjà pris en charge'
    );
    RETURN result;
  END IF;
  
  -- Tout est OK, prendre en charge le signalement
  UPDATE signalements
  SET 
    locked = true,
    etat = 'en_cours',
    updated_at = NOW()
  WHERE id = signalement_id
    AND assigned_to = authority_id;
  
  -- Logger l'action
  INSERT INTO autorite_logs (autorite_id, action, signalement_id, details)
  VALUES (
    authority_id,
    'prise_en_charge',
    signalement_id,
    json_build_object('timestamp', NOW(), 'locked', true, 'etat', 'en_cours')
  );
  
  result := json_build_object(
    'success', true,
    'message', 'Signalement pris en charge avec succès'
  );
  
  RETURN result;
END;
$$;

-- ============================================================================
-- TEST: Vérifier la fonction
-- ============================================================================

-- Remplacer ces IDs par des vrais IDs de votre base
-- SELECT take_charge_signalement(
--   '1e131362-f301-4ad8-8814-93a7c2a0d6f0'::UUID,
--   '3cfb2a36-deaa-4c2b-87a3-68c5830500ff'::UUID
-- );

-- ============================================================================
-- RÉSULTAT ATTENDU:
-- ============================================================================
-- Si l'agent n'a pas de mission en cours:
--   {"success": true, "message": "Signalement pris en charge avec succès"}
--
-- Si l'agent a déjà une mission en cours:
--   {"success": false, "message": "Vous avez déjà une mission en cours..."}
-- ============================================================================

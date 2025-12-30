-- ============================================================================
-- FONCTION: Marquer un signalement comme résolu
-- ============================================================================

CREATE OR REPLACE FUNCTION resolve_signalement(
  signalement_id UUID,
  authority_id UUID,
  note TEXT DEFAULT NULL,
  photo_apres_url TEXT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  result JSON;
  v_note TEXT := note;
  v_photo_apres_url TEXT := photo_apres_url;
BEGIN
  -- Vérifier que le signalement est bien assigné à cette autorité
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
  
  -- Vérifier que le signalement est bien pris en charge (locked=true)
  IF NOT EXISTS (
    SELECT 1 FROM signalements 
    WHERE id = signalement_id 
    AND locked = true
  ) THEN
    result := json_build_object(
      'success', false,
      'message', 'Vous devez d''abord prendre en charge ce signalement'
    );
    RETURN result;
  END IF;
  
  -- Marquer comme résolu et déverrouiller pour permettre une nouvelle prise en charge
  UPDATE signalements
  SET 
    etat = 'resolu',
    locked = false,  -- Libérer l'autorité pour prendre un nouveau signalement
    note_resolution = v_note,
    photo_apres_url = v_photo_apres_url,
    resolved_at = NOW()
  WHERE id = signalement_id
    AND assigned_to = authority_id;
  
  -- Logger l'action (optionnel, commenté si la table n'existe pas)
  -- INSERT INTO autorite_logs (autorite_id, action, signalement_id, details)
  -- VALUES (
  --   authority_id,
  --   'resolution',
  --   signalement_id,
  --   json_build_object(
  --     'timestamp', NOW(), 
  --     'etat', 'resolu',
  --     'locked', false,
  --     'has_note', v_note IS NOT NULL,
  --     'has_photo', v_photo_apres_url IS NOT NULL
  --   )
  -- );
  
  result := json_build_object(
    'success', true,
    'message', 'Signalement marqué comme résolu'
  );
  
  RETURN result;
END;
$$;

-- ============================================================================
-- AJOUTER LES COLONNES SI ELLES N'EXISTENT PAS
-- ============================================================================

-- Colonne pour la note de résolution
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'signalements' 
    AND column_name = 'note_resolution'
  ) THEN
    ALTER TABLE signalements ADD COLUMN note_resolution TEXT;
    RAISE NOTICE 'Colonne note_resolution ajoutée';
  ELSE
    RAISE NOTICE 'Colonne note_resolution existe déjà';
  END IF;
END $$;

-- Colonne pour la photo après résolution
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'signalements' 
    AND column_name = 'photo_apres_url'
  ) THEN
    ALTER TABLE signalements ADD COLUMN photo_apres_url TEXT;
    RAISE NOTICE 'Colonne photo_apres_url ajoutée';
  ELSE
    RAISE NOTICE 'Colonne photo_apres_url existe déjà';
  END IF;
END $$;

-- Colonne pour la date de résolution
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'signalements' 
    AND column_name = 'resolved_at'
  ) THEN
    ALTER TABLE signalements ADD COLUMN resolved_at TIMESTAMP WITH TIME ZONE;
    RAISE NOTICE 'Colonne resolved_at ajoutée';
  ELSE
    RAISE NOTICE 'Colonne resolved_at existe déjà';
  END IF;
END $$;

-- ============================================================================
-- TEST DE LA FONCTION
-- ============================================================================

-- Remplacer par vos vrais IDs
-- SELECT resolve_signalement(
--   '1e131362-f301-4ad8-8814-93a7c2a0d6f0'::UUID,
--   '3cfb2a36-deaa-4c2b-87a3-68c5830500ff'::UUID,
--   'Problème résolu après nettoyage',
--   'https://exemple.com/photo_apres.jpg'
-- );

-- ============================================================================
-- RÉSULTATS ATTENDUS:
-- ============================================================================
-- Si succès:
--   {"success": true, "message": "Signalement marqué comme résolu"}
--   Le signalement aura: etat='resolu', locked=false
--
-- Si pas assigné:
--   {"success": false, "message": "Ce signalement ne vous est pas assigné"}
--
-- Si pas pris en charge:
--   {"success": false, "message": "Vous devez d'abord prendre en charge ce signalement"}
-- ============================================================================

-- ============================================
-- FONCTIONNALITÉ: Suppression de signalement par l'utilisateur
-- Conditions: < 1h après création ET état = "en_attente"
-- SOFT DELETE: Le signalement est marqué comme supprimé mais reste en DB
-- Date: 2025-12-30
-- ============================================

-- 0. Ajouter les colonnes pour le soft delete si elles n'existent pas
DO $$
BEGIN
  -- Colonne pour marquer comme supprimé par l'utilisateur
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'signalements' AND column_name = 'deleted_by_user') THEN
    ALTER TABLE signalements ADD COLUMN deleted_by_user BOOLEAN DEFAULT FALSE;
  END IF;
  
  -- Colonne pour la date de suppression
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'signalements' AND column_name = 'deleted_at') THEN
    ALTER TABLE signalements ADD COLUMN deleted_at TIMESTAMPTZ DEFAULT NULL;
  END IF;
  
  -- Colonne pour la raison de suppression (optionnel)
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'signalements' AND column_name = 'deletion_reason') THEN
    ALTER TABLE signalements ADD COLUMN deletion_reason TEXT DEFAULT NULL;
  END IF;
END $$;

-- 1. Fonction pour vérifier si un signalement peut être supprimé
CREATE OR REPLACE FUNCTION can_delete_signalement(p_signalement_id UUID, p_user_id UUID)
RETURNS TABLE (
  can_delete BOOLEAN,
  reason TEXT,
  minutes_remaining INT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_signalement RECORD;
  v_minutes_since_creation INT;
  v_minutes_remaining INT;
BEGIN
  -- Récupérer le signalement
  SELECT id, user_id, etat, created_at, deleted_by_user
  INTO v_signalement
  FROM signalements
  WHERE id = p_signalement_id;
  
  -- Vérifier si le signalement existe
  IF v_signalement.id IS NULL THEN
    RETURN QUERY SELECT FALSE, 'Signalement introuvable'::TEXT, 0;
    RETURN;
  END IF;
  
  -- Vérifier si déjà supprimé
  IF v_signalement.deleted_by_user = TRUE THEN
    RETURN QUERY SELECT FALSE, 'Ce signalement a déjà été supprimé'::TEXT, 0;
    RETURN;
  END IF;
  
  -- Vérifier si l'utilisateur est le propriétaire
  IF v_signalement.user_id != p_user_id THEN
    RETURN QUERY SELECT FALSE, 'Vous n''êtes pas le propriétaire de ce signalement'::TEXT, 0;
    RETURN;
  END IF;
  
  -- Vérifier l'état (doit être "en_attente")
  IF v_signalement.etat != 'en_attente' THEN
    RETURN QUERY SELECT FALSE, 'Ce signalement est déjà en cours de traitement et ne peut plus être supprimé'::TEXT, 0;
    RETURN;
  END IF;
  
  -- Calculer le temps écoulé depuis la création
  v_minutes_since_creation := EXTRACT(EPOCH FROM (NOW() - v_signalement.created_at)) / 60;
  v_minutes_remaining := 60 - v_minutes_since_creation;
  
  -- Vérifier si moins d'1 heure s'est écoulée
  IF v_minutes_since_creation >= 60 THEN
    RETURN QUERY SELECT FALSE, 'Le délai de suppression (1 heure) est dépassé'::TEXT, 0;
    RETURN;
  END IF;
  
  -- Toutes les conditions sont remplies
  RETURN QUERY SELECT TRUE, 'Suppression autorisée'::TEXT, v_minutes_remaining;
END;
$$;

-- 2. Fonction pour supprimer un signalement (SOFT DELETE)
-- Le signalement est marqué comme supprimé mais reste dans la base pour l'admin
CREATE OR REPLACE FUNCTION delete_user_signalement(p_signalement_id UUID, p_user_id UUID)
RETURNS TABLE (
  success BOOLEAN,
  message TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_can_delete BOOLEAN;
  v_reason TEXT;
BEGIN
  -- Vérifier si la suppression est autorisée
  SELECT cd.can_delete, cd.reason 
  INTO v_can_delete, v_reason
  FROM can_delete_signalement(p_signalement_id, p_user_id) cd;
  
  IF NOT v_can_delete THEN
    RETURN QUERY SELECT FALSE, v_reason;
    RETURN;
  END IF;
  
  -- SOFT DELETE: Marquer comme supprimé au lieu de supprimer physiquement
  UPDATE signalements
  SET 
    deleted_by_user = TRUE,
    deleted_at = NOW(),
    deletion_reason = 'Supprimé par l''utilisateur dans le délai d''1 heure'
  WHERE id = p_signalement_id AND user_id = p_user_id;
  
  -- Vérifier si la mise à jour a réussi
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Erreur lors de la suppression du signalement'::TEXT;
    RETURN;
  END IF;
  
  RETURN QUERY SELECT TRUE, 'Signalement supprimé avec succès'::TEXT;
END;
$$;

-- 3. Donner les permissions d'exécution
GRANT EXECUTE ON FUNCTION can_delete_signalement(UUID, UUID) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION delete_user_signalement(UUID, UUID) TO anon, authenticated;

-- 4. Créer un index pour améliorer les performances des requêtes
CREATE INDEX IF NOT EXISTS idx_signalements_deleted_by_user ON signalements(deleted_by_user);

-- 5. Vérification
SELECT 'Fonctions de suppression (soft delete) créées avec succès!' AS message;

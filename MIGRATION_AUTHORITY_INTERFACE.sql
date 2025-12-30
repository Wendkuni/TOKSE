-- Migration pour l'interface Autorité
-- Ajoute les colonnes nécessaires pour la gestion des signalements par les autorités

-- 1. Ajouter colonne assigned_to dans signalements
ALTER TABLE signalements 
ADD COLUMN IF NOT EXISTS assigned_to UUID REFERENCES users(id);

-- 2. Ajouter colonne locked pour éviter les prises en charge multiples
ALTER TABLE signalements 
ADD COLUMN IF NOT EXISTS locked BOOLEAN DEFAULT FALSE;

-- 3. Ajouter colonnes pour la résolution
ALTER TABLE signalements 
ADD COLUMN IF NOT EXISTS photo_apres TEXT,
ADD COLUMN IF NOT EXISTS note_resolution TEXT,
ADD COLUMN IF NOT EXISTS resolved_at TIMESTAMP WITH TIME ZONE;

-- 4. Ajouter colonne zone_intervention dans users
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS zone_intervention TEXT;

-- 5. Créer index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_signalements_assigned_to ON signalements(assigned_to);
CREATE INDEX IF NOT EXISTS idx_signalements_locked ON signalements(locked);
CREATE INDEX IF NOT EXISTS idx_users_zone_intervention ON users(zone_intervention);

-- 6. Ajouter contrainte CHECK pour les rôles d'autorité
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check;
ALTER TABLE users ADD CONSTRAINT users_role_check 
CHECK (role IN ('citizen', 'citoyen', 'police', 'hygiene', 'voirie', 'environnement', 'securite', 'admin'));

-- 7. Créer vue pour les statistiques autorité
CREATE OR REPLACE VIEW authority_stats AS
SELECT 
  assigned_to,
  COUNT(*) FILTER (WHERE statut = 'en_cours') AS signalements_en_cours,
  COUNT(*) FILTER (WHERE statut = 'resolu') AS signalements_resolus,
  COUNT(*) FILTER (WHERE statut = 'resolu' AND resolved_at >= CURRENT_DATE) AS resolus_aujourdhui,
  AVG(EXTRACT(EPOCH FROM (resolved_at - created_at))/3600) FILTER (WHERE statut = 'resolu') AS temps_moyen_resolution_heures
FROM signalements
WHERE assigned_to IS NOT NULL
GROUP BY assigned_to;

-- 8. Fonction pour verrouiller un signalement lors de la prise en charge
CREATE OR REPLACE FUNCTION take_charge_signalement(
  signalement_id UUID,
  authority_id UUID
)
RETURNS JSON AS $$
DECLARE
  result JSON;
BEGIN
  -- Vérifier si le signalement est déjà verrouillé
  IF EXISTS (SELECT 1 FROM signalements WHERE id = signalement_id AND locked = TRUE) THEN
    RAISE EXCEPTION 'Signalement déjà pris en charge par une autre autorité';
  END IF;
  
  -- Mettre à jour le signalement
  UPDATE signalements
  SET 
    statut = 'en_cours',
    assigned_to = authority_id,
    locked = TRUE,
    updated_at = NOW()
  WHERE id = signalement_id
  RETURNING json_build_object(
    'success', TRUE,
    'signalement_id', id,
    'assigned_to', assigned_to,
    'statut', statut
  ) INTO result;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9. Fonction pour marquer un signalement comme résolu
CREATE OR REPLACE FUNCTION resolve_signalement(
  signalement_id UUID,
  authority_id UUID,
  photo_apres_url TEXT DEFAULT NULL,
  note TEXT DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
  result JSON;
BEGIN
  -- Vérifier que c'est bien l'autorité assignée
  IF NOT EXISTS (
    SELECT 1 FROM signalements 
    WHERE id = signalement_id 
    AND assigned_to = authority_id
  ) THEN
    RAISE EXCEPTION 'Seule l''autorité assignée peut résoudre ce signalement';
  END IF;
  
  -- Mettre à jour le signalement
  UPDATE signalements
  SET 
    statut = 'resolu',
    photo_apres = photo_apres_url,
    note_resolution = note,
    resolved_at = NOW(),
    updated_at = NOW()
  WHERE id = signalement_id
  RETURNING json_build_object(
    'success', TRUE,
    'signalement_id', id,
    'statut', statut,
    'resolved_at', resolved_at
  ) INTO result;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 10. Policy RLS pour les autorités
ALTER TABLE signalements ENABLE ROW LEVEL SECURITY;

-- Les autorités peuvent voir tous les signalements de leur zone
CREATE POLICY "Authorities can view all signalements"
ON signalements FOR SELECT
TO authenticated
USING (
  TRUE -- Pour l'instant, toutes les autorités voient tous les signalements
  -- TODO: Filtrer par zone_intervention une fois configuré
);

-- Les autorités peuvent mettre à jour les signalements qu'elles ont pris en charge
CREATE POLICY "Authorities can update assigned signalements"
ON signalements FOR UPDATE
TO authenticated
USING (
  assigned_to = auth.uid()
)
WITH CHECK (
  assigned_to = auth.uid()
);

-- 11. Table pour l'historique des actions des autorités
CREATE TABLE IF NOT EXISTS authority_actions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  authority_id UUID NOT NULL REFERENCES users(id),
  signalement_id UUID NOT NULL REFERENCES signalements(id),
  action TEXT NOT NULL CHECK (action IN ('take_charge', 'resolve', 'update', 'reassign')),
  details JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_authority_actions_authority_id ON authority_actions(authority_id);
CREATE INDEX IF NOT EXISTS idx_authority_actions_signalement_id ON authority_actions(signalement_id);
CREATE INDEX IF NOT EXISTS idx_authority_actions_created_at ON authority_actions(created_at DESC);

-- 12. Trigger pour enregistrer les actions des autorités
CREATE OR REPLACE FUNCTION log_authority_action()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'UPDATE' AND OLD.assigned_to IS NULL AND NEW.assigned_to IS NOT NULL THEN
    -- Prise en charge
    INSERT INTO authority_actions (authority_id, signalement_id, action, details)
    VALUES (NEW.assigned_to, NEW.id, 'take_charge', json_build_object(
      'old_statut', OLD.statut,
      'new_statut', NEW.statut
    ));
  ELSIF TG_OP = 'UPDATE' AND OLD.statut != 'resolu' AND NEW.statut = 'resolu' THEN
    -- Résolution
    INSERT INTO authority_actions (authority_id, signalement_id, action, details)
    VALUES (NEW.assigned_to, NEW.id, 'resolve', json_build_object(
      'photo_apres', NEW.photo_apres,
      'note_resolution', NEW.note_resolution,
      'resolved_at', NEW.resolved_at
    ));
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS authority_action_log ON signalements;
CREATE TRIGGER authority_action_log
AFTER UPDATE ON signalements
FOR EACH ROW
EXECUTE FUNCTION log_authority_action();

-- 13. Afficher un résumé des modifications
SELECT 
  'Migration terminée : colonnes ajoutées (assigned_to, locked, photo_apres, note_resolution, resolved_at, zone_intervention)' AS status;

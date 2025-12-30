-- Migration pour ajouter les fonctionnalités admin

-- 1. Table des logs d'activité
CREATE TABLE IF NOT EXISTS logs_activite (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  type_action TEXT NOT NULL, -- 'desactivation_compte', 'reactivation_compte', 'creation_autorite', 'modification_role', 'traitement_signalement'
  utilisateur_cible_id UUID REFERENCES utilisateurs(id),
  autorite_id UUID REFERENCES utilisateurs(id),
  signalement_id UUID REFERENCES signalements(id),
  details JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Table des demandes de suppression de compte
CREATE TABLE IF NOT EXISTS demandes_suppression (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  utilisateur_id UUID REFERENCES utilisateurs(id) NOT NULL,
  statut TEXT DEFAULT 'en_attente', -- 'en_attente', 'traitee', 'annulee'
  raison TEXT,
  traite_par TEXT, -- 'admin' ou 'systeme'
  date_traitement TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Ajouter des colonnes à la table utilisateurs si elles n'existent pas
ALTER TABLE utilisateurs 
ADD COLUMN IF NOT EXISTS date_desactivation TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS en_attente_suppression BOOLEAN DEFAULT FALSE;

-- 4. Index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_logs_activite_type ON logs_activite(type_action);
CREATE INDEX IF NOT EXISTS idx_logs_activite_date ON logs_activite(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_logs_activite_utilisateur ON logs_activite(utilisateur_cible_id);
CREATE INDEX IF NOT EXISTS idx_demandes_suppression_statut ON demandes_suppression(statut);
CREATE INDEX IF NOT EXISTS idx_demandes_suppression_date ON demandes_suppression(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_utilisateurs_role ON utilisateurs(role);
CREATE INDEX IF NOT EXISTS idx_utilisateurs_actif ON utilisateurs(est_actif);

-- 5. Fonction pour désactiver automatiquement les comptes après 48h
CREATE OR REPLACE FUNCTION auto_deactivate_accounts()
RETURNS void AS $$
BEGIN
  -- Désactiver les comptes avec demande de suppression > 48h
  UPDATE utilisateurs u
  SET est_actif = FALSE,
      date_desactivation = NOW()
  FROM demandes_suppression ds
  WHERE u.id = ds.utilisateur_id
    AND ds.statut = 'en_attente'
    AND ds.created_at < NOW() - INTERVAL '48 hours'
    AND u.est_actif = TRUE;
  
  -- Marquer les demandes comme traitées
  UPDATE demandes_suppression
  SET statut = 'traitee',
      traite_par = 'systeme',
      date_traitement = NOW()
  WHERE statut = 'en_attente'
    AND created_at < NOW() - INTERVAL '48 hours';
    
  -- Logger l'action
  INSERT INTO logs_activite (type_action, utilisateur_cible_id, details)
  SELECT 
    'desactivation_compte',
    utilisateur_id,
    jsonb_build_object(
      'raison', 'Désactivation automatique après 48h',
      'timestamp', NOW()
    )
  FROM demandes_suppression
  WHERE statut = 'traitee'
    AND traite_par = 'systeme'
    AND date_traitement > NOW() - INTERVAL '1 minute';
END;
$$ LANGUAGE plpgsql;

-- 6. RLS (Row Level Security) Policies
ALTER TABLE logs_activite ENABLE ROW LEVEL SECURITY;
ALTER TABLE demandes_suppression ENABLE ROW LEVEL SECURITY;

-- Les admins peuvent tout voir
CREATE POLICY "Admins can view all logs"
  ON logs_activite FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM utilisateurs
      WHERE utilisateurs.id = auth.uid()
      AND utilisateurs.role = 'admin'
    )
  );

CREATE POLICY "Admins can insert logs"
  ON logs_activite FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM utilisateurs
      WHERE utilisateurs.id = auth.uid()
      AND utilisateurs.role = 'admin'
    )
  );

CREATE POLICY "Admins can view all deletion requests"
  ON demandes_suppression FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM utilisateurs
      WHERE utilisateurs.id = auth.uid()
      AND utilisateurs.role = 'admin'
    )
  );

CREATE POLICY "Users can create deletion requests"
  ON demandes_suppression FOR INSERT
  WITH CHECK (auth.uid() = utilisateur_id);

CREATE POLICY "Admins can update deletion requests"
  ON demandes_suppression FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM utilisateurs
      WHERE utilisateurs.id = auth.uid()
      AND utilisateurs.role = 'admin'
    )
  );

-- 7. Trigger pour vérifier les restrictions des comptes en attente de suppression
CREATE OR REPLACE FUNCTION check_account_pending_deletion()
RETURNS TRIGGER AS $$
BEGIN
  -- Vérifier si l'utilisateur est en attente de suppression
  IF EXISTS (
    SELECT 1 FROM demandes_suppression
    WHERE utilisateur_id = auth.uid()
    AND statut = 'en_attente'
  ) THEN
    -- Empêcher les modifications de profil
    IF TG_TABLE_NAME = 'utilisateurs' AND TG_OP = 'UPDATE' THEN
      IF NEW.nom != OLD.nom 
        OR NEW.prenom != OLD.prenom 
        OR NEW.email != OLD.email 
        OR NEW.photo_url != OLD.photo_url THEN
        RAISE EXCEPTION 'Impossible de modifier le profil: compte en attente de suppression';
      END IF;
    END IF;
    
    -- Empêcher la création de nouveaux signalements
    IF TG_TABLE_NAME = 'signalements' AND TG_OP = 'INSERT' THEN
      RAISE EXCEPTION 'Impossible de créer un signalement: compte en attente de suppression';
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Appliquer le trigger
DROP TRIGGER IF EXISTS check_deletion_on_profile_update ON utilisateurs;
CREATE TRIGGER check_deletion_on_profile_update
  BEFORE UPDATE ON utilisateurs
  FOR EACH ROW
  EXECUTE FUNCTION check_account_pending_deletion();

DROP TRIGGER IF EXISTS check_deletion_on_signalement_insert ON signalements;
CREATE TRIGGER check_deletion_on_signalement_insert
  BEFORE INSERT ON signalements
  FOR EACH ROW
  EXECUTE FUNCTION check_account_pending_deletion();

-- 8. Vue pour les statistiques admin
CREATE OR REPLACE VIEW admin_statistics AS
SELECT
  (SELECT COUNT(*) FROM utilisateurs WHERE est_actif = TRUE) AS total_utilisateurs_actifs,
  (SELECT COUNT(*) FROM utilisateurs WHERE role = 'citoyen' AND est_actif = TRUE) AS total_citoyens,
  (SELECT COUNT(*) FROM utilisateurs WHERE role != 'citoyen' AND role != 'admin' AND est_actif = TRUE) AS total_autorites,
  (SELECT COUNT(*) FROM signalements WHERE created_at >= CURRENT_DATE) AS signalements_aujourdhui,
  (SELECT COUNT(*) FROM signalements WHERE statut = 'en_cours') AS signalements_en_cours,
  (SELECT COUNT(*) FROM signalements WHERE statut = 'resolu') AS signalements_resolus,
  (SELECT COUNT(*) FROM signalements) AS total_signalements,
  (SELECT COUNT(*) FROM demandes_suppression WHERE statut = 'en_attente') AS demandes_suppression_en_attente;

-- Grant permissions sur la vue
GRANT SELECT ON admin_statistics TO authenticated;

COMMENT ON TABLE logs_activite IS 'Journal de toutes les actions administratives';
COMMENT ON TABLE demandes_suppression IS 'Demandes de suppression de compte utilisateur';
COMMENT ON FUNCTION auto_deactivate_accounts() IS 'Désactive automatiquement les comptes après 48h de demande de suppression';

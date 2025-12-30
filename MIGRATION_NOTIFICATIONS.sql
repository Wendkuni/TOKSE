-- Migration : Système de notifications pour les autorités
-- Date : 2025-12-23

-- 1. Créer la table notifications
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  authority_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('new', 'urgent', 'resolved', 'info', 'assigned')),
  signalement_id UUID REFERENCES signalements(id) ON DELETE CASCADE,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Index pour performances
CREATE INDEX IF NOT EXISTS idx_notifications_authority_id ON notifications(authority_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(type);
CREATE INDEX IF NOT EXISTS idx_notifications_signalement_id ON notifications(signalement_id);

-- 3. RLS (Row Level Security)
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Policy : Les autorités peuvent voir leurs propres notifications
CREATE POLICY "Autorités peuvent voir leurs notifications"
  ON notifications
  FOR SELECT
  USING (auth.uid() = authority_id);

-- Policy : Les autorités peuvent mettre à jour leurs notifications (marquer comme lu)
CREATE POLICY "Autorités peuvent mettre à jour leurs notifications"
  ON notifications
  FOR UPDATE
  USING (auth.uid() = authority_id);

-- Policy : Le système peut insérer des notifications
CREATE POLICY "Système peut créer des notifications"
  ON notifications
  FOR INSERT
  WITH CHECK (true);

-- Policy : Les autorités peuvent supprimer leurs notifications
CREATE POLICY "Autorités peuvent supprimer leurs notifications"
  ON notifications
  FOR DELETE
  USING (auth.uid() = authority_id);

-- 4. Fonction pour créer une notification automatiquement
CREATE OR REPLACE FUNCTION create_notification_for_new_signalement()
RETURNS TRIGGER AS $$
DECLARE
  authority_record RECORD;
BEGIN
  -- Créer une notification pour toutes les autorités de la même catégorie
  -- (police pour route, hygiène pour déchets, etc.)
  FOR authority_record IN 
    SELECT id FROM users 
    WHERE role IN ('police', 'hygiene', 'voirie', 'environnement', 'securite')
    AND status = 'active'
  LOOP
    INSERT INTO notifications (
      authority_id,
      title,
      message,
      type,
      signalement_id,
      is_read
    ) VALUES (
      authority_record.id,
      '🆕 Nouveau signalement',
      'Un nouveau signalement de ' || NEW.categorie || ' a été créé',
      'new',
      NEW.id,
      FALSE
    );
  END LOOP;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 5. Trigger pour créer une notification quand un nouveau signalement est créé
DROP TRIGGER IF EXISTS trigger_create_notification_new_signalement ON signalements;
CREATE TRIGGER trigger_create_notification_new_signalement
  AFTER INSERT ON signalements
  FOR EACH ROW
  EXECUTE FUNCTION create_notification_for_new_signalement();

-- 6. Fonction pour notifier l'autorité assignée
CREATE OR REPLACE FUNCTION notify_authority_on_assignment()
RETURNS TRIGGER AS $$
BEGIN
  -- Si un signalement est assigné à une autorité
  IF NEW.assigned_to IS NOT NULL AND (OLD.assigned_to IS NULL OR OLD.assigned_to != NEW.assigned_to) THEN
    INSERT INTO notifications (
      authority_id,
      title,
      message,
      type,
      signalement_id,
      is_read
    ) VALUES (
      NEW.assigned_to,
      '🎯 Signalement assigné',
      'Un signalement vous a été assigné',
      'assigned',
      NEW.id,
      FALSE
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 7. Trigger pour notifier lors de l'assignation
DROP TRIGGER IF EXISTS trigger_notify_on_assignment ON signalements;
CREATE TRIGGER trigger_notify_on_assignment
  AFTER UPDATE ON signalements
  FOR EACH ROW
  WHEN (NEW.assigned_to IS NOT NULL)
  EXECUTE FUNCTION notify_authority_on_assignment();

-- 8. Fonction pour notifier lors de la résolution
CREATE OR REPLACE FUNCTION notify_on_resolution()
RETURNS TRIGGER AS $$
BEGIN
  -- Si le signalement passe à résolu
  IF NEW.etat = 'resolu' AND OLD.etat != 'resolu' AND NEW.assigned_to IS NOT NULL THEN
    INSERT INTO notifications (
      authority_id,
      title,
      message,
      type,
      signalement_id,
      is_read
    ) VALUES (
      NEW.assigned_to,
      '✅ Mission complétée',
      'Le signalement a été marqué comme résolu',
      'resolved',
      NEW.id,
      FALSE
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 9. Trigger pour notifier lors de la résolution
DROP TRIGGER IF EXISTS trigger_notify_on_resolution ON signalements;
CREATE TRIGGER trigger_notify_on_resolution
  AFTER UPDATE ON signalements
  FOR EACH ROW
  WHEN (NEW.etat = 'resolu')
  EXECUTE FUNCTION notify_on_resolution();

-- 10. Fonction pour nettoyer les anciennes notifications (> 30 jours)
CREATE OR REPLACE FUNCTION cleanup_old_notifications()
RETURNS void AS $$
BEGIN
  DELETE FROM notifications
  WHERE created_at < NOW() - INTERVAL '30 days'
  AND is_read = TRUE;
END;
$$ LANGUAGE plpgsql;

-- 11. Fonction pour compter les notifications non lues
CREATE OR REPLACE FUNCTION get_unread_count(authority_user_id UUID)
RETURNS INTEGER AS $$
DECLARE
  unread_count INTEGER;
BEGIN
  SELECT COUNT(*)
  INTO unread_count
  FROM notifications
  WHERE authority_id = authority_user_id
  AND is_read = FALSE;
  
  RETURN unread_count;
END;
$$ LANGUAGE plpgsql;

-- Vérification
SELECT 'Migration notifications terminée avec succès!' AS status;

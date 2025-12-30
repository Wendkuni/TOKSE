-- ============================================
-- SYSTÈME COMPLET DE SUPPRESSION DE COMPTE
-- Avec notifications admin et suppression automatique après 48h
-- Date: 2025-12-30
-- ============================================

-- 1. Vérifier que la table account_deletion_requests existe
-- (Normalement déjà créée par MIGRATION_DELETION_REQUESTS.sql)
-- IMPORTANT: Utiliser account_deletion_requests (pas deletion_requests)

-- 2. Ajouter une politique pour que les admins voient toutes les demandes
DROP POLICY IF EXISTS "Admins can view all deletion requests" ON account_deletion_requests;
CREATE POLICY "Admins can view all deletion requests"
  ON account_deletion_requests
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role IN ('admin', 'super_admin')
    )
  );

-- 3. Créer une fonction pour notifier les admins lors d'une demande de suppression
CREATE OR REPLACE FUNCTION notify_admins_on_deletion_request()
RETURNS TRIGGER AS $$
DECLARE
  admin_record RECORD;
  user_email TEXT;
  user_name TEXT;
BEGIN
  -- Récupérer les infos de l'utilisateur qui demande la suppression
  SELECT email, nom, prenom 
  INTO user_email, user_name
  FROM users 
  WHERE id = NEW.user_id;
  
  -- Créer une notification pour chaque admin et super_admin
  FOR admin_record IN 
    SELECT id FROM users WHERE role IN ('admin', 'super_admin') AND is_active = true
  LOOP
    INSERT INTO notifications (
      user_id,
      type,
      titre,
      message,
      data,
      created_at
    ) VALUES (
      admin_record.id,
      'account_deletion_request',
      'Demande de suppression de compte',
      'L''utilisateur ' || COALESCE(user_name, user_email) || ' (' || user_email || ') a demandé la suppression de son compte. La suppression automatique est prévue le ' || 
        TO_CHAR(NEW.deletion_scheduled_for, 'DD/MM/YYYY à HH24:MI') || '.',
      jsonb_build_object(
        'user_id', NEW.user_id,
        'deletion_request_id', NEW.id,
        'deletion_scheduled_for', NEW.deletion_scheduled_for,
        'user_email', user_email
      ),
      NOW()
    );
  END LOOP;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Créer le trigger pour notifier les admins
DROP TRIGGER IF EXISTS trigger_notify_admins_deletion ON account_deletion_requests;
CREATE TRIGGER trigger_notify_admins_deletion
  AFTER INSERT ON account_deletion_requests
  FOR EACH ROW
  WHEN (NEW.status = 'pending')
  EXECUTE FUNCTION notify_admins_on_deletion_request();

-- 5. Créer une fonction pour supprimer automatiquement les comptes après 48h
CREATE OR REPLACE FUNCTION auto_delete_expired_accounts()
RETURNS void AS $$
DECLARE
  request_record RECORD;
  deleted_count INTEGER := 0;
BEGIN
  -- Trouver toutes les demandes pending dont la date de suppression est dépassée
  FOR request_record IN 
    SELECT dr.*, u.email, u.nom, u.prenom
    FROM account_deletion_requests dr
    JOIN users u ON u.id = dr.user_id
    WHERE dr.status = 'pending'
    AND dr.deletion_scheduled_for <= NOW()
  LOOP
    BEGIN
      -- Désactiver le compte (soft delete)
      UPDATE users 
      SET 
        is_active = false,
        updated_at = NOW()
      WHERE id = request_record.user_id;
      
      -- Marquer la demande comme complétée
      UPDATE account_deletion_requests
      SET 
        status = 'completed',
        completed_at = NOW()
      WHERE id = request_record.id;
      
      -- Logger l'action
      INSERT INTO logs_activite (
        type_action,
        description,
        details,
        created_at
      ) VALUES (
        'suppression_compte_auto',
        'Suppression automatique du compte après 48h',
        jsonb_build_object(
          'user_id', request_record.user_id,
          'email', request_record.email,
          'nom', request_record.nom,
          'prenom', request_record.prenom,
          'deletion_request_id', request_record.id
        ),
        NOW()
      );
      
      deleted_count := deleted_count + 1;
      
      RAISE NOTICE 'Compte % supprimé automatiquement', request_record.email;
      
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'Erreur suppression compte %: %', request_record.email, SQLERRM;
    END;
  END LOOP;
  
  RAISE NOTICE 'Auto-suppression terminée: % comptes traités', deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Créer une fonction pg_cron pour exécuter auto_delete_expired_accounts toutes les heures
-- NOTE: pg_cron doit être activé dans Supabase (Extensions > pg_cron)
-- Cette commande doit être exécutée par un super utilisateur dans Supabase Dashboard > SQL Editor

-- SELECT cron.schedule(
--   'auto-delete-expired-accounts',  -- nom du job
--   '0 * * * *',                      -- toutes les heures à minute 0
--   $$ SELECT auto_delete_expired_accounts(); $$
-- );

-- 7. Alternative : Créer une Edge Function Supabase à appeler toutes les heures
-- Créer un endpoint dans Supabase Edge Functions:
-- File: supabase/functions/auto-delete-accounts/index.ts

-- 8. Fonction pour permettre à l'utilisateur d'annuler sa demande
CREATE OR REPLACE FUNCTION cancel_deletion_request(request_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE account_deletion_requests
  SET 
    status = 'cancelled',
    cancelled_at = NOW()
  WHERE id = request_id
  AND user_id = auth.uid()
  AND status = 'pending';
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Demande de suppression introuvable ou déjà traitée';
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9. Fonction pour permettre à un admin de traiter immédiatement une demande
CREATE OR REPLACE FUNCTION admin_process_deletion_request(
  request_id UUID,
  approve BOOLEAN
)
RETURNS void AS $$
DECLARE
  request_user_id UUID;
  admin_id UUID := auth.uid();
BEGIN
  -- Vérifier que l'appelant est admin
  IF NOT EXISTS (
    SELECT 1 FROM users 
    WHERE id = admin_id 
    AND role IN ('admin', 'super_admin')
  ) THEN
    RAISE EXCEPTION 'Accès refusé: administrateur requis';
  END IF;
  
  -- Récupérer l'user_id de la demande
  SELECT user_id INTO request_user_id
  FROM account_deletion_requests
  WHERE id = request_id AND status = 'pending';
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Demande introuvable ou déjà traitée';
  END IF;
  
  IF approve THEN
    -- Approuver: désactiver le compte immédiatement
    UPDATE users SET is_active = false WHERE id = request_user_id;
    UPDATE account_deletion_requests 
    SET status = 'completed', completed_at = NOW()
    WHERE id = request_id;
    
    -- Logger
    INSERT INTO logs_activite (
      autorite_id,
      type_action,
      description,
      details
    ) VALUES (
      admin_id,
      'suppression_compte',
      'Suppression de compte approuvée par admin',
      jsonb_build_object('user_id', request_user_id, 'request_id', request_id)
    );
  ELSE
    -- Refuser: annuler la demande
    UPDATE account_deletion_requests 
    SET status = 'cancelled', cancelled_at = NOW()
    WHERE id = request_id;
    
    -- Logger
    INSERT INTO logs_activite (
      autorite_id,
      type_action,
      description,
      details
    ) VALUES (
      admin_id,
      'refus_suppression_compte',
      'Demande de suppression refusée par admin',
      jsonb_build_object('user_id', request_user_id, 'request_id', request_id)
    );
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 10. Vue pour les admins pour voir toutes les demandes de suppression
CREATE OR REPLACE VIEW admin_deletion_requests_view AS
SELECT 
  dr.id,
  dr.user_id,
  u.email,
  u.nom,
  u.prenom,
  u.telephone,
  u.is_active,
  dr.requested_at,
  dr.deletion_scheduled_for,
  dr.status,
  dr.cancelled_at,
  dr.completed_at,
  EXTRACT(EPOCH FROM (dr.deletion_scheduled_for - NOW())) / 3600 AS hours_remaining
FROM account_deletion_requests dr
JOIN users u ON u.id = dr.user_id
ORDER BY dr.requested_at DESC;

-- 11. Table pour les demandes de réactivation
CREATE TABLE IF NOT EXISTS account_reactivation_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  deletion_request_id UUID REFERENCES account_deletion_requests(id),
  requested_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  status VARCHAR(20) NOT NULL DEFAULT 'pending', -- 'pending', 'approved', 'rejected'
  processed_at TIMESTAMP WITH TIME ZONE,
  processed_by UUID REFERENCES users(id),
  reason TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Index pour les requêtes
CREATE INDEX IF NOT EXISTS idx_reactivation_requests_user_id ON account_reactivation_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_reactivation_requests_status ON account_reactivation_requests(status);

-- Une seule demande pending par utilisateur
CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_pending_reactivation_per_user 
  ON account_reactivation_requests(user_id) 
  WHERE status = 'pending';

-- RLS pour la table de réactivation
ALTER TABLE account_reactivation_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own reactivation requests"
  ON account_reactivation_requests FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create reactivation requests"
  ON account_reactivation_requests FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can view all reactivation requests"
  ON account_reactivation_requests FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role IN ('admin', 'super_admin')
    )
  );

CREATE POLICY "Admins can update reactivation requests"
  ON account_reactivation_requests FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role IN ('admin', 'super_admin')
    )
  );

-- 12. Fonction pour notifier les admins lors d'une demande de réactivation
CREATE OR REPLACE FUNCTION notify_admins_on_reactivation_request()
RETURNS TRIGGER AS $$
DECLARE
  admin_record RECORD;
  user_email TEXT;
  user_name TEXT;
BEGIN
  -- Récupérer les infos de l'utilisateur
  SELECT email, nom, prenom 
  INTO user_email, user_name
  FROM users 
  WHERE id = NEW.user_id;
  
  -- Créer une notification pour chaque admin et super_admin
  FOR admin_record IN 
    SELECT id FROM users WHERE role IN ('admin', 'super_admin') AND is_active = true
  LOOP
    INSERT INTO notifications (
      user_id,
      type,
      titre,
      message,
      data,
      created_at
    ) VALUES (
      admin_record.id,
      'account_reactivation_request',
      'Demande de réactivation de compte',
      'L''utilisateur ' || COALESCE(user_name, user_email) || ' (' || user_email || ') demande la réactivation de son compte.',
      jsonb_build_object(
        'user_id', NEW.user_id,
        'reactivation_request_id', NEW.id,
        'user_email', user_email
      ),
      NOW()
    );
  END LOOP;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 13. Trigger pour notifier les admins des demandes de réactivation
DROP TRIGGER IF EXISTS trigger_notify_admins_reactivation ON account_reactivation_requests;
CREATE TRIGGER trigger_notify_admins_reactivation
  AFTER INSERT ON account_reactivation_requests
  FOR EACH ROW
  WHEN (NEW.status = 'pending')
  EXECUTE FUNCTION notify_admins_on_reactivation_request();

-- 14. Fonction pour traiter une demande de réactivation (admin)
CREATE OR REPLACE FUNCTION admin_process_reactivation_request(
  request_id UUID,
  approve BOOLEAN
)
RETURNS void AS $$
DECLARE
  request_user_id UUID;
  admin_id UUID := auth.uid();
BEGIN
  -- Vérifier que l'appelant est admin
  IF NOT EXISTS (
    SELECT 1 FROM users 
    WHERE id = admin_id 
    AND role IN ('admin', 'super_admin')
  ) THEN
    RAISE EXCEPTION 'Accès refusé: administrateur requis';
  END IF;
  
  -- Récupérer l'user_id de la demande
  SELECT user_id INTO request_user_id
  FROM account_reactivation_requests
  WHERE id = request_id AND status = 'pending';
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Demande introuvable ou déjà traitée';
  END IF;
  
  IF approve THEN
    -- Approuver: réactiver le compte immédiatement
    UPDATE users SET is_active = true, updated_at = NOW() WHERE id = request_user_id;
    
    -- Annuler toutes les demandes de suppression pending pour cet utilisateur
    UPDATE account_deletion_requests 
    SET status = 'cancelled', cancelled_at = NOW()
    WHERE user_id = request_user_id AND status = 'pending';
    
    -- Marquer la demande de réactivation comme approuvée
    UPDATE account_reactivation_requests 
    SET 
      status = 'approved', 
      processed_at = NOW(),
      processed_by = admin_id
    WHERE id = request_id;
    
    -- Logger
    INSERT INTO logs_activite (
      autorite_id,
      type_action,
      description,
      details
    ) VALUES (
      admin_id,
      'reactivation_compte',
      'Réactivation de compte approuvée par admin',
      jsonb_build_object('user_id', request_user_id, 'request_id', request_id)
    );
  ELSE
    -- Refuser la demande de réactivation
    UPDATE account_reactivation_requests 
    SET 
      status = 'rejected', 
      processed_at = NOW(),
      processed_by = admin_id
    WHERE id = request_id;
    
    -- Logger
    INSERT INTO logs_activite (
      autorite_id,
      type_action,
      description,
      details
    ) VALUES (
      admin_id,
      'refus_reactivation_compte',
      'Demande de réactivation refusée par admin',
      jsonb_build_object('user_id', request_user_id, 'request_id', request_id)
    );
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 15. Fonction pour admin d'activer/désactiver manuellement un compte
CREATE OR REPLACE FUNCTION admin_toggle_account_status(
  target_user_id UUID,
  activate BOOLEAN
)
RETURNS void AS $$
DECLARE
  admin_id UUID := auth.uid();
  user_email TEXT;
BEGIN
  -- Vérifier que l'appelant est admin
  IF NOT EXISTS (
    SELECT 1 FROM users 
    WHERE id = admin_id 
    AND role IN ('admin', 'super_admin')
  ) THEN
    RAISE EXCEPTION 'Accès refusé: administrateur requis';
  END IF;
  
  -- Récupérer l'email de l'utilisateur
  SELECT email INTO user_email FROM users WHERE id = target_user_id;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Utilisateur introuvable';
  END IF;
  
  -- Activer ou désactiver le compte
  UPDATE users 
  SET is_active = activate, updated_at = NOW() 
  WHERE id = target_user_id;
  
  -- Si activation, annuler les demandes de suppression pending
  IF activate THEN
    UPDATE account_deletion_requests 
    SET status = 'cancelled', cancelled_at = NOW()
    WHERE user_id = target_user_id AND status = 'pending';
  END IF;
  
  -- Logger l'action
  INSERT INTO logs_activite (
    autorite_id,
    type_action,
    description,
    details
  ) VALUES (
    admin_id,
    CASE WHEN activate THEN 'activation_compte_manuel' ELSE 'desactivation_compte_manuel' END,
    CASE WHEN activate THEN 'Activation manuelle du compte par admin' ELSE 'Désactivation manuelle du compte par admin' END,
    jsonb_build_object('user_id', target_user_id, 'user_email', user_email, 'activated', activate)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 16. Vue pour les demandes de réactivation (admins)
CREATE OR REPLACE VIEW admin_reactivation_requests_view AS
SELECT 
  rr.id,
  rr.user_id,
  u.email,
  u.nom,
  u.prenom,
  u.telephone,
  u.is_active,
  rr.requested_at,
  rr.status,
  rr.processed_at,
  rr.processed_by,
  admin.email as processed_by_email,
  rr.reason
FROM account_reactivation_requests rr
JOIN users u ON u.id = rr.user_id
LEFT JOIN users admin ON admin.id = rr.processed_by
ORDER BY rr.requested_at DESC;

-- 17. Vérification finale
SELECT 
  'Système de suppression et réactivation installé avec succès!' as message,
  COUNT(*) as demandes_pending
FROM account_deletion_requests 
WHERE status = 'pending';

-- ============================================
-- INSTRUCTIONS D'ACTIVATION
-- ============================================
-- 1. Exécuter ce script dans Supabase SQL Editor
-- 2. Activer pg_cron dans Extensions (si pas déjà fait)
-- 3. Exécuter la commande cron.schedule (ligne 133) en tant que super user
-- 4. OU créer une Edge Function et l'appeler via un webhook externe toutes les heures
-- 5. Modifier l'interface admin pour afficher les demandes de suppression

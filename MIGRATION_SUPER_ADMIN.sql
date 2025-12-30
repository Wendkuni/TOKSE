-- ============================================
-- MIGRATION SUPER ADMIN - TOKSE
-- Ajout des fonctionnalités de gouvernance et audit
-- Date: 2025-12-18
-- ============================================

-- 1. Ajouter la colonne permissions dans la table users
ALTER TABLE users ADD COLUMN IF NOT EXISTS permissions JSONB DEFAULT '{
  "view_users": true,
  "manage_users": false,
  "view_authorities": true,
  "manage_authorities": false,
  "view_signalements": true,
  "manage_signalements": false,
  "view_logs": true,
  "manage_admins": false,
  "view_statistics": true,
  "export_data": false
}'::jsonb;

-- 2. Ajouter des types d'actions supplémentaires pour l'audit
COMMENT ON COLUMN logs_activite.type_action IS 'Types: creation_admin, suppression_admin, modification_permissions, desactivation_admin, reactivation_admin, creation_autorite, modification_role, desactivation_compte, reactivation_compte, traitement_signalement, suppression_compte';

-- 3. Créer un index sur autorite_id pour les requêtes d'audit
CREATE INDEX IF NOT EXISTS idx_logs_autorite ON logs_activite(autorite_id);
CREATE INDEX IF NOT EXISTS idx_logs_type_action ON logs_activite(type_action);
CREATE INDEX IF NOT EXISTS idx_logs_created_at ON logs_activite(created_at DESC);

-- 4. Vue pour les statistiques d'audit
CREATE OR REPLACE VIEW audit_statistics AS
SELECT
  (SELECT COUNT(*) FROM logs_activite) AS total_actions,
  (SELECT COUNT(DISTINCT autorite_id) FROM logs_activite WHERE created_at >= NOW() - INTERVAL '7 days') AS admins_actifs_7j,
  (SELECT COUNT(*) FROM logs_activite WHERE created_at >= CURRENT_DATE) AS actions_aujourdhui,
  (SELECT COUNT(*) FROM logs_activite WHERE type_action IN ('suppression_admin', 'modification_permissions', 'desactivation_admin', 'suppression_compte')) AS actions_sensibles,
  (SELECT COUNT(*) FROM users WHERE role = 'admin' AND is_active = TRUE) AS total_admins_actifs;

-- Grant permissions sur la vue
GRANT SELECT ON audit_statistics TO authenticated;

-- 5. Fonction pour valider les permissions d'un admin
CREATE OR REPLACE FUNCTION check_admin_permission(
  admin_id UUID,
  permission_key TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
  admin_permissions JSONB;
BEGIN
  -- Récupérer les permissions de l'admin
  SELECT permissions INTO admin_permissions
  FROM users
  WHERE id = admin_id AND role = 'admin';
  
  -- Si pas de permissions définies, refuser
  IF admin_permissions IS NULL THEN
    RETURN FALSE;
  END IF;
  
  -- Vérifier si la permission existe et est à true
  RETURN COALESCE((admin_permissions->permission_key)::boolean, FALSE);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. RLS Policy pour la gestion des admins
-- Seuls les admins avec manage_admins peuvent modifier les autres admins
CREATE POLICY "Admins with manage_admins can update other admins"
  ON users FOR UPDATE
  USING (
    role = 'admin' 
    AND EXISTS (
      SELECT 1 FROM users u
      WHERE u.id = auth.uid()
      AND u.role = 'admin'
      AND check_admin_permission(u.id, 'manage_admins')
    )
  );

-- 7. Policy pour l'export de données
CREATE POLICY "Admins with export_data can view all data"
  ON logs_activite FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
      AND check_admin_permission(users.id, 'export_data')
    )
  );

-- 8. Trigger pour logger toutes les modifications de permissions
CREATE OR REPLACE FUNCTION log_permission_change()
RETURNS TRIGGER AS $$
BEGIN
  -- Si les permissions ont changé
  IF OLD.permissions IS DISTINCT FROM NEW.permissions THEN
    INSERT INTO logs_activite (
      type_action,
      autorite_id,
      utilisateur_cible_id,
      details
    )
    VALUES (
      'modification_permissions',
      auth.uid(),
      NEW.id,
      jsonb_build_object(
        'old_permissions', OLD.permissions,
        'new_permissions', NEW.permissions,
        'timestamp', NOW()
      )
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Créer le trigger
DROP TRIGGER IF EXISTS trigger_log_permission_change ON users;
CREATE TRIGGER trigger_log_permission_change
  AFTER UPDATE ON users
  FOR EACH ROW
  WHEN (OLD.permissions IS DISTINCT FROM NEW.permissions)
  EXECUTE FUNCTION log_permission_change();

-- 9. Fonction pour obtenir l'historique d'actions d'un admin
CREATE OR REPLACE FUNCTION get_admin_action_history(
  admin_id UUID,
  days_back INTEGER DEFAULT 30
)
RETURNS TABLE (
  action_date TIMESTAMP WITH TIME ZONE,
  type_action TEXT,
  utilisateur_cible_nom TEXT,
  details JSONB
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    l.created_at,
    l.type_action,
    COALESCE(u.nom || ' ' || u.prenom, 'N/A') AS utilisateur_cible_nom,
    l.details
  FROM logs_activite l
  LEFT JOIN users u ON l.utilisateur_cible_id = u.id
  WHERE l.autorite_id = admin_id
    AND l.created_at >= NOW() - (days_back || ' days')::INTERVAL
  ORDER BY l.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 10. Vue pour le dashboard super admin
CREATE OR REPLACE VIEW super_admin_dashboard AS
SELECT
  -- Admins
  (SELECT COUNT(*) FROM users WHERE role = 'admin' AND is_active = TRUE) AS admins_actifs,
  (SELECT COUNT(*) FROM users WHERE role = 'admin') AS total_admins,
  
  -- Actions audit
  (SELECT COUNT(*) FROM logs_activite WHERE created_at >= CURRENT_DATE) AS actions_today,
  (SELECT COUNT(*) FROM logs_activite WHERE created_at >= NOW() - INTERVAL '7 days') AS actions_7days,
  
  -- Admins les plus actifs
  (
    SELECT json_agg(json_build_object(
      'admin_id', autorite_id,
      'count', action_count
    ))
    FROM (
      SELECT autorite_id, COUNT(*) as action_count
      FROM logs_activite
      WHERE created_at >= NOW() - INTERVAL '30 days'
      GROUP BY autorite_id
      ORDER BY action_count DESC
      LIMIT 5
    ) t
  ) AS top_admins_30days,
  
  -- Types d'actions les plus fréquentes
  (
    SELECT json_agg(json_build_object(
      'action', type_action,
      'count', action_count
    ))
    FROM (
      SELECT type_action, COUNT(*) as action_count
      FROM logs_activite
      WHERE created_at >= NOW() - INTERVAL '30 days'
      GROUP BY type_action
      ORDER BY action_count DESC
    ) t
  ) AS action_types_30days;

GRANT SELECT ON super_admin_dashboard TO authenticated;

-- 11. Commentaires
COMMENT ON FUNCTION check_admin_permission IS 'Vérifie si un admin possède une permission spécifique';
COMMENT ON FUNCTION get_admin_action_history IS 'Récupère l''historique des actions d''un admin sur une période donnée';
COMMENT ON VIEW audit_statistics IS 'Statistiques globales pour le système d''audit';
COMMENT ON VIEW super_admin_dashboard IS 'Dashboard super admin avec métriques et top performers';

-- 12. Accorder les permissions super admin au premier admin (à adapter)
-- ATTENTION: Remplacer 'admin@tokse.com' par l'email du super admin
UPDATE users 
SET permissions = '{
  "view_users": true,
  "manage_users": true,
  "view_authorities": true,
  "manage_authorities": true,
  "view_signalements": true,
  "manage_signalements": true,
  "view_logs": true,
  "manage_admins": true,
  "view_statistics": true,
  "export_data": true
}'::jsonb
WHERE email = 'admin@tokse.com' AND role = 'admin';

-- 13. Créer des index pour les performances
CREATE INDEX IF NOT EXISTS idx_users_role_active ON users(role, is_active);
CREATE INDEX IF NOT EXISTS idx_users_permissions ON users USING gin(permissions);

-- ============================================
-- FIN DE LA MIGRATION
-- ============================================

-- Vérifications post-migration
DO $$
BEGIN
  RAISE NOTICE '✅ Migration Super Admin terminée';
  RAISE NOTICE 'Total admins: %', (SELECT COUNT(*) FROM users WHERE role = 'admin');
  RAISE NOTICE 'Total logs: %', (SELECT COUNT(*) FROM logs_activite);
  RAISE NOTICE 'Permissions activées: OUI';
END $$;

-- Fix RLS pour permettre aux super_admin de voir les logs_activite

-- Option 1 : Désactiver complètement le RLS sur logs_activite (plus simple)
ALTER TABLE logs_activite DISABLE ROW LEVEL SECURITY;

-- OU

-- Option 2 : Garder le RLS mais autoriser les admins et super_admins à tout voir (plus sécurisé)
ALTER TABLE logs_activite ENABLE ROW LEVEL SECURITY;

-- Supprimer les anciennes politiques si elles existent
DROP POLICY IF EXISTS "Admins can view all logs" ON logs_activite;
DROP POLICY IF EXISTS "Admins can insert logs" ON logs_activite;

-- Créer des politiques pour les admins/super_admins
CREATE POLICY "Admins can view all logs" ON logs_activite
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role IN ('admin', 'super_admin')
    )
  );

CREATE POLICY "Admins can insert logs" ON logs_activite
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role IN ('admin', 'super_admin', 'police', 'police_municipale', 'hygiene', 'voirie', 'environnement', 'securite', 'mairie')
    )
  );

-- Vérification : tester si vous pouvez lire les logs
SELECT COUNT(*) as logs_visibles FROM logs_activite;

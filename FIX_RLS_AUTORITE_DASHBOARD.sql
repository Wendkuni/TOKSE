-- ============================================================================
-- FIX: Permissions RLS pour le panel autorité
-- ============================================================================
-- Ce script corrige les permissions Row Level Security (RLS) pour permettre
-- aux autorités de lire tous les signalements dans le dashboard

-- 1. Vérifier les politiques RLS existantes sur la table signalements
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE tablename = 'signalements';

-- 2. Activer RLS sur la table signalements (si pas déjà fait)
ALTER TABLE signalements ENABLE ROW LEVEL SECURITY;

-- 3. Supprimer les anciennes politiques restrictives si elles existent
DROP POLICY IF EXISTS "Autorités peuvent lire leurs signalements" ON signalements;
DROP POLICY IF EXISTS "Autorités lecture par type" ON signalements;

-- 4. Créer une politique permettant aux autorités de lire TOUS les signalements
CREATE POLICY "Autorités peuvent lire tous les signalements"
ON signalements
FOR SELECT
TO authenticated
USING (
  -- Les autorités (tous rôles sauf citizen) peuvent voir tous les signalements
  EXISTS (
    SELECT 1 FROM users
    WHERE users.id = auth.uid()
    AND users.role IN ('police', 'hygiene', 'voirie', 'environnement', 'securite', 'mairie', 'admin', 'super_admin')
  )
  OR
  -- Les citoyens peuvent voir leurs propres signalements
  user_id = auth.uid()
);

-- 5. Permettre aux autorités de mettre à jour les signalements
DROP POLICY IF EXISTS "Autorités peuvent modifier signalements" ON signalements;
CREATE POLICY "Autorités peuvent modifier signalements"
ON signalements
FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE users.id = auth.uid()
    AND users.role IN ('police', 'hygiene', 'voirie', 'environnement', 'securite', 'mairie', 'admin', 'super_admin')
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM users
    WHERE users.id = auth.uid()
    AND users.role IN ('police', 'hygiene', 'voirie', 'environnement', 'securite', 'mairie', 'admin', 'super_admin')
  )
);

-- 6. Vérifier que les politiques sont bien créées
SELECT 
  policyname,
  cmd,
  roles
FROM pg_policies
WHERE tablename = 'signalements'
ORDER BY policyname;

-- ============================================================================
-- INSTRUCTIONS:
-- 1. Copiez tout ce code
-- 2. Allez dans Supabase Dashboard > SQL Editor
-- 3. Collez et exécutez ce script
-- 4. Vérifiez les résultats de la dernière requête
-- 5. Rechargez le panel autorité dans le navigateur
-- ============================================================================

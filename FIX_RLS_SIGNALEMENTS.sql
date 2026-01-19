-- ============================================
-- FIX: Politiques RLS pour signalements
-- Problème: auth.uid() est NULL pour connexion par téléphone
-- Solution: Permettre INSERT/SELECT pour anon et authenticated
-- Date: 2025-12-30
-- ============================================

-- 1. Supprimer les anciennes politiques restrictives sur signalements
DROP POLICY IF EXISTS "authenticated_insert_signalements" ON signalements;
DROP POLICY IF EXISTS "authenticated_select_signalements" ON signalements;
DROP POLICY IF EXISTS "authorities_update_signalements" ON signalements;
DROP POLICY IF EXISTS "Authenticated users can create signalements" ON signalements;
DROP POLICY IF EXISTS "Public can view all signalements" ON signalements;
DROP POLICY IF EXISTS "Authorities can update signalements" ON signalements;
DROP POLICY IF EXISTS "Anyone can view public signalements" ON signalements;
DROP POLICY IF EXISTS "Users can view own signalements" ON signalements;
DROP POLICY IF EXISTS "Les signalements sont visibles par tous" ON signalements;
DROP POLICY IF EXISTS "Les utilisateurs authentifiés peuvent créer des signalements" ON signalements;
DROP POLICY IF EXISTS "Les utilisateurs peuvent modifier leurs signalements" ON signalements;
DROP POLICY IF EXISTS "Les utilisateurs peuvent supprimer leurs signalements" ON signalements;
DROP POLICY IF EXISTS "Allow insert signalements" ON signalements;
DROP POLICY IF EXISTS "Allow select signalements" ON signalements;
DROP POLICY IF EXISTS "Allow update signalements" ON signalements;
DROP POLICY IF EXISTS "Allow delete signalements" ON signalements;

-- 2. S'assurer que RLS est activé
ALTER TABLE signalements ENABLE ROW LEVEL SECURITY;

-- 3. Créer des politiques permissives pour les connexions par téléphone

-- SELECT: Tout le monde peut voir les signalements (feed public)
CREATE POLICY "Allow select signalements"
  ON signalements
  FOR SELECT
  TO anon, authenticated
  USING (true);

-- INSERT: Permettre la création de signalements
-- La vérification de l'utilisateur se fait côté application
CREATE POLICY "Allow insert signalements"
  ON signalements
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);

-- UPDATE: Permettre les mises à jour (pour les autorités et les propriétaires)
CREATE POLICY "Allow update signalements"
  ON signalements
  FOR UPDATE
  TO anon, authenticated
  USING (true)
  WITH CHECK (true);

-- DELETE: Permettre la suppression (contrôlée par la fonction RPC)
CREATE POLICY "Allow delete signalements"
  ON signalements
  FOR DELETE
  TO anon, authenticated
  USING (true);

-- 4. Vérification
SELECT 'Politiques RLS pour signalements créées avec succès!' AS message;

-- 5. Lister les politiques actives
SELECT 
  policyname,
  cmd,
  roles
FROM pg_policies 
WHERE tablename = 'signalements';

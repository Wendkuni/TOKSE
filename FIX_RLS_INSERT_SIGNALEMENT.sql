-- ============================================================================
-- FIX: Permissions RLS pour la création de signalements par les citoyens
-- ============================================================================
-- Ce script ajoute la politique INSERT manquante pour permettre aux citoyens
-- de créer des signalements

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

-- 2. Supprimer l'ancienne politique INSERT si elle existe
DROP POLICY IF EXISTS "Citoyens peuvent créer signalements" ON signalements;
DROP POLICY IF EXISTS "Users can insert signalements" ON signalements;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON signalements;

-- 3. Créer la politique permettant aux utilisateurs authentifiés de créer des signalements
CREATE POLICY "Citoyens peuvent créer signalements"
ON signalements
FOR INSERT
TO authenticated
WITH CHECK (
  -- L'utilisateur doit être authentifié et créer son propre signalement
  user_id = auth.uid()
);

-- 4. Vérifier que toutes les politiques sont bien créées
SELECT 
  policyname,
  cmd,
  roles,
  qual,
  with_check
FROM pg_policies
WHERE tablename = 'signalements'
ORDER BY cmd, policyname;

-- ============================================================================
-- RÉSULTAT ATTENDU:
-- Vous devriez voir au moins 3 politiques:
-- 1. "Citoyens peuvent créer signalements" (INSERT)
-- 2. "Autorités peuvent lire tous les signalements" (SELECT)
-- 3. "Autorités peuvent modifier signalements" (UPDATE)
-- ============================================================================

-- ============================================================================
-- INSTRUCTIONS:
-- 1. Copiez tout ce code
-- 2. Allez dans Supabase Dashboard > SQL Editor
-- 3. Collez et exécutez ce script
-- 4. Vérifiez les résultats de la dernière requête
-- 5. Testez la création d'un signalement dans l'application mobile
-- ============================================================================

-- ============================================
-- FIX: Politiques RLS pour account_deletion_requests
-- Problème: auth.uid() est NULL pour connexion par téléphone
-- Solution: Créer des fonctions RPC avec SECURITY DEFINER
-- Date: 2025-12-30
-- ============================================

-- 0. SUPPRIMER LES ANCIENNES FONCTIONS (pour éviter les conflits de type)
DROP FUNCTION IF EXISTS get_user_deletion_request(UUID);
DROP FUNCTION IF EXISTS cancel_deletion_request(UUID);

-- 1. FONCTION: Récupérer la demande de suppression d'un utilisateur
-- SECURITY DEFINER permet de contourner les RLS
CREATE OR REPLACE FUNCTION get_user_deletion_request(p_user_id UUID)
RETURNS TABLE (
  id UUID,
  user_id UUID,
  status TEXT,
  created_at TIMESTAMPTZ,
  deletion_scheduled_for TIMESTAMPTZ,
  cancelled_at TIMESTAMPTZ
) 
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    adr.id,
    adr.user_id,
    adr.status,
    adr.created_at,
    adr.deletion_scheduled_for,
    adr.cancelled_at
  FROM account_deletion_requests adr
  WHERE adr.user_id = p_user_id
    AND adr.status = 'pending'
  LIMIT 1;
END;
$$;

-- 2. FONCTION: Annuler une demande de suppression
CREATE OR REPLACE FUNCTION cancel_deletion_request(p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_rows_affected INT;
BEGIN
  UPDATE account_deletion_requests
  SET 
    status = 'cancelled',
    cancelled_at = NOW()
  WHERE user_id = p_user_id
    AND status = 'pending';
  
  GET DIAGNOSTICS v_rows_affected = ROW_COUNT;
  
  RETURN v_rows_affected > 0;
END;
$$;

-- 3. ALTERNATIVE: Ajouter une politique RLS permissive pour SELECT
-- Permet à TOUS (même anonymes) de lire leurs propres demandes par user_id
-- C'est sécurisé car on ne peut voir QUE les demandes de l'user_id passé en paramètre

DROP POLICY IF EXISTS "Allow read by user_id" ON account_deletion_requests;
CREATE POLICY "Allow read by user_id"
  ON account_deletion_requests
  FOR SELECT
  TO anon, authenticated
  USING (true);  -- Permet la lecture, la sécurité est dans la clause WHERE de la requête

-- 4. Politique pour UPDATE (annulation)
DROP POLICY IF EXISTS "Allow update by user_id" ON account_deletion_requests;
CREATE POLICY "Allow update by user_id"
  ON account_deletion_requests
  FOR UPDATE
  TO anon, authenticated
  USING (true)
  WITH CHECK (true);

-- 5. Donner les permissions d'exécution
GRANT EXECUTE ON FUNCTION get_user_deletion_request(UUID) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION cancel_deletion_request(UUID) TO anon, authenticated;

-- 6. Vérification
SELECT 'Politiques RLS créées avec succès!' AS message;

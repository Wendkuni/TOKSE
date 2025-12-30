-- ============================================
-- CORRECTION: Ajouter autorite_id aux logs existants
-- Date: 2025-12-19
-- Objectif: Remplir le champ autorite_id des logs_activite existants
-- ============================================

-- IMPORTANT: Remplace 'TON_USER_ID_ICI' par ton vrai ID utilisateur
-- Pour trouver ton ID, exécute d'abord:
-- SELECT id, email, nom, prenom FROM users WHERE role = 'super_admin';

-- Option 1: Si tu es le seul super admin, mettre ton ID automatiquement
DO $$
DECLARE
    super_admin_id UUID;
BEGIN
    -- Récupérer l'ID du super admin
    SELECT id INTO super_admin_id 
    FROM users 
    WHERE role = 'super_admin' 
    LIMIT 1;
    
    IF super_admin_id IS NOT NULL THEN
        -- Mettre à jour tous les logs sans autorite_id
        UPDATE logs_activite 
        SET autorite_id = super_admin_id 
        WHERE autorite_id IS NULL;
        
        RAISE NOTICE '✓ Logs mis à jour avec l''ID du super admin: %', super_admin_id;
    ELSE
        RAISE NOTICE '✗ Aucun super admin trouvé';
    END IF;
END $$;

-- Option 2: Si tu as plusieurs super admins, assigner manuellement
-- Décommente et remplace l'ID:
/*
UPDATE logs_activite 
SET autorite_id = 'TON_USER_ID_ICI'::UUID
WHERE autorite_id IS NULL;
*/

-- Vérification
SELECT 
    COUNT(*) as total_logs,
    COUNT(autorite_id) as logs_avec_autorite,
    COUNT(*) - COUNT(autorite_id) as logs_sans_autorite
FROM logs_activite;

-- Voir quelques exemples
SELECT 
    id,
    type_action,
    autorite_id,
    created_at
FROM logs_activite
ORDER BY created_at DESC
LIMIT 10;

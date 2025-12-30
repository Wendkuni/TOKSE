-- =====================================================
-- MIGRATION: Ajouter colonne assigned_to
-- Date: 2025-12-19
-- Description: Ajouter la colonne assigned_to pour 
--              l'assignation des signalements aux agents
-- =====================================================

-- 1. Ajouter la colonne assigned_to (nullable)
ALTER TABLE signalements 
ADD COLUMN IF NOT EXISTS assigned_to UUID REFERENCES users(id);

-- 2. Créer un index pour améliorer les performances des requêtes
CREATE INDEX IF NOT EXISTS idx_signalements_assigned_to 
ON signalements(assigned_to);

-- 3. Créer un index composé pour les requêtes fréquentes
CREATE INDEX IF NOT EXISTS idx_signalements_assigned_etat 
ON signalements(assigned_to, etat);

-- 4. Ajouter un commentaire pour documentation
COMMENT ON COLUMN signalements.assigned_to IS 
'ID de l''agent à qui le signalement est assigné';

-- 5. Vérifier que la colonne existe
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'signalements' 
AND column_name = 'assigned_to';

-- =====================================================
-- NOTE: Exécuter ce script dans Supabase SQL Editor
-- Chemin: Dashboard > SQL Editor > New Query
-- =====================================================

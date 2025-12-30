-- Migration: Ajouter la colonne locked à la table signalements
-- Cette colonne permet de gérer la prise en charge manuelle des signalements par les agents
-- Date: 2025-12-20

-- 1. Ajouter la colonne locked
ALTER TABLE signalements 
ADD COLUMN IF NOT EXISTS locked BOOLEAN DEFAULT FALSE NOT NULL;

-- 2. Ajouter un commentaire pour documenter la colonne
COMMENT ON COLUMN signalements.locked IS 
'Indique si le signalement a été pris en charge par l''agent assigné. FALSE = assigné mais pas encore pris en charge, TRUE = pris en charge activement';

-- 3. Créer un index pour optimiser les requêtes sur locked
CREATE INDEX IF NOT EXISTS idx_signalements_locked ON signalements(locked);

-- 4. Créer un index composite pour les requêtes d'agents
CREATE INDEX IF NOT EXISTS idx_signalements_assigned_locked 
ON signalements(assigned_to, locked) 
WHERE assigned_to IS NOT NULL;

-- 5. Mettre à jour les signalements existants déjà en cours
-- Les signalements avec statut 'en_cours' sont considérés comme déjà pris en charge
UPDATE signalements 
SET locked = TRUE 
WHERE statut = 'en_cours' AND assigned_to IS NOT NULL;

-- 6. Vérification: Afficher les colonnes de la table
SELECT column_name, data_type, column_default, is_nullable
FROM information_schema.columns
WHERE table_name = 'signalements' 
  AND column_name IN ('locked', 'assigned_to', 'statut', 'etat')
ORDER BY ordinal_position;

-- 7. Vérification: Compter les signalements par état locked
SELECT 
  locked,
  statut,
  COUNT(*) as count
FROM signalements
WHERE assigned_to IS NOT NULL
GROUP BY locked, statut
ORDER BY locked, statut;

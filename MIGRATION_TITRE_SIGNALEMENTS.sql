-- Migration: Ajouter le champ 'titre' à la table signalements
-- Date: November 13, 2025
-- Description: Ajoute un champ titre optionnel pour les signalements de catégorie "autre"

-- Ajouter la colonne titre
ALTER TABLE signalements ADD COLUMN IF NOT EXISTS titre TEXT;

-- Ajouter un commentaire sur la colonne
COMMENT ON COLUMN signalements.titre IS 'Titre du signalement (utilisé pour la catégorie "autre")';

-- Index sur titre pour les recherches (optionnel)
-- CREATE INDEX idx_signalements_titre ON signalements(titre) WHERE titre IS NOT NULL;

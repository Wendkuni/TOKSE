-- Migration pour ajouter le support des enregistrements vocaux
-- À exécuter dans l'éditeur SQL de Supabase

-- Ajouter les colonnes pour les enregistrements audio
ALTER TABLE signalements 
ADD COLUMN IF NOT EXISTS audio_url text,
ADD COLUMN IF NOT EXISTS audio_duration integer;

-- Ajouter des commentaires pour la documentation
COMMENT ON COLUMN signalements.audio_url IS 'URL du fichier audio enregistré (message vocal)';
COMMENT ON COLUMN signalements.audio_duration IS 'Durée de l''audio en secondes';

-- Créer un index pour optimiser les requêtes sur les signalements avec audio
CREATE INDEX IF NOT EXISTS idx_signalements_audio ON signalements(audio_url) WHERE audio_url IS NOT NULL;

-- Vérifier les colonnes ajoutées
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'signalements' 
AND column_name IN ('audio_url', 'audio_duration');

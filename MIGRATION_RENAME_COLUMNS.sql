-- Migration pour la table signalements
-- À exécuter dans l'éditeur SQL de Supabase

-- ÉTAPE 1: Vérifier d'abord les colonnes existantes
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'signalements'
ORDER BY ordinal_position;

-- RÉSULTAT: Les colonnes sont déjà en français !
-- ✅ categorie, description, photo_url, adresse, titre, felicitations, audio_url, audio_duration
-- ⚠️ SEULE DIFFÉRENCE: 'statut' au lieu de 'etat'

-- ÉTAPE 2: S'assurer que photo_url est OBLIGATOIRE (NOT NULL)
-- ET que description peut être null (car audio peut remplacer le texte)
ALTER TABLE signalements ALTER COLUMN description DROP NOT NULL;

-- ÉTAPE 3: Ajouter contrainte CHECK : au moins description OU audio doit être présent
ALTER TABLE signalements DROP CONSTRAINT IF EXISTS signalements_content_check;
ALTER TABLE signalements ADD CONSTRAINT signalements_content_check 
  CHECK (
    (description IS NOT NULL AND description != '') OR 
    (audio_url IS NOT NULL AND audio_url != '')
  );

-- ÉTAPE 4: Vérifier les valeurs actuelles de statut AVANT d'ajouter la contrainte
SELECT DISTINCT statut, COUNT(*) as count
FROM signalements
GROUP BY statut;

-- ÉTAPE 5: Corriger les valeurs invalides
-- Convertir 'nouveau' en 'en_attente' (valeur par défaut pour les nouveaux signalements)
UPDATE signalements SET statut = 'en_attente' WHERE statut = 'nouveau';
UPDATE signalements SET statut = 'en_attente' WHERE statut IS NULL OR statut = '';
UPDATE signalements SET statut = 'en_attente' WHERE statut NOT IN ('en_attente', 'en_cours', 'resolu', 'rejete');

-- ÉTAPE 6: Ajouter la contrainte sur le statut (après correction)
ALTER TABLE signalements DROP CONSTRAINT IF EXISTS signalements_statut_check;
ALTER TABLE signalements ADD CONSTRAINT signalements_statut_check 
  CHECK (statut IN ('en_attente', 'en_cours', 'resolu', 'rejete'));

-- ÉTAPE 7: Créer un index sur statut pour améliorer les performances (optionnel)
CREATE INDEX IF NOT EXISTS idx_signalements_statut ON signalements(statut);

-- ÉTAPE 8: Vérifier que tout est OK
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'signalements'
ORDER BY ordinal_position;

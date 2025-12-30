-- Créer le bucket pour les audios de signalements
-- Ce bucket stockera les enregistrements vocaux des descriptions de signalements

-- 1. Créer le bucket s'il n'existe pas
INSERT INTO storage.buckets (id, name, public)
VALUES ('signalement-audios', 'signalement-audios', true)
ON CONFLICT (id) DO NOTHING;

-- 2. Activer les politiques RLS sur le bucket
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- 3. Politique: Tout le monde peut lire les audios publics
CREATE POLICY "Les audios sont accessibles publiquement"
ON storage.objects FOR SELECT
USING (bucket_id = 'signalement-audios');

-- 4. Politique: Les utilisateurs authentifiés peuvent uploader des audios
CREATE POLICY "Les utilisateurs authentifiés peuvent uploader des audios"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'signalement-audios' 
  AND auth.role() = 'authenticated'
);

-- 5. Politique: Les utilisateurs peuvent supprimer leurs propres audios
CREATE POLICY "Les utilisateurs peuvent supprimer leurs propres audios"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'signalement-audios' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Vérification: Afficher les buckets existants
SELECT * FROM storage.buckets WHERE id = 'signalement-audios';

# 🎤 Configuration du Support Audio Vocal

## Statut actuel

✅ **Backend Flutter** : Prêt et configuré
- Le modèle `SignalementModel` a les champs `audioUrl` et `audioDuration`
- Le repository `SignalementsRepository` envoie déjà les données audio
- La fonction `createSignalement()` accepte les paramètres audio

## ⚠️ Action requise : Base de données Supabase

La table `signalements` dans Supabase doit avoir les colonnes suivantes :

### Colonnes nécessaires

| Colonne | Type | Nullable | Description |
|---------|------|----------|-------------|
| `audio_url` | `text` | ✅ Oui | URL ou chemin du fichier audio |
| `audio_duration` | `integer` | ✅ Oui | Durée de l'audio en secondes |

### 🔧 Migration à exécuter

1. **Ouvrez votre dashboard Supabase** : https://app.supabase.com
2. **Allez dans "SQL Editor"**
3. **Copiez et exécutez** le contenu du fichier `MIGRATION_ADD_AUDIO_COLUMNS.sql`

```sql
-- Migration pour ajouter le support des enregistrements vocaux
ALTER TABLE signalements 
ADD COLUMN IF NOT EXISTS audio_url text,
ADD COLUMN IF NOT EXISTS audio_duration integer;

-- Ajouter des commentaires
COMMENT ON COLUMN signalements.audio_url IS 'URL du fichier audio enregistré';
COMMENT ON COLUMN signalements.audio_duration IS 'Durée de l''audio en secondes';

-- Index pour optimiser les requêtes
CREATE INDEX IF NOT EXISTS idx_signalements_audio 
ON signalements(audio_url) WHERE audio_url IS NOT NULL;
```

4. **Cliquez sur "Run"** pour exécuter la migration

### 📦 Storage pour les fichiers audio (optionnel)

Si vous voulez stocker les fichiers audio dans Supabase Storage :

1. **Créez un bucket** nommé `audios` ou `signalements-audio`
2. **Configurez les politiques** :

```sql
-- Permettre l'upload d'audio
CREATE POLICY "Les utilisateurs authentifiés peuvent uploader des audios"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'audios' 
    AND auth.role() = 'authenticated'
  );

-- Permettre la lecture publique
CREATE POLICY "Les audios sont publics"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'audios');
```

### ✅ Vérification

Après la migration, vérifiez que tout fonctionne :

1. **Testez l'enregistrement vocal** dans l'app
2. **Vérifiez dans Supabase** → Table Editor → signalements
3. **Confirmez** que les colonnes `audio_url` et `audio_duration` sont présentes

### 📊 Structure finale de la table signalements

```
signalements
├── id (uuid, PK)
├── user_id (uuid, FK)
├── titre (text)
├── description (text)
├── categorie (text)
├── photo_url (text)
├── audio_url (text)           ← NOUVEAU
├── audio_duration (integer)    ← NOUVEAU
├── latitude (numeric)
├── longitude (numeric)
├── adresse (text)
├── etat (text)
├── felicitations (integer)
├── created_at (timestamptz)
└── updated_at (timestamptz)
```

### 🎯 Prochaines étapes

Une fois la migration exécutée :
1. ✅ L'enregistrement vocal sera sauvegardé en base
2. ✅ La durée sera stockée
3. ✅ Les signalements avec audio s'afficheront correctement
4. ✅ Le lecteur audio fonctionnera dans le feed et les détails

---

**Note** : Pour l'instant, l'audio est stocké localement sur l'appareil. Pour un vrai upload vers Supabase Storage, il faudra implémenter la fonction d'upload dans le repository.

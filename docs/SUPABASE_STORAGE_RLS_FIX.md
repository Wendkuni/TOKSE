## Correction: Erreur RLS sur Supabase Storage

### Erreur reçue:
```
StorageApiError: new row violates row-level security policy
```

### Cause:
Le bucket `signalements-photos` a des règles Row Level Security (RLS) trop restrictives qui empêchent l'upload.

### Solution - Désactiver RLS (pour développement)

1. **Aller sur Supabase Dashboard**
   - URL: https://supabase.com/dashboard

2. **Sélectionner ton projet "Tokse"**

3. **Aller à Storage → Buckets**

4. **Trouver le bucket "signalements-photos"**

5. **Cliquer sur ⚙️ (settings) du bucket**

6. **Chercher la section "Policies"**

7. **Supprimer ou désactiver les RLS restrictives**
   - Clique sur la politique restrictive
   - Clique sur "Delete" ou "Disable"

### Alternative - Ajouter une politique permissive

Si tu préfères garder RLS, ajoute cette politique:

**Pour les uploads:**
```sql
CREATE POLICY "Allow authenticated users to upload photos"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'signalements-photos' 
  AND (auth.uid()::text) = (storage.foldername(name))[1]
);
```

**Pour les lectures:**
```sql
CREATE POLICY "Allow anyone to read photos"
ON storage.objects FOR SELECT
TO authenticated, anon
USING (bucket_id = 'signalements-photos');
```

### Après correction:
Réessaie de créer un signalement - l'upload devrait fonctionner ! ✅

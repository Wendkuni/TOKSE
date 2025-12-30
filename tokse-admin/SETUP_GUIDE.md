# Guide de Configuration - TOKSE Admin Dashboard

## 🎯 Configuration Rapide (5 minutes)

### Étape 1: Configuration Supabase

1. **Aller dans votre dashboard Supabase**
   - URL: https://app.supabase.com

2. **Récupérer les credentials**
   - Project Settings → API
   - Copier:
     - Project URL
     - anon/public key

3. **Exécuter la migration SQL**
   - SQL Editor → New Query
   - Copier tout le contenu de `MIGRATION_ADMIN_FEATURES.sql`
   - Cliquer "Run"

### Étape 2: Configuration du projet

1. **Créer le fichier `.env`** dans `tokse-admin/`:
   ```bash
   cd tokse-admin
   touch .env  # ou créer manuellement
   ```

2. **Ajouter vos credentials**:
   ```env
   VITE_SUPABASE_URL=https://xxxxxxxxxxxxx.supabase.co
   VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
   ```

### Étape 3: Créer un compte admin

Dans Supabase SQL Editor:

```sql
-- Option 1: Via l'interface Auth (recommandé)
-- Aller dans Authentication → Users → Add user
-- Email: admin@tokse.com
-- Password: votre_mot_de_passe_securise
-- Copier l'ID créé

-- Ensuite, créer le profil:
INSERT INTO utilisateurs (id, email, nom, prenom, role, est_actif)
VALUES (
  'COLLER_L_ID_COPIE_ICI',
  'admin@tokse.com',
  'Admin',
  'Tokse',
  'admin',
  TRUE
);

-- Option 2: Via SQL direct (si vous avez les extensions)
-- Créer l'auth user
INSERT INTO auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  created_at,
  updated_at
)
VALUES (
  '00000000-0000-0000-0000-000000000000',
  gen_random_uuid(),
  'authenticated',
  'authenticated',
  'admin@tokse.com',
  crypt('VotreMotDePasse123!', gen_salt('bf')),
  NOW(),
  NOW(),
  NOW()
)
RETURNING id;  -- Notez cet ID

-- Créer le profil avec l'ID récupéré
INSERT INTO utilisateurs (id, email, nom, prenom, role, est_actif)
VALUES (
  'ID_RECUPERE_CI_DESSUS',
  'admin@tokse.com',
  'Admin',
  'Tokse',
  'admin',
  TRUE
);
```

### Étape 4: Lancer l'application

```bash
cd tokse-admin
npm install
npm run dev
```

Ouvrir: http://localhost:5173

### Étape 5: Première connexion

- Email: `admin@tokse.com`
- Password: celui que vous avez configuré

---

## 🔧 Configuration avancée

### Cron Job pour auto-désactivation

Pour que la désactivation automatique fonctionne, configurer un cron job Supabase:

1. **Database → Extensions** → Activer `pg_cron`

2. **SQL Editor** → Exécuter:
   ```sql
   -- Exécuter la fonction toutes les heures
   SELECT cron.schedule(
     'auto-deactivate-accounts',
     '0 * * * *',  -- Toutes les heures
     $$SELECT auto_deactivate_accounts()$$
   );
   ```

### Configurer les emails Supabase

Pour les notifications par email:

1. **Authentication → Email Templates**
2. Configurer SMTP custom ou utiliser Supabase SMTP
3. Personnaliser les templates

### RLS (Row Level Security)

Vérifier que RLS est activé sur toutes les tables:

```sql
-- Vérifier le statut RLS
SELECT schemaname, tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN ('logs_activite', 'demandes_suppression', 'utilisateurs');

-- Si rowsecurity = false, activer:
ALTER TABLE logs_activite ENABLE ROW LEVEL SECURITY;
ALTER TABLE demandes_suppression ENABLE ROW LEVEL SECURITY;
```

---

## 🐛 Problèmes courants

### "Missing Supabase environment variables"

**Solution:**
1. Vérifier que `.env` existe dans `tokse-admin/`
2. Vérifier les noms des variables: `VITE_SUPABASE_URL` et `VITE_SUPABASE_ANON_KEY`
3. Redémarrer le serveur dev: `npm run dev`

### "Accès refusé. Seuls les administrateurs..."

**Solution:**
1. Vérifier que l'utilisateur a bien le rôle `admin`:
   ```sql
   SELECT id, email, role FROM utilisateurs WHERE email = 'admin@tokse.com';
   ```
2. Si le rôle n'est pas `admin`, le corriger:
   ```sql
   UPDATE utilisateurs SET role = 'admin' WHERE email = 'admin@tokse.com';
   ```

### Impossible de voir les logs

**Solution:**
Vérifier les RLS policies:
```sql
-- Créer la policy si elle n'existe pas
CREATE POLICY "Admins can view all logs"
  ON logs_activite FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM utilisateurs
      WHERE utilisateurs.id = auth.uid()
      AND utilisateurs.role = 'admin'
    )
  );
```

### Tailwind ne fonctionne pas

**Solution:**
1. Vérifier que `tailwind.config.js` existe
2. Vérifier que `postcss.config.js` existe
3. Dans `src/index.css`, vérifier les imports:
   ```css
   @tailwind base;
   @tailwind components;
   @tailwind utilities;
   ```
4. Redémarrer: `npm run dev`

---

## 📝 Checklist de déploiement

Avant de déployer en production:

- [ ] Modifier le mot de passe admin par défaut
- [ ] Configurer SMTP custom pour les emails
- [ ] Activer le cron job pour auto-désactivation
- [ ] Vérifier toutes les RLS policies
- [ ] Tester la création d'autorité
- [ ] Tester la désactivation/réactivation de compte
- [ ] Tester le système de demande de suppression
- [ ] Configurer les variables d'environnement sur la plateforme de déploiement
- [ ] Activer HTTPS
- [ ] Configurer un domaine custom

---

## 🔐 Sécurité Production

### Variables d'environnement

Ne JAMAIS commiter le fichier `.env` !

Ajouter à `.gitignore`:
```
.env
.env.local
.env.production
```

### Rotate les clés Supabase

Après déploiement:
1. Générer de nouvelles clés dans Supabase
2. Mettre à jour dans le `.env` de production
3. Invalider les anciennes clés

### Rate Limiting

Configurer dans Supabase:
- Authentication → Rate Limits
- API → Rate Limits

---

## 📞 Support

En cas de problème:
1. Vérifier les logs du navigateur (F12 → Console)
2. Vérifier les logs Supabase (Database → Logs)
3. Consulter le README principal
4. Créer une issue sur le repo

---

**Développé par AMIR TECH**  
TOKSE Project © 2025

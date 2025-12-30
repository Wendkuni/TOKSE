# Configuration Supabase pour TOKSE Flutter

## 🔑 Variables d'environnement

Pour configurer votre connexion Supabase, vous devez obtenir vos clés API depuis votre dashboard Supabase.

### 1. Obtenir vos clés Supabase

1. Allez sur [https://app.supabase.com](https://app.supabase.com)
2. Sélectionnez votre projet
3. Allez dans **Settings** → **API**
4. Copiez :
   - **Project URL** (URL)
   - **anon/public key** (Clé publique)

### 2. Configurer l'application

Éditez le fichier `lib/core/config/supabase_config.dart` :

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // ⚠️ REMPLACEZ CES VALEURS PAR VOS VRAIES CLÉS
  static const String supabaseUrl = 'https://votre-projet.supabase.co';
  static const String supabaseAnonKey = 'votre-cle-anon-publique';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        autoRefreshToken: true,
        persistSession: true,
      ),
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
```

## 📊 Structure de la base de données

### Table : profiles

```sql
CREATE TABLE profiles (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  name text NOT NULL,
  phone text UNIQUE NOT NULL,
  role text DEFAULT 'citizen' CHECK (role IN ('citizen', 'authority', 'admin')),
  avatar_url text,
  bio text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now()
);

-- Index pour les recherches rapides
CREATE INDEX idx_profiles_phone ON profiles(phone);
CREATE INDEX idx_profiles_role ON profiles(role);
```

### Table : signalements

```sql
CREATE TABLE signalements (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  title text NOT NULL,
  description text,
  image_url text,
  location text,
  latitude numeric(10, 8),
  longitude numeric(11, 8),
  status text DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'resolved', 'rejected')),
  category text,
  upvotes integer DEFAULT 0,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now()
);

-- Index pour les performances
CREATE INDEX idx_signalements_user ON signalements(user_id);
CREATE INDEX idx_signalements_status ON signalements(status);
CREATE INDEX idx_signalements_created ON signalements(created_at DESC);
```

### Table : felicitations

```sql
CREATE TABLE felicitations (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  signalement_id uuid REFERENCES signalements(id) ON DELETE CASCADE,
  user_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  created_at timestamp with time zone DEFAULT now(),
  UNIQUE(signalement_id, user_id)
);

-- Index
CREATE INDEX idx_felicitations_signalement ON felicitations(signalement_id);
CREATE INDEX idx_felicitations_user ON felicitations(user_id);
```

## 🔒 Row Level Security (RLS)

Activez RLS pour sécuriser vos données :

```sql
-- Activer RLS sur toutes les tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE signalements ENABLE ROW LEVEL SECURITY;
ALTER TABLE felicitations ENABLE ROW LEVEL SECURITY;

-- Politiques pour profiles
CREATE POLICY "Les profils sont visibles par tous" 
  ON profiles FOR SELECT 
  USING (true);

CREATE POLICY "Les utilisateurs peuvent créer leur profil" 
  ON profiles FOR INSERT 
  WITH CHECK (true);

CREATE POLICY "Les utilisateurs peuvent modifier leur profil" 
  ON profiles FOR UPDATE 
  USING (auth.uid() = id);

-- Politiques pour signalements
CREATE POLICY "Les signalements sont visibles par tous" 
  ON signalements FOR SELECT 
  USING (true);

CREATE POLICY "Les utilisateurs authentifiés peuvent créer des signalements" 
  ON signalements FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Les utilisateurs peuvent modifier leurs signalements" 
  ON signalements FOR UPDATE 
  USING (auth.uid() = user_id);

CREATE POLICY "Les utilisateurs peuvent supprimer leurs signalements" 
  ON signalements FOR DELETE 
  USING (auth.uid() = user_id);

-- Politiques pour felicitations
CREATE POLICY "Les félicitations sont visibles par tous" 
  ON felicitations FOR SELECT 
  USING (true);

CREATE POLICY "Les utilisateurs authentifiés peuvent féliciter" 
  ON felicitations FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Les utilisateurs peuvent retirer leurs félicitations" 
  ON felicitations FOR DELETE 
  USING (auth.uid() = user_id);
```

## 📦 Storage

Configurez le storage pour les images :

1. Dans Supabase Dashboard → **Storage**
2. Créez un bucket nommé **`signalements`**
3. Configurez les politiques :

```sql
-- Permettre l'upload d'images
CREATE POLICY "Les utilisateurs authentifiés peuvent uploader des images"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'signalements' AND auth.role() = 'authenticated');

-- Permettre la lecture publique
CREATE POLICY "Les images sont publiques"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'signalements');

-- Permettre la suppression de ses propres images
CREATE POLICY "Les utilisateurs peuvent supprimer leurs images"
  ON storage.objects FOR DELETE
  USING (bucket_id = 'signalements' AND auth.uid() = owner);
```

## 🔧 Fonctions SQL utiles

### Fonction pour compter les signalements par utilisateur

```sql
CREATE OR REPLACE FUNCTION get_user_stats(user_uuid uuid)
RETURNS TABLE (
  total_signalements bigint,
  total_felicitations bigint,
  signalements_resolus bigint
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COUNT(DISTINCT s.id) as total_signalements,
    COUNT(DISTINCT f.id) as total_felicitations,
    COUNT(DISTINCT CASE WHEN s.status = 'resolved' THEN s.id END) as signalements_resolus
  FROM profiles p
  LEFT JOIN signalements s ON s.user_id = p.id
  LEFT JOIN felicitations f ON f.signalement_id = s.id
  WHERE p.id = user_uuid
  GROUP BY p.id;
END;
$$ LANGUAGE plpgsql;
```

## 🧪 Test de connexion

Pour tester votre connexion Supabase dans l'application :

```dart
// Dans un écran de test ou main.dart
void testSupabaseConnection() async {
  try {
    final response = await SupabaseConfig.client
        .from('profiles')
        .select()
        .limit(1);
    
    print('✅ Connexion Supabase réussie !');
    print('Données: $response');
  } catch (e) {
    print('❌ Erreur de connexion: $e');
  }
}
```

## 📝 Notes importantes

1. **Ne jamais commiter vos clés** dans le code source
2. **Utilisez des variables d'environnement** pour la production
3. **Activez RLS** pour toutes les tables sensibles
4. **Configurez CORS** si nécessaire pour le web
5. **Testez les politiques** avant de déployer

## 🔗 Ressources

- [Documentation Supabase](https://supabase.com/docs)
- [Flutter Supabase Package](https://pub.dev/packages/supabase_flutter)
- [Row Level Security Guide](https://supabase.com/docs/guides/auth/row-level-security)

---

**Note de sécurité** : Les clés `anon/public` peuvent être exposées dans l'application mobile car elles sont protégées par les politiques RLS. Cependant, **NE JAMAIS exposer la clé `service_role`** qui a tous les privilèges.

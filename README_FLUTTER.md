# TOKSE Flutter - Application de Signalement Urbain

<div align="center">
  <h1>🚨 TOKSE</h1>
  <p><strong>Signaler des problèmes urbains</strong></p>
</div>

## 📱 À propos

TOKSE est une application mobile Flutter permettant aux citoyens de signaler des problèmes urbains (nids de poule, éclairage défectueux, déchets, etc.) et de suivre leur résolution en temps réel.

### ✨ Fonctionnalités principales

- 🔐 **Authentification** : Connexion/Inscription via numéro de téléphone
- 📸 **Signalements** : Créer des signalements avec photos et géolocalisation
- 📰 **Feed** : Voir les signalements de la communauté
- 👤 **Profil** : Gérer son profil et voir ses statistiques
- 🌓 **Thème** : Mode sombre et clair avec persistance
- 🗺️ **Carte** : Visualiser les signalements sur une carte

## 🏗️ Architecture

```
lib/
├── core/
│   ├── config/          # Configuration Supabase
│   ├── theme/           # Thèmes et styles
│   └── router/          # Navigation (GoRouter)
├── features/
│   ├── auth/            # Authentification
│   ├── home/            # Écran d'accueil
│   ├── feed/            # Fil d'actualité
│   ├── signalement/     # Création de signalements
│   └── profile/         # Profil utilisateur
└── main.dart            # Point d'entrée
```

## 🚀 Démarrage rapide

### Prérequis

- Flutter SDK 3.2.0+
- Android Studio / VS Code
- Java 17
- Gradle 8.5
- Compte Supabase

### Installation

1. **Cloner le projet**
```bash
cd Tokse_Project
```

2. **Installer les dépendances**
```bash
flutter pub get
```

3. **Configurer Supabase**

Éditez `lib/core/config/supabase_config.dart` et ajoutez vos clés :
```dart
static const String supabaseUrl = 'VOTRE_SUPABASE_URL';
static const String supabaseAnonKey = 'VOTRE_SUPABASE_ANON_KEY';
```

4. **Lancer l'application**
```bash
flutter run
```

## 📦 Dépendances principales

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # UI & Design
  google_fonts: ^6.1.0
  cached_network_image: ^3.3.1
  
  # State Management
  provider: ^6.1.1
  
  # Navigation
  go_router: ^13.0.0
  
  # Backend
  supabase_flutter: ^2.3.4
  
  # Storage
  shared_preferences: ^2.2.2
  
  # Location
  geolocator: ^11.0.0
  geocoding: ^3.0.0
  
  # Image
  image_picker: ^1.0.7
```

## ⚙️ Configuration Gradle

Le projet utilise :
- **Gradle** : 8.5
- **Android Gradle Plugin** : 8.2.2
- **Kotlin** : 1.9.22
- **Java** : 17
- **compileSdk** : 34
- **minSdk** : 24
- **targetSdk** : 34

### Fichiers Gradle configurés

- ✅ `android/build.gradle` - Configuration projet
- ✅ `android/app/build.gradle` - Configuration app
- ✅ `android/settings.gradle` - Plugins Flutter
- ✅ `android/gradle/wrapper/gradle-wrapper.properties` - Version Gradle

## 🎨 Thèmes

L'application supporte les modes **clair** et **sombre** :

```dart
// Mode sombre (par défaut)
- Background: #0a0e27
- Primary: #1a73e8
- Accent: #4285f4

// Mode clair
- Background: #ffffff
- Primary: #1a73e8
- Accent: #4285f4
```

## 📱 Écrans

1. **Splash** (`/splash`) - Écran de démarrage animé
2. **Login** (`/login`) - Connexion par téléphone
3. **Signup** (`/signup`) - Inscription
4. **Home** (`/home`) - Navigation principale avec tabs :
   - Accueil - Statistiques et actions rapides
   - Feed - Signalements de la communauté
   - Signaler - Créer un signalement
   - Profil - Gérer son compte

## 🔧 Commandes utiles

```bash
# Lancer en mode debug
flutter run

# Lancer en mode release
flutter run --release

# Construire l'APK
flutter build apk --release

# Analyser le code
flutter analyze

# Formater le code
flutter format lib/

# Nettoyer le projet
flutter clean

# Vérifier les mises à jour
flutter pub outdated
```

## 🐛 Résolution de problèmes

### Gradle

Si vous avez des erreurs Gradle :
```bash
cd android
./gradlew clean
./gradlew build
```

### Flutter

```bash
flutter clean
flutter pub get
flutter pub upgrade
```

### Android Studio

1. File → Invalidate Caches / Restart
2. Sync Project with Gradle Files

## 📊 Base de données Supabase

### Tables nécessaires

```sql
-- Table profiles
CREATE TABLE profiles (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  name text NOT NULL,
  phone text UNIQUE NOT NULL,
  role text DEFAULT 'citizen',
  avatar_url text,
  created_at timestamp with time zone DEFAULT now()
);

-- Table signalements
CREATE TABLE signalements (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid REFERENCES profiles(id),
  title text NOT NULL,
  description text,
  image_url text,
  location text,
  latitude numeric,
  longitude numeric,
  status text DEFAULT 'pending',
  created_at timestamp with time zone DEFAULT now()
);
```

## 🤝 Contribution

Les contributions sont les bienvenues ! Pour contribuer :

1. Fork le projet
2. Créer une branche (`git checkout -b feature/AmazingFeature`)
3. Commit les changements (`git commit -m 'Add AmazingFeature'`)
4. Push vers la branche (`git push origin feature/AmazingFeature`)
5. Ouvrir une Pull Request

## 📝 Licence

Ce projet est sous licence MIT.

## 👥 Auteurs

- **Développement** - TOKSE Team

## 📞 Support

Pour toute question ou support :
- 📧 Email : support@tokse.app
- 🌐 Site web : https://tokse.app

---

<div align="center">
  <p>Fait avec ❤️ en Flutter</p>
  <p>🚨 <strong>TOKSE</strong> - Ensemble, améliorons notre ville</p>
</div>

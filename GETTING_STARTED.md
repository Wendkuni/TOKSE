# Guide de Démarrage TOKSE Flutter

## 🚀 Installation Rapide

### Étape 1 : Vérifier l'environnement

```bash
flutter doctor
```

Assurez-vous que tout est ✅ (surtout Flutter, Android toolchain, Android Studio)

### Étape 2 : Installer les dépendances

```bash
cd "c:\Users\ing KONATE B. SAMUEL\Documents\Projet DEV\PROJET-Flutter\Tokse_Project"
flutter pub get
```

### Étape 3 : Configurer Supabase

1. Ouvrez `lib/core/config/supabase_config.dart`
2. Remplacez les valeurs par vos vraies clés Supabase :
   ```dart
   static const String supabaseUrl = 'https://votre-projet.supabase.co';
   static const String supabaseAnonKey = 'votre-cle-anon';
   ```

3. Créez les tables dans Supabase (voir `SUPABASE_SETUP.md`)

### Étape 4 : Lancer l'application

```bash
# Sur émulateur/device Android
flutter run

# Ou avec hot reload
flutter run --hot
```

## 📱 Structure du Projet

```
lib/
├── main.dart                           # Point d'entrée
├── core/
│   ├── config/
│   │   └── supabase_config.dart       # Configuration Supabase
│   ├── theme/
│   │   ├── app_theme.dart             # Thèmes light/dark
│   │   └── theme_provider.dart        # Provider pour thème
│   └── router/
│       └── app_router.dart            # Navigation GoRouter
└── features/
    ├── auth/
    │   ├── data/repositories/
    │   │   └── auth_repository.dart   # Logique auth
    │   └── presentation/screens/
    │       ├── splash_screen.dart     # Écran de démarrage
    │       ├── login_screen.dart      # Connexion
    │       └── signup_screen.dart     # Inscription
    ├── home/
    │   └── presentation/screens/
    │       └── home_screen.dart       # Écran principal avec tabs
    ├── feed/
    │   └── presentation/screens/
    │       └── feed_screen.dart       # Fil d'actualité
    ├── signalement/
    │   └── presentation/screens/
    │       └── signalement_screen.dart # Créer signalement
    └── profile/
        └── presentation/screens/
            └── profile_screen.dart    # Profil utilisateur
```

## 🔧 Configuration Gradle

✅ **Gradle 8.5** - Version moderne et stable
✅ **Android Gradle Plugin 8.2.2** - Compatible avec Gradle 8.5
✅ **Kotlin 1.9.22** - Dernière version stable
✅ **Java 17** - Version LTS recommandée
✅ **MinSdk 24** - Android 7.0+ (94% des appareils)
✅ **TargetSdk 34** - Android 14

### Fichiers configurés

- `android/build.gradle` ✅
- `android/app/build.gradle` ✅
- `android/settings.gradle` ✅
- `android/gradle/wrapper/gradle-wrapper.properties` ✅

## 🎨 Thèmes

L'app utilise Material Design 3 avec 2 thèmes :

### Mode Sombre (défaut)
- Background : `#0a0e27` (Noir profond)
- Surface : `#1a1e37`
- Card : `#2a2e47`
- Primary : `#1a73e8` (Bleu)
- Secondary : `#4285f4` (Bleu clair)

### Mode Clair
- Background : `#ffffff` (Blanc)
- Surface : `#f5f5f5` (Gris clair)
- Card : `#ffffff`
- Primary : `#1a73e8`
- Secondary : `#4285f4`

Le thème est persistant (sauvegardé avec SharedPreferences).

## 📋 Fonctionnalités Implémentées

### ✅ Authentification
- Splash screen animé
- Connexion par téléphone (+226 XX XX XX XX)
- Inscription avec nom et téléphone
- Validation et formatage automatique

### ✅ Navigation
- GoRouter pour navigation déclarative
- Bottom Navigation Bar avec 4 tabs
- Routes nommées et typage fort

### ✅ Écrans
1. **Splash** - Animation de démarrage
2. **Login/Signup** - Auth avec gradient moderne
3. **Home** - Navigation principale :
   - Tab Accueil : Statistiques et actions rapides
   - Tab Feed : Liste des signalements
   - Tab Signaler : Créer un signalement
   - Tab Profil : Gérer son compte

### ✅ Thème
- Provider pour gestion de thème
- Toggle dark/light
- Persistance avec SharedPreferences
- Support Material 3

### ✅ Backend
- Configuration Supabase
- Repository pattern
- CRUD operations prêtes

## 🧪 Tests

```bash
# Analyser le code
flutter analyze

# Formater le code
flutter format lib/ --set-exit-if-changed

# Linter
flutter analyze --no-fatal-infos
```

## 🏗️ Build

### Debug APK
```bash
flutter build apk --debug
```

### Release APK
```bash
flutter build apk --release
```

### App Bundle (Play Store)
```bash
flutter build appbundle --release
```

## 🐛 Troubleshooting

### Erreur Gradle

```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

### Erreur de dépendances

```bash
flutter pub cache repair
flutter pub get
```

### Problème de version

```bash
flutter upgrade
flutter doctor -v
```

## 📦 Dépendances Clés

| Package | Version | Usage |
|---------|---------|-------|
| supabase_flutter | ^2.3.4 | Backend |
| provider | ^6.1.1 | State management |
| go_router | ^13.0.0 | Navigation |
| shared_preferences | ^2.2.2 | Stockage local |
| geolocator | ^11.0.0 | Géolocalisation |
| image_picker | ^1.0.7 | Sélection photos |
| google_fonts | ^6.1.0 | Typographie |

## 🎯 Prochaines Étapes

1. **Configurer Supabase** :
   - Créer les tables (voir SUPABASE_SETUP.md)
   - Ajouter vos clés API
   - Tester la connexion

2. **Compléter les écrans** :
   - Implémenter la création de signalements
   - Ajouter la carte interactive
   - Gérer les images avec image_picker

3. **Ajouter les fonctionnalités** :
   - Upload d'images vers Supabase Storage
   - Géolocalisation en temps réel
   - Notifications push
   - Système de votes

4. **Tester** :
   - Tests unitaires
   - Tests d'intégration
   - Tests sur vrais devices

## 💡 Commandes Utiles

```bash
# Hot reload (r)
# Hot restart (R)
# Ouvrir DevTools (w)
# Quitter (q)

# Voir les logs
flutter logs

# Build watch mode
flutter run --hot

# Profiling
flutter run --profile

# Vérifier les performances
flutter run --trace-startup
```

## 📞 Support

- 📖 Documentation Flutter : https://docs.flutter.dev
- 📖 Documentation Supabase : https://supabase.com/docs
- 💬 Discord Flutter : https://discord.gg/flutter

## ✅ Checklist de Déploiement

- [ ] Clés Supabase configurées
- [ ] Tables créées dans Supabase
- [ ] RLS activé et testé
- [ ] Images de test uploadées
- [ ] Tests manuels sur Android
- [ ] Tests manuels sur iOS (si applicable)
- [ ] Performance optimisée
- [ ] Icônes et splash screen personnalisés
- [ ] Version et build number mis à jour
- [ ] Changelog rédigé

---

**Fait avec ❤️ en Flutter** | TOKSE Team 2025

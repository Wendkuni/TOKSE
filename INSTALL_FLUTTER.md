# 🚀 Installation Flutter pour Windows

Flutter n'est pas encore installé sur votre système. Voici comment l'installer :

## Méthode 1 : Installation Rapide (Recommandée)

### Étape 1 : Télécharger Flutter

1. Allez sur [https://flutter.dev/docs/get-started/install/windows](https://flutter.dev/docs/get-started/install/windows)
2. Téléchargez le dernier SDK Flutter (fichier .zip)
3. Extrayez le fichier dans `C:\src\flutter` (ou `C:\flutter`)

### Étape 2 : Ajouter Flutter au PATH

1. Appuyez sur `Windows + R`
2. Tapez `sysdm.cpl` et appuyez sur Entrée
3. Allez dans l'onglet **Avancé**
4. Cliquez sur **Variables d'environnement**
5. Dans **Variables système**, trouvez `Path` et cliquez **Modifier**
6. Cliquez **Nouveau** et ajoutez : `C:\src\flutter\bin` (ou votre chemin)
7. Cliquez **OK** sur toutes les fenêtres

### Étape 3 : Vérifier l'installation

Ouvrez un **nouveau** PowerShell et tapez :

```powershell
flutter doctor
```

## Méthode 2 : Installation avec Git

```powershell
# 1. Installer Git si pas déjà fait
# Télécharger depuis : https://git-scm.com/download/win

# 2. Cloner Flutter
cd C:\src
git clone https://github.com/flutter/flutter.git -b stable

# 3. Ajouter au PATH (voir étape 2 ci-dessus)
# C:\src\flutter\bin

# 4. Vérifier
flutter doctor
```

## Dépendances Requises

### 1. Android Studio (pour développement Android)

1. Téléchargez [Android Studio](https://developer.android.com/studio)
2. Installez avec les options par défaut
3. Ouvrez Android Studio
4. Allez dans **File → Settings → Appearance & Behavior → System Settings → Android SDK**
5. Installez :
   - Android SDK Platform-Tools
   - Android SDK Build-Tools
   - Android SDK Command-line Tools

### 2. Android SDK

```powershell
flutter doctor --android-licenses
# Acceptez toutes les licences (tapez 'y')
```

### 3. Visual Studio Code (Recommandé pour Flutter)

1. Téléchargez [VS Code](https://code.visualstudio.com/)
2. Installez les extensions :
   - **Flutter** (par Dart Code)
   - **Dart** (par Dart Code)

### 4. Créer un émulateur Android

Dans Android Studio :
1. **Tools → Device Manager**
2. Cliquez **Create Device**
3. Choisissez **Pixel 5** ou similaire
4. Téléchargez une **System Image** (API 33 ou 34 recommandé)
5. Finalisez la création

## Vérification Complète

```powershell
flutter doctor -v
```

Vous devriez voir :
```
[✓] Flutter (Channel stable, 3.x.x)
[✓] Windows Version (Windows 10 or later)
[✓] Android toolchain - develop for Android devices
[✓] Chrome - develop for the web
[✓] Visual Studio - develop Windows apps (optional)
[✓] Android Studio (version 2023.x)
[✓] VS Code (version 1.x)
[✓] Connected device (1 available)
[✓] Network resources
```

## Après Installation

Une fois Flutter installé, revenez dans ce projet et lancez :

```powershell
cd "c:\Users\ing KONATE B. SAMUEL\Documents\Projet DEV\PROJET-Flutter\Tokse_Project"

# Installer les dépendances
flutter pub get

# Vérifier la configuration
flutter doctor

# Lancer l'application
flutter run
```

## Problèmes Courants

### "cmdlet flutter not found"
- Redémarrez PowerShell après avoir ajouté Flutter au PATH
- Vérifiez que le PATH pointe vers `flutter\bin`

### "Android licenses not accepted"
```powershell
flutter doctor --android-licenses
```

### "No connected devices"
- Lancez un émulateur Android
- Ou connectez un appareil physique en USB (mode débogage activé)

### "Gradle build failed"
- Notre projet utilise Gradle 8.5 (compatible et moderne)
- Vérifiez Java 17 installé : `java -version`

## Configuration Java

Flutter nécessite Java 17 pour Gradle 8.x :

1. Téléchargez [OpenJDK 17](https://adoptium.net/temurin/releases/?version=17)
2. Installez avec les options par défaut
3. Vérifiez : `java -version`

## Résumé des Commandes

```powershell
# 1. Vérifier Flutter
flutter --version

# 2. Vérifier tout
flutter doctor -v

# 3. Installer les dépendances du projet
cd "c:\Users\ing KONATE B. SAMUEL\Documents\Projet DEV\PROJET-Flutter\Tokse_Project"
flutter pub get

# 4. Lancer l'app
flutter run

# 5. Build APK
flutter build apk --release
```

## Temps d'Installation Estimé

- Flutter SDK : **5-10 min**
- Android Studio : **15-20 min**
- Configuration complète : **30-40 min**

## Support

Si vous rencontrez des problèmes :
- [Documentation officielle](https://docs.flutter.dev/get-started/install/windows)
- [Flutter Discord](https://discord.gg/flutter)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/flutter)

---

**Une fois Flutter installé, votre application TOKSE sera prête à être lancée ! 🚀**

# 🔑 Comment obtenir votre clé API Google Maps GRATUITE

## ✅ **2500 requêtes GRATUITES par jour** (suffisant pour votre application)

---

## **Étape 1 : Créer un projet Google Cloud**

1. Allez sur : https://console.cloud.google.com/
2. Connectez-vous avec votre compte Google
3. Cliquez sur **"Sélectionner un projet"** (en haut)
4. Cliquez sur **"NOUVEAU PROJET"**
5. Nom du projet : `TOKSE-App` (ou autre nom)
6. Cliquez sur **"CRÉER"**

---

## **Étape 2 : Activer l'API Geocoding**

1. Dans le menu de gauche, allez dans **"API et services"** → **"Bibliothèque"**
2. Recherchez : `Geocoding API`
3. Cliquez sur **"Geocoding API"**
4. Cliquez sur **"ACTIVER"**

---

## **Étape 3 : Créer une clé API**

1. Dans le menu de gauche, allez dans **"Identifiants"**
2. Cliquez sur **"+ CRÉER DES IDENTIFIANTS"** (en haut)
3. Sélectionnez **"Clé API"**
4. Votre clé est générée ! **Copiez-la** 

Exemple : `AIzaSyD1234567890abcdefghijklmnopqrstu`

---

## **Étape 4 : Sécuriser votre clé (IMPORTANT)**

⚠️ **Ne pas mettre la clé publiquement sur GitHub !**

### **Option 1 : Restriction par application Android**
1. Cliquez sur votre clé créée
2. Dans **"Restrictions liées à l'application"** :
   - Sélectionnez **"Applications Android"**
   - Cliquez sur **"Ajouter un nom de package et une empreinte"**
   - Nom du package : `com.tokse.tokse_project` (vérifiez dans `android/app/build.gradle`)
   - Empreinte SHA-1 : Obtenez-la avec cette commande :
     ```bash
     cd android
     ./gradlew signingReport
     ```
3. Cliquez sur **"ENREGISTRER"**

### **Option 2 : Limitation de quota (recommandé en développement)**
1. Cliquez sur votre clé
2. Dans **"Restrictions liées à l'API"** :
   - Sélectionnez **"Limiter la clé aux API sélectionnées"**
   - Cochez **"Geocoding API"**
3. Dans **"Quotas"** :
   - Limitez à **100 requêtes par jour** pour les tests
   - Augmentez à **2500/jour** en production

---

## **Étape 5 : Ajouter la clé dans le code**

1. Ouvrez le fichier : `lib/core/services/geocoding_service.dart`
2. Ligne 12, remplacez :
   ```dart
   static const String? _googleApiKey = 'VOTRE_CLE_API_ICI';
   ```
   Par :
   ```dart
   static const String? _googleApiKey = 'AIzaSyD1234567890abcdefghijklmnopqrstu';
   ```
   *(Mettez VOTRE vraie clé)*

3. **Build et testez** :
   ```bash
   flutter build apk --release
   ```

---

## **Étape 6 : Vérifier que ça fonctionne**

Dans les logs de l'application, vous devriez voir :
```
🔑 [GEOCODING] Utilisation Google Maps API...
✅ [GEOCODING] Google Maps a répondu avec succès
🏘️ [GEOCODING] Google - Quartier: Katr Yaar
🏙️ [GEOCODING] Google - Ville: Ouagadougou
```

Au lieu de :
```
⚠️ [GEOCODING] ATTENTION: Clé Google Maps non configurée !
```

---

## **💰 Tarification (rassurez-vous, c'est GRATUIT)**

| Service | Prix | Quota gratuit |
|---------|------|---------------|
| Geocoding API | 5$ / 1000 requêtes | **2500 GRATUIT/jour** |

**Calcul pour TOKSE :**
- 100 signalements/jour = 100 requêtes
- **LARGEMENT dans le quota gratuit** ✅

Si vous dépassez 2500/jour :
- Les 2500 premiers = **GRATUIT**
- Au-delà : 5$ / 1000 requêtes (0.005$ par requête)

---

## **🔒 Sécurité : Protéger votre clé**

### **NE PAS faire :**
❌ Mettre la clé sur GitHub public
❌ Laisser la clé sans restriction

### **À FAIRE :**
✅ Restriction par package Android
✅ Limiter aux API nécessaires (Geocoding uniquement)
✅ Activer des alertes de quota

---

## **🆘 Support**

Si vous avez des problèmes :
1. Vérifiez que l'API Geocoding est **activée**
2. Vérifiez que la **facturation est activée** (nécessaire même pour le quota gratuit)
3. Vérifiez les logs : `flutter run` pour voir les erreurs

**Documentation officielle :**
https://developers.google.com/maps/documentation/geocoding/start

---

**Voilà ! Vous avez maintenant une localisation précise avec les quartiers de Ouagadougou** 🎯

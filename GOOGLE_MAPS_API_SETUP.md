# Configuration Géocodage - TOKSE

L'application utilise **3 niveaux de géocodage** pour obtenir les quartiers et villes :

## 🌟 Système actuel (par ordre de priorité)

### 1️⃣ **Google Maps Geocoding API** (Optionnel - Le plus précis)
- ✅ Meilleure précision des quartiers
- ✅ Données très fiables
- 💰 Gratuit jusqu'à 2500 requêtes/jour
- 💳 Nécessite une carte bancaire (même pour gratuit)

### 2️⃣ **Nominatim (OpenStreetMap)** ✨ **ACTIVÉ PAR DÉFAUT**
- ✅ **100% GRATUIT et illimité**
- ✅ Open source
- ✅ Bonne couverture en Afrique
- ✅ **Aucune configuration requise**
- ⚠️ Respecter 1 requête/seconde (limite serveur public)

### 3️⃣ **Geocoding Standard** (Fallback)
- ✅ Toujours disponible
- ⚠️ Moins précis dans certaines régions

## 🚀 Configuration actuelle

**Par défaut, l'application utilise Nominatim (OSM) - GRATUIT** ✅

Vous n'avez **rien à configurer** ! L'application est déjà optimale.

## 📊 Comparaison

| Service | Quartiers | Coût | Config requise |
|---------|-----------|------|----------------|
| **Nominatim (OSM)** ✨ | ✅ Bon | **GRATUIT** | ❌ Aucune |
| Google Maps | ✅ Excellent | 2500/jour gratuit | ✅ Oui |
| Geocoding standard | ⚠️ Limité | Gratuit | ❌ Aucune |

## 🔧 (OPTIONNEL) Activer Google Maps API pour encore plus de précision

Si vous voulez la **meilleure précision possible**, vous pouvez ajouter Google Maps :

### Étapes :

1. **Créer un projet Google Cloud** :
   - Aller sur https://console.cloud.google.com/
   - Créer un nouveau projet ou sélectionner un existant

2. **Activer l'API Geocoding** :
   - Dans le menu, aller à "APIs & Services" > "Library"
   - Rechercher "Geocoding API"
   - Cliquer sur "Enable"

3. **Créer une clé API** :
   - Aller à "APIs & Services" > "Credentials"
   - Cliquer sur "Create Credentials" > "API Key"
   - Copier la clé générée

4. **Restreindre la clé (recommandé)** :
   - Cliquer sur la clé créée
   - Dans "API restrictions", sélectionner "Restrict key"
   - Cocher seulement "Geocoding API"
   - Sauvegarder

5. **Ajouter la clé dans le code** :
   - Ouvrir le fichier `lib/core/services/geocoding_service.dart`
   - Remplacer `static const String? _googleApiKey = null;`
   - Par `static const String? _googleApiKey = 'VOTRE_CLE_ICI';`

## 💰 Tarification Google (si activé)

- **2500 requêtes gratuites par jour**
- Au-delà : 0,005 $ (≈ 3 FCFA) par requête
- Pour TOKSE : largement suffisant avec les utilisateurs actuels

## ✅ Recommandation

**Gardez la configuration actuelle (Nominatim)** - c'est gratuit et performant !

N'activez Google Maps que si vous constatez que les quartiers ne sont pas assez précis dans votre zone.

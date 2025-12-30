# 🚔 INTERFACE AUTORITÉ - TOKSE Flutter

## 📋 Vue d'ensemble

L'interface Autorité permet aux agents des services municipaux (Police, Hygiène, Voirie, Environnement, Sécurité) de gérer efficacement les signalements citoyens.

---

## 🧭 Navigation

### **Rôles et Navigation**

| Rôle | Onglets |
|------|---------|
| **Citoyen** | Accueil – Signalement – Profil |
| **Autorité** | Accueil – Carte – Profil |

La navigation est **automatique** selon le champ `role` dans Supabase :
- `citizen` ou `citoyen` → Interface Citoyen
- `police`, `hygiene`, `voirie`, `environnement`, `securite` → Interface Autorité

---

## 📱 Écrans Implémentés

### 🏠 1. Onglet ACCUEIL (Autorité)

**Fichier** : `lib/features/authority/presentation/screens/authority_home_screen.dart`

**Fonctionnalités** :

#### 📊 Statistiques du jour
- 🔥 **Signalements reçus aujourd'hui**
- ⏳ **Signalements en cours**
- ✅ **Signalements résolus**
- 📍 **Signalements à traiter** (non résolus)

#### 📋 Liste des signalements à traiter

**Tri automatique par** :
1. Statut (en_attente d'abord)
2. Proximité géographique
3. Date de création (plus récents)

**Chaque carte affiche** :
- 🗑️ Catégorie (emoji + label coloré)
- 📏 Distance (ex: "350 m" ou "2.5 km")
- 🟠 Statut (badge coloré)
- 📅 Date & heure (format relatif : "Il y a 2h")
- 📷 Photo miniature (ou emoji catégorie si pas de photo)
- ➡️ Bouton "Voir détails"

#### 🗺️ Bouton "Voir la carte"
Renvoie vers l'onglet **Carte** (index 1 du bottom nav).

---

### 🗺️ 2. Onglet CARTE (Autorité)

**Fichier** : `lib/features/authority/presentation/screens/authority_map_screen.dart`

**Fonctionnalités** :

#### Carte interactive
- **Provider** : OpenStreetMap (via `flutter_map`)
- **Position en temps réel** : Marqueur bleu avec icône personne
- **Suivi automatique** : Mise à jour tous les 10 mètres
- **Clustering** : Regroupement automatique des signalements proches

#### Marqueurs des signalements
- **Couleur** selon statut :
  - 🟠 Orange = en_attente
  - 🔵 Bleu = en_cours
  - 🟢 Vert = resolu
- **Emoji** selon catégorie : 🗑️ 🚧 🏭 📢
- **Border** : 3px blanc avec shadow pour visibilité

#### Interaction au clic sur un marqueur

**Popup modale** affichant :
- 📷 **Photo** du signalement (si disponible)
- 🗑️ **Catégorie** (emoji + description)
- 📏 **Distance** depuis position autorité
- 🟠 **Statut** actuel

**Actions disponibles** :

##### 🚀 Prendre en charge
- Met à jour : `statut = EN_COURS`
- Assigne : `assigned_to = idAutorité`
- Verrouille : `locked = TRUE`
- ✅ Envoie notification au citoyen
- ⚠️ Aucune autre autorité ne peut le prendre

##### 🧭 Naviguer (Google Maps)
Ouvre Google Maps avec directions vers le signalement :
```
https://www.google.com/maps/dir/?api=1&destination=lat,lng
```

##### 🔍 Voir détails
Navigue vers l'écran détaillé du signalement (réutilise `SignalementDetailScreen`).

---

### 👤 3. Onglet PROFIL (Autorité)

**Fichier** : `lib/features/profile/presentation/screens/authority_profile_screen.dart`

**Fonctionnalités** :

#### 🛑 Informations du compte (NON modifiables)

Définies par l'admin, affichage en lecture seule :
- 👤 **Nom** & **Prénom**
- 🏷️ **Rôle** (Police municipale, Hygiène, Voirie, Environnement, Sécurité)
- 📞 **Numéro professionnel**
- 📧 **Email**
- 📍 **Zone d'intervention** (DREN / district)

#### 📋 Historique des interventions

**Filtres** :
- 📅 **Aujourd'hui**
- 📆 **Cette semaine**
- 📜 **Tout l'historique**

**Chaque intervention affiche** :
- 🖼️ **Photo avant / après**
- 🗑️ **Catégorie**
- 📍 **Lieu**
- 📝 **Note ajoutée** lors de la résolution
- ⏱️ **Temps de résolution** (en heures)
- 📅 **Date** de résolution

#### ⚙️ Paramètres

L'autorité peut :
- 📍 **Activer/désactiver localisation** (suivi en temps réel)
- 🔔 **Activer/désactiver notifications**
- 🚪 **Se déconnecter**

---

## 🗄️ Structure des Fichiers

```
lib/features/authority/
├── presentation/
│   └── screens/
│       ├── authority_home_screen.dart      # Accueil avec stats + liste
│       ├── authority_map_screen.dart       # Carte interactive
│       └── authority_main_screen.dart      # Navigation 3 onglets

lib/features/profile/
└── presentation/
    └── screens/
        └── authority_profile_screen.dart   # Profil + historique

lib/core/router/
└── app_router.dart                         # Navigation conditionnelle

lib/features/auth/
└── presentation/
    └── screens/
        ├── splash_screen.dart              # Redirection selon rôle
        └── login_screen.dart               # Connexion + redirection
```

---

## 🛢️ Base de Données

### Nouvelles Colonnes (MIGRATION_AUTHORITY_INTERFACE.sql)

#### Table `signalements`
```sql
assigned_to UUID REFERENCES users(id)     -- Autorité assignée
locked BOOLEAN DEFAULT FALSE              -- Verrouillage (pris en charge)
photo_apres TEXT                          -- Photo après résolution
note_resolution TEXT                      -- Note de l'autorité
resolved_at TIMESTAMP WITH TIME ZONE      -- Date de résolution
```

#### Table `users`
```sql
zone_intervention TEXT                    -- Zone géographique (DREN/district)
```

### Fonctions SQL

#### `take_charge_signalement(signalement_id, authority_id)`
```sql
-- Prise en charge d'un signalement
-- Vérifie que non verrouillé
-- Met à jour statut, assigned_to, locked
-- Retourne JSON avec confirmation
```

#### `resolve_signalement(signalement_id, authority_id, photo_apres_url, note)`
```sql
-- Marquer comme résolu
-- Vérifie que c'est l'autorité assignée
-- Met à jour statut, photo_apres, note_resolution, resolved_at
-- Retourne JSON avec confirmation
```

### Vues SQL

#### `authority_stats`
Statistiques par autorité :
- Signalements en cours
- Signalements résolus (total + aujourd'hui)
- Temps moyen de résolution (en heures)

### Historique des Actions

Table `authority_actions` :
- `take_charge` : Prise en charge
- `resolve` : Résolution
- `update` : Modification
- `reassign` : Réassignation

---

## 📦 Dépendances Ajoutées

```yaml
# pubspec.yaml
dependencies:
  flutter_map: ^6.1.0      # Cartes OpenStreetMap
  latlong2: ^0.9.0         # Coordonnées géographiques
  geolocator: ^11.0.0      # Position GPS
  geocoding: ^3.0.0        # Adresses
```

**Installation** :
```bash
flutter pub get
```

---

## 🚀 Workflow Autorité

### 1️⃣ Connexion
```
Login Screen → Vérification rôle → authority-home (si autorité)
```

### 2️⃣ Consultation
```
Accueil → Stats du jour + Liste triée par proximité
```

### 3️⃣ Prise en charge
```
Carte → Clic marqueur → Prendre en charge
→ Statut EN_COURS + Locked + Notification citoyen
```

### 4️⃣ Navigation
```
Popup → Naviguer → Google Maps → Itinéraire
```

### 5️⃣ Résolution
```
Sur terrain → Marquer résolu
→ Photo après (optionnelle)
→ Note courte
→ Notifications citoyen + admin
```

### 6️⃣ Historique
```
Profil → Interventions → Filtres (Aujourd'hui/Semaine/Tout)
```

---

## ⚠️ Comportements Critiques

### 🔒 Verrouillage des Signalements

Quand une autorité clique **"Prendre en charge"** :

```sql
UPDATE signalements SET
  statut = 'en_cours',
  assigned_to = <id_autorité>,
  locked = TRUE;
```

**Résultat** :
- ❌ Aucune autre autorité ne peut le prendre
- ✅ Le citoyen reçoit une notification
- 📊 Apparaît dans les stats "En cours"

### 🎯 Tri par Proximité

Calcul de distance avec Geolocator :
```dart
final meters = Geolocator.distanceBetween(
  autorityLat, autorityLng,
  signalementLat, signalementLng,
);
```

**Affichage** :
- < 1000m → "350 m"
- ≥ 1000m → "2.5 km"

### 🔔 Notifications

**À implémenter** (Firebase Cloud Messaging) :

#### Prise en charge
```json
{
  "to": "citoyen_fcm_token",
  "notification": {
    "title": "Signalement pris en charge",
    "body": "La Police municipale traite votre signalement"
  }
}
```

#### Résolution
```json
{
  "to": ["citoyen_fcm_token", "admin_fcm_token"],
  "notification": {
    "title": "Signalement résolu",
    "body": "Votre signalement a été traité par l'Hygiène"
  }
}
```

---

## 🧪 Tests Recommandés

### Test 1 : Navigation conditionnelle
1. Créer un utilisateur `role = police`
2. Se connecter
3. ✅ Vérifier redirection vers `authority-home`
4. ✅ Vérifier 3 onglets (Accueil / Carte / Profil)

### Test 2 : Tri par proximité
1. Créer 5 signalements à distances variées (100m, 500m, 2km, 5km, 10km)
2. Ouvrir Accueil Autorité
3. ✅ Vérifier ordre croissant des distances

### Test 3 : Prise en charge
1. Autorité A clique "Prendre en charge" sur signalement X
2. ✅ Statut passe à EN_COURS
3. ✅ assigned_to = id_autorité_A
4. ✅ locked = TRUE
5. Autorité B essaie de prendre en charge X
6. ✅ Message d'erreur "Déjà pris en charge"

### Test 4 : Navigation Google Maps
1. Clic "Naviguer" sur un signalement
2. ✅ Google Maps s'ouvre avec itinéraire
3. ✅ Destination = coordonnées du signalement

### Test 5 : Résolution
1. Autorité assignée marque signalement comme résolu
2. Ajoute photo après + note
3. ✅ Statut = resolu
4. ✅ resolved_at = timestamp actuel
5. ✅ Apparaît dans historique Profil

---

## 📊 Statistiques & KPI

### Indicateurs Clés (authority_stats)

```sql
SELECT 
  assigned_to,
  signalements_en_cours,      -- Nombre actuel en traitement
  signalements_resolus,        -- Total résolus
  resolus_aujourdhui,          -- Résolus ce jour
  temps_moyen_resolution_heures -- Performance (temps moyen)
FROM authority_stats;
```

**Affichage dans Accueil** :
- 🔥 Reçus aujourd'hui
- ⏳ En cours
- ✅ Résolus
- 📍 À traiter

---

## 🔐 Sécurité & Permissions

### Row Level Security (RLS)

```sql
-- Les autorités voient tous les signalements
CREATE POLICY "Authorities can view all signalements"
ON signalements FOR SELECT TO authenticated
USING (TRUE);

-- Les autorités modifient uniquement leurs signalements assignés
CREATE POLICY "Authorities can update assigned signalements"
ON signalements FOR UPDATE TO authenticated
USING (assigned_to = auth.uid())
WITH CHECK (assigned_to = auth.uid());
```

### Permissions Localisation

Requises dans `AndroidManifest.xml` et `Info.plist` :
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

---

## 🛠️ Configuration Requise

### 1. Exécuter la migration SQL
```bash
# Copier le contenu de MIGRATION_AUTHORITY_INTERFACE.sql
# Coller dans Supabase SQL Editor
# Exécuter
```

### 2. Installer les dépendances
```bash
cd tokse_flutter
flutter pub get
```

### 3. Tester sur émulateur
```bash
flutter run
```

### 4. Créer des comptes de test

**Citizen** :
```sql
INSERT INTO users (telephone, nom, prenom, role) 
VALUES ('+22670123456', 'Traoré', 'Fatima', 'citizen');
```

**Autorité** :
```sql
INSERT INTO users (telephone, nom, prenom, role, zone_intervention) 
VALUES ('+22670987654', 'Ouédraogo', 'Jean', 'police', 'Ouagadougou Centre');
```

---

## 📝 TODO Restants

### Priorité HAUTE
- [ ] Implémenter appels RPC `take_charge_signalement()` et `resolve_signalement()`
- [ ] Ajouter upload photo_apres lors de la résolution
- [ ] Implémenter notifications Firebase (prise en charge + résolution)

### Priorité MOYENNE
- [ ] Ajouter filtrage par zone_intervention sur la carte
- [ ] Implémenter temps moyen de résolution dans stats
- [ ] Ajouter bouton "Réassigner" pour admin

### Priorité BASSE
- [ ] Clustering intelligent des marqueurs (fusion si > 50)
- [ ] Mode hors ligne (cache local des signalements)
- [ ] Export PDF de l'historique interventions

---

## 📞 Support

Pour toute question :
- 📧 Email : support@tokse.app
- 📱 Téléphone : +226 XX XX XX XX

---

**Version** : 1.0.0  
**Date** : Décembre 2025  
**Auteur** : AMIR TECH

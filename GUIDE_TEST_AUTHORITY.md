# 🧪 GUIDE DE TEST - INTERFACE AUTORITÉ

Ce guide vous permet de tester complètement l'interface Autorité de TOKSE, de la création du compte à la prise en charge des signalements.

---

## Prérequis

✅ Migration SQL déployée (voir `GUIDE_DEPLOYMENT_SQL.md`)  
✅ App Flutter compilée (`flutter build apk` ou `flutter run`)  
✅ Accès au Dashboard Supabase

---

## ÉTAPE 1 : Créer un compte autorité de test

### Option A : Via le SQL Editor Supabase

1. Aller dans **SQL Editor** de votre projet Supabase
2. Exécuter cette requête :

```sql
-- Créer un utilisateur autorité (Police)
INSERT INTO users (
  telephone,
  nom,
  prenom,
  role,
  zone_intervention,
  created_at,
  updated_at
)
VALUES (
  '+22670000001',           -- Numéro de téléphone de test
  'Ouédraogo',              -- Nom
  'Jean',                   -- Prénom
  'police',                 -- Rôle (police, hygiene, voirie, environnement, securite)
  'Secteur 15 Ouagadougou', -- Zone d'intervention
  NOW(),
  NOW()
)
RETURNING id, telephone, nom, prenom, role, zone_intervention;
```

**Noter l'ID retourné** (exemple: `d4e5f6g7-h8i9-j0k1-l2m3-n4o5p6q7r8s9`)

3. **Créer le compte d'authentification** (pour le login par téléphone) :

```sql
-- Lier l'utilisateur à l'authentification Supabase
-- IMPORTANT : Remplacer 'USER_ID' par l'ID retourné ci-dessus
UPDATE auth.users
SET raw_user_meta_data = jsonb_set(
  COALESCE(raw_user_meta_data, '{}'::jsonb),
  '{role}',
  '"police"'
)
WHERE phone = '+22670000001';
```

### Option B : Via l'interface Admin Dashboard

Si vous avez déjà un admin dashboard avec formulaire de création d'autorité :

1. Login admin : http://localhost:5173/admin
2. Cliquer sur **"Créer une autorité"**
3. Remplir :
   - Téléphone : `+22670000001`
   - Nom : `Ouédraogo`
   - Prénom : `Jean`
   - Rôle : `Police`
   - Zone : `Secteur 15 Ouagadougou`
4. Cliquer **Enregistrer**

---

## ÉTAPE 2 : Login avec le compte autorité

1. **Ouvrir l'app Flutter** (sur émulateur ou appareil réel)
2. Si vous êtes connecté, **se déconnecter** :
   - Aller dans Profil → Paramètres → Déconnexion
3. Sur l'écran de **Login**, entrer :
   - Numéro : `+22670000001`
   - Code OTP : `123456` (si env. dev) ou vérifier le SMS
4. **Valider le code**

### ✅ Résultat attendu

Après validation, l'app doit :
- ✅ Rediriger vers `/authority-home` (PAS `/home`)
- ✅ Afficher 3 onglets : **Accueil** | **Carte** | **Profil**
- ✅ Afficher les stats dans l'onglet Accueil (Reçus, En cours, Résolus, À traiter)

### ❌ Si ça redirige vers `/home` (interface citoyen)

**Problème** : Le rôle n'est pas reconnu comme autorité.

**Solution** : Vérifier le rôle dans la DB :

```sql
SELECT id, telephone, nom, prenom, role 
FROM users 
WHERE telephone = '+22670000001';
```

Le champ `role` doit être : `'police'`, `'hygiene'`, `'voirie'`, `'environnement'`, ou `'securite'`.

---

## ÉTAPE 3 : Tester l'onglet Accueil

1. Dans l'onglet **Accueil** :
   - ✅ Vérifier les **4 cartes de stats** :
     - 🔥 **Reçus aujourd'hui** (nombre de signalements créés aujourd'hui)
     - ⏳ **En cours** (signalements assignés à cette autorité)
     - ✅ **Résolus** (signalements résolus)
     - 📍 **À traiter** (signalements non résolus)
   - ✅ Vérifier la **liste des signalements**
   - ✅ Vérifier le **tri par proximité** (distance affichée : "350 m", "2.5 km")

2. Cliquer sur **"Voir la carte"** :
   - ✅ Doit naviguer vers l'onglet **Carte**

3. Cliquer sur **un signalement** dans la liste :
   - ✅ Doit ouvrir les détails du signalement

---

## ÉTAPE 4 : Tester l'onglet Carte

1. Aller dans l'onglet **Carte** :
   - ✅ La carte OpenStreetMap doit s'afficher
   - ✅ Un **marqueur bleu** (👤) doit montrer votre position actuelle
   - ✅ Des **marqueurs colorés** (🔴 🟠 🟢) doivent montrer les signalements

2. **Cliquer sur un marqueur rouge** (signalement en attente) :
   - ✅ Un **popup** doit s'ouvrir en bas de l'écran
   - ✅ Le popup doit afficher :
     - Photo du signalement (ou emoji de catégorie)
     - Description
     - Distance (ex: "à 450 m")
     - Catégorie (Déchets sauvages, Route endommagée, etc.)
     - Statut (badge coloré)
     - **3 boutons** :
       - 🚨 **Prendre en charge**
       - 🗺️ **Naviguer**
       - 👁️ **Voir détails**

3. **Tester le bouton "Naviguer"** :
   - Cliquer sur **Naviguer**
   - ✅ Google Maps doit s'ouvrir avec l'itinéraire vers le signalement

4. **Tester le bouton "Voir détails"** :
   - Cliquer sur **Voir détails**
   - ✅ L'écran de détails du signalement doit s'ouvrir

---

## ÉTAPE 5 : Tester "Prendre en charge"

C'est la fonctionnalité principale ! 🚨

1. Dans l'onglet **Carte**, cliquer sur un **marqueur rouge** (signalement en attente)
2. Dans le popup, cliquer sur **"Prendre en charge"**

### ✅ Résultat attendu

- ✅ Un **loader** doit apparaître : "Prise en charge en cours..."
- ✅ Après 1-2 secondes : **Snackbar vert** : "✅ Signalement pris en charge avec succès"
- ✅ Le popup doit **se fermer**
- ✅ Le marqueur doit **changer de couleur** (rouge → orange)
- ✅ La liste dans l'onglet **Accueil** doit se **mettre à jour**

### ❌ Erreurs possibles

#### Erreur : "Ce signalement a déjà été pris en charge"

**Cause** : Une autre autorité a déjà pris en charge ce signalement.

**Solution** : 
- Créer un nouveau signalement de test
- Ou libérer le signalement en base :

```sql
-- Libérer un signalement pour qu'il soit à nouveau disponible
UPDATE signalements
SET 
  assigned_to = NULL,
  locked = FALSE,
  statut = 'en_attente'
WHERE id = 'ID_DU_SIGNALEMENT';
```

#### Erreur : "Utilisateur non authentifié"

**Cause** : La session a expiré.

**Solution** : Se déconnecter et se reconnecter.

#### Erreur : "Undefined name 'take_charge_signalement'"

**Cause** : La migration SQL n'a pas été exécutée ou a échoué.

**Solution** : Retourner à **GUIDE_DEPLOYMENT_SQL.md** et vérifier que la fonction existe :

```sql
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_name = 'take_charge_signalement';
```

---

## ÉTAPE 6 : Vérifier dans la base de données

Après avoir pris en charge un signalement, vérifier les changements en DB :

```sql
-- Vérifier l'état du signalement
SELECT 
  id,
  description,
  statut,
  assigned_to,
  locked,
  created_at,
  updated_at
FROM signalements
WHERE id = 'ID_DU_SIGNALEMENT_PRIS_EN_CHARGE';
```

### ✅ Valeurs attendues

- `statut` : `'en_cours'` (avant : `'en_attente'`)
- `assigned_to` : `'ID_DE_LAUTORITE'` (avant : `NULL`)
- `locked` : `TRUE` (avant : `FALSE`)
- `updated_at` : horodatage récent

### Vérifier l'audit log

```sql
-- Voir l'historique des actions
SELECT 
  action_type,
  authority_id,
  signalement_id,
  performed_at
FROM authority_actions
WHERE signalement_id = 'ID_DU_SIGNALEMENT'
ORDER BY performed_at DESC;
```

### ✅ Résultat attendu

Une ligne avec :
- `action_type` : `'take_charge'`
- `authority_id` : ID de l'autorité connectée
- `performed_at` : horodatage de la prise en charge

---

## ÉTAPE 7 : Tester l'onglet Profil

1. Aller dans l'onglet **Profil**
2. Vérifier les informations affichées :
   - ✅ **Avatar** (icône de bouclier)
   - ✅ **Nom + Prénom** (Ouédraogo Jean)
   - ✅ **Badge de rôle** (Police / Hygiène / Voirie / etc.)
   - ✅ **Informations** (téléphone, email, zone d'intervention) - **non modifiables**
   - ✅ **Historique des interventions** (liste des signalements résolus)
   - ✅ **Filtres** : Aujourd'hui / Cette semaine / Tout
   - ✅ **Paramètres** : toggle localisation, toggle notifications

3. Tester le toggle **"Activer la localisation"** :
   - Désactiver → Réactiver
   - ✅ Vérifier que le marqueur bleu disparaît/réapparaît sur la carte

4. Tester **"Se déconnecter"** :
   - Cliquer sur le bouton rouge **"Se déconnecter"**
   - ✅ Une **popup de confirmation** doit apparaître
   - Confirmer
   - ✅ Redirection vers l'écran de **Login**

---

## ÉTAPE 8 : Tester avec plusieurs autorités (optionnel)

Pour tester le verrouillage des signalements :

1. **Créer une 2ème autorité** (exemple: Hygiène) :

```sql
INSERT INTO users (telephone, nom, prenom, role, zone_intervention)
VALUES ('+22670000002', 'Zoromé', 'Marie', 'hygiene', 'Secteur 12 Ouaga')
RETURNING id;
```

2. **Login avec l'autorité 1** (Police) :
   - Prendre en charge un signalement X

3. **Login avec l'autorité 2** (Hygiène) :
   - Essayer de prendre en charge **le même signalement X**
   - ✅ **Erreur attendue** : "Ce signalement a déjà été pris en charge"

4. **Vérifier le verrouillage en DB** :

```sql
SELECT 
  id,
  description,
  assigned_to,
  locked,
  statut
FROM signalements
WHERE id = 'ID_SIGNALEMENT_X';
```

- `assigned_to` doit pointer vers l'**Autorité 1** (Police)
- `locked` doit être `TRUE`
- `statut` doit être `'en_cours'`

---

## 🎯 CHECKLIST FINALE

### Navigation conditionnelle
- [ ] Login avec citoyen → redirige vers `/home` (Accueil / Signalement / Profil)
- [ ] Login avec autorité → redirige vers `/authority-home` (Accueil / Carte / Profil)

### Onglet Accueil
- [ ] Stats affichées (4 cartes : Reçus, En cours, Résolus, À traiter)
- [ ] Liste des signalements triée par proximité
- [ ] Distances affichées correctement ("350 m", "2.5 km")
- [ ] Bouton "Voir la carte" fonctionne

### Onglet Carte
- [ ] Carte OpenStreetMap s'affiche
- [ ] Marqueur bleu (position autorité) visible
- [ ] Marqueurs signalements colorés (rouge, orange, vert)
- [ ] Popup s'ouvre au clic sur un marqueur
- [ ] Bouton "Prendre en charge" fonctionne
- [ ] Bouton "Naviguer" ouvre Google Maps
- [ ] Bouton "Voir détails" ouvre l'écran de détails

### Prise en charge
- [ ] Loader "Prise en charge en cours..." s'affiche
- [ ] Snackbar vert de succès s'affiche
- [ ] Marqueur change de couleur (rouge → orange)
- [ ] Signalement verrouillé en DB (`locked = TRUE`)
- [ ] Signalement assigné (`assigned_to = ID_AUTORITE`)
- [ ] Statut mis à jour (`statut = 'en_cours'`)
- [ ] Action enregistrée dans `authority_actions`

### Onglet Profil
- [ ] Informations affichées (nom, rôle, zone)
- [ ] Historique des interventions visible
- [ ] Filtres fonctionnent (Aujourd'hui / Cette semaine / Tout)
- [ ] Toggle localisation fonctionne
- [ ] Déconnexion fonctionne avec popup de confirmation

---

## 🐛 TROUBLESHOOTING

### Problème : App crash au lancement

**Solution** :
```bash
flutter clean
flutter pub get
flutter run
```

### Problème : Marqueurs ne s'affichent pas

**Solution** : Vérifier que les signalements ont lat/lng :

```sql
SELECT id, description, latitude, longitude
FROM signalements
WHERE latitude IS NOT NULL AND longitude IS NOT NULL
LIMIT 10;
```

### Problème : "Failed to load network image"

**Cause** : URLs des photos invalides ou serveur d'images inaccessible.

**Solution temporaire** : Les emojis de catégorie s'afficheront à la place.

### Problème : Google Maps ne s'ouvre pas

**Cause** : Permissions URL Launcher non configurées.

**Solution Android** (`android/app/src/main/AndroidManifest.xml`) :

```xml
<queries>
  <intent>
    <action android:name="android.intent.action.VIEW" />
    <data android:scheme="https" />
  </intent>
  <intent>
    <action android:name="android.intent.action.VIEW" />
    <data android:scheme="geo" />
  </intent>
</queries>
```

---

## ✅ SUCCÈS !

Si tous les tests passent, votre interface Autorité est **100% fonctionnelle** ! 🎉

Les autorités peuvent maintenant :
- ✅ Se connecter avec leur rôle
- ✅ Voir les signalements en temps réel
- ✅ Voir leur position sur une carte
- ✅ Prendre en charge des signalements
- ✅ Naviguer vers les lieux d'intervention
- ✅ Consulter leur historique d'interventions

**Prochaines étapes** (optionnelles) :
- [ ] Implémenter la résolution de signalements (bouton "Marquer comme résolu")
- [ ] Ajouter l'upload de photo après intervention (`photo_apres`)
- [ ] Implémenter les notifications push (Firebase)
- [ ] Ajouter un filtre par catégorie dans l'onglet Carte
- [ ] Ajouter des statistiques avancées (temps moyen de résolution, taux de résolution, etc.)

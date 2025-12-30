# TOKSE Admin Dashboard

Interface d'administration web pour la plateforme TOKSE (Civic Engagement App).

## 🚀 Fonctionnalités

### ✅ Implémenté

#### 1. **Authentification Admin**
- Connexion sécurisée avec email/mot de passe
- Vérification du rôle admin via Supabase
- Routes protégées avec redirection automatique
- Gestion des sessions persistantes

#### 2. **Tableau de bord (Dashboard)**
- **Statistiques en temps réel:**
  - Total utilisateurs actifs
  - Nombre de citoyens
  - Nombre d'autorités
  - Signalements du jour
  - Signalements en cours
  - Signalements résolus
- **Autorités par rôle:** Affichage groupé des autorités par fonction
- **Actions rapides:** Accès direct aux fonctions principales
- **Preview carte:** Emplacement prévu pour la carte interactive

#### 3. **Gestion des utilisateurs**
- **Deux onglets:** CITOYENS / AUTORITÉS
- **Recherche avancée:** Par nom, email, téléphone
- **Consultation profil:** Informations complètes + historique signalements
- **Actions:**
  - Voir le profil détaillé
  - Désactiver/Réactiver un compte
  - Consulter l'historique d'activité

#### 4. **Journal d'activité (Logs)**
- **Suivi complet des actions:**
  - Désactivation de comptes
  - Réactivation de comptes
  - Création d'autorités
  - Modification de rôles
  - Traitement de signalements
- **Filtres par type d'action**
- **Mise à jour en temps réel** (Supabase Realtime)
- **Détails JSON** pour chaque action

#### 5. **Création d'autorités**
- **Formulaire complet:**
  - Nom, Prénom
  - Email
  - Numéro de téléphone
  - Rôle (Police municipale, Mairie, Hygiène, Voirie, etc.)
  - Mot de passe initial
- **Rôles disponibles:**
  - Police Municipale
  - Mairie
  - Service d'Hygiène
  - Service de Voirie
  - Service Environnement
  - Service de Sécurité
- **Validation et feedback** immédiat

#### 6. **Notifications & Demandes de suppression**
- **Système de suppression différée (48h):**
  - Notification immédiate à l'admin
  - Compte-à-rebours visible
  - Alerte urgente (< 6h restantes)
  - Désactivation automatique après 48h
- **Actions possibles:**
  - Désactiver manuellement
  - Annuler la demande
- **Règles appliquées pendant l'attente:**
  - ✅ Utilisateur peut consulter l'app
  - ❌ Modification de profil interdite
  - ❌ Création de signalements interdite

---

## 🛠️ Technologies

- **Frontend:** React 18 + Vite
- **Styling:** Tailwind CSS
- **Routing:** React Router v6
- **Backend:** Supabase (Auth, PostgreSQL, Realtime)
- **Icons:** Lucide React
- **Date handling:** date-fns
- **Charts:** Recharts (prévu)
- **Maps:** Leaflet + React-Leaflet (prévu)

---

## 📦 Installation

### Prérequis

- Node.js >= 18.x
- npm ou yarn
- Compte Supabase

### Étapes

1. **Installer les dépendances**
   ```bash
   cd tokse-admin
   npm install
   ```

2. **Configurer les variables d'environnement**
   
   Créer un fichier `.env`:
   
   ```env
   VITE_SUPABASE_URL=https://votre-projet.supabase.co
   VITE_SUPABASE_ANON_KEY=votre_cle_anonyme_ici
   ```

3. **Exécuter les migrations SQL**
   
   Dans Supabase SQL Editor, exécutez `MIGRATION_ADMIN_FEATURES.sql`

4. **Créer un compte admin**
   
   ```sql
   INSERT INTO utilisateurs (id, email, nom, prenom, role, est_actif)
   VALUES (uuid_generate_v4(), 'admin@tokse.com', 'Admin', 'Tokse', 'admin', TRUE);
   ```

5. **Lancer le serveur**
   ```bash
   npm run dev
   ```

6. **Accéder:** [http://localhost:5173](http://localhost:5173)

---

## 🔐 Sécurité

- **RLS (Row Level Security)** sur toutes les tables sensibles
- **Triggers de validation** pour comptes en attente de suppression
- **Auto-désactivation** après 48h via fonction SQL

---

## 📊 Fonctionnalités Realtime

- Logs d'activité en temps réel
- Notifications instantanées de demandes de suppression
- Statistiques automatiquement mises à jour

---

## 🚀 Déploiement

```bash
npm run build
```

Déployer le contenu de `dist/` sur Vercel, Netlify, ou serveur classique.

---

## 👨‍💻 Développeur

**AMIR TECH** - TOKSE Project © 2025


The React Compiler is not enabled on this template because of its impact on dev & build performances. To add it, see [this documentation](https://react.dev/learn/react-compiler/installation).

## Expanding the ESLint configuration

If you are developing a production application, we recommend using TypeScript with type-aware lint rules enabled. Check out the [TS template](https://github.com/vitejs/vite/tree/main/packages/create-vite/template-react-ts) for information on how to integrate TypeScript and [`typescript-eslint`](https://typescript-eslint.io) in your project.

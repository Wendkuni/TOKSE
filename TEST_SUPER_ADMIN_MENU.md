# ✅ Checklist de Test - Menu Super Admin

## Menu Principal (Sidebar)

### 1. 🏠 **Tableau de bord** (`/dashboard`)
- [ ] Le lien fonctionne
- [ ] Affiche les statistiques globales
- [ ] Affiche les cartes : Total Utilisateurs, Utilisateurs, Opérateurs, Signalements aujourd'hui, En cours, Résolus
- [ ] La carte interactive s'affiche correctement

**Statut attendu** : ✅ Page d'accueil avec vue d'ensemble du système

---

### 2. 👥 **Utilisateurs** (`/dashboard/users`)
- [ ] Le lien fonctionne
- [ ] Onglet "Utilisateurs" affiche les utilisateurs (role = 'citizen')
- [ ] Onglet "Opérateurs" affiche les opérateurs (tous les rôles sauf citizen et super_admin)
- [ ] Boutons "Voir profil" fonctionnent
- [ ] Boutons "Activer/Désactiver" fonctionnent
- [ ] Badge "Opérateur" avec icône bouclier apparaît correctement
- [ ] Recherche fonctionne
- [ ] Pagination fonctionne

**Statut attendu** : ✅ Gestion complète des utilisateurs et opérateurs

---

### 3. 📋 **Signalements** (`/dashboard/signalements`)
- [ ] Le lien fonctionne
- [ ] La carte Leaflet s'affiche
- [ ] Les clusters de signalements apparaissent
- [ ] Clic sur un marqueur ouvre un popup avec détails
- [ ] Le popup affiche : photo, catégorie, description, état, utilisateur, date, localisation
- [ ] Les filtres fonctionnent (catégorie, état, recherche)
- [ ] Légende s'affiche correctement

**Statut attendu** : ✅ Carte interactive des signalements

---

### 4. 📊 **Journal d'activité** (`/dashboard/logs`)
- [ ] Le lien fonctionne
- [ ] Liste des logs d'activité s'affiche
- [ ] Filtres fonctionnent (admin, action, dates, recherche)
- [ ] Pagination fonctionne
- [ ] Les badges de couleur s'affichent selon le type d'action
- [ ] Export fonctionne

**Statut attendu** : ✅ Suivi des actions des administrateurs

---

### 5. 🛡️ **Gestion Admins** (`/dashboard/admins`)
- [ ] Le lien fonctionne
- [ ] Liste des administrateurs s'affiche
- [ ] **Badge violet "Super Admin"** apparaît à côté de votre nom
- [ ] Bouton "Créer un admin" est accessible
- [ ] Bouton "Gérer permissions" fonctionne pour les admins normaux
- [ ] Bouton "Gérer permissions" est actif pour vous-même (super admin)
- [ ] Boutons "Activer/Désactiver" fonctionnent
- [ ] Bouton "Supprimer" est désactivé pour vous-même
- [ ] Création d'un admin enregistre un log dans Audit Système
- [ ] Pagination fonctionne

**Statut attendu** : ✅ Gestion complète des administrateurs avec hiérarchie des permissions

---

### 6. 🔍 **Audit Système** (`/dashboard/audit`)
- [ ] Le lien fonctionne
- [ ] Statistiques globales s'affichent
- [ ] Cartes : Total actions, Admins actifs, Actions aujourd'hui, Actions sensibles
- [ ] Cartes utilisateurs : Total, Actifs, Utilisateurs standards actifs, Opérateurs actifs
- [ ] Liste des logs d'audit s'affiche
- [ ] Filtres fonctionnent (admin, action, dates, recherche)
- [ ] **Vous voyez les logs de création d'admins** (ex: Bitchibali Stephane)
- [ ] Les logs mentionnent "TOKSE Admin" ou votre nom comme créateur
- [ ] Bouton "Générer rapport d'audit (PDF)" fonctionne
- [ ] Le PDF généré utilise la terminologie correcte (Utilisateur/Opérateur)
- [ ] Pagination fonctionne

**Statut attendu** : ✅ Audit complet avec logs détaillés et rapport PDF

---

### 7. ➕ **Créer opérateur** (`/dashboard/create-authority`)
- [ ] Le lien fonctionne
- [ ] Formulaire de création s'affiche
- [ ] Champs : Nom, Prénom, Email, Téléphone, Mot de passe
- [ ] Liste des rôles disponibles (Police, Mairie, Hygiène, Voirie, etc.)
- [ ] Sélection de la zone d'intervention
- [ ] Bouton "Créer l'opérateur" fonctionne
- [ ] Un log est créé dans logs_activite
- [ ] Le nouveau compte apparaît dans l'onglet "Utilisateurs" > "Opérateurs"

**Statut attendu** : ✅ Création d'opérateurs avec rôles spécifiques

---

### 8. 🔔 **Notifications** (`/dashboard/notifications`)
- [ ] Le lien fonctionne
- [ ] Liste des notifications s'affiche
- [ ] Filtres fonctionnent (type, statut)
- [ ] Boutons "Marquer comme lu" fonctionnent
- [ ] Création de notification fonctionne
- [ ] Pagination fonctionne

**Statut attendu** : ✅ Système de notifications

---

### 9. 📈 **Statistiques** (`/dashboard/statistics`)
- [ ] Le lien fonctionne
- [ ] Graphiques s'affichent (par catégorie, par statut, tendances)
- [ ] Filtres de période fonctionnent (semaine, mois, année)
- [ ] Taux de résolution affiché
- [ ] Temps de réponse moyen affiché
- [ ] Top autorités affiché
- [ ] Graphiques interactifs (Recharts)

**Statut attendu** : ✅ Visualisation des données

---

### 10. ⚙️ **Mon profil** (`/dashboard/profile`)
- [ ] Le lien fonctionne
- [ ] Informations du profil s'affichent
- [ ] Email affiché
- [ ] **Rôle affiché : "Super Administrateur"**
- [ ] Modification du profil fonctionne
- [ ] Changement de mot de passe fonctionne

**Statut attendu** : ✅ Gestion du profil personnel

---

### 11. 🚪 **Déconnexion**
- [ ] Le bouton "Déconnexion" fonctionne
- [ ] Redirection vers `/login`
- [ ] Session effacée (localStorage vidé)
- [ ] Impossible d'accéder aux pages protégées après déconnexion

**Statut attendu** : ✅ Déconnexion propre

---

### 12. 🔄 **Toggle Menu (Nouveau)**
- [ ] Le bouton rond avec flèche apparaît
- [ ] Clic cache le menu (sidebar collapse)
- [ ] Clic réaffiche le menu
- [ ] Le contenu principal s'ajuste (marge dynamique)
- [ ] Animation fluide (transition 300ms)
- [ ] Icône change (ChevronLeft ⟷ ChevronRight)

**Statut attendu** : ✅ Menu collapsible fonctionnel

---

## Vérifications Spécifiques Super Admin

### A. Permissions Système
- [ ] Vous pouvez créer des administrateurs
- [ ] Vous pouvez modifier les permissions de n'importe quel admin (même un autre super admin si nécessaire)
- [ ] Vous pouvez désactiver/activer n'importe quel admin (sauf vous-même pour la suppression)
- [ ] Vous pouvez voir TOUS les logs d'activité (y compris les vôtres)
- [ ] Badge "Super Admin" violet affiché dans Gestion Admins

### B. Comportement au Login
- [ ] Login avec antoinekonate@gmail.com redirige vers `/dashboard` (pas `/autorite`)
- [ ] `localStorage.getItem('admin_role')` retourne `"super_admin"`
- [ ] Aucune restriction de permissions dans l'interface

### C. Logs et Audit
- [ ] Les logs de création d'admin mentionnent votre nom ("TOKSE Admin" ou "Admin TOKSE")
- [ ] Les logs de modification de permissions mentionnent admin_modificateur et admin_cible
- [ ] Le rapport PDF d'audit affiche :
  - "Application mobile utilisateur" (pas citoyenne)
  - "Application mobile opérateur" (pas autorité)
  - "Utilisateurs (Créateurs de signalements)" (pas Citoyens)
  - "Opérateurs (Gestionnaires de signalements)" (pas Autorités)
  - "Utilisateurs standards actifs" (pas Citoyens actifs)
  - "Opérateurs actifs" (pas Autorités actives)

---

## 🐛 Problèmes Courants

### Si une page ne s'affiche pas :
1. Ouvrir la console (F12)
2. Vérifier les erreurs JavaScript
3. Vérifier que `localStorage.getItem('admin_role')` = `"super_admin"`
4. Essayer `localStorage.clear()` puis se reconnecter

### Si vous êtes redirigé vers le panel opérateur :
1. Vider le cache : `localStorage.clear()`
2. Se déconnecter
3. Se reconnecter
4. Vérifier dans Supabase que `role = 'super_admin'` dans la table `users`

### Si les permissions ne fonctionnent pas :
1. Vérifier dans la console : `JSON.parse(localStorage.getItem('admin_user')).role`
2. Devrait afficher `"super_admin"`
3. Si c'est `"admin"`, refaire la requête SQL `UPDATE users SET role = 'super_admin' WHERE email = 'antoinekonate@gmail.com'`

---

## ✅ Checklist Complète

- [ ] Tous les liens du menu fonctionnent
- [ ] Toutes les pages s'affichent correctement
- [ ] Le badge "Super Admin" est visible
- [ ] Les permissions sont illimitées
- [ ] Les logs sont enregistrés avec le bon créateur
- [ ] Le rapport PDF utilise la bonne terminologie
- [ ] Le menu toggle fonctionne
- [ ] La déconnexion fonctionne

---

**Date du test** : _____________
**Testeur** : TOKSE Admin (antoinekonate@gmail.com)
**Rôle** : Super Administrateur

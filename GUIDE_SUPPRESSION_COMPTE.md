# Système Complet de Suppression de Compte Utilisateur

## ✅ État Actuel de l'Implémentation

### Ce qui était déjà fait :
1. ✅ Table `account_deletion_requests` (créée mais nommée `deletion_requests`)
2. ✅ Bouton de suppression dans le profil utilisateur
3. ✅ Délai de 48h avant suppression
4. ✅ Possibilité d'annuler la demande

### Ce qui manquait :
1. ❌ **Notifications aux admins** lors d'une demande de suppression
2. ❌ **Suppression automatique après 48h** par le système
3. ❌ **Bouton trop visible** (gros bouton rouge)
4. ❌ **Logique de réactivation** claire

---

## ❓ Question Fréquente : Réactivation juste après la demande ?

### Réponse : Ça dépend du statut du compte !

**CAS 1 : AVANT les 48h (compte actif)** → "Annuler la suppression"
- ✅ Annulation **IMMÉDIATE** 
- ✅ Pas besoin d'admin
- ✅ Retour à la normale instantané

**CAS 2 : APRÈS les 48h (compte désactivé)** → "Demander la réactivation"
- ⏳ **Nécessite approbation admin**
- ⏳ Notification envoyée aux admins
- ⏳ Réactivation après validation

---

## 🔧 Modifications Apportées

### 1. Application Mobile Flutter (`profile_screen.dart`)

**AVANT** : Gros bouton rouge très visible avec icône
```dart
OutlinedButton.icon(
  icon: const Icon(Icons.delete_forever, size: 20),
  label: const Text('Supprimer le compte', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
  style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFc0392b), ...)
)
```

**APRÈS** : Petit lien texte discret en gris
```dart
TextButton(
  child: const Text('Supprimer mon compte', 
    style: TextStyle(fontSize: 13, color: Colors.grey, decoration: TextDecoration.underline)
  )
)
```

✅ **Résultat** : Le bouton est maintenant très discret, en bas de la page, en petit, en gris

---

### 2. Base de Données SQL

#### Fichier 1 : `FIX_RENAME_DELETION_TABLE.sql`
**But** : Corriger l'incohérence de nommage

- Renomme `deletion_requests` → `account_deletion_requests` 
- Met à jour tous les index associés
- Assure la cohérence avec le code Flutter

#### Fichier 2 : `COMPLETE_DELETION_SYSTEM.sql`
**But** : Système complet de suppression avec notifications et auto-suppression

**Composants créés** :

1. **Politique RLS pour admins**
   - Permet aux admins/super_admins de voir toutes les demandes de suppression

2. **Fonction `notify_admins_on_deletion_request()`**
   - Envoie une notification à TOUS les admins/super_admins
   - Contient : email utilisateur, nom, date de suppression prévue
   - Type de notification : `'account_deletion_request'`

3. **Trigger automatique**
   - Se déclenche à chaque INSERT dans `account_deletion_requests`
   - Appelle automatiquement la fonction de notification

4. **Fonction `auto_delete_expired_accounts()`**
   - Trouve toutes les demandes pending dont la date est dépassée
   - Désactive les comptes (is_active = false)
   - Marque les demandes comme 'completed'
   - Log l'action dans `logs_activite`

5. **Job pg_cron** (à activer manuellement)
   - Exécute `auto_delete_expired_accounts()` toutes les heures
   - Commande : `SELECT cron.schedule('auto-delete-expired-accounts', '0 * * * *', ...)`

6. **Fonction `cancel_deletion_request(request_id)`**
   - Permet à l'utilisateur d'annuler sa propre demande
   - Vérifie que la demande est bien 'pending'

7. **Fonction `admin_process_deletion_request(request_id, approve)`**
   - Permet à un admin de traiter immédiatement une demande
   - Si approve=true : désactive le compte immédiatement
   - Si approve=false : annule la demande
   - Log l'action dans `logs_activite`

8. **Vue `admin_deletion_requests_view`**
   - Vue SQL pour afficher toutes les demandes avec les infos utilisateur
   - Calcule les heures restantes avant suppression automatique

---

## 📋 Instructions d'Installation

### Étape 1 : Base de données
```sql
-- 1. Renommer la table (si elle existe sous l'ancien nom)
-- Exécuter dans Supabase SQL Editor
\i FIX_RENAME_DELETION_TABLE.sql

-- 2. Installer le système complet
\i COMPLETE_DELETION_SYSTEM.sql
```

### Étape 2 : Activer pg_cron
1. Aller dans Supabase Dashboard
2. Database > Extensions
3. Activer `pg_cron` si pas déjà fait

### Étape 3 : Créer le job cron
```sql
-- Exécuter en tant que super user dans SQL Editor
SELECT cron.schedule(
  'auto-delete-expired-accounts',
  '0 * * * *',  -- Toutes les heures à minute 0
  $$ SELECT auto_delete_expired_accounts(); $$
);
```

### Étape 4 : Vérifier l'installation
```sql
-- Vérifier que le job est créé
SELECT * FROM cron.job;

-- Tester manuellement la fonction
SELECT auto_delete_expired_accounts();
```

---

## 🎯 Fonctionnement du Système

### Scénario 1 : Utilisateur demande la suppression

1. **Utilisateur clique sur "Supprimer mon compte"** (lien discret en bas du profil)
2. **Popup de confirmation** : "Votre compte sera supprimé après 48h..."
3. **Si confirmation** :
   - Insert dans `account_deletion_requests` avec `status='pending'`
   - Date de suppression = NOW() + 48h
4. **Trigger automatique** :
   - ✅ Notification envoyée à TOUS les admins
   - Notification visible dans le panneau admin
5. **Pendant les 48h** :
   - L'utilisateur peut annuler via le profil
   - Un admin peut approuver ou refuser immédiatement
6. **Après 48h** :
   - Job cron s'exécute toutes les heures
   - Trouve les demandes expirées
   - ✅ Désactive automatiquement le compte (is_active=false)
   - Marque la demande comme 'completed'
   - Log l'action

### Scénario 2 : Admin traite la demande

**Option A : Approuver immédiatement**
```sql
SELECT admin_process_deletion_request('request_id', true);
```
- Compte désactivé immédiatement
- Pas besoin d'attendre 48h

**Option B : Refuser la demande**
```sql
SELECT admin_process_deletion_request('request_id', false);
```
- Demande annulée
- Compte reste actif

---

## 🔍 Interface Admin à Créer

### Page "Demandes de Suppression" (à ajouter dans tokse-admin)

Afficher la vue `admin_deletion_requests_view` avec :
- Email, nom, prénom de l'utilisateur
- Date de la demande
- Date de suppression prévue
- Heures restantes
- Statut (pending/completed/cancelled)
- Boutons : "Approuver" / "Refuser"

### Notifications

Les admins reçoivent déjà les notifications dans la table `notifications` avec :
- Type : `'account_deletion_request'`
- Titre : "Demande de suppression de compte"
- Message : Détails de l'utilisateur et date prévue
- Data JSON : `user_id`, `deletion_request_id`, `deletion_scheduled_for`, `user_email`

---

## 📊 Requêtes Utiles

```sql
-- Voir toutes les demandes pending
SELECT * FROM admin_deletion_requests_view WHERE status = 'pending';

-- Voir les demandes qui vont expirer dans moins de 6h
SELECT * FROM admin_deletion_requests_view 
WHERE status = 'pending' AND hours_remaining < 6;

-- Historique des suppressions
SELECT * FROM admin_deletion_requests_view 
WHERE status = 'completed' 
ORDER BY completed_at DESC;

-- Vérifier les notifications envoyées
SELECT * FROM notifications 
WHERE type = 'account_deletion_request' 
ORDER BY created_at DESC;

-- Voir les logs de suppression automatique
SELECT * FROM logs_activite 
WHERE type_action = 'suppression_compte_auto'
ORDER BY created_at DESC;
```

---

## ✅ Checklist de Validation

- [x] Table renommée en `account_deletion_requests`
- [x] Bouton de suppression rendu discret (petit lien gris)
- [x] Notifications aux admins lors d'une demande
- [x] Trigger automatique fonctionnel
- [x] Fonction de suppression automatique après 48h
- [ ] Job pg_cron activé (à faire manuellement)
- [ ] Interface admin pour gérer les demandes (à créer)
- [x] Fonction pour admin de traiter immédiatement
- [x] Fonction pour utilisateur d'annuler
- [x] Logs dans `logs_activite`

---

## 🚨 Important

1. **pg_cron doit être activé** dans Supabase Extensions
2. **Le job cron doit être créé** avec la commande `cron.schedule`
3. **Tester en dev** avant de déployer en production
4. **Créer l'interface admin** pour visualiser et gérer les demandes

---

## 🔄 Alternative : Edge Function

Si pg_cron ne fonctionne pas, créer une Edge Function Supabase :

```typescript
// supabase/functions/auto-delete-accounts/index.ts
import { createClient } from '@supabase/supabase-js'

Deno.serve(async (req) => {
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  )
  
  const { data, error } = await supabase.rpc('auto_delete_expired_accounts')
  
  return new Response(JSON.stringify({ success: !error, data, error }), {
    headers: { 'Content-Type': 'application/json' }
  })
})
```

Puis appeler cette fonction via un cron externe (Cron-Job.org, GitHub Actions, etc.)

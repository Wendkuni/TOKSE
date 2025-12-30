# 🔧 Guide de Débogage - Pages qui ne fonctionnent pas

## 1. Journal d'activité (`/dashboard/logs`)

### Symptômes possibles :
- ❌ Page blanche
- ❌ Spinner qui tourne à l'infini
- ❌ Message "Aucun log trouvé" alors qu'il y en a

### Diagnostic dans la console (F12) :

```javascript
// Vérifier la connexion Supabase
const { data, error } = await supabase.from('logs_activite').select('*').limit(1)
console.log('Test logs_activite:', data, error)

// Vérifier les foreign keys
const { data: logs } = await supabase.from('logs_activite').select('*').limit(1)
console.log('Premier log:', logs[0])
console.log('autorite_id:', logs[0]?.autorite_id)
console.log('utilisateur_cible_id:', logs[0]?.utilisateur_cible_id)
```

### Solutions :
1. **Si erreur "relation does not exist"** :
   - La table `logs_activite` n'existe pas dans Supabase
   - Créez-la avec la migration appropriée

2. **Si erreur de jointure** :
   - Les foreign keys ne sont pas bien configurées
   - Vérifiez que `autorite_id` et `utilisateur_cible_id` pointent vers la table `users`

3. **Si aucune donnée** :
   - Il n'y a pas encore de logs
   - Créez un admin pour générer un log de création

### Ce que les corrections font :
✅ Gestion d'erreur améliorée avec logs console
✅ Fallback vers requête simple si les jointures échouent
✅ Messages d'erreur explicites dans la console

---

## 2. Audit Système (`/dashboard/audit`)

### Symptômes possibles :
- ❌ Statistiques affichent 0 partout
- ❌ Liste des logs vide
- ❌ Bouton "Générer rapport PDF" ne fait rien

### Diagnostic dans la console (F12) :

```javascript
// Vérifier les statistiques
const { count: totalUsers } = await supabase.from('users').select('*', { count: 'exact', head: true })
console.log('Total utilisateurs:', totalUsers)

const { count: totalSignalements } = await supabase.from('signalements').select('*', { count: 'exact', head: true })
console.log('Total signalements:', totalSignalements)

// Vérifier les logs avec détails
const { data: logs } = await supabase.from('logs_activite').select('*').limit(5)
console.log('Logs d\'audit:', logs)
```

### Solutions :
1. **Si statistiques = 0** :
   - Les requêtes retournent `null` au lieu de `0`
   - Les corrections ajoutent `|| 0` partout

2. **Si rapport PDF vide** :
   - `jsPDF` ou `jspdf-autotable` non installés
   - Vérifiez dans `tokse-admin/package.json`

3. **Si logs vides mais il y en a** :
   - Problème de récupération des infos admin/cible
   - Les corrections ajoutent des logs console pour diagnostiquer

### Ce que les corrections font :
✅ Logs console à chaque étape (`console.log('📋 Logs récupérés:', ...)`)
✅ Gestion d'erreur pour les requêtes de users
✅ Affichage des erreurs Supabase explicites

---

## 3. Statistiques (`/dashboard/statistics`)

### Symptômes possibles :
- ❌ Graphiques ne s'affichent pas
- ❌ "Aucune donnée disponible"
- ❌ Erreur `Recharts` dans la console

### Diagnostic dans la console (F12) :

```javascript
// Vérifier les signalements
const { data: signalements } = await supabase.from('signalements').select('*')
console.log('Signalements:', signalements)
console.log('Par catégorie:', signalements.reduce((acc, s) => {
  acc[s.categorie] = (acc[s.categorie] || 0) + 1
  return acc
}, {}))

// Vérifier Recharts
console.log('Recharts disponible:', typeof window.Recharts !== 'undefined')
```

### Solutions :
1. **Si aucun signalement** :
   - La table est vide
   - Créez des signalements depuis l'app mobile ou directement dans Supabase

2. **Si erreur de date** :
   - Bug dans le calcul de `startDate` (modifiait l'objet `now`)
   - ✅ **CORRIGÉ** : Création de nouvelles dates à chaque fois

3. **Si Recharts ne charge pas** :
   - Vérifiez `package.json` : `"recharts": "^2.x.x"`
   - Réinstallez : `npm install recharts`

### Ce que les corrections font :
✅ Correction du bug de date (ne modifie plus `now`)
✅ Logs console pour voir période et nombre de signalements
✅ Gestion d'erreur avec message explicite

---

## 🔍 Comment Déboguer (Instructions Pas à Pas)

### Étape 1 : Ouvrir la Console
1. Appuyez sur **F12** dans Chrome/Edge
2. Allez dans l'onglet **Console**
3. Naviguez vers la page qui ne fonctionne pas

### Étape 2 : Lire les Messages
Recherchez :
- ❌ Messages en **rouge** (erreurs)
- ⚠️ Messages en **jaune** (avertissements)
- 📋 Messages commençant par un emoji (mes logs de debug)

### Étape 3 : Tester Manuellement
Dans la console, collez et exécutez :

```javascript
// Importer supabase (si pas déjà fait)
import { supabase } from './lib/supabase'

// Test Journal d'activité
const testLogs = async () => {
  const { data, error } = await supabase.from('logs_activite').select('*').limit(10)
  console.log('✅ Logs:', data?.length, 'erreur:', error)
}
testLogs()

// Test Audit
const testAudit = async () => {
  const { count } = await supabase.from('users').select('*', { count: 'exact', head: true })
  console.log('✅ Total users:', count)
}
testAudit()

// Test Statistiques
const testStats = async () => {
  const { data } = await supabase.from('signalements').select('*')
  console.log('✅ Signalements:', data?.length)
}
testStats()
```

### Étape 4 : Envoyer les Résultats
Copiez-moi les messages de la console, notamment :
- Les erreurs en rouge
- Les logs avec emojis (📋, 📊, ❌, etc.)
- Les résultats des tests manuels

---

## 🚀 Actions Rapides

### Si rien ne s'affiche du tout :
```bash
# Dans tokse-admin/
npm install
npm run dev
```

### Si erreur "Module not found" :
```bash
cd tokse-admin
npm install jspdf jspdf-autotable recharts
```

### Si erreur Supabase :
1. Vérifiez `.env` dans `tokse-admin/`
2. Vérifiez que les clés Supabase sont valides
3. Testez la connexion dans la console

---

## ✅ Checklist de Vérification

Avant de dire qu'une page ne fonctionne pas :

- [ ] J'ai rafraîchi la page (F5)
- [ ] J'ai vidé le cache (Ctrl+Shift+R)
- [ ] J'ai ouvert la console (F12)
- [ ] J'ai regardé les messages d'erreur
- [ ] J'ai testé manuellement dans la console
- [ ] J'ai vérifié que Supabase fonctionne (autre page OK)

Si tout est coché et ça ne marche toujours pas, copiez-moi le contenu de la console ! 🔍

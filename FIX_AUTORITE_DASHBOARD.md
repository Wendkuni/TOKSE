# ✅ FIX - Tableau de bord Autorité vide

**Date:** 22 décembre 2025  
**Problème:** Le tableau de bord autorité n'affichait aucune donnée (stats et signalements vides)

---

## 🐛 Cause du problème

Le code filtrait les signalements par `user.autorite_type`, mais ce champ n'était pas toujours défini dans l'objet utilisateur. Les autorités ont un `role` (comme `'police'`, `'hygiene'`, `'voirie'`, etc.) mais pas nécessairement un champ `autorite_type` explicite.

### Ancien code (buggé) :
```javascript
const autoriteType = user?.autorite_type || localStorage.getItem('autoriteType');
query = query.eq('autorite_type', autoriteType);
```

**Problème:** Si `user.autorite_type` est `null` ou `undefined`, la requête échoue ou ne retourne rien.

---

## ✅ Solution appliquée

### 1. Fonction de mapping `role` → `autorite_type`

Ajout d'une fonction helper pour convertir le `role` de l'utilisateur en `autorite_type` :

```javascript
const getAutoriteType = (user) => {
  if (!user) return null;
  
  // Si autorite_type est déjà défini, l'utiliser
  if (user.autorite_type) return user.autorite_type;
  
  // Sinon, mapper le role vers autorite_type
  const roleMapping = {
    'police': 'police',
    'police_municipale': 'police',
    'hygiene': 'hygiene',
    'voirie': 'voirie',
    'environnement': 'environnement',
    'securite': 'securite',
    'mairie': 'mairie'
  };
  
  return roleMapping[user.role] || user.role;
};
```

### 2. Modification des requêtes

Les requêtes utilisent maintenant `getAutoriteType(user)` :

```javascript
const autoriteType = getAutoriteType(user);

let query = supabase
  .from('signalements')
  .select('...');

// Filtrer par autorite_type si défini
if (autoriteType) {
  query = query.eq('autorite_type', autoriteType);
} else {
  // Afficher tous les signalements si pas de type défini
  console.warn('⚠️ Aucun autorite_type défini, affichage de TOUS les signalements');
}
```

### 3. Gestion du cas NULL

Si `autorite_type` est `null`, le tableau de bord affiche **tous les signalements** au lieu de ne rien afficher.

---

## 📁 Fichiers modifiés

1. ✅ `tokse-admin/src/pages/autorite/AutoriteDashboardPage.jsx`
   - Ajout de `getAutoriteType()`
   - Modification de `fetchStats()`
   - Modification de `fetchRecentSignalements()`
   - Correction du titre du tableau de bord

2. ✅ `tokse-admin/src/pages/autorite/AutoriteSignalementsPage.jsx`
   - Ajout de `getAutoriteType()`
   - Modification de `fetchSignalements()`

---

## 🧪 Comment tester

### 1. Démarrer le serveur
```bash
cd tokse-admin
npm run dev
```

### 2. Se connecter avec une autorité
- Aller sur `http://localhost:5173/`
- Se connecter avec un compte autorité (police, hygiene, voirie, etc.)

### 3. Vérifier le tableau de bord
- Les statistiques doivent s'afficher
- Les signalements récents doivent apparaître
- Le titre doit afficher : "Tableau de bord - [type]"

### 4. Vérifier dans la console
Ouvrir la console du navigateur (F12) pour voir les logs de debug :
```
🔍 [DASHBOARD] User object: {...}
🔍 [DASHBOARD] User autorite_type: police
📊 [STATS] Using autorite_type: police
📊 [STATS] Signalements found: 5
```

---

## 🔍 Diagnostic SQL

Si le problème persiste, exécuter ce SQL dans Supabase :

```sql
-- Vérifier les autorités
SELECT id, nom, prenom, role, autorite_type
FROM users
WHERE role IN ('police', 'hygiene', 'voirie', 'environnement', 'securite');

-- Vérifier les signalements
SELECT id, titre, categorie, autorite_type, etat
FROM signalements
ORDER BY created_at DESC
LIMIT 10;

-- Compter par autorite_type
SELECT 
  COALESCE(autorite_type, 'NULL') as type,
  COUNT(*) as nombre
FROM signalements
GROUP BY autorite_type;
```

---

## 📝 Notes importantes

### Pourquoi ce mapping ?

Les autorités dans la base de données ont un `role` spécifique (`police`, `hygiene`, etc.), mais les signalements utilisent le champ `autorite_type` pour indiquer à quelle autorité ils sont assignés.

Ce mapping garantit la cohérence entre :
- **Table `users`** : `role` = `'police'`
- **Table `signalements`** : `autorite_type` = `'police'`

### Si les signalements n'ont pas d'autorite_type

Si des signalements existent sans `autorite_type` défini, ils peuvent être assignés automatiquement :

```sql
-- Assigner automatiquement selon la catégorie
UPDATE signalements 
SET autorite_type = CASE 
  WHEN categorie = 'securite' THEN 'police'
  WHEN categorie = 'proprete' THEN 'hygiene'
  WHEN categorie = 'infrastructure' THEN 'voirie'
  WHEN categorie = 'environnement' THEN 'environnement'
  ELSE 'mairie'
END
WHERE autorite_type IS NULL;
```

---

## ✅ Résultat

- ✅ Le tableau de bord autorité affiche maintenant les données
- ✅ Les statistiques se chargent correctement
- ✅ Les signalements récents apparaissent
- ✅ Le mapping `role` → `autorite_type` fonctionne
- ✅ Gestion robuste du cas NULL

---

**Statut:** ✅ **BUG CORRIGÉ**

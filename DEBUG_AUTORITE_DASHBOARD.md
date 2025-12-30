# 🐛 DEBUG - Tableau de bord Autorité vide

## Problème
Le tableau de bord du panel autorité (tokse-admin) n'affiche aucune donnée.

## Causes potentielles

### 1. Problème avec `autorite_type`
- Le code filtre les signalements par `autorite_type`
- Mais `autorite_type` peut être `null` ou ne pas correspondre au `role` de l'utilisateur

### 2. Mapping role ↔ autorite_type
- Dans la table `users`, les autorités ont un `role` : `'police'`, `'hygiene'`, `'voirie'`, etc.
- Dans la table `signalements`, il y a un champ `autorite_type` qui devrait correspondre
- Le problème : **le mapping n'est peut-être pas cohérent**

### 3. Différence entre `role` et `autorite_type`
```
Table users:
- role: 'police', 'hygiene', 'voirie', 'environnement', 'securite'

Table signalements:
- autorite_type: ??? (doit correspondre au role)
```

## Solutions

### Option A : Utiliser `role` directement
Au lieu de filtrer par `autorite_type`, on pourrait filtrer par `role` de l'utilisateur connecté.

### Option B : Mapper `role` → `autorite_type`
Créer une correspondance explicite :
```js
const roleToAutoriteType = {
  'police': 'police',
  'police_municipale': 'police',
  'hygiene': 'hygiene',
  'voirie': 'voirie',
  'environnement': 'environnement',
  'securite': 'securite',
  'mairie': 'mairie'
};
```

### Option C : Afficher TOUS les signalements si `autorite_type` est null
Si l'autorité n'a pas de type spécifique, afficher tous les signalements.

## Prochaines étapes
1. ✅ Ajouter des logs de debug dans AutoriteDashboardPage.jsx
2. 🔄 Démarrer le serveur et vérifier les logs dans la console
3. 🔍 Vérifier dans la base de données les valeurs de `autorite_type` des signalements
4. 🔧 Implémenter la solution appropriée

## Logs ajoutés
- `user` object
- `user.autorite_type`
- `localStorage.getItem('autoriteType')`
- Résultat des requêtes Supabase

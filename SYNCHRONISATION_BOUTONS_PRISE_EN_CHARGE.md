# Synchronisation automatique en temps réel

## Problèmes résolus

1. **Boutons "Prendre en charge"** : Quand une autorité prend en charge un signalement depuis n'importe quel écran (carte, liste, détails), tous les autres boutons "Prendre en charge" du même signalement se grisent instantanément.

2. **Statistiques** : Les statistiques (aujourd'hui, en cours, résolus) se mettent à jour automatiquement sur tous les écrans.

3. **Historique** : L'historique des interventions se rafraîchit automatiquement dans les profils.

## Solution mise en place

### 1. Service de Broadcasting (`SignalementStateService`)

**Fichier:** `lib/core/services/signalement_state_service.dart`

Service singleton qui diffuse les changements d'état des signalements à tous les écrans en temps réel.

**Fonctionnalités:**
- `notifyTakeCharge(signalementId, agentId)` - Diffuse qu'un signalement a été pris en charge
- `notifyResolve(signalementId)` - Diffuse qu'un signalement a été résolu
- `notifyUpdate(signalementId)` - Diffuse une mise à jour générique
- `stateChanges` - Stream pour écouter les événements

### 2. Écrans modifiés

Tous les écrans ont été modifiés pour écouter les changements en temps réel :

#### authority_home_screen.dart
- **Broadcaster:** Après prise en charge réussie dans `_takeChargeAndGoToMap()`
- **Listener:** Écoute les changements et recharge `_loadData()`
- **UI:** Bouton déjà conditionné par `isMySignalement` (vérifie `locked` et `assignedTo`)
- **Stats:** Les statistiques (aujourd'hui, en cours, résolus) se recalculent automatiquement

#### authority_map_screen.dart
- **Broadcaster:** Après prise en charge réussie dans `_takeChargeFromMap()` et `_takeCharge()`
- **Broadcaster:** Après résolution réussie dans `_resolveSignalement()`
- **Listener:** Écoute les changements et recharge `_loadData()`
- **UI:** 
  - Bouton principal désactivé si `locked == true`
  - Bouton dans popup (marqueur) caché si `locked == true`

#### signalement_detail_screen.dart
- **Broadcaster:** Après prise en charge réussie dans `_takeChargeSignalement()`
- **Listener:** Écoute les changements et recharge si c'est notre signalement
- **UI:** Bouton désactivé et texte changé si `locked == true`

#### profile_screen.dart (Citoyen)
- **Listener:** Écoute les changements et recharge `_loadProfileData()`
- **Stats:** Les statistiques utilisateur se mettent à jour automatiquement
- **Liste:** La liste des signalements de l'utilisateur se rafraîchit

#### authority_profile_screen.dart (Autorité)
- **Listener:** Écoute les changements et recharge `_loadData()`
- **Historique:** L'historique des interventions se met à jour automatiquement

### 3. Flux de synchronisation

```
Autorité clique "Prendre en charge" (écran A)
         ↓
API Supabase met à jour signalement (locked = true, assigned_to = agent_id)
         ↓
Succès retourné à l'écran A
         ↓
SignalementStateService.notifyTakeCharge() broadcast l'événement
         ↓
Tous les écrans (B, C, D...) reçoivent l'événement via leur StreamSubscription
         ↓
Chaque écran appelle _loadData() pour recharger depuis Supabase
         ↓
UI se rebuild automatiquement avec locked = true
         ↓
Tous les boutons "Prendre en charge" du même signalement se grisent
```

### 4. Conditions d'affichage des boutons

| Écran | Condition | Comportement |
|-------|-----------|--------------|
| **authority_home_screen** | `isMySignalement` (locked && assignedTo == moi) | Bouton null, affiche "Déjà pris en charge" grisé |
| **authority_map_screen (principal)** | `!locked` | Bouton désactivé + texte "Déjà pris en charge" |
| **authority_map_screen (popup)** | `!locked` | Bouton caché complètement |
| **signalement_detail_screen** | `locked` | Bouton désactivé + icône lock + texte adapté |

### 5. Avantages

✅ **Synchronisation temps réel** - Pas besoin de rafraîchir manuellement  
✅ **Aucun doublon** - Impossible de prendre en charge 2 fois le même signalement  
✅ **UX cohérente** - L'état est identique partout (boutons, stats, historique)  
✅ **Performance** - Rechargement intelligent uniquement quand nécessaire  
✅ **Maintenable** - Service centralisé facile à déboguer  
✅ **Stats en direct** - Les compteurs s'actualisent automatiquement  
✅ **Historique live** - L'historique des interventions est toujours à jour

### 6. Tests recommandés

1. **Test multi-écran:**
   - Ouvrir signalement dans 2 écrans (carte + détails)
   - Prendre en charge depuis la carte
   - Vérifier que le bouton détails se grise instantanément

2. **Test multi-agent:**
   - 2 autorités connectées
   - Les 2 voient le même signalement
   - Agent A prend en charge
   - Agent B voit le bouton se griser

3. **Test navigation:**
   - Liste → Prendre en charge → Carte
   - Carte devrait afficher la mission en cours
   - Bouton "Prendre en charge" ne devrait plus être visible

### 7. Logs de débogage

Le service génère des logs pour faciliter le débogage :

```
📢 [STATE_SERVICE] Broadcasting: Signalement xxx pris en charge par yyy
📢 [AUTHORITY_HOME] Événement reçu: takeCharge pour signalement xxx
📢 [PROFILE] Événement reçu: takeCharge pour signalement xxx
📢 [AUTHORITY_PROFILE] Événement reçu: takeCharge pour signalement xxx
✅ [AUTHORITY_HOME] Listener d'état configuré
✅ [MAP] Listener d'état configuré
✅ [DETAIL] Listener d'état configuré
✅ [PROFILE] Listener d'état configuré
✅ [AUTHORITY_PROFILE] Listener d'état configuré
```

### 8. Événements diffusés

Le service diffuse 3 types d'événements :

| Événement | Quand | Écrans impactés |
|-----------|-------|-----------------|
| **notifyTakeCharge(id, agentId)** | Signalement pris en charge | Tous (boutons, stats, historique) |
| **notifyResolve(id)** | Signalement résolu | Tous (stats, historique, compteurs) |
| **notifyUpdate(id)** | Mise à jour générique | Tous (données rafraîchies) |[DETAIL] Événement reçu: takeCharge pour signalement xxx
✅ [AUTHORITY_HOME] Listener d'état configuré
```

## Migration future possible

Si besoin de plus de puissance, on peut remplacer le `StreamController` par:
- **Provider** / **Riverpod** - State management plus robuste
- **Bloc** - Pattern plus structuré
- **GetX** - State management + navigation

Mais la solution actuelle est suffisante pour le besoin actuel.

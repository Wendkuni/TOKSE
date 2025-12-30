# Architecture de synchronisation temps réel

## Vue d'ensemble

```
┌─────────────────────────────────────────────────────────────────┐
│                  SignalementStateService (Singleton)             │
│                                                                  │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │            StreamController<SignalementStateEvent>         │ │
│  └───────────────────────────────────────────────────────────┘ │
│                                                                  │
│  Methods:                                                        │
│  • notifyTakeCharge(signalementId, agentId)                    │
│  • notifyResolve(signalementId)                                │
│  • notifyUpdate(signalementId)                                 │
└─────────────────────────────────────────────────────────────────┘
                                 ↓
                    ┌────────────┴────────────┐
                    │  Broadcast à tous les   │
                    │  écrans qui écoutent    │
                    └────────────┬────────────┘
                                 ↓
    ┌────────────────────────────┼────────────────────────────┐
    ↓                            ↓                            ↓
┌───────────────┐       ┌───────────────┐          ┌───────────────┐
│ AuthorityHome │       │ AuthorityMap  │          │ SignalDetails │
│    Screen     │       │    Screen     │          │    Screen     │
├───────────────┤       ├───────────────┤          ├───────────────┤
│ • Stats       │       │ • Boutons     │          │ • Bouton      │
│ • Liste       │       │ • Marqueurs   │          │   "Prendre    │
│ • Boutons     │       │ • Navigation  │          │    en charge" │
│               │       │ • Mission     │          │               │
└───────────────┘       └───────────────┘          └───────────────┘
    ↓                            ↓                            ↓
    ↓                            ↓                            ↓
┌───────────────┐       ┌───────────────┐          
│ ProfileScreen │       │ AuthorityProf │          
│  (Citoyen)    │       │    Screen     │          
├───────────────┤       ├───────────────┤          
│ • Stats user  │       │ • Historique  │          
│ • Mes signale │       │ • Stats agent │          
│   -ments      │       │               │          
└───────────────┘       └───────────────┘          
```

## Flux d'événements

### Cas 1 : Prise en charge d'un signalement

```
1. Autorité clique "Prendre en charge" (Screen A)
         ↓
2. API Supabase : UPDATE signalements 
   SET locked = true, assigned_to = agent_id
         ↓
3. Succès retourné
         ↓
4. SignalementStateService.notifyTakeCharge()
         ↓
5. Broadcast → StreamController.add(event)
         ↓
    ┌────┴────┬────┬────┬────┐
    ↓         ↓    ↓    ↓    ↓
  Home      Map  Det  Prof AuthProf
    ↓         ↓    ↓    ↓    ↓
  reload   reload reload reload reload
    ↓         ↓    ↓    ↓    ↓
  setState setState setState setState setState
    ↓         ↓    ↓    ↓    ↓
  UI mis à jour automatiquement
```

### Cas 2 : Résolution d'un signalement

```
1. Autorité marque "Résolu" (Map Screen)
         ↓
2. API Supabase : UPDATE signalements 
   SET etat = 'resolu'
         ↓
3. Succès retourné
         ↓
4. SignalementStateService.notifyResolve()
         ↓
5. Broadcast → Tous les écrans
         ↓
6. Stats recalculées (en_cours--, resolus++)
         ↓
7. Historique mis à jour
         ↓
8. Boutons disparaissent (etat = 'resolu')
```

## Gestion de la mémoire

### Cycle de vie des listeners

```dart
@override
void initState() {
  super.initState();
  _loadData();
  _setupRealtimeListener();  // Supabase realtime
  _setupStateListener();     // Service local ✓
}

@override
void dispose() {
  _realtimeChannel?.unsubscribe();  // Cleanup Supabase
  _stateSubscription?.cancel();     // Cleanup service ✓
  super.dispose();
}
```

### Singleton Service

```dart
// Une seule instance pour toute l'application
final SignalementStateService _stateService = SignalementStateService();

// Pas de dispose() nécessaire sur l'instance
// Le StreamController reste ouvert pendant toute la vie de l'app
```

## Avantages de cette architecture

✅ **Découplage** : Les écrans ne se connaissent pas entre eux  
✅ **Scalable** : Facile d'ajouter de nouveaux écrans  
✅ **Testable** : Le service peut être mocké facilement  
✅ **Performant** : Broadcast léger, pas de polling  
✅ **Résilient** : Si un écran n'écoute pas, les autres fonctionnent  
✅ **Debug friendly** : Logs centralisés dans le service  

## Comparaison avec d'autres solutions

| Solution | Avantages | Inconvénients |
|----------|-----------|---------------|
| **StreamController (actuel)** | Simple, natif Dart, léger | Pas de persistance |
| Provider/Riverpod | State management robuste | Overhead pour ce besoin |
| Bloc Pattern | Très structuré | Trop complexe pour ce cas |
| GetX | Tout-en-un | Dépendance externe lourde |
| WebSocket/Socket.io | Temps réel pur | Complexe, coût serveur |

## Évolution future

Si besoin de fonctionnalités avancées :

1. **Persistance des événements** : Stocker dans SQLite
2. **Queue d'événements** : Pour gérer hors ligne
3. **Retry logic** : Re-tenter les broadcasts échoués
4. **Analytics** : Tracker les événements pour metrics
5. **Multi-device sync** : Sync entre plusieurs devices du même user

Pour l'instant, la solution actuelle est optimale pour le besoin.

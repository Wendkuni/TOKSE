# Guide de Migration Progressive vers Clean Architecture

## 🎯 Objectif
Migrer progressivement votre code existant vers la nouvelle architecture Clean **sans tout casser**.

---

## ✅ CE QUI A ÉTÉ FAIT

### 1. Structure ajoutée (SANS toucher au code existant)

```
lib/
├── core/
│   ├── di/injection_container.dart        # 🆕 GetIt setup
│   ├── errors/
│   │   ├── failures.dart                  # 🆕 Gestion erreurs
│   │   ├── exceptions.dart                # 🆕 Exceptions
│   │   └── errors.dart                    # 🆕 Export
│   └── utils/logger.dart                  # 🆕 Logger centralisé
│
├── features/
│   ├── auth/domain/                       # 🆕 Couche métier auth
│   │   ├── entities/user_entity.dart
│   │   ├── repositories/i_auth_repository.dart
│   │   └── usecases/
│   │
│   └── signalement/domain/                # 🆕 Couche métier signalement
│       ├── entities/signalement_entity.dart
│       ├── repositories/i_signalement_repository.dart
│       └── usecases/
```

### 2. Dépendances ajoutées dans `pubspec.yaml`

```yaml
dependencies:
  flutter_riverpod: ^2.4.10      # State management moderne
  get_it: ^7.6.7                 # Dependency injection
  dartz: ^0.10.1                 # Functional programming (Either)
  equatable: ^2.0.5              # Comparaison d'objets
  
dev_dependencies:
  build_runner: ^2.4.8           # Génération de code
  mockito: ^5.4.4                # Tests unitaires
```

---

## 🚀 COMMENT UTILISER (2 OPTIONS)

### Option A : Nouvelle Architecture pour NOUVELLES Features ✨

**Utilisez la nouvelle architecture UNIQUEMENT pour les nouvelles fonctionnalités.**

Votre code existant continue de fonctionner normalement !

#### Exemple : Créer une nouvelle feature "Notifications"

```dart
// 1. Créer l'entité
// lib/features/notifications/domain/entities/notification_entity.dart
class NotificationEntity extends Equatable {
  final String id;
  final String title;
  final String message;
  // ...
}

// 2. Créer l'interface repository
// lib/features/notifications/domain/repositories/i_notification_repository.dart
abstract class INotificationRepository {
  Future<Either<Failure, List<NotificationEntity>>> getNotifications();
}

// 3. Créer le UseCase
// lib/features/notifications/domain/usecases/get_notifications_usecase.dart
class GetNotificationsUseCase {
  final INotificationRepository repository;
  
  Future<Either<Failure, List<NotificationEntity>>> execute() async {
    return await repository.getNotifications();
  }
}

// 4. Implémenter le repository
// lib/features/notifications/data/repositories/notification_repository.dart
class NotificationRepository implements INotificationRepository {
  @override
  Future<Either<Failure, List<NotificationEntity>>> getNotifications() async {
    try {
      // Votre code ici
      return Right(notifications);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}

// 5. Enregistrer dans GetIt (injection_container.dart)
sl.registerLazySingleton<INotificationRepository>(
  () => NotificationRepository(),
);
sl.registerLazySingleton(() => GetNotificationsUseCase(sl()));

// 6. Utiliser dans votre widget
final useCase = sl<GetNotificationsUseCase>();
final result = await useCase.execute();

result.fold(
  (failure) => AppLogger.error('Erreur', error: failure.message),
  (notifications) => AppLogger.info('${notifications.length} notifs'),
);
```

---

### Option B : Migrer Progressivement le Code Existant 🔄

**Migrer feature par feature, en commençant par les plus simples.**

#### Étape 1 : Faire implémenter l'interface par votre repository existant

```dart
// Votre repository ACTUEL (lib/features/feed/data/repositories/signalements_repository.dart)
class SignalementsRepository {
  // ... votre code existant ...
}

// 🔄 AJOUTEZ juste "implements ISignalementRepository"
class SignalementsRepository implements ISignalementRepository {
  // ... votre code existant reste INCHANGÉ ...
  
  // Ajoutez les méthodes manquantes avec votre logique actuelle
  @override
  Future<Either<Failure, List<SignalementEntity>>> getSignalements() async {
    try {
      // Votre code existant
      final data = await _supabase.from('signalements').select();
      
      // Convertir en entities
      final signalements = data.map((json) => 
        SignalementEntity(/* mapper vos données */)
      ).toList();
      
      return Right(signalements);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
```

#### Étape 2 : Migrer un écran à la fois

```dart
// AVANT (votre code actuel)
class _FeedScreenState extends State<FeedScreen> {
  final SignalementsRepository _repository = SignalementsRepository();
  List<SignalementModel> _signalements = [];
  
  Future<void> _loadSignalements() async {
    try {
      final data = await _repository.getSignalements();
      setState(() => _signalements = data);
    } catch (e) {
      print('Erreur: $e');
    }
  }
}

// APRÈS (avec nouvelle architecture)
class _FeedScreenState extends State<FeedScreen> {
  final _getSignalementsUseCase = sl<GetSignalementsUseCase>();
  List<SignalementEntity> _signalements = [];
  
  Future<void> _loadSignalements() async {
    final result = await _getSignalementsUseCase.execute();
    
    result.fold(
      (failure) => AppLogger.error('Erreur', error: failure.message),
      (signalements) => setState(() => _signalements = signalements),
    );
  }
}
```

---

## 📋 PLAN DE MIGRATION PROGRESSIF

### Phase 1 : Installation (✅ FAIT)
- [x] Ajouter dépendances
- [x] Créer structure Domain
- [x] Créer gestion d'erreurs
- [x] Créer injection de dépendances

### Phase 2 : Initialisation (À FAIRE)
- [ ] Modifier `main.dart` pour initialiser GetIt
- [ ] Tester que l'app démarre toujours

### Phase 3 : Migration Feature par Feature (À FAIRE)

#### A. Feature Auth (Priorité: Haute)
- [ ] Faire implémenter `IAuthRepository` par `AuthRepository` existant
- [ ] Créer mappers entre Models et Entities
- [ ] Migrer LoginScreen pour utiliser les UseCases
- [ ] Tester la connexion

#### B. Feature Signalement (Priorité: Haute)
- [ ] Faire implémenter `ISignalementRepository`
- [ ] Créer mappers
- [ ] Migrer CreateSignalement vers UseCase
- [ ] Tester la création

#### C. Feature Feed (Priorité: Moyenne)
- [ ] Migrer FeedScreen
- [ ] Utiliser GetSignalementsUseCase
- [ ] Tester l'affichage

#### D. Feature Profile (Priorité: Basse)
- [ ] Migrer ProfileScreen
- [ ] Ajouter UpdateProfileUseCase

---

## 🔧 COMMANDES UTILES

### Installer les dépendances
```bash
flutter pub get
```

### Générer le code (Freezed, Riverpod, etc.)
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Lancer les tests
```bash
flutter test
```

### Vérifier les erreurs de syntaxe
```bash
flutter analyze
```

---

## ⚠️ POINTS D'ATTENTION

### 1. Ne supprimez PAS votre code existant
- Gardez vos Models actuels (SignalementModel)
- Créez des Entities en parallèle
- Utilisez des mappers pour convertir

### 2. Testez après chaque modification
- Compilez après chaque changement
- Testez la fonctionnalité migrée
- Ne passez pas à la feature suivante avant validation

### 3. Logger au lieu de print()
```dart
// ❌ Ne faites plus ça
print('Données chargées');

// ✅ Faites ça
AppLogger.info('Données chargées', tag: 'Feed');
```

---

## 🆘 EN CAS DE PROBLÈME

### Erreur : "Type X is not a subtype of Y"
**Solution** : Créez un mapper pour convertir vos Models en Entities

```dart
// lib/features/feed/data/models/signalement_model.dart
extension SignalementModelX on SignalementModel {
  SignalementEntity toEntity() {
    return SignalementEntity(
      id: id,
      titre: titre,
      // ... mapper tous les champs
    );
  }
}
```

### Erreur : "GetIt: Object not registered"
**Solution** : Vérifiez que vous avez enregistré la dépendance dans `injection_container.dart`

```dart
sl.registerLazySingleton(() => MonUseCase(sl()));
```

### Erreur de compilation après ajout dépendances
**Solution** : Lancez `flutter clean` puis `flutter pub get`

---

## 📞 AIDE

Si vous rencontrez des difficultés :

1. Vérifiez [ARCHITECTURE_CLEAN.md](./ARCHITECTURE_CLEAN.md)
2. Regardez les exemples dans `features/auth/domain/` et `features/signalement/domain/`
3. Consultez la documentation des packages utilisés

---

**Important** : Cette migration n'est PAS urgente. Prenez votre temps et migrez feature par feature quand vous êtes à l'aise.

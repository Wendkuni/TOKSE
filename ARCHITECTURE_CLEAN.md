# 🏗️ Architecture TOKSE - Clean Architecture

## 📐 Structure du Projet

```
lib/
├── core/                          # Code partagé dans toute l'app
│   ├── config/                    # Configuration (Supabase, etc.)
│   ├── di/                        # Injection de dépendances (GetIt)
│   │   └── injection_container.dart
│   ├── errors/                    # Gestion d'erreurs centralisée
│   │   ├── failures.dart          # Erreurs pour la couche présentation
│   │   ├── exceptions.dart        # Exceptions pour la couche data
│   │   └── errors.dart            # Export centralisé
│   ├── router/                    # Navigation (GoRouter)
│   ├── theme/                     # Thème global
│   └── utils/                     # Utilitaires
│       └── logger.dart            # Logger centralisé
│
├── features/                      # Fonctionnalités (feature-first)
│   ├── auth/
│   │   ├── domain/               # 🆕 Logique métier pure
│   │   │   ├── entities/         # Entités métier (User)
│   │   │   ├── repositories/     # Interfaces (contrats)
│   │   │   └── usecases/         # Cas d'usage métier
│   │   ├── data/                 # Accès aux données
│   │   │   └── repositories/     # Implémentations
│   │   └── presentation/         # UI
│   │       ├── screens/
│   │       └── widgets/
│   │
│   ├── signalement/
│   │   ├── domain/               # 🆕 Couche métier
│   │   │   ├── entities/         # SignalementEntity
│   │   │   ├── repositories/     # ISignalementRepository
│   │   │   └── usecases/         # GetSignalements, CreateSignalement...
│   │   ├── data/
│   │   └── presentation/
│   │
│   ├── feed/
│   ├── profile/
│   └── authority/
│
└── shared/                        # Widgets réutilisables
```

---

## 🎯 Principes de Clean Architecture

### 1. **Séparation en 3 couches**

```
┌─────────────────────────────────┐
│      PRESENTATION LAYER         │  ← UI, Widgets, Screens
│   (Depends on Domain)            │
├─────────────────────────────────┤
│        DOMAIN LAYER              │  ← Business Logic (pure Dart)
│   (No dependencies)              │     Entities, UseCases, Interfaces
├─────────────────────────────────┤
│         DATA LAYER               │  ← API, Database, Cache
│   (Depends on Domain)            │     Models, Repositories Impl
└─────────────────────────────────┘
```

### 2. **Flux de dépendances**

- ✅ **Presentation** dépend de **Domain**
- ✅ **Data** dépend de **Domain**
- ❌ **Domain** ne dépend de RIEN (logique pure)

---

## 🔧 Technologies Utilisées

| Couche | Technologie | Rôle |
|--------|-------------|------|
| **State Management** | Provider + (Riverpod bientôt) | Gestion d'état |
| **Dependency Injection** | GetIt | Service Locator |
| **Navigation** | GoRouter | Routing déclaratif |
| **Error Handling** | Dartz (Either<L,R>) | Gestion fonctionnelle des erreurs |
| **Backend** | Supabase | BaaS (Auth, DB, Storage) |
| **Logging** | AppLogger | Logs centralisés |

---

## 📝 Comment Utiliser la Nouvelle Architecture

### 1. **Injection de Dépendances**

Dans `main.dart`, initialisez les dépendances :

```dart
import 'core/di/injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await SupabaseConfig.initialize();
  await di.initDependencies(); // 🆕 Initialiser GetIt
  
  runApp(MyApp());
}
```

### 2. **Utiliser un UseCase dans un Widget**

```dart
import 'package:flutter/material.dart';
import '../../domain/usecases/get_signalements_usecase.dart';
import '../../domain/entities/signalement_entity.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/utils/logger.dart';

class FeedScreen extends StatefulWidget {
  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  // 🆕 Injection du UseCase
  final _getSignalementsUseCase = sl<GetSignalementsUseCase>();
  
  List<SignalementEntity> _signalements = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSignalements();
  }

  Future<void> _loadSignalements() async {
    setState(() => _isLoading = true);
    
    // 🆕 Appel du UseCase avec gestion d'erreurs
    final result = await _getSignalementsUseCase.execute();
    
    result.fold(
      // En cas d'erreur
      (failure) {
        AppLogger.error('Erreur chargement signalements', error: failure.message);
        setState(() {
          _errorMessage = failure.message;
          _isLoading = false;
        });
      },
      // En cas de succès
      (signalements) {
        AppLogger.info('✅ ${signalements.length} signalements chargés');
        setState(() {
          _signalements = signalements;
          _isLoading = false;
          _errorMessage = null;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return CircularProgressIndicator();
    if (_errorMessage != null) return Text('Erreur: $_errorMessage');
    
    return ListView.builder(
      itemCount: _signalements.length,
      itemBuilder: (context, index) {
        final signalement = _signalements[index];
        return ListTile(
          title: Text(signalement.titre),
          subtitle: Text(signalement.description),
          leading: Text(signalement.getCategoryIcon()),
        );
      },
    );
  }
}
```

### 3. **Créer un nouveau UseCase**

```dart
// 1. Créer le UseCase
class DeleteSignalementUseCase {
  final ISignalementRepository repository;

  DeleteSignalementUseCase(this.repository);

  Future<Either<Failure, void>> execute(String id) async {
    if (id.isEmpty) {
      return const Left(ValidationFailure(message: 'ID invalide'));
    }
    return await repository.deleteSignalement(id);
  }
}

// 2. L'enregistrer dans injection_container.dart
sl.registerLazySingleton(() => DeleteSignalementUseCase(sl()));

// 3. L'utiliser dans votre widget
final deleteUseCase = sl<DeleteSignalementUseCase>();
await deleteUseCase.execute(signalementId);
```

### 4. **Logging Centralisé**

Remplacez tous les `print()` par `AppLogger` :

```dart
// ❌ Avant
print('Utilisateur connecté: $userId');

// ✅ Après
AppLogger.info('Utilisateur connecté', tag: 'Auth');
AppLogger.debug('User ID: $userId', tag: 'Auth');
AppLogger.error('Échec connexion', error: exception, tag: 'Auth');
AppLogger.network('POST', '/api/signalements', statusCode: 201);
```

---

## ✅ Avantages de cette Architecture

| Avantage | Description |
|----------|-------------|
| **Testabilité** | Chaque couche peut être testée indépendamment |
| **Maintenabilité** | Code organisé, facile à modifier |
| **Scalabilité** | Ajout de features sans impacter l'existant |
| **Séparation des responsabilités** | UI ≠ Logic ≠ Data |
| **Indépendance du framework** | La logique métier ne dépend pas de Flutter |

---

## 🚀 Prochaines Étapes (Migration Progressive)

### Phase 1 : Adaptation des Repositories Existants ✅

- [x] Créer interfaces `IAuthRepository`, `ISignalementRepository`
- [x] Faire implémenter ces interfaces par les repos existants
- [x] Enregistrer dans GetIt

### Phase 2 : Migration vers Riverpod (Recommandé)

```dart
// Exemple de Provider Riverpod
@riverpod
class FeedNotifier extends _$FeedNotifier {
  @override
  Future<List<SignalementEntity>> build() async {
    final useCase = ref.read(getSignalementsUseCaseProvider);
    final result = await useCase.execute();
    
    return result.fold(
      (failure) => throw Exception(failure.message),
      (signalements) => signalements,
    );
  }
}

// Utilisation dans un widget
class FeedScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedState = ref.watch(feedNotifierProvider);
    
    return feedState.when(
      data: (signalements) => ListView(...),
      loading: () => CircularProgressIndicator(),
      error: (err, stack) => ErrorWidget(err),
    );
  }
}
```

### Phase 3 : Tests Unitaires

```dart
// test/features/signalement/domain/usecases/get_signalements_test.dart
void main() {
  late GetSignalementsUseCase useCase;
  late MockSignalementRepository mockRepo;

  setUp(() {
    mockRepo = MockSignalementRepository();
    useCase = GetSignalementsUseCase(mockRepo);
  });

  test('should return signalements from repository', () async {
    // Arrange
    when(mockRepo.getSignalements())
        .thenAnswer((_) async => Right([testSignalement]));

    // Act
    final result = await useCase.execute();

    // Assert
    expect(result, Right([testSignalement]));
    verify(mockRepo.getSignalements());
  });
}
```

---

## 📚 Ressources

- [Clean Architecture (Uncle Bob)](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Flutter Clean Architecture Guide](https://resocoder.com/flutter-clean-architecture-tdd/)
- [Riverpod Documentation](https://riverpod.dev/)
- [GetIt Package](https://pub.dev/packages/get_it)
- [Dartz Package](https://pub.dev/packages/dartz)

---

## 💡 Conseils

1. **Ne modifiez PAS votre code existant qui fonctionne** - Utilisez la nouvelle architecture pour les nouvelles features
2. **Migrez progressivement** - Feature par feature
3. **Testez au fur et à mesure** - Ajoutez des tests unitaires pour chaque UseCase
4. **Documentez** - Ajoutez des commentaires pour expliquer la logique métier

---

**Créé le** : 18 décembre 2025  
**Version** : 1.0.0  
**Auteur** : TOKSE Team

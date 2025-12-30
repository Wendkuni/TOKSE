# Guide de Tests Unitaires - TOKSE

## 🧪 Structure des Tests

```
test/
├── features/
│   ├── auth/
│   │   └── domain/
│   │       └── usecases/
│   │           ├── get_current_user_usecase_test.dart
│   │           └── sign_in_with_phone_usecase_test.dart
│   │
│   └── signalement/
│       └── domain/
│           └── usecases/
│               ├── get_signalements_usecase_test.dart
│               └── create_signalement_usecase_test.dart
│
└── core/
    └── utils/
        └── logger_test.dart
```

---

## 🚀 Lancer les Tests

### Tous les tests
```bash
flutter test
```

### Un fichier spécifique
```bash
flutter test test/features/signalement/domain/usecases/get_signalements_usecase_test.dart
```

### Avec coverage
```bash
flutter test --coverage
```

### Générer les mocks
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 📝 Anatomie d'un Test

```dart
void main() {
  // 1. Variables partagées
  late MonUseCase useCase;
  late MockRepository mockRepository;

  // 2. Setup avant chaque test
  setUp(() {
    mockRepository = MockRepository();
    useCase = MonUseCase(mockRepository);
  });

  // 3. Groupe de tests
  group('MonUseCase', () {
    
    // 4. Données de test
    const tData = 'test data';
    
    // 5. Test individuel
    test('should return data when repository succeeds', () async {
      // Arrange (préparation)
      when(mockRepository.getData())
          .thenAnswer((_) async => Right(tData));

      // Act (action)
      final result = await useCase.execute();

      // Assert (vérification)
      expect(result, Right(tData));
      verify(mockRepository.getData());
      verifyNoMoreInteractions(mockRepository);
    });
  });
}
```

---

## 🎯 Bonnes Pratiques

### 1. Nommage des Tests

```dart
// ✅ BON : Descriptif et clair
test('should return signalements from repository when successful', () {});
test('should return ServerFailure when API call fails', () {});
test('should return ValidationFailure when titre is empty', () {});

// ❌ MAUVAIS : Trop vague
test('test get signalements', () {});
test('error case', () {});
```

### 2. Pattern AAA (Arrange-Act-Assert)

```dart
test('should validate phone format', () async {
  // Arrange : Préparez vos données et mocks
  const invalidPhone = '123';
  
  // Act : Exécutez l'action à tester
  final result = await useCase.execute(phone: invalidPhone);
  
  // Assert : Vérifiez le résultat
  expect(result, isA<Left>());
  expect(result.fold((l) => l, (r) => null), 
         isA<ValidationFailure>());
});
```

### 3. Un Test = Un Comportement

```dart
// ✅ BON : Teste un seul aspect
test('should return ValidationFailure when titre is empty', () {
  // Test uniquement cette condition
});

test('should return ValidationFailure when titre is too short', () {
  // Test uniquement cette autre condition
});

// ❌ MAUVAIS : Teste plusieurs choses
test('should validate all inputs', () {
  // Teste titre, description, categorie... en même temps
});
```

### 4. Tests Indépendants

```dart
// ✅ BON : Chaque test est isolé
test('test 1', () {
  final localMock = MockRepository();
  // ...
});

test('test 2', () {
  final localMock = MockRepository();
  // ...
});

// ❌ MAUVAIS : Tests dépendants
var sharedData;
test('test 1', () {
  sharedData = 'test';
});

test('test 2', () {
  // Dépend du test 1
  expect(sharedData, 'test');
});
```

---

## 🛠️ Commandes Utiles

### Installer Mockito et générer les mocks
```bash
flutter pub add --dev mockito build_runner
flutter pub run build_runner build --delete-conflicting-outputs
```

### Vérifier la couverture de code
```bash
# Générer le rapport
flutter test --coverage

# Voir le rapport (nécessite lcov)
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html  # macOS
start coverage/html/index.html # Windows
```

### Tests en watch mode (reexécute à chaque sauvegarde)
```bash
flutter test --watch
```

---

## 📚 Ressources

- [Flutter Testing Guide](https://docs.flutter.dev/testing)
- [Mockito Package](https://pub.dev/packages/mockito)
- [Test-Driven Development](https://resocoder.com/flutter-tdd-clean-architecture-course/)

---

**Objectif** : Atteindre **70%+ de couverture de code** sur la couche Domain

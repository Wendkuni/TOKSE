import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tokse_flutter/core/errors/failures.dart';
import 'package:tokse_flutter/features/signalement/domain/entities/signalement_entity.dart';
import 'package:tokse_flutter/features/signalement/domain/repositories/i_signalement_repository.dart';
import 'package:tokse_flutter/features/signalement/domain/usecases/create_signalement_usecase.dart';

@GenerateNiceMocks([MockSpec<ISignalementRepository>()])
import 'create_signalement_usecase_test.mocks.dart';

void main() {
  late CreateSignalementUseCase useCase;
  late MockISignalementRepository mockRepository;

  setUp(() {
    mockRepository = MockISignalementRepository();
    useCase = CreateSignalementUseCase(mockRepository);
  });

  group('CreateSignalementUseCase', () {
    const tTitre = 'Déchet sur la rue';
    const tDescription = 'Gros tas de déchets au coin de la rue';
    const tCategorie = 'dechets';
    const tLatitude = 48.8566;
    const tLongitude = 2.3522;

    final tSignalement = SignalementEntity(
      id: '1',
      titre: tTitre,
      description: tDescription,
      categorie: tCategorie,
      etat: 'en_attente',
      latitude: tLatitude,
      longitude: tLongitude,
      userId: 'user123',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      photoUrl: null,
      felicitations: 0,
    );

    test('should create signalement when data is valid', () async {
      // arrange
      when(mockRepository.createSignalement(
        titre: anyNamed('titre'),
        description: anyNamed('description'),
        categorie: anyNamed('categorie'),
        latitude: anyNamed('latitude'),
        longitude: anyNamed('longitude'),
      )).thenAnswer((_) async => Right(tSignalement));

      // act
      final result = await useCase.execute(
        titre: tTitre,
        description: tDescription,
        categorie: tCategorie,
        latitude: tLatitude,
        longitude: tLongitude,
      );

      // assert
      expect(result, Right(tSignalement));
      verify(mockRepository.createSignalement(
        titre: tTitre,
        description: tDescription,
        categorie: tCategorie,
        latitude: tLatitude,
        longitude: tLongitude,
      ));
    });

    test('should return ValidationFailure when titre is empty', () async {
      // act
      final result = await useCase.execute(
        titre: '',
        description: tDescription,
        categorie: tCategorie,
        latitude: tLatitude,
        longitude: tLongitude,
      );

      // assert
      expect(result, const Left(ValidationFailure(message: 'Le titre est requis')));
      verifyZeroInteractions(mockRepository);
    });

    test('should return ValidationFailure when titre is too short', () async {
      // act
      final result = await useCase.execute(
        titre: 'Test',
        description: tDescription,
        categorie: tCategorie,
        latitude: tLatitude,
        longitude: tLongitude,
      );

      // assert
      expect(
        result,
        const Left(ValidationFailure(
          message: 'Le titre doit contenir au moins 5 caractères',
        )),
      );
      verifyZeroInteractions(mockRepository);
    });

    test('should return ValidationFailure when description is empty', () async {
      // act
      final result = await useCase.execute(
        titre: tTitre,
        description: '',
        categorie: tCategorie,
        latitude: tLatitude,
        longitude: tLongitude,
      );

      // assert
      expect(
        result,
        const Left(ValidationFailure(message: 'La description est requise')),
      );
      verifyZeroInteractions(mockRepository);
    });

    test('should return ValidationFailure when categorie is invalid', () async {
      // act
      final result = await useCase.execute(
        titre: tTitre,
        description: tDescription,
        categorie: 'invalid_category',
        latitude: tLatitude,
        longitude: tLongitude,
      );

      // assert
      expect(
        result,
        const Left(ValidationFailure(message: 'Catégorie invalide')),
      );
      verifyZeroInteractions(mockRepository);
    });

    test('should return ServerFailure when repository fails', () async {
      // arrange
      const tFailure = ServerFailure(message: 'Erreur serveur');
      when(mockRepository.createSignalement(
        titre: anyNamed('titre'),
        description: anyNamed('description'),
        categorie: anyNamed('categorie'),
        latitude: anyNamed('latitude'),
        longitude: anyNamed('longitude'),
      )).thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await useCase.execute(
        titre: tTitre,
        description: tDescription,
        categorie: tCategorie,
        latitude: tLatitude,
        longitude: tLongitude,
      );

      // assert
      expect(result, const Left(tFailure));
    });
  });
}

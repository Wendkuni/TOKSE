import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tokse_flutter/core/errors/failures.dart';
import 'package:tokse_flutter/features/signalement/domain/entities/signalement_entity.dart';
import 'package:tokse_flutter/features/signalement/domain/repositories/i_signalement_repository.dart';
import 'package:tokse_flutter/features/signalement/domain/usecases/get_signalements_usecase.dart';

// Génération du mock avec Mockito
@GenerateNiceMocks([MockSpec<ISignalementRepository>()])
import 'get_signalements_usecase_test.mocks.dart';

void main() {
  late GetSignalementsUseCase useCase;
  late MockISignalementRepository mockRepository;

  setUp(() {
    mockRepository = MockISignalementRepository();
    useCase = GetSignalementsUseCase(mockRepository);
  });

  group('GetSignalementsUseCase', () {
    final tSignalement = SignalementEntity(
      id: '1',
      titre: 'Test Signalement',
      description: 'Description test',
      categorie: 'dechets',
      etat: 'en_attente',
      latitude: 48.8566,
      longitude: 2.3522,
      userId: 'user123',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      photoUrl: null,
      felicitations: 0,
    );

    final tSignalementList = [tSignalement];

    test('should return list of signalements from repository', () async {
      // arrange
      when(mockRepository.getSignalements())
          .thenAnswer((_) async => Right(tSignalementList));

      // act
      final result = await useCase.execute();

      // assert
      expect(result, Right(tSignalementList));
      verify(mockRepository.getSignalements());
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return ServerFailure when repository fails', () async {
      // arrange
      const tFailure = ServerFailure(message: 'Erreur serveur');
      when(mockRepository.getSignalements())
          .thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await useCase.execute();

      // assert
      expect(result, const Left(tFailure));
      verify(mockRepository.getSignalements());
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return NetworkFailure when no internet connection', () async {
      // arrange
      const tFailure = NetworkFailure();
      when(mockRepository.getSignalements())
          .thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await useCase.execute();

      // assert
      expect(result, const Left(tFailure));
      verify(mockRepository.getSignalements());
    });
  });
}

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../feed/data/repositories/signalements_repository.dart';
import '../../domain/entities/signalement_entity.dart';
import '../../domain/repositories/i_signalement_repository.dart';
import '../mappers/signalement_mapper.dart';

/// Implémentation du repository avec Clean Architecture
class SignalementRepositoryImpl implements ISignalementRepository {
  final SignalementsRepository _oldRepo;
  final AuthRepository _authRepo;

  SignalementRepositoryImpl({
    SignalementsRepository? oldRepo,
    AuthRepository? authRepo,
  })  : _oldRepo = oldRepo ?? SignalementsRepository(),
        _authRepo = authRepo ?? AuthRepository();

  @override
  Future<Either<Failure, List<SignalementEntity>>> getSignalements() async {
    try {
      AppLogger.info('Récupération des signalements', tag: 'SignalementRepo');
      final models = await _oldRepo.getSignalements();
      final entities = models.map((model) => model.toEntity()).toList();
      AppLogger.info('✅ ${entities.length} signalements récupérés', tag: 'SignalementRepo');
      return Right(entities);
    } catch (e) {
      AppLogger.error('Erreur getSignalements', error: e, tag: 'SignalementRepo');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, SignalementEntity>> getSignalementById(String id) async {
    try {
      AppLogger.debug('Récupération signalement $id', tag: 'SignalementRepo');
      final model = await _oldRepo.getSignalement(id);
      return Right(model.toEntity());
    } catch (e) {
      AppLogger.error('Erreur getSignalementById', error: e, tag: 'SignalementRepo');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<SignalementEntity>>> getUserSignalements(String userId) async {
    try {
      final models = await _oldRepo.getUserSignalements();
      final entities = models.map((m) => m.toEntity()).toList();
      // Filter by userId
      final filteredEntities = entities.where((e) => e.userId == userId).toList();
      return Right(filteredEntities);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<SignalementEntity>>> getSignalementsByCategory(String category) async {
    try {
      final models = await _oldRepo.getSignalements();
      final entities = models.map((m) => m.toEntity()).toList();
      // Filter by category
      final filteredEntities = entities.where((e) => e.categorie == category).toList();
      return Right(filteredEntities);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<SignalementEntity>>> getSignalementsByStatus(String status) async {
    try {
      final models = await _oldRepo.getSignalements();
      final entities = models.map((m) => m.toEntity()).toList();
      // Filter by status
      final filteredEntities = entities.where((e) => e.etat == status).toList();
      return Right(filteredEntities);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, SignalementEntity>> createSignalement({
    required String titre,
    required String description,
    required String categorie,
    required double latitude,
    required double longitude,
    String? adresse,
    List<String>? photosUrls,
    String? audioUrl,
    bool isUrgent = false,
  }) async {
    try {
      AppLogger.info('Création signalement: $titre', tag: 'SignalementRepo');
      
      final userId = await _authRepo.getStoredUserId();
      if (userId == null) {
        return const Left(AuthenticationFailure(message: 'Utilisateur non connecté'));
      }

      final model = await _oldRepo.createSignalement(
        titre: titre,
        description: description,
        categorie: categorie,
        photoUrl: photosUrls?.firstOrNull,
        audioUrl: audioUrl,
        latitude: latitude,
        longitude: longitude,
        adresse: adresse,
      );

      AppLogger.info('✅ Signalement créé avec ID: ${model.id}', tag: 'SignalementRepo');
      return Right(model.toEntity());
    } catch (e) {
      AppLogger.error('Erreur createSignalement', error: e, tag: 'SignalementRepo');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateSignalementStatus(
    String signalementId,
    String newStatus,
  ) async {
    try {
      await _oldRepo.updateSignalement(
        signalementId,
        etat: newStatus,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addFelicitation(String signalementId) async {
    try {
      AppLogger.debug('Ajout félicitation sur $signalementId', tag: 'SignalementRepo');
      await _oldRepo.addFelicitation(signalementId);
      return const Right(null);
    } catch (e) {
      AppLogger.error('Erreur addFelicitation', error: e, tag: 'SignalementRepo');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> removeFelicitation(String signalementId) async {
    try {
      await _oldRepo.removeFelicitation(signalementId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteSignalement(String signalementId) async {
    try {
      await _oldRepo.deleteSignalement(signalementId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Set<String>>> getUserFelicitations() async {
    try {
      AppLogger.debug('Récupération des félicitations utilisateur', tag: 'SignalementRepo');
      final felicitations = await _oldRepo.getUserFelicitations();
      return Right(felicitations);
    } catch (e) {
      AppLogger.error('Erreur getUserFelicitations', error: e, tag: 'SignalementRepo');
      return Left(ServerFailure(message: e.toString()));
    }
  }
}

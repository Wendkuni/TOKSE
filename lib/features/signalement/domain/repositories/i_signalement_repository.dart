import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/signalement_entity.dart';

/// Interface du repository (contrat)
/// L'implémentation sera dans la couche data
abstract class ISignalementRepository {
  /// Récupère tous les signalements
  Future<Either<Failure, List<SignalementEntity>>> getSignalements();

  /// Récupère un signalement par son ID
  Future<Either<Failure, SignalementEntity>> getSignalementById(String id);

  /// Récupère les signalements d'un utilisateur
  Future<Either<Failure, List<SignalementEntity>>> getUserSignalements(String userId);

  /// Récupère les signalements par catégorie
  Future<Either<Failure, List<SignalementEntity>>> getSignalementsByCategory(String category);

  /// Récupère les signalements par statut
  Future<Either<Failure, List<SignalementEntity>>> getSignalementsByStatus(String status);

  /// Crée un nouveau signalement
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
  });

  /// Met à jour le statut d'un signalement (pour les autorités)
  Future<Either<Failure, void>> updateSignalementStatus(
    String signalementId,
    String newStatus,
  );

  /// Ajoute une félicitation à un signalement
  Future<Either<Failure, void>> addFelicitation(String signalementId);

  /// Retire une félicitation d'un signalement
  Future<Either<Failure, void>> removeFelicitation(String signalementId);

  /// Supprime un signalement
  Future<Either<Failure, void>> deleteSignalement(String signalementId);

  /// Récupère les IDs des signalements félicités par l'utilisateur actuel
  Future<Either<Failure, Set<String>>> getUserFelicitations();
}

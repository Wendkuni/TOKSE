import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/signalement_entity.dart';
import '../repositories/i_signalement_repository.dart';

/// Use Case : Créer un nouveau signalement
class CreateSignalementUseCase {
  final ISignalementRepository repository;

  CreateSignalementUseCase(this.repository);

  Future<Either<Failure, SignalementEntity>> execute({
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
    // Validation métier
    if (titre.trim().isEmpty) {
      return const Left(ValidationFailure(message: 'Le titre est requis'));
    }

    if (description.trim().isEmpty) {
      return const Left(ValidationFailure(message: 'La description est requise'));
    }

    if (titre.length < 5) {
      return const Left(ValidationFailure(
          message: 'Le titre doit contenir au moins 5 caractères'));
    }

    if (description.length < 10) {
      return const Left(ValidationFailure(
          message: 'La description doit contenir au moins 10 caractères'));
    }

    const validCategories = ['dechets', 'route', 'pollution', 'eclairage', 'espaces_verts', 'autre'];
    if (!validCategories.contains(categorie)) {
      return const Left(ValidationFailure(message: 'Catégorie invalide'));
    }

    // Appel au repository
    return await repository.createSignalement(
      titre: titre,
      description: description,
      categorie: categorie,
      latitude: latitude,
      longitude: longitude,
      adresse: adresse,
      photosUrls: photosUrls,
      audioUrl: audioUrl,
      isUrgent: isUrgent,
    );
  }
}

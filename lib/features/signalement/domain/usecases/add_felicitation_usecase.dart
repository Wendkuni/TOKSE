import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/i_signalement_repository.dart';

/// Use Case : Ajouter une félicitation à un signalement
class AddFelicitationUseCase {
  final ISignalementRepository repository;

  AddFelicitationUseCase(this.repository);

  Future<Either<Failure, void>> execute(String signalementId) async {
    if (signalementId.trim().isEmpty) {
      return const Left(ValidationFailure(message: 'ID du signalement invalide'));
    }

    return await repository.addFelicitation(signalementId);
  }

  /// Alias pour execute()
  Future<Either<Failure, void>> call(String signalementId) => execute(signalementId);
}

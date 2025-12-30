import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../repositories/i_signalement_repository.dart';

/// Use case pour retirer une félicitation d'un signalement
class RemoveFelicitationUseCase {
  final ISignalementRepository _repository;

  RemoveFelicitationUseCase(this._repository);

  /// Retire une félicitation du signalement spécifié
  /// 
  /// Returns:
  /// - Right(void) si la félicitation est retirée avec succès
  /// - Left(Failure) si une erreur se produit
  Future<Either<Failure, void>> call(String signalementId) async {
    AppLogger.info('Retrait félicitation signalement $signalementId', tag: 'RemoveFelicitationUseCase');
    
    final result = await _repository.removeFelicitation(signalementId);
    
    return result.fold(
      (failure) {
        AppLogger.error('Échec retrait félicitation', tag: 'RemoveFelicitationUseCase');
        return Left(failure);
      },
      (_) {
        AppLogger.info('✅ Félicitation retirée avec succès', tag: 'RemoveFelicitationUseCase');
        return const Right(null);
      },
    );
  }
}

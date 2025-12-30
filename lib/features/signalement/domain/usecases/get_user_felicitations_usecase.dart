import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/i_signalement_repository.dart';

/// Use case pour récupérer les IDs des signalements félicités par l'utilisateur actuel
class GetUserFelicitationsUseCase {
  final ISignalementRepository _repository;

  GetUserFelicitationsUseCase(this._repository);

  Future<Either<Failure, Set<String>>> call() async {
    return await _repository.getUserFelicitations();
  }
}

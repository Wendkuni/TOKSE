import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/signalement_entity.dart';
import '../repositories/i_signalement_repository.dart';

/// Use Case : Récupérer tous les signalements
class GetSignalementsUseCase {
  final ISignalementRepository repository;

  GetSignalementsUseCase(this.repository);

  Future<Either<Failure, List<SignalementEntity>>> execute() async {
    return await repository.getSignalements();
  }

  /// Alias pour execute()
  Future<Either<Failure, List<SignalementEntity>>> call() => execute();
}

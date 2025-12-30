import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/i_auth_repository.dart';

/// Use Case : Récupérer l'utilisateur courant
class GetCurrentUserUseCase {
  final IAuthRepository repository;

  GetCurrentUserUseCase(this.repository);

  Future<Either<Failure, UserEntity?>> execute() async {
    return await repository.getCurrentUser();
  }

  /// Alias pour execute()
  Future<Either<Failure, UserEntity?>> call() => execute();
}

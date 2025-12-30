import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/i_auth_repository.dart';

/// Use Case : Déconnexion
class SignOutUseCase {
  final IAuthRepository repository;

  SignOutUseCase(this.repository);

  Future<Either<Failure, void>> execute() async {
    return await repository.signOut();
  }
}

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/i_auth_repository.dart';

/// Use Case : Connexion avec téléphone
class SignInWithPhoneUseCase {
  final IAuthRepository repository;

  SignInWithPhoneUseCase(this.repository);

  Future<Either<Failure, UserEntity>> execute({
    required String phone,
    required String password,
  }) async {
    // Validation métier
    if (phone.trim().isEmpty) {
      return const Left(ValidationFailure(message: 'Le numéro de téléphone est requis'));
    }

    if (password.trim().isEmpty) {
      return const Left(ValidationFailure(message: 'Le mot de passe est requis'));
    }

    // Validation format téléphone (simple)
    final phoneRegex = RegExp(r'^\+?[0-9]{8,15}$');
    if (!phoneRegex.hasMatch(phone.replaceAll(' ', ''))) {
      return const Left(ValidationFailure(message: 'Format de téléphone invalide'));
    }

    return await repository.signInWithPhone(
      phone: phone,
      password: password,
    );
  }
}

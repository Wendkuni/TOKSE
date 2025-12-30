import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';

/// Interface du repository d'authentification
abstract class IAuthRepository {
  /// Récupère l'utilisateur actuellement connecté
  Future<Either<Failure, UserEntity?>> getCurrentUser();

  /// Vérifie si l'utilisateur est authentifié
  Future<Either<Failure, bool>> isAuthenticated();

  /// Connexion avec téléphone et mot de passe
  Future<Either<Failure, UserEntity>> signInWithPhone({
    required String phone,
    required String password,
  });

  /// Inscription avec OTP
  Future<Either<Failure, void>> signUpWithOtp({
    required String phone,
    required String nom,
    required String prenom,
  });

  /// Vérification du code OTP
  Future<Either<Failure, UserEntity>> verifyOtp({
    required String phone,
    required String otp,
    required String nom,
    required String prenom,
  });

  /// Déconnexion
  Future<Either<Failure, void>> signOut();

  /// Mise à jour du profil utilisateur
  Future<Either<Failure, UserEntity>> updateProfile({
    String? nom,
    String? prenom,
    String? email,
    String? avatarUrl,
  });

  /// Récupère l'ID utilisateur stocké localement
  Future<Either<Failure, String?>> getStoredUserId();

  /// Rafraîchit la session utilisateur
  Future<Either<Failure, void>> refreshSession();
}

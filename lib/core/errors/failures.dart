import 'package:equatable/equatable.dart';

/// Classe de base pour toutes les erreurs de l'application
abstract class Failure extends Equatable {
  final String message;
  final int? code;

  const Failure({
    required this.message,
    this.code,
  });

  @override
  List<Object?> get props => [message, code];
}

/// Erreur serveur (API, Supabase)
class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    super.code,
  });
}

/// Erreur de connexion réseau
class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'Pas de connexion internet',
  });
}

/// Erreur d'authentification
class AuthenticationFailure extends Failure {
  const AuthenticationFailure({
    required super.message,
    super.code,
  });
}

/// Erreur de validation
class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
  });
}

/// Erreur de permission
class PermissionFailure extends Failure {
  const PermissionFailure({
    required super.message,
  });
}

/// Erreur de cache local
class CacheFailure extends Failure {
  const CacheFailure({
    super.message = 'Erreur de cache local',
  });
}

/// Erreur inconnue
class UnknownFailure extends Failure {
  const UnknownFailure({
    super.message = 'Une erreur inconnue s\'est produite',
  });
}

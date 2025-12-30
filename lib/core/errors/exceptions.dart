/// Exceptions de l'application (couche data)
/// Seront converties en Failures dans les repositories
library;

class ServerException implements Exception {
  final String message;
  final int? statusCode;

  const ServerException({
    required this.message,
    this.statusCode,
  });

  @override
  String toString() => 'ServerException: $message (code: $statusCode)';
}

class NetworkException implements Exception {
  final String message;

  const NetworkException({
    this.message = 'Pas de connexion internet',
  });

  @override
  String toString() => 'NetworkException: $message';
}

class CacheException implements Exception {
  final String message;

  const CacheException({
    this.message = 'Erreur de cache local',
  });

  @override
  String toString() => 'CacheException: $message';
}

class AuthenticationException implements Exception {
  final String message;
  final int? statusCode;

  const AuthenticationException({
    required this.message,
    this.statusCode,
  });

  @override
  String toString() => 'AuthenticationException: $message';
}

class ValidationException implements Exception {
  final String message;
  final Map<String, String>? fieldErrors;

  const ValidationException({
    required this.message,
    this.fieldErrors,
  });

  @override
  String toString() => 'ValidationException: $message';
}

class PermissionException implements Exception {
  final String message;

  const PermissionException({
    required this.message,
  });

  @override
  String toString() => 'PermissionException: $message';
}

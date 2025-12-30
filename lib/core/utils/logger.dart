import 'dart:developer' as developer;

/// Logger centralisé pour l'application TOKSE
/// Remplace les print() pour un meilleur contrôle des logs
class AppLogger {
  static const String _appName = 'TOKSE';
  
  /// Log de debug (développement uniquement)
  static void debug(String message, {String? tag}) {
    developer.log(
      message,
      name: tag != null ? '$_appName:$tag' : _appName,
      level: 500, // DEBUG level
    );
  }

  /// Log d'information
  static void info(String message, {String? tag}) {
    developer.log(
      message,
      name: tag != null ? '$_appName:$tag' : _appName,
      level: 800, // INFO level
    );
  }

  /// Log d'avertissement
  static void warning(String message, {String? tag}) {
    developer.log(
      message,
      name: tag != null ? '$_appName:$tag' : _appName,
      level: 900, // WARNING level
    );
  }

  /// Log d'erreur
  static void error(String message, {Object? error, StackTrace? stackTrace, String? tag}) {
    developer.log(
      message,
      name: tag != null ? '$_appName:$tag' : _appName,
      error: error,
      stackTrace: stackTrace,
      level: 1000, // ERROR level
    );
  }

  /// Log réseau (requêtes API)
  static void network(String method, String endpoint, {int? statusCode, dynamic data}) {
    final status = statusCode != null ? ' [$statusCode]' : '';
    developer.log(
      '$method $endpoint$status',
      name: '$_appName:Network',
      level: 500,
    );
    if (data != null) {
      developer.log('Data: $data', name: '$_appName:Network', level: 500);
    }
  }

  /// Log de navigation
  static void navigation(String from, String to) {
    developer.log(
      'Navigation: $from → $to',
      name: '$_appName:Router',
      level: 500,
    );
  }

  /// Log d'authentification
  static void auth(String action, {String? userId}) {
    final user = userId != null ? ' (user: $userId)' : '';
    developer.log(
      'Auth: $action$user',
      name: '$_appName:Auth',
      level: 800,
    );
  }
}

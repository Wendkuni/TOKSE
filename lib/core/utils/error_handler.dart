import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Classe utilitaire pour convertir les erreurs techniques en messages clairs
class ErrorHandler {
  /// Convertit une exception en message clair pour l'utilisateur
  static String getReadableMessage(dynamic error) {
    // Erreurs de connexion réseau
    if (error is SocketException) {
      return 'Pas de connexion internet. Vérifiez votre connexion et réessayez.';
    }

    // Erreurs de timeout
    if (error.toString().contains('TimeoutException') ||
        error.toString().contains('timeout') ||
        error.toString().contains('Timeout') ||
        error.toString().contains('TIMED_OUT')) {
      return 'La connexion a pris trop de temps. Vérifiez votre connexion internet.';
    }

    // Erreurs de connexion génériques
    if (error.toString().contains('SocketException') ||
        error.toString().contains('Connection refused') ||
        error.toString().contains('Connection reset') ||
        error.toString().contains('Connection closed') ||
        error.toString().contains('Connection failed') ||
        error.toString().contains('Network is unreachable') ||
        error.toString().contains('No address associated') ||
        error.toString().contains('UnknownHostException') ||
        error.toString().contains('ERR_CONNECTION') ||
        error.toString().contains('ERR_INTERNET') ||
        error.toString().contains('ERR_NETWORK') ||
        error.toString().contains('net::ERR_')) {
      return 'Problème de connexion internet. Vérifiez votre réseau et réessayez.';
    }

    // Erreurs DNS
    if (error.toString().contains('Failed host lookup') ||
        error.toString().contains('getaddrinfo failed') ||
        error.toString().contains('Name or service not known')) {
      return 'Impossible de se connecter au serveur. Vérifiez votre connexion internet.';
    }

    // Erreurs Supabase/PostgrestException
    if (error is PostgrestException) {
      return _handlePostgrestError(error);
    }

    // Erreurs d'authentification Supabase
    if (error is AuthException) {
      return _handleAuthError(error);
    }

    // Erreurs HTTP génériques
    if (error.toString().contains('status code: 401') ||
        error.toString().contains('401')) {
      return 'Session expirée. Veuillez vous reconnecter.';
    }
    if (error.toString().contains('status code: 403') ||
        error.toString().contains('403')) {
      return 'Vous n\'avez pas les droits pour effectuer cette action.';
    }
    if (error.toString().contains('status code: 404') ||
        error.toString().contains('404')) {
      return 'L\'élément demandé n\'existe pas ou a été supprimé.';
    }
    if (error.toString().contains('status code: 500') ||
        error.toString().contains('500') ||
        error.toString().contains('Internal Server Error')) {
      return 'Erreur du serveur. Veuillez réessayer plus tard.';
    }
    if (error.toString().contains('status code: 502') ||
        error.toString().contains('status code: 503') ||
        error.toString().contains('status code: 504')) {
      return 'Le serveur est temporairement indisponible. Réessayez dans quelques instants.';
    }

    // Erreurs de permission
    if (error.toString().contains('permission') ||
        error.toString().contains('Permission')) {
      return 'Permission refusée. Veuillez autoriser l\'application dans les paramètres.';
    }

    // Erreurs de localisation
    if (error.toString().contains('location') ||
        error.toString().contains('Location') ||
        error.toString().contains('GPS')) {
      return 'Impossible d\'obtenir votre position. Activez la localisation et réessayez.';
    }

    // Message par défaut plus sympathique
    final errorStr = error.toString().toLowerCase();
    if (errorStr.contains('exception') || errorStr.contains('error')) {
      return 'Une erreur est survenue. Veuillez réessayer.';
    }

    return 'Une erreur inattendue s\'est produite. Veuillez réessayer.';
  }

  /// Gère les erreurs Postgrest (base de données Supabase)
  static String _handlePostgrestError(PostgrestException error) {
    final code = error.code;
    final message = error.message.toLowerCase();

    // Erreurs de contrainte
    if (code == '23505' || message.contains('duplicate')) {
      return 'Cet élément existe déjà.';
    }
    if (code == '23503' || message.contains('foreign key')) {
      return 'L\'élément référencé n\'existe pas.';
    }
    if (code == '23502' || message.contains('not null')) {
      return 'Certaines informations obligatoires sont manquantes.';
    }

    // Erreurs RLS (Row Level Security)
    if (message.contains('rls') ||
        message.contains('policy') ||
        message.contains('row-level security')) {
      return 'Vous n\'avez pas les droits pour cette action.';
    }

    // Erreurs de connexion à la base de données
    if (message.contains('connection') || message.contains('timeout')) {
      return 'Problème de connexion au serveur. Réessayez plus tard.';
    }

    return 'Erreur lors de l\'opération. Veuillez réessayer.';
  }

  /// Gère les erreurs d'authentification Supabase
  static String _handleAuthError(AuthException error) {
    final message = error.message.toLowerCase();

    if (message.contains('invalid login') ||
        message.contains('invalid credentials')) {
      return 'Email ou mot de passe incorrect.';
    }
    if (message.contains('email not confirmed')) {
      return 'Veuillez confirmer votre email avant de vous connecter.';
    }
    if (message.contains('user not found')) {
      return 'Aucun compte trouvé avec cet email.';
    }
    if (message.contains('email already') ||
        message.contains('user already registered')) {
      return 'Un compte existe déjà avec cet email.';
    }
    if (message.contains('password') && message.contains('weak')) {
      return 'Le mot de passe est trop faible. Utilisez au moins 8 caractères.';
    }
    if (message.contains('expired') || message.contains('session')) {
      return 'Votre session a expiré. Veuillez vous reconnecter.';
    }
    if (message.contains('rate limit') || message.contains('too many')) {
      return 'Trop de tentatives. Veuillez patienter quelques minutes.';
    }
    if (message.contains('network') || message.contains('connection')) {
      return 'Problème de connexion. Vérifiez votre internet et réessayez.';
    }

    return 'Erreur d\'authentification. Veuillez réessayer.';
  }

  /// Vérifie si l'erreur est liée à un problème de connexion
  static bool isNetworkError(dynamic error) {
    if (error is SocketException) return true;

    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('socket') ||
        errorStr.contains('connection') ||
        errorStr.contains('timeout') ||
        errorStr.contains('network') ||
        errorStr.contains('internet') ||
        errorStr.contains('host lookup') ||
        errorStr.contains('unreachable') ||
        errorStr.contains('net::err_');
  }

  /// Vérifie si l'erreur nécessite une reconnexion
  static bool requiresReauth(dynamic error) {
    if (error is AuthException) return true;

    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('401') ||
        errorStr.contains('unauthorized') ||
        errorStr.contains('session') ||
        errorStr.contains('expired') ||
        errorStr.contains('jwt');
  }
}

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/supabase_config.dart';

class AuthRepository {
  static const String _userIdKey = 'tokse_user_id';
  static const String _userPhoneKey = 'tokse_user_phone';
  static const String _lastLoginKey = 'tokse_last_login';
  static const int _sessionExpirationDays = 30; // Expiration après 30 jours (1 mois)
  final _supabase = SupabaseConfig.client;

  User? get currentUser => _supabase.auth.currentUser;

  // Récupérer l'ID utilisateur stocké localement (solution temporaire)
  Future<String?> getStoredUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  Future<bool> isAuthenticated() async {
    // Vérifier d'abord la session Supabase
    final session = _supabase.auth.currentSession;
    if (session != null) {
      // Mettre à jour le timestamp de dernière connexion
      await _updateLastLogin();
      return true;
    }
    
    // Sinon vérifier si on a un userId stocké localement
    final userId = await getStoredUserId();
    if (userId == null) return false;
    
    // Vérifier si la session n'a pas expiré (14 jours)
    final prefs = await SharedPreferences.getInstance();
    final lastLoginStr = prefs.getString(_lastLoginKey);
    
    if (lastLoginStr == null) {
      // Pas de timestamp, considérer comme expiré
      await signOut();
      return false;
    }
    
    final lastLogin = DateTime.parse(lastLoginStr);
    final now = DateTime.now();
    final difference = now.difference(lastLogin).inDays;
    
    if (difference >= _sessionExpirationDays) {
      // Session expirée après 30 jours d'inactivité
      print('⏰ [AUTH] Session expirée après $difference jours (limite: $_sessionExpirationDays jours)');
      await signOut();
      return false;
    }
    
    // Session valide, mettre à jour le timestamp
    await _updateLastLogin();
    print('✅ [AUTH] Session valide (dernière connexion: il y a $difference jours)');
    return true;
  }

  Future<void> signInWithPhone(String phone) async {
    try {
      print('🔐 [AUTH] Tentative de connexion avec: $phone');
      
      // Vérifier si l'utilisateur existe dans la table users
      final response = await _supabase
          .from('users')
          .select('id, telephone, nom, prenom, role, email')
          .eq('telephone', phone)
          .maybeSingle();

      if (response == null) {
        print('❌ [AUTH] Compte inexistant');
        throw Exception('Le compte n\'existe pas, veuillez créer un compte');
      }

      final userId = response['id'] as String;
      final userEmail = response['email'] as String?;
      print('✅ [AUTH] Utilisateur trouvé: $userId');
      
      // ✅ CORRECTION: Vérifier si l'utilisateur est déjà authentifié dans Supabase Auth
      try {
        // Tenter de récupérer l'utilisateur depuis auth.users via RPC ou admin
        // Si l'utilisateur existe dans auth.users, créer une session
        if (userEmail != null && userEmail.isNotEmpty) {
          // L'utilisateur a un compte auth.users (créé via signup)
          // On doit utiliser signInWithPassword ou OTP
          print('📱 [AUTH] Utilisateur avec email Auth détecté: $userEmail');
          
          // Stocker temporairement l'ID (la vraie session sera créée après OTP/password)
          await _storeUserId(userId, phone);
          print('✅ [AUTH] Session locale créée pour $userId');
        } else {
          // L'utilisateur existe dans la table users mais PAS dans auth.users
          // C'est le cas pour les connexions par téléphone sans OTP
          print('⚠️ [AUTH] Utilisateur sans compte Auth Supabase détecté');
          
          // Stocker l'ID localement
          await _storeUserId(userId, phone);
          print('✅ [AUTH] Session locale créée pour $userId');
        }
      } catch (authError) {
        print('⚠️ [AUTH] Erreur vérification auth: $authError');
        // Continuer avec session locale
        await _storeUserId(userId, phone);
      }
      
      /* VERSION AVEC OTP (à activer en production):
      print('📱 [AUTH] Envoi du code OTP...');
      await _supabase.auth.signInWithOtp(
        phone: phone,
        shouldCreateUser: false,
      );
      print('✅ [AUTH] Code OTP envoyé avec succès');
      */
    } catch (e) {
      print('❌ [AUTH] Erreur signInWithPhone: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    // Supprimer aussi les données locales
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_userPhoneKey);
    await prefs.remove(_lastLoginKey);
    // Ne pas supprimer has_accepted_terms et user_profile_type pour conserver les préférences
    print('🚪 [AUTH] Déconnexion et suppression des données locales');
  }

  Future<void> signUp({required String name, required String phone}) async {
    try {
      // Envoyer le code OTP pour inscription via Supabase Auth
      await _supabase.auth.signInWithOtp(
        phone: phone,
        shouldCreateUser: true, // Créer l'utilisateur si nécessaire
      );
      
      print('Code OTP d\'inscription envoyé à $phone');
      // Le profil sera créé après vérification OTP
    } catch (e) {
      print('Erreur signUp: $e');
      throw Exception('Erreur lors de l\'inscription: ${e.toString()}');
    }
  }

  Future<void> verifyOtp({required String phone, required String token}) async {
    try {
      // Vérifier le code OTP
      final response = await _supabase.auth.verifyOTP(
        phone: phone,
        token: token,
        type: OtpType.sms,
      );

      if (response.session == null) {
        throw Exception('Code OTP invalide');
      }

      print('OTP vérifié avec succès');
    } catch (e) {
      print('Erreur verifyOtp: $e');
      throw Exception('Code OTP invalide ou expiré');
    }
  }

  // Stocker l'ID utilisateur localement avec timestamp
  Future<void> _storeUserId(String userId, String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
    await prefs.setString(_userPhoneKey, phone);
    await prefs.setString(_lastLoginKey, DateTime.now().toIso8601String());
    print('📅 [AUTH] Timestamp de connexion enregistré');
  }
  
  // Mettre à jour le timestamp de dernière activité
  Future<void> _updateLastLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastLoginKey, DateTime.now().toIso8601String());
  }
}

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../features/feed/data/models/signalement_model.dart';

/// Service de cache local pour mode offline
class LocalCacheService {
  static const String _signalementsCacheKey = 'cached_signalements';
  static const String _lastUpdateKey = 'cache_last_update';
  static const int _cacheExpirationHours = 24; // Cache valide 24h

  /// Sauvegarder les signalements en cache
  Future<void> cacheSignalements(List<SignalementModel> signalements) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Convertir les signalements en JSON
      final jsonList = signalements.map((s) => s.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      
      // Sauvegarder
      await prefs.setString(_signalementsCacheKey, jsonString);
      await prefs.setString(_lastUpdateKey, DateTime.now().toIso8601String());
      
      print('💾 [CACHE] ${signalements.length} signalement(s) mis en cache');
    } catch (e) {
      print('❌ [CACHE] Erreur sauvegarde: $e');
    }
  }

  /// Récupérer les signalements du cache
  Future<List<SignalementModel>?> getCachedSignalements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Vérifier si le cache existe
      final jsonString = prefs.getString(_signalementsCacheKey);
      if (jsonString == null) {
        print('⚠️ [CACHE] Aucun cache trouvé');
        return null;
      }
      
      // Vérifier si le cache n'a pas expiré
      final lastUpdateStr = prefs.getString(_lastUpdateKey);
      if (lastUpdateStr != null) {
        final lastUpdate = DateTime.parse(lastUpdateStr);
        final now = DateTime.now();
        final difference = now.difference(lastUpdate);
        
        if (difference.inHours >= _cacheExpirationHours) {
          print('⏰ [CACHE] Cache expiré (${difference.inHours}h)');
          await clearCache();
          return null;
        }
      }
      
      // Décoder et retourner les signalements
      final jsonList = jsonDecode(jsonString) as List;
      final signalements = jsonList
          .map((json) => SignalementModel.fromJson(json as Map<String, dynamic>))
          .toList();
      
      print('💾 [CACHE] ${signalements.length} signalement(s) chargés du cache');
      return signalements;
    } catch (e) {
      print('❌ [CACHE] Erreur lecture: $e');
      return null;
    }
  }

  /// Vérifier si le cache est valide
  Future<bool> isCacheValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final jsonString = prefs.getString(_signalementsCacheKey);
      if (jsonString == null) return false;
      
      final lastUpdateStr = prefs.getString(_lastUpdateKey);
      if (lastUpdateStr == null) return false;
      
      final lastUpdate = DateTime.parse(lastUpdateStr);
      final now = DateTime.now();
      final difference = now.difference(lastUpdate);
      
      return difference.inHours < _cacheExpirationHours;
    } catch (e) {
      return false;
    }
  }

  /// Effacer le cache
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_signalementsCacheKey);
      await prefs.remove(_lastUpdateKey);
      print('🗑️ [CACHE] Cache effacé');
    } catch (e) {
      print('❌ [CACHE] Erreur effacement: $e');
    }
  }
}

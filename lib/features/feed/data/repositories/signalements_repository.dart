import '../../../../core/config/supabase_config.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../profile/data/models/user_stats_model.dart';
import '../models/signalement_model.dart';

class SignalementsRepository {
  final _supabase = SupabaseConfig.client;
  final _authRepo = AuthRepository();

  // Ajouter une félicitation
  Future<void> addFelicitation(String signalementId) async {
    try {
      String? userId =
          _supabase.auth.currentUser?.id ?? await _authRepo.getStoredUserId();
      if (userId == null) throw Exception('Utilisateur non connecté');

      // Vérifier si déjà félicité
      final existing = await _supabase
          .from('felicitations')
          .select()
          .eq('user_id', userId)
          .eq('signalement_id', signalementId)
          .maybeSingle();

      if (existing != null) {
        throw Exception('Vous avez déjà félicité ce signalement');
      }

      // Ajouter la félicitation
      await _supabase.from('felicitations').insert({
        'user_id': userId,
        'signalement_id': signalementId,
      });

      // Récupérer le compteur actuel et l'incrémenter
      final signalement = await _supabase
          .from('signalements')
          .select('felicitations')
          .eq('id', signalementId)
          .single();

      final currentCount = signalement['felicitations'] as int? ?? 0;
      await _supabase
          .from('signalements')
          .update({'felicitations': currentCount + 1}).eq('id', signalementId);

      print('✅ [REPO] Félicitation ajoutée avec succès');
    } catch (e) {
      print('Erreur addFelicitation: $e');
      rethrow;
    }
  }

  // Créer un nouveau signalement
  Future<SignalementModel> createSignalement({
    String? titre,
    required String description,
    required String categorie,
    String? photoUrl,
    double? latitude,
    double? longitude,
    String? adresse,
    String? audioUrl,
    Duration? audioDuration,
  }) async {
    try {
      print('🔐 [REPO] Vérification de l\'utilisateur...');

      // Essayer d'abord avec Supabase Auth
      String? userId = _supabase.auth.currentUser?.id;

      // Si pas de session Auth, utiliser l'ID stocké localement
      if (userId == null) {
        print('⚠️ [REPO] Pas de session Auth, vérification locale...');
        userId = await _authRepo.getStoredUserId();
      }

      if (userId == null) {
        print('❌ [REPO] Utilisateur non connecté!');
        throw Exception('Utilisateur non connecté');
      }

      print('✅ [REPO] User ID: $userId');

      // Si c'est un signalement audio, mettre une description claire
      final finalDescription = (audioUrl != null && audioUrl.isNotEmpty)
          ? (description.isEmpty ? '🎤 Message vocal' : description)
          : description;

      final data = {
        'user_id': userId,
        'titre': titre,
        'description': finalDescription,
        'categorie': categorie,
        'photo_url': photoUrl,
        'latitude': latitude,
        'longitude': longitude,
        'adresse': adresse,
        'audio_url': audioUrl,
        'audio_duration': audioDuration?.inSeconds,
        'etat': 'en_attente', // etat au lieu de status
        'felicitations': 0,
      };

      print('📦 [REPO] Données à insérer:');
      print('   Latitude: $latitude (type: ${latitude.runtimeType})');
      print('   Longitude: $longitude (type: ${longitude.runtimeType})');
      print('   Adresse: $adresse');
      print('   Titre: $titre');
      print('   Catégorie: $categorie');

      print('⏳ [REPO] Insertion dans Supabase...');
      final response = await _supabase
          .from('signalements')
          .insert(data)
          .select('*, users!signalements_user_id_fkey(*)')
          .single();

      print('✅ [REPO] Signalement créé avec succès!');
      print('   Response: $response');

      return SignalementModel.fromJson(response);
    } catch (e) {
      print('❌ [REPO] Erreur createSignalement: $e');
      rethrow; // Relancer l'erreur originale pour que ErrorHandler puisse la traiter
    }
  }

  // Supprimer un signalement
  Future<void> deleteSignalement(String id) async {
    try {
      await _supabase.from('signalements').delete().eq('id', id);
    } catch (e) {
      print('Erreur deleteSignalement: $e');
      rethrow;
    }
  }

  // Récupérer un signalement spécifique
  Future<SignalementModel> getSignalement(String id) async {
    try {
      final response = await _supabase
          .from('signalements')
          .select('*, users!signalements_user_id_fkey(*)')
          .eq('id', id)
          .single();

      return SignalementModel.fromJson(response);
    } catch (e) {
      print('Erreur getSignalement: $e');
      rethrow;
    }
  }

  // Récupérer tous les signalements avec les profils des auteurs
  Future<List<SignalementModel>> getSignalements() async {
    try {
      print('🔵 [FEED] Début chargement signalements...');
      print('🔵 [FEED] Auth user: ${_supabase.auth.currentUser?.id}');
      
      final response = await _supabase
          .from('signalements')
          .select('*, users!signalements_user_id_fkey(*)')
          .order('created_at', ascending: false);

      print('✅ [FEED] Signalements récupérés: ${(response as List).length}');
      
      final signalements = (response as List)
          .map((json) => SignalementModel.fromJson(json))
          .toList();
      
      print('✅ [FEED] Signalements mappés: ${signalements.length}');
      return signalements;
    } catch (e) {
      print('❌ [FEED] Erreur getSignalements: $e');
      rethrow;
    }
  }

  // Récupérer les félicitations de l'utilisateur
  Future<Set<String>> getUserFelicitations() async {
    try {
      String? userId =
          _supabase.auth.currentUser?.id ?? await _authRepo.getStoredUserId();
      if (userId == null) return {};

      final response = await _supabase
          .from('felicitations')
          .select('signalement_id')
          .eq('user_id', userId);

      return (response as List)
          .map((f) => f['signalement_id'] as String)
          .toSet();
    } catch (e) {
      print('Erreur getUserFelicitations: $e');
      return {};
    }
  }

  // Récupérer les signalements de l'utilisateur connecté
  Future<List<SignalementModel>> getUserSignalements() async {
    try {
      String? userId =
          _supabase.auth.currentUser?.id ?? await _authRepo.getStoredUserId();
      if (userId == null) throw Exception('Utilisateur non connecté');

      final response = await _supabase
          .from('signalements')
          .select('*, users!signalements_user_id_fkey(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => SignalementModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Erreur getUserSignalements: $e');
      rethrow;
    }
  }

  // Récupérer les statistiques utilisateur
  Future<UserStatsModel> getUserStats() async {
    try {
      String? userId =
          _supabase.auth.currentUser?.id ?? await _authRepo.getStoredUserId();
      if (userId == null) throw Exception('Utilisateur non connecté');

      print('📊 [STATS] Récupération stats pour user: $userId');

      final signalements = await _supabase
          .from('signalements')
          .select('etat, felicitations')
          .eq('user_id', userId);

      print(
          '📊 [STATS] Nombre signalements récupérés: ${(signalements as List).length}');
      if (signalements.isNotEmpty) {
        print('📊 [STATS] Premier signalement exemple: ${signalements[0]}');
      }

      final totalSignalements = signalements.length;
      final enAttente =
          signalements.where((s) => s['etat'] == 'en_attente').length;
      final enCours = signalements.where((s) => s['etat'] == 'en_cours').length;
      final resolus = signalements.where((s) => s['etat'] == 'resolu').length;
      final totalFelicitations = signalements.fold<int>(
        0,
        (sum, s) => sum + (s['felicitations'] as int? ?? 0),
      );

      print(
          '📊 [STATS] Résultats: Total=$totalSignalements, EnAttente=$enAttente, EnCours=$enCours, Resolus=$resolus, Félicitations=$totalFelicitations');

      return UserStatsModel(
        totalSignalements: totalSignalements,
        totalFelicitations: totalFelicitations,
        totalResolus: resolus,
        enAttente: enAttente,
        enCours: enCours,
        resolus: resolus,
      );
    } catch (e) {
      print('❌ [STATS] Erreur getUserStats: $e');
      return UserStatsModel(
        totalSignalements: 0,
        totalFelicitations: 0,
        totalResolus: 0,
        enAttente: 0,
        enCours: 0,
        resolus: 0,
      );
    }
  }

  // Retirer une félicitation
  Future<void> removeFelicitation(String signalementId) async {
    try {
      String? userId =
          _supabase.auth.currentUser?.id ?? await _authRepo.getStoredUserId();
      if (userId == null) throw Exception('Utilisateur non connecté');

      // Supprimer la félicitation
      await _supabase
          .from('felicitations')
          .delete()
          .eq('user_id', userId)
          .eq('signalement_id', signalementId);

      // Récupérer le compteur actuel et le décrémenter
      final signalement = await _supabase
          .from('signalements')
          .select('felicitations')
          .eq('id', signalementId)
          .single();

      final currentCount = signalement['felicitations'] as int? ?? 0;
      await _supabase.from('signalements').update({
        'felicitations': currentCount > 0 ? currentCount - 1 : 0
      }).eq('id', signalementId);

      print('✅ [REPO] Félicitation retirée avec succès');
    } catch (e) {
      print('Erreur removeFelicitation: $e');
      rethrow;
    }
  }

  /// Résoudre un signalement (appel RPC Supabase)
  ///
  /// Cette méthode appelle la fonction PostgreSQL `resolve_signalement`
  /// qui marque le signalement comme résolu et enregistre les données de résolution.
  ///
  /// Paramètres:
  /// - [signalementId] : ID du signalement à résoudre
  /// - [authorityId] : ID de l'autorité qui résout
  /// - [photoApresUrl] : URL de la photo après intervention (optionnel)
  /// - [note] : Note de résolution (optionnel)
  ///
  /// Retourne un Map avec:
  /// - success (bool) : true si succès
  /// - message (String) : message de confirmation ou d'erreur
  /// - signalement (Map?) : données mises à jour du signalement
  Future<Map<String, dynamic>> resolveSignalement(
    String signalementId,
    String authorityId, {
    String? photoApresUrl,
    String? note,
  }) async {
    try {
      print(
          '✅ [REPO] Résolution du signalement $signalementId par $authorityId');

      final result = await _supabase.rpc('resolve_signalement', params: {
        'signalement_id': signalementId,
        'authority_id': authorityId,
        'photo_apres_url': photoApresUrl,
        'note': note,
      });

      print('✅ [REPO] Résultat RPC: $result');

      if (result is Map<String, dynamic>) {
        return result;
      }

      return {
        'success': true,
        'message': 'Signalement résolu avec succès',
        'data': result,
      };
    } catch (e) {
      print('❌ [REPO] Erreur resolveSignalement: $e');

      String errorMessage = e.toString();
      if (errorMessage.contains('not assigned')) {
        errorMessage = 'Vous devez d\'abord prendre en charge ce signalement';
      } else if (errorMessage.contains('not found')) {
        errorMessage = 'Signalement introuvable';
      } else {
        errorMessage = 'Impossible de résoudre ce signalement';
      }

      return {
        'success': false,
        'message': errorMessage,
        'error': e.toString(),
      };
    }
  }

  // ===== MÉTHODES POUR L'INTERFACE AUTORITÉ =====

  /// Prendre en charge un signalement (appel RPC Supabase)
  ///
  /// Cette méthode appelle la fonction PostgreSQL `take_charge_signalement`
  /// qui verrouille le signalement et l'assigne à l'autorité.
  ///
  /// Paramètres:
  /// - [signalementId] : ID du signalement à prendre en charge
  /// - [authorityId] : ID de l'autorité qui prend en charge
  ///
  /// Retourne un Map avec:
  /// - success (bool) : true si succès
  /// - message (String) : message de confirmation ou d'erreur
  /// - signalement (Map?) : données mises à jour du signalement
  Future<Map<String, dynamic>> takeChargeSignalement(
    String signalementId,
    String authorityId,
  ) async {
    try {
      print(
          '🚨 [REPO] Prise en charge du signalement $signalementId par $authorityId');

      final result = await _supabase.rpc('take_charge_signalement', params: {
        'signalement_id': signalementId,
        'authority_id': authorityId,
      });

      print('✅ [REPO] Résultat RPC: $result');

      // Le résultat est déjà un Map si la fonction retourne JSON
      if (result is Map<String, dynamic>) {
        return result;
      }

      // Fallback si le résultat n'est pas au format attendu
      return {
        'success': true,
        'message': 'Signalement pris en charge avec succès',
        'data': result,
      };
    } catch (e) {
      print('❌ [REPO] Erreur takeChargeSignalement: $e');

      // Parser l'erreur PostgreSQL pour donner un message clair
      String errorMessage = e.toString();
      if (errorMessage.contains('already assigned')) {
        errorMessage =
            'Ce signalement a déjà été pris en charge par une autre autorité';
      } else if (errorMessage.contains('not found')) {
        errorMessage = 'Signalement introuvable';
      } else {
        errorMessage = 'Impossible de prendre en charge ce signalement';
      }

      return {
        'success': false,
        'message': errorMessage,
        'error': e.toString(),
      };
    }
  }

  // Mettre à jour un signalement
  Future<void> updateSignalement(
    String id, {
    String? titre,
    String? description,
    String? categorie,
    String? photoUrl,
    String? etat,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (titre != null) data['titre'] = titre;
      if (description != null) data['description'] = description;
      if (categorie != null) data['categorie'] = categorie;
      if (photoUrl != null) data['photo_url'] = photoUrl;
      if (etat != null) data['etat'] = etat;
      data['updated_at'] = DateTime.now().toIso8601String();

      await _supabase.from('signalements').update(data).eq('id', id);
    } catch (e) {
      print('Erreur updateSignalement: $e');
      rethrow;
    }
  }

  /// Récupérer les signalements assignés à une autorité spécifique
  /// Utilisé pour l'écran d'accueil de l'autorité
  /// Ne retourne que les signalements dont l'autorité a pris en charge (locked = true)
  Future<List<SignalementModel>> getAgentAssignedSignalements(
      String agentId) async {
    try {
      print(
          '🔎 [REPO] Récupération des signalements assignés à l\'autorité $agentId');

      final response = await _supabase
          .from('signalements')
          .select('*, users!signalements_user_id_fkey(*)')
          .eq('assigned_to', agentId)
          .eq('locked',
              true) // IMPORTANT : Seulement les signalements pris en charge explicitement
          .inFilter('etat',
              ['en_cours', 'en_attente']) // Seulement les signalements actifs
          .order('created_at', ascending: false);

      final signalements = (response as List)
          .map((json) => SignalementModel.fromJson(json))
          .toList();

      print(
          '✅ [REPO] ${signalements.length} signalement(s) pris en charge trouvé(s)');
      return signalements;
    } catch (e) {
      print('❌ [REPO] Erreur getAgentAssignedSignalements: $e');
      rethrow;
    }
  }

  /// Récupérer tous les signalements assignés à une autorité (locked ou non)
  /// Utilisé pour la carte où l'autorité peut voir et prendre en charge les signalements
  Future<List<SignalementModel>> getAllAgentSignalements(String agentId) async {
    try {
      print(
          '🔎 [REPO] Récupération de tous les signalements assignés à l\'autorité $agentId');

      final response = await _supabase
          .from('signalements')
          .select('*, users!signalements_user_id_fkey(*)')
          .eq('assigned_to', agentId)
          .inFilter('etat',
              ['en_cours', 'en_attente']) // Seulement les signalements actifs
          .order('created_at', ascending: false);

      print('📦 [REPO] Réponse brute: ${response.length} résultat(s)');
      if (response.isNotEmpty) {
        print('📋 [REPO] Premier signalement: ${response[0]}');
      }

      final signalements = (response as List)
          .map((json) => SignalementModel.fromJson(json))
          .toList();

      print(
          '✅ [REPO] ${signalements.length} signalement(s) assigné(s) au total trouvé(s)');
      if (signalements.isNotEmpty) {
        for (var sig in signalements) {
          print(
              '   - ${sig.id}: etat=${sig.etat}, locked=${sig.locked}, assigned_to=${sig.assignedTo}');
        }
      }
      return signalements;
    } catch (e) {
      print('❌ [REPO] Erreur getAllAgentSignalements: $e');
      rethrow;
    }
  }
}

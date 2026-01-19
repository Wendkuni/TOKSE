import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/services/signalement_state_service.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../feed/data/models/signalement_model.dart';
import '../../../feed/data/repositories/signalements_repository.dart';

/// Écran d'accueil pour les autorités
/// Affiche tous les signalements disponibles avec bouton "Prendre en charge"
/// Cliquer sur "Prendre en charge" assigne le signalement et redirige vers la carte
class AuthorityHomeScreen extends StatefulWidget {
  const AuthorityHomeScreen({super.key});

  @override
  State<AuthorityHomeScreen> createState() => _AuthorityHomeScreenState();
}

class _AuthorityHomeScreenState extends State<AuthorityHomeScreen> {
  final AuthRepository _authRepo = AuthRepository();
  final SignalementsRepository _signalementsRepo = SignalementsRepository();
  // final NotificationsRepository _notificationsRepo = NotificationsRepository();
  final _supabase = SupabaseConfig.client;
  final SignalementStateService _stateService = SignalementStateService();

  RealtimeChannel? _realtimeChannel;
  StreamSubscription<SignalementStateEvent>? _stateSubscription;

  bool _isLoading = true;
  Position? _initialPosition; // Position FIGÉE au chargement (pour calcul distance)
  String? _authorityId;
  // int _unreadNotificationsCount = 0;
  
  // Cache des distances calculées UNE SEULE FOIS (Map<signalementId, distance en mètres>)
  final Map<String, double> _cachedDistances = {};

  // Tous les signalements actifs (en_attente ET en_cours, SAUF resolu)
  List<SignalementModel> _availableSignalements = [];

  // Mes signalements pris en charge (en_cours uniquement)
  List<SignalementModel> _mySignalements = [];

  // Stats
  int _signalementsToday = 0;
  int _signalementsEnCours = 0;
  int _signalementsResolus = 0;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1a73e8),
        title: const Text(
          'TOKSE Opérateur',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              print('🔄 [AUTHORITY_HOME] Rafraîchissement manuel demandé');
              _loadData();
            },
          ),
          // Notification désactivée pour cette version
          // Stack(
          //   children: [
          //     IconButton(
          //       icon: const Icon(Icons.notifications_outlined,
          //           color: Colors.white),
          //       onPressed: () {
          //         context.push('/authority-notifications');
          //       },
          //     ),
          //     // Badge avec le nombre de notifications
          //     if (_unreadNotificationsCount > 0)
          //       Positioned(
          //         right: 8,
          //         top: 8,
          //         child: Container(
          //           padding: const EdgeInsets.all(4),
          //           decoration: const BoxDecoration(
          //             color: Color(0xFFe74c3c),
          //             shape: BoxShape.circle,
          //           ),
          //           constraints: const BoxConstraints(
          //             minWidth: 16,
          //             minHeight: 16,
          //           ),
          //           child: Text(
          //             _unreadNotificationsCount > 99
          //                 ? '99+'
          //                 : _unreadNotificationsCount.toString(),
          //             style: const TextStyle(
          //               color: Colors.white,
          //               fontSize: 10,
          //               fontWeight: FontWeight.bold,
          //           ),
          //           textAlign: TextAlign.center,
          //         ),
          //       ),
          //     ),
          //   ],
          // ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Statistiques du jour
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1a73e8), Color(0xFF4285f4)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📊 Mes statistiques',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: '🔥',
                            label: 'Aujourd\'hui',
                            value: _signalementsToday.toString(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            icon: '⏳',
                            label: 'En cours',
                            value: _signalementsEnCours.toString(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: '✅',
                            label: 'Résolus',
                            value: _signalementsResolus.toString(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            icon: '🎯',
                            label: 'Mes missions',
                            value: _mySignalements.length.toString(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Bouton "Voir la carte"
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Navigation vers l'onglet Carte (index 1 du bottom nav)
                      context.go('/authority-home', extra: {'tabIndex': 1});
                    },
                    icon: const Icon(Icons.map, size: 28),
                    label: const Text(
                      'Voir la carte',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10b981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),

              // Liste des missions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '� Signalements disponibles',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_availableSignalements.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1a73e8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_availableSignalements.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Liste scrollable des signalements disponibles
                    if (_availableSignalements.isEmpty)
                      _EmptyMissionCard()
                    else
                      ..._availableSignalements.map((signalement) {
                        // Vérifier si c'est MA prise en charge
                        final isMySignalement =
                            signalement.assignedTo == _authorityId &&
                                signalement.locked;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _MissionCard(
                            signalement: signalement,
                            distance: _calculateDistance(signalement),
                            totalMissions: _availableSignalements.length,
                            currentIndex:
                                _availableSignalements.indexOf(signalement) + 1,
                            onNext: null, // Pas de navigation, on scroll
                            onPrevious: null, // Pas de navigation, on scroll
                            onViewDetails: () {
                              context.push('/signalement/${signalement.id}');
                            },
                            onViewOnMap: () {
                              // Rediriger vers la carte avec le signalement
                              context.go('/authority-home', extra: {
                                'tabIndex': 1,
                                'signalementId': signalement.id
                              });
                            },
                            onMarkResolved:
                                null, // Résolution uniquement depuis la carte
                            onTakeCharge: isMySignalement
                                ? null
                                : () {
                                    _takeChargeAndGoToMap(signalement);
                                  },
                          ),
                        );
                      }),
                  ],
                ),
              ),

              const SizedBox(height: 80), // Espace pour le bottom nav
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    print('🏠 [AUTHORITY_HOME] initState appelé');
    _loadData();
    _setupRealtimeListener();
    _setupStateListener();
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    _stateSubscription?.cancel();
    super.dispose();
  }

  /// Écouter les changements d'état des signalements depuis d'autres écrans
  void _setupStateListener() {
    _stateSubscription = _stateService.stateChanges.listen((event) {
      print(
          '📢 [AUTHORITY_HOME] Événement reçu: ${event.type} pour signalement ${event.signalementId}');
      // Recharger les données pour synchroniser l'UI
      _loadData();
    });
    print("✅ [AUTHORITY_HOME] Listener d'état configuré");
  }

  /// Écouter les changements en temps réel sur la table signalements
  void _setupRealtimeListener() {
    _realtimeChannel = _supabase
        .channel('signalements_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'signalements',
          callback: (payload) {
            print(
                '🔄 [AUTHORITY_HOME] Changement détecté dans signalements: ${payload.eventType}');
            // Recharger les données quand un signalement change
            _loadData();
          },
        )
        .subscribe();

    print('✅ [AUTHORITY_HOME] Listener temps réel configuré');
  }

  String? _calculateDistance(SignalementModel signalement) {
    // Utiliser le cache si disponible (distance calculée UNE SEULE FOIS)
    if (_cachedDistances.containsKey(signalement.id)) {
      return _formatDistance(_cachedDistances[signalement.id]!);
    }
    
    // Si pas dans le cache, calculer et mettre en cache
    if (_initialPosition == null) return null;

    final meters = Geolocator.distanceBetween(
      _initialPosition!.latitude,
      _initialPosition!.longitude,
      signalement.latitude ?? 0.0,
      signalement.longitude ?? 0.0,
    );
    
    // Mettre en cache pour ne JAMAIS recalculer
    _cachedDistances[signalement.id] = meters;
    print('📏 [DISTANCE] Calculée UNE FOIS pour ${signalement.id}: ${meters.round()}m');
    
    return _formatDistance(meters);
  }
  
  /// Obtenir la distance en mètres (pour le tri)
  double? _getDistance(SignalementModel signalement) {
    if (_cachedDistances.containsKey(signalement.id)) {
      return _cachedDistances[signalement.id];
    }
    
    if (_initialPosition == null) return null;
    
    final meters = Geolocator.distanceBetween(
      _initialPosition!.latitude,
      _initialPosition!.longitude,
      signalement.latitude ?? 0.0,
      signalement.longitude ?? 0.0,
    );
    
    _cachedDistances[signalement.id] = meters;
    return meters;
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  Future<Position?> _getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('⚠️ [LOCATION] Service désactivé');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('⚠️ [LOCATION] Permission refusée');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('⚠️ [LOCATION] Permission refusée définitivement');
        return null;
      }

      // Obtenir position avec haute précision
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 10),
      );
      
      print('✅ [LOCATION] Position obtenue avec précision: ${position.accuracy}m');
      return position;
    } catch (e) {
      print('❌ [LOCATION] Erreur: $e');
      return null;
    }
  }

  Future<void> _loadData() async {
    print('🔄 [AUTHORITY_HOME] Début _loadData');
    
    // Afficher le loading seulement si pas encore de données
    if (_availableSignalements.isEmpty) {
      setState(() => _isLoading = true);
    }
    
    try {
      // 1. Récupérer l'ID de l'autorité rapidement
      String? authorityId = _supabase.auth.currentUser?.id;
      authorityId ??= await _authRepo.getStoredUserId();
      
      if (authorityId == null) {
        print('❌ [AUTHORITY_HOME] Autorité non authentifiée');
        setState(() => _isLoading = false);
        return;
      }

      print('✅ [AUTHORITY_HOME] Autorité ID: $authorityId');
      _authorityId = authorityId;

      // 2. Charger les signalements EN PREMIER (sans attendre la position)
      print('🎯 [AUTHORITY_HOME] Chargement des signalements...');
      final allSignalements = await _signalementsRepo.getSignalements()
          .timeout(const Duration(seconds: 8));

      // Filtrer : afficher tous les signalements actifs (en_attente OU en_cours)
      // SAUF ceux qui sont résolus
      final availableSignalements = allSignalements.where((sig) {
        return sig.etat != 'resolu';
      }).toList();

      // Mes signalements (déjà pris en charge par moi)
      final mySignalements = allSignalements.where((sig) {
        return sig.assignedTo == authorityId && sig.etat != 'resolu';
      }).toList();

      print(
          '📋 [AUTHORITY_HOME] ${availableSignalements.length} signalement(s) disponible(s)');
      print(
          '📋 [AUTHORITY_HOME] ${mySignalements.length} signalement(s) pris en charge par moi');

      // 3. Calculer les stats
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);

      final statsToday = allSignalements
          .where((s) =>
              s.etat == 'resolu' &&
              s.assignedTo == authorityId &&
              s.resolvedAt != null &&
              s.resolvedAt!.isAfter(todayStart))
          .length;

      final statsEnCours =
          allSignalements.where((s) => s.etat == 'en_cours').length;
      final statsResolus =
          allSignalements.where((s) => s.etat == 'resolu').length;

      print(
          '📊 [AUTHORITY_HOME] Stats: Aujourd\'hui=$statsToday, EnCours=$statsEnCours, Résolus=$statsResolus');

      // 4. Mettre à jour l'UI IMMÉDIATEMENT (sans attendre la position)
      if (mounted) {
        setState(() {
          _availableSignalements = availableSignalements;
          _mySignalements = mySignalements;
          _signalementsToday = statsToday;
          _signalementsEnCours = statsEnCours;
          _signalementsResolus = statsResolus;
          _isLoading = false;
        });
      }

      print('✅ [AUTHORITY_HOME] Chargement des données terminé');

      // 5. Obtenir la position EN ARRIÈRE-PLAN (ne bloque plus l'UI)
      _loadPositionInBackground(availableSignalements);

    } on TimeoutException {
      print('⏰ [AUTHORITY_HOME] Timeout - chargement trop long');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('❌ [AUTHORITY_HOME] Erreur: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Charge la position en arrière-plan et trie les signalements par distance
  Future<void> _loadPositionInBackground(List<SignalementModel> signalements) async {
    try {
      print('📍 [AUTHORITY_HOME] Demande de position en arrière-plan...');
      final position = await _getCurrentPosition();
      
      if (position != null && mounted) {
        print('✅ [AUTHORITY_HOME] Position obtenue: ${position.latitude}, ${position.longitude}');
        
        // FIGER la position initiale pour le calcul des distances
        _initialPosition = position;
        
        // Trier les signalements par distance
        final sortedSignalements = List<SignalementModel>.from(_availableSignalements);
        sortedSignalements.sort((a, b) {
          final distA = _getDistance(a);
          final distB = _getDistance(b);
          if (distA == null && distB == null) return 0;
          if (distA == null) return 1;
          if (distB == null) return -1;
          return distA.compareTo(distB);
        });
        
        setState(() {
          _availableSignalements = sortedSignalements;
        });
        
        print('✅ [AUTHORITY_HOME] Signalements triés par distance');
      } else {
        print('⚠️ [AUTHORITY_HOME] Position non disponible');
      }
    } catch (e) {
      print('⚠️ [AUTHORITY_HOME] Erreur position en arrière-plan: $e');
    }
  }

  Future<void> _takeChargeAndGoToMap(SignalementModel signalement) async {
    if (_authorityId == null) return;

    try {
      // Prendre en charge le signalement
      final result = await _signalementsRepo.takeChargeSignalement(
        signalement.id,
        _authorityId!,
      );

      if (result['success'] == true) {
        // Broadcaster le changement d'état
        _stateService.notifyTakeCharge(signalement.id, _authorityId!);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Signalement pris en charge'),
            backgroundColor: Color(0xFF3b82f6),
            duration: Duration(seconds: 2),
          ),
        );

        // Rediriger vers la carte (onglet 1)
        context.go('/authority-home',
            extra: {'tabIndex': 1, 'signalementId': signalement.id});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${result['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ErrorHandler.getReadableMessage(e)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Widget pour afficher un message quand aucun signalement n'est disponible
class _EmptyMissionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun signalement disponible',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tous les signalements ont été pris en charge.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Widget pour afficher la mission en cours
class _MissionCard extends StatelessWidget {
  final SignalementModel signalement;
  final String? distance;
  final int? totalMissions;
  final int? currentIndex;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final VoidCallback onViewDetails;
  final VoidCallback onViewOnMap;
  final VoidCallback? onMarkResolved;
  final VoidCallback? onTakeCharge;

  const _MissionCard({
    required this.signalement,
    this.distance,
    this.totalMissions,
    this.currentIndex,
    this.onNext,
    this.onPrevious,
    required this.onViewDetails,
    required this.onViewOnMap,
    required this.onMarkResolved,
    required this.onTakeCharge,
  });

  @override
  Widget build(BuildContext context) {
    final timeAgo = _formatTimeAgo(signalement.createdAt);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo avec badges superposés
            if (signalement.photoUrl != null &&
                signalement.photoUrl!.isNotEmpty)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      signalement.photoUrl!,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: double.infinity,
                          height: 200,
                          color: Colors.grey[300],
                          child: Icon(Icons.image,
                              size: 80, color: Colors.grey[600]),
                        );
                      },
                    ),
                  ),
                  // Gradient overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.3),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Badge catégorie (top-right)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        _getCategoryLabel(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  // Badge statut (top-left)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        _getStatusLabel(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // Badge pris en charge (bottom-left)
                  if (signalement.locked)
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock, size: 14, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'Pris en charge',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              )
            else
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: _getCategoryColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    _getCategoryEmoji(),
                    style: const TextStyle(fontSize: 80),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Description (avec indicateur audio si présent)
            if (signalement.audioUrl != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1a73e8).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF1a73e8).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.mic,
                      size: 18,
                      color: Color(0xFF1a73e8),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '🎙️ Message vocal',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1a73e8),
                      ),
                    ),
                    if (signalement.audioDuration != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1a73e8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${signalement.audioDuration! ~/ 60}:${(signalement.audioDuration! % 60).toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ] else ...[
              Text(
                signalement.description,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Distance + Date
            Row(
              children: [
                if (distance != null && distance!.isNotEmpty) ...[
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: Colors.grey[700],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    distance!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.grey[700],
                ),
                const SizedBox(width: 4),
                Text(
                  timeAgo,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onViewOnMap,
                    icon: const Icon(Icons.map, size: 20),
                    label: const Text('Carte'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1a73e8),
                      side: const BorderSide(color: Color(0xFF1a73e8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onViewDetails,
                    icon: const Icon(Icons.info_outline, size: 20),
                    label: const Text('Détails'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1a73e8),
                      side: const BorderSide(color: Color(0xFF1a73e8)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: signalement.locked && onMarkResolved != null
                  ? ElevatedButton.icon(
                      onPressed: onMarkResolved,
                      icon: const Icon(Icons.check_circle, size: 22),
                      label: const Text(
                        'Marquer comme résolu',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10b981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    )
                  : signalement.locked && onTakeCharge == null
                      ? ElevatedButton.icon(
                          onPressed: null, // Désactivé
                          icon: const Icon(Icons.lock, size: 22),
                          label: const Text(
                            'Déjà pris en charge',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[400],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: onTakeCharge,
                          icon: const Icon(Icons.assignment_ind, size: 22),
                          label: const Text(
                            'Prendre en charge',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3b82f6),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays}j';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Color _getCategoryColor() {
    switch (signalement.categorie) {
      case 'dechets':
        return const Color(0xFFe74c3c);
      case 'route':
        return const Color(0xFFf39c12);
      case 'pollution':
        return const Color(0xFF9b59b6);
      default:
        return const Color(0xFF34495e);
    }
  }

  String _getCategoryEmoji() {
    switch (signalement.categorie) {
      case 'dechets':
        return '🗑️';
      case 'route':
        return '🚧';
      case 'pollution':
        return '🏭';
      default:
        return '📢';
    }
  }

  String _getCategoryLabel() {
    switch (signalement.categorie) {
      case 'dechets':
        return 'Déchets';
      case 'route':
        return 'Route dégradée';
      case 'pollution':
        return 'Pollution';
      default:
        return 'Autre';
    }
  }

  Color _getStatusColor() {
    switch (signalement.etat) {
      case 'en_attente':
        return const Color(0xFFf59e0b);
      case 'en_cours':
        return const Color(0xFF3b82f6);
      case 'resolu':
        return const Color(0xFF10b981);
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel() {
    switch (signalement.etat) {
      case 'en_attente':
        return 'EN ATTENTE';
      case 'en_cours':
        return 'EN COURS';
      case 'resolu':
        return 'RÉSOLU';
      default:
        return signalement.etat.toUpperCase();
    }
  }
}

class _StatCard extends StatelessWidget {
  final String icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }
}

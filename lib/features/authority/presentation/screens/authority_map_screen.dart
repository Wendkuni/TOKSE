import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/utils/error_handler.dart';

import '../../../../core/services/local_cache_service.dart';
import '../../../../core/services/routing_service.dart';
import '../../../../core/services/signalement_state_service.dart';
import '../../../../core/services/voice_navigation_service.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../feed/data/models/signalement_model.dart';
import '../../../feed/data/repositories/signalements_repository.dart';

/// Écran Carte pour les autorités
/// Mode normal: affiche signalements assignés avec bouton "Prendre en charge"
/// Mode mission active: focus sur UNE mission avec itinéraire et détection proximité
class AuthorityMapScreen extends StatefulWidget {
  final String? signalementIdToLoad;

  const AuthorityMapScreen({super.key, this.signalementIdToLoad});

  @override
  State<AuthorityMapScreen> createState() => _AuthorityMapScreenState();
}

class _AuthorityMapScreenState extends State<AuthorityMapScreen> {
  final SignalementsRepository _signalementsRepo = SignalementsRepository();
  final AuthRepository _authRepo = AuthRepository();
  final LocalCacheService _cacheService = LocalCacheService();
  final RoutingService _routingService = RoutingService();
  final SignalementStateService _stateService = SignalementStateService();
  late final MapController _mapController;

  bool _isLoading = true;
  Position? _currentPosition;
  List<SignalementModel> _signalements = [];
  SignalementModel? _activeMission; // Mission en cours
  StreamSubscription<Position>? _positionStream;
  StreamSubscription<SignalementStateEvent>? _stateSubscription;
  VoiceNavigationService? _voiceNavigation;

  // Pour l'itinéraire
  List<LatLng> _routePoints = [];
  double _distanceToDestination = 0;
  int _estimatedTimeMinutes = 0;
  bool _isNearDestination = false; // < 1m du point (précision maximale)
  String? _agentId;
  bool _isOfflineMode = false;
  double _lastAnnouncedDistance = 0; // Pour éviter d'annoncer trop souvent
  DateTime? _lastRouteCalculation; // Pour éviter trop de recalculs

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
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _activeMission != null
            ? const Color(0xFFf59e0b) // Orange si mission active
            : const Color(0xFF1a73e8),
        title: Text(
          _activeMission != null
              ? 'Mission en cours'
              : 'Carte des signalements',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location, color: Colors.white),
            onPressed: () {
              if (_currentPosition != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _mapController.move(
                    LatLng(_currentPosition!.latitude,
                        _currentPosition!.longitude),
                    16.0,
                  );
                });
              }
            },
            tooltip: 'Ma position',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(12.3714, -1.5197),
              initialZoom: 7.5,
              minZoom: 6.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.tokse.app',
              ),
              // Itinéraire actif (mission en cours)
              if (_activeMission != null && _routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: const Color(0xFF1a73e8),
                      strokeWidth: 6.0,
                      borderColor: Colors.white,
                      borderStrokeWidth: 2.0,
                    ),
                  ],
                ),
              // Marqueurs des signalements (mode normal ou mission)
              if (_activeMission == null)
                MarkerClusterLayerWidget(
                  options: MarkerClusterLayerOptions(
                    maxClusterRadius: 45,
                    size: const Size(50, 50),
                    markers: _signalements
                        .where((s) => s.latitude != null && s.longitude != null)
                        .map((signalement) => Marker(
                              point: LatLng(signalement.latitude!,
                                  signalement.longitude!),
                              width: 50,
                              height: 50,
                              child: GestureDetector(
                                onTap: () => _showSignalementPopup(signalement),
                                child: _buildSignalementMarker(signalement),
                              ),
                            ))
                        .toList(),
                    builder: (context, markers) {
                      return Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1a73e8), Color(0xFF4A90E2)],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1a73e8).withOpacity(0.6),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            markers.length.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                )
              else
                // Marqueur de la mission active
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(_activeMission!.latitude!,
                          _activeMission!.longitude!),
                      width: 60,
                      height: 60,
                      child: GestureDetector(
                        onTap: () => _showSignalementPopup(_activeMission!),
                        child: _buildMissionMarker(_activeMission!),
                      ),
                    ),
                  ],
                ),
              // Marqueur de la position actuelle de l'utilisateur
              if (_currentPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(_currentPosition!.latitude,
                          _currentPosition!.longitude),
                      width: 70,
                      height: 70,
                      child: _buildUserPositionMarker(),
                    ),
                  ],
                ),
            ],
          ),
          if (_activeMission != null) _buildMissionBanner(),
          if (_activeMission == null)
            Positioned(
              top: 16,
              left: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on,
                            color: Color(0xFF1a73e8), size: 20),
                        const SizedBox(width: 6),
                        Text(
                          '${_signalements.length} signalement(s)',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1a73e8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isOfflineMode)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.offline_bolt,
                              color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Mode hors ligne',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          if (_activeMission != null && !_activeMission!.locked)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: _buildTakeChargeButton(),
            ),
          if (_activeMission != null &&
              _activeMission!.locked &&
              (_distanceToDestination <= 30 || _estimatedTimeMinutes <= 1))
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: _buildResolveButton(),
            ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _loadData();
    _startLocationTracking();
    _setupStateListener();

    // Si un signalementId est fourni, le charger automatiquement
    if (widget.signalementIdToLoad != null) {
      print('🎯 [MAP] SignalementId fourni: ${widget.signalementIdToLoad}');
      _loadAndFocusSignalement(widget.signalementIdToLoad!);
    }
  }

  @override
  void didUpdateWidget(AuthorityMapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Détecter si un nouveau signalementId a été fourni
    if (widget.signalementIdToLoad != null &&
        widget.signalementIdToLoad != oldWidget.signalementIdToLoad) {
      print(
          '🔄 [MAP] Nouveau signalementId détecté: ${widget.signalementIdToLoad}');
      _loadAndFocusSignalement(widget.signalementIdToLoad!);
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _stateSubscription?.cancel();
    _voiceNavigation?.dispose();
    super.dispose();
  }

  /// Écouter les changements d'état des signalements depuis d'autres écrans
  void _setupStateListener() {
    _stateSubscription = _stateService.stateChanges.listen((event) {
      print(
          '📢 [MAP] Événement reçu: ${event.type} pour signalement ${event.signalementId}');
      // Recharger les données pour synchroniser l'UI
      _loadData();
    });
    print("✅ [MAP] Listener d'état configuré");
  }

  String _getCategoryEmoji(String categorie) {
    switch (categorie) {
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

  String _getCategoryLabel(String categorie) {
    switch (categorie) {
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

  /// Construire le bandeau d'informations de la mission active
  Widget _buildMissionBanner() {
    if (_activeMission == null) return const SizedBox.shrink();

    // Titre : catégorie ou titre du signalement
    String missionTitle =
        _activeMission!.titre != null && _activeMission!.titre!.isNotEmpty
            ? _activeMission!.titre!
            : _getCategoryLabel(_activeMission!.categorie);

    // Format de la distance
    String distanceText = _distanceToDestination < 1000
        ? '${_distanceToDestination.round()} m'
        : '${(_distanceToDestination / 1000).toStringAsFixed(1)} km';

    // Format du temps
    String timeText = _estimatedTimeMinutes < 60
        ? '$_estimatedTimeMinutes min'
        : '${(_estimatedTimeMinutes / 60).toStringAsFixed(1)}h';

    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFf59e0b),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFf59e0b).withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 2,
            ),
            const BoxShadow(
              color: Colors.black45,
              blurRadius: 15,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header avec icône et titre
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFf59e0b), Color(0xFFfbbf24)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFf59e0b).withOpacity(0.6),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Text(
                    _getCategoryEmoji(_activeMission!.categorie),
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            '⚡ ',
                            style: TextStyle(fontSize: 14),
                          ),
                          const Text(
                            'MISSION ACTIVE',
                            style: TextStyle(
                              color: Color(0xFFf59e0b),
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        missionTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          shadows: [
                            Shadow(
                              color: Colors.black45,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Stats : Distance et Temps (style NASA)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF1a73e8).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Distance
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1a73e8), Color(0xFF4A90E2)],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1a73e8).withOpacity(0.6),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.navigation,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          distanceText,
                          style: const TextStyle(
                            color: Color(0xFF4fc3f7),
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'monospace',
                            shadows: [
                              Shadow(
                                color: Color(0xFF4fc3f7),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'DISTANCE',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Séparateur
                  Container(
                    height: 60,
                    width: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.1),
                          Colors.white.withOpacity(0.5),
                          Colors.white.withOpacity(0.1),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  // Temps
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF10b981), Color(0xFF34d399)],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10b981).withOpacity(0.6),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.access_time,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          timeText,
                          style: const TextStyle(
                            color: Color(0xFF4ade80),
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'monospace',
                            shadows: [
                              Shadow(
                                color: Color(0xFF4ade80),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'ETA',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Indicateur de proximité
            if (_isNearDestination) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10b981), Color(0xFF34d399)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10b981).withOpacity(0.6),
                      blurRadius: 15,
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 24),
                    SizedBox(width: 10),
                    Text(
                      '🎯 DESTINATION ATTEINTE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Construire le bouton "Prendre en charge"
  Widget _buildTakeChargeButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Info du signalement
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1a73e8).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Color(0xFF1a73e8),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Signalement disponible',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _activeMission?.description ?? 'Sans description',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Bouton prendre en charge
          ElevatedButton.icon(
            onPressed: _activeMission != null && !_activeMission!.locked
                ? _takeChargeFromMap
                : null,
            icon: const Icon(Icons.assignment_ind, size: 24),
            label: Text(
              _activeMission?.locked == true
                  ? 'Déjà pris en charge'
                  : 'Prendre en charge',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _activeMission?.locked == true
                  ? Colors.grey
                  : const Color(0xFF3b82f6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construire le bouton "Marquer comme résolu"
  Widget _buildResolveButton() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Badge distance si disponible
          if (_distanceToDestination <= 30 || _estimatedTimeMinutes <= 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _isNearDestination
                    ? const Color(0xFF10b981)
                    : const Color(0xFFf59e0b),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isNearDestination ? Icons.check_circle : Icons.near_me,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isNearDestination
                        ? '📍 Vous êtes sur le lieu'
                        : '📍 Vous êtes proche du lieu',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          if (_distanceToDestination <= 30 || _estimatedTimeMinutes <= 1)
            const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _activeMission != null
                ? () => _showResolveDialog(_activeMission!)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10b981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              '✅ Marquer comme résolu',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
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

      // Obtenir position avec haute précision pour le suivi en temps réel
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 10),
      );
      
      print('✅ [MAP_LOCATION] Position avec précision: ${position.accuracy}m');
      return position;
    } catch (e) {
      print('❌ [LOCATION] Erreur: $e');
      return null;
    }
  }

  Color _getStatusColor(String? etat) {
    switch (etat) {
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

  /// Construire le marqueur pour un signalement (style NASA)
  Widget _buildSignalementMarker(SignalementModel signalement) {
    final color = _getStatusColor(signalement.etat);
    final emoji = _getCategoryEmoji(signalement.categorie);
    final isUrgent = signalement.etat == 'en_attente';

    return Stack(
      alignment: Alignment.center,
      children: [
        // Effet de pulsation pour les signalements urgents
        if (isUrgent)
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withOpacity(0.4),
                width: 2,
              ),
            ),
          ),
        // Marqueur principal avec effet glow
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.6),
                blurRadius: 15,
                spreadRadius: 2,
              ),
              const BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ),
      ],
    );
  }

  /// Construire le marqueur pour la mission active (style NASA)
  Widget _buildMissionMarker(SignalementModel mission) {
    final emoji = _getCategoryEmoji(mission.categorie);

    return Stack(
      alignment: Alignment.center,
      children: [
        // Animation de pulsation externe
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFf59e0b).withOpacity(0.3),
              width: 3,
            ),
          ),
        ),
        // Marqueur principal avec animation
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFf59e0b), Color(0xFFfbbf24)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFf59e0b).withOpacity(0.8),
                blurRadius: 20,
                spreadRadius: 3,
              ),
              const BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
        // Badge "Mission"
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Text(
              '⚡',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  /// Construire le marqueur de position de l'utilisateur (style NASA)
  Widget _buildUserPositionMarker() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Cercle externe pulsant (radar)
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF1a73e8).withOpacity(0.3),
              width: 2,
            ),
          ),
        ),
        // Cercle moyen
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF1a73e8).withOpacity(0.2),
          ),
        ),
        // Marqueur principal avec icône
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1a73e8), Color(0xFF4A90E2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1a73e8).withOpacity(0.8),
                blurRadius: 20,
                spreadRadius: 2,
              ),
              const BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(
            Icons.navigation,
            color: Colors.white,
            size: 24,
          ),
        ),
        // Point central
        Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Récupérer l'ID de l'agent
      final agentId = await _authRepo.getStoredUserId();
      if (agentId == null) {
        print('❌ [AUTHORITY_MAP] Agent non authentifié');
        setState(() => _isLoading = false);
        return;
      }

      _agentId = agentId;
      print('✅ [AUTHORITY_MAP] Agent ID: $agentId');

      // Obtenir position actuelle
      final position = await _getCurrentPosition();

      List<SignalementModel> signalements = [];

      // Essayer de charger depuis le serveur
      try {
        // Récupérer UNIQUEMENT les signalements pris en charge (locked=true)
        signalements =
            await _signalementsRepo.getAgentAssignedSignalements(agentId);
        print(
            '📊 [AUTHORITY_MAP] ${signalements.length} signalement(s) pris en charge');

        // Sauvegarder en cache
        await _cacheService.cacheSignalements(signalements);

        setState(() => _isOfflineMode = false);
      } catch (e) {
        print('⚠️ [AUTHORITY_MAP] Erreur réseau, utilisation du cache: $e');

        // Essayer de charger depuis le cache
        final cached = await _cacheService.getCachedSignalements();
        if (cached != null) {
          signalements = cached.where((s) => s.assignedTo == agentId).toList();
          setState(() => _isOfflineMode = true);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.offline_bolt, color: Colors.white),
                    SizedBox(width: 12),
                    Text('📡 Mode hors ligne - Données en cache'),
                  ],
                ),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
        } else {
          throw Exception('Aucune donnée disponible (réseau et cache)');
        }
      }

      // Trouver la mission active (signalement en_cours)
      SignalementModel? activeMission;
      try {
        activeMission = signalements.firstWhere((s) => s.etat == 'en_cours');
        print('🎯 [AUTHORITY_MAP] Mission active trouvée: ${activeMission.id}');
      } catch (e) {
        print('⚠️ [AUTHORITY_MAP] Aucune mission en cours');
      }

      setState(() {
        _currentPosition = position;
        _signalements = signalements;
        _activeMission = activeMission;
        _isLoading = false;
      });

      // Si mission active, calculer l'itinéraire
      if (activeMission != null && position != null) {
        await _calculateRoute();
        _focusOnMission();

        // Démarrer la navigation vocale si pas déjà active
        if (_voiceNavigation == null) {
          await _startVoiceNavigation();
        }
      } else if (position != null && mounted) {
        // Arrêter la navigation vocale si plus de mission
        _voiceNavigation?.stop();
        _voiceNavigation = null;

        // Centrer sur la position de l'agent
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _mapController.move(
            LatLng(position.latitude, position.longitude),
            14.0,
          );
        });
      }
    } catch (e) {
      print('❌ [AUTHORITY_MAP] Erreur: $e');
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Charge un signalement spécifique et calcule l'itinéraire automatiquement
  Future<void> _loadAndFocusSignalement(String signalementId) async {
    print('🎯 [MAP] Chargement du signalement: $signalementId');

    try {
      // Charger le signalement directement depuis la base de données
      final signalement = await _signalementsRepo.getSignalement(signalementId);
      print('✅ [MAP] Signalement chargé: ${signalement.description}');

      // Attendre que la position actuelle soit disponible
      int attempts = 0;
      while (_currentPosition == null && attempts < 10) {
        print(
            '⏳ [MAP] Attente de la position GPS... (tentative ${attempts + 1}/10)');
        await Future.delayed(const Duration(milliseconds: 500));
        attempts++;
      }

      if (_currentPosition == null) {
        print('❌ [MAP] Position GPS non disponible après 5 secondes');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Impossible d\'obtenir votre position GPS'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Si le signalement a une position valide, calculer l'itinéraire
      if (signalement.latitude != null && signalement.longitude != null) {
        print(
            '📍 [MAP] Position du signalement: ${signalement.latitude}, ${signalement.longitude}');
        print(
            '📍 [MAP] Position actuelle: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');

        // Mettre à jour l'état avec ce signalement comme mission temporaire
        setState(() {
          _activeMission = signalement;
        });

        // Calculer l'itinéraire
        await _calculateRoute();

        // Centrer la carte pour montrer le trajet
        _focusOnMission();

        print('✅ [MAP] Itinéraire calculé et carte centrée');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('📍 Itinéraire calculé vers le signalement'),
              backgroundColor: Color(0xFF10b981),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        print('⚠️ [MAP] Le signalement n\'a pas de coordonnées GPS');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Ce signalement n\'a pas de position GPS'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ [MAP] Erreur lors du chargement du signalement: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _navigateToLocation(SignalementModel signalement) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${signalement.latitude},${signalement.longitude}',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Impossible d\'ouvrir Google Maps'),
          ),
        );
      }
    }
  }

  void _showSignalementDetails(SignalementModel signalement) {
    context.push('/signalement/${signalement.id}');
  }

  void _showSignalementPopup(SignalementModel signalement) {
    // Calculer la distance
    String? distance;
    if (_currentPosition != null &&
        signalement.latitude != null &&
        signalement.longitude != null) {
      final meters = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        signalement.latitude!,
        signalement.longitude!,
      );

      if (meters < 1000) {
        distance = '${meters.round()} m';
      } else {
        distance = '${(meters / 1000).toStringAsFixed(1)} km';
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Barre de drag
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Photo
            if (signalement.photoUrl != null &&
                signalement.photoUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  signalement.photoUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey[300],
                      child:
                          Icon(Icons.image, size: 60, color: Colors.grey[600]),
                    );
                  },
                ),
              ),

            const SizedBox(height: 16),

            // Catégorie + Description (avec indicateur audio)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getCategoryEmoji(signalement.categorie),
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Indicateur audio si présent
                      if (signalement.audioUrl != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1a73e8).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF1a73e8).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.mic,
                                size: 14,
                                color: Color(0xFF1a73e8),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '🎙️ Message vocal',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1a73e8),
                                ),
                              ),
                              if (signalement.audioDuration != null) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1a73e8),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${signalement.audioDuration! ~/ 60}:${(signalement.audioDuration! % 60).toString().padLeft(2, '0')}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      // Description texte
                      Text(
                        signalement.description,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Distance
            if (distance != null)
              Row(
                children: [
                  const Icon(Icons.location_on, size: 18, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    'À $distance',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 20),

            // Boutons d'action
            // Afficher "Prendre en charge" seulement si pas encore pris en charge
            if (!signalement.locked)
              ElevatedButton.icon(
                onPressed: () => _takeCharge(signalement),
                icon: const Icon(Icons.check_circle, size: 24),
                label: const Text(
                  'Prendre en charge',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10b981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              )
            else
              // Afficher un message si déjà pris en charge
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[300]!, width: 2),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle,
                        color: Colors.green[700], size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Mission déjà prise en charge',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToLocation(signalement);
              },
              icon: const Icon(Icons.navigation, size: 24),
              label: const Text(
                'Naviguer',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF3b82f6),
                side: const BorderSide(color: Color(0xFF3b82f6), width: 2),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 12),

            TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _showSignalementDetails(signalement);
              },
              icon: const Icon(Icons.info_outline, size: 24),
              label: const Text(
                'Voir détails',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[700],
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _startLocationTracking() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy
          .bestForNavigation, // Précision maximale pour navigation
      distanceFilter: 1, // Mettre à jour tous les 1 mètre (ultra réactif)
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      // Vérifier la précision GPS (accuracy en mètres)
      // Si la précision est mauvaise (> 5m), on ignore cette position
      if (position.accuracy > 5.0) {
        print(
            '⚠️ [GPS] Précision insuffisante: ${position.accuracy.toStringAsFixed(1)}m (> 5m)');
        return;
      }

      setState(() {
        _currentPosition = position;
      });

      // Si mission active, vérifier la proximité et recalculer l'itinéraire
      if (_activeMission != null &&
          _activeMission!.latitude != null &&
          _activeMission!.longitude != null) {
        final distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          _activeMission!.latitude!,
          _activeMission!.longitude!,
        );

        final wasNear = _isNearDestination;
        setState(() {
          _distanceToDestination = distance;
          _isNearDestination = distance <=
              1.0; // 1 mètre = précision maximale, vraiment sur place

          // Recalculer le temps estimé en fonction de la distance restante
          if (_routePoints.isNotEmpty && _distanceToDestination > 0) {
            // Vitesse moyenne en ville = 30 km/h
            _estimatedTimeMinutes =
                ((_distanceToDestination / 1000) / 30 * 60).round();
            // Minimum 1 minute
            if (_estimatedTimeMinutes < 1) _estimatedTimeMinutes = 1;
          }
        });

        // Annoncer l'arrivée si on vient d'entrer dans la zone
        if (_isNearDestination && !wasNear) {
          if (_voiceNavigation != null) {
            _voiceNavigation!.announceArrival();
          }
          // Zoomer automatiquement sur la position quand on arrive (à 1m)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _mapController.move(
              LatLng(position.latitude, position.longitude),
              19.5, // Zoom ultra précis pour voir exactement où on est (1m)
            );
          });
        }

        // Zoom adaptatif basé sur la distance pour éviter le chevauchement des icônes
        if (!_isNearDestination) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            double zoomLevel;
            if (distance < 2) {
              zoomLevel = 19.0; // Ultra proche (< 2m) : zoom maximum
            } else if (distance < 10) {
              zoomLevel = 18.5; // Très proche (< 10m) : zoom très élevé
            } else if (distance < 50) {
              zoomLevel = 18.0; // Proche (< 50m) : zoom élevé
            } else if (distance < 100) {
              zoomLevel = 17.5; // À portée (< 100m)
            } else if (distance < 200) {
              zoomLevel = 17.0; // À proximité (< 200m)
            } else if (distance < 500) {
              zoomLevel = 16.0; // Moyen (< 500m)
            } else {
              zoomLevel = 15.0; // Loin : zoom normal
            }

            // Centrer entre ma position et le signalement
            final centerLat =
                (position.latitude + _activeMission!.latitude!) / 2;
            final centerLng =
                (position.longitude + _activeMission!.longitude!) / 2;

            _mapController.move(
              LatLng(centerLat, centerLng),
              zoomLevel,
            );
          });
        }

        // Annoncer la distance à intervalles réguliers
        if (_voiceNavigation != null) {
          // Annoncer tous les 100m
          if ((distance - _lastAnnouncedDistance).abs() >= 100) {
            _voiceNavigation!.announceDistance(distance);
            _lastAnnouncedDistance = distance;
          }
        }

        // Recalculer l'itinéraire pour mise à jour en temps réel
        // Recalculer si:
        // 1. L'agent s'est déplacé de plus de 50m (au lieu de 100m)
        // 2. Au moins 15 secondes se sont écoulées (au lieu de 30s)
        // 3. Pas encore arrivé (distance > 50m)
        if (_routePoints.isNotEmpty && distance > 50) {
          final timeSinceLastRecalc = DateTime.now()
              .difference(_lastRouteCalculation ?? DateTime.now())
              .inSeconds;
          // Recalculer toutes les 15 secondes pour route optimale en temps réel
          if (timeSinceLastRecalc > 15) {
            print('🔄 [ROUTE] Recalcul itinéraire (distance: ${distance.round()}m, dernière calc: ${timeSinceLastRecalc}s)');
            _calculateRoute();
            _lastRouteCalculation = DateTime.now();
          }
        }

        // Mettre à jour la position pour la navigation vocale
        _voiceNavigation?.updatePosition(position);
      }
    });
  }

  /// Démarrer la navigation vocale
  Future<void> _startVoiceNavigation() async {
    if (_activeMission == null) return;

    try {
      // Pour l'instant, créer une navigation simple sans instructions détaillées
      // Dans une vraie implémentation, utiliser les instructions de OSRM
      _voiceNavigation = VoiceNavigationService([]);
      await _voiceNavigation!.initialize();
      await _voiceNavigation!.speak(
          'Navigation vers ${_getCategoryLabel(_activeMission!.categorie)} démarrée');

      print('🔊 [VOICE_NAV] Navigation vocale démarrée');
    } catch (e) {
      print('❌ [VOICE_NAV] Erreur: $e');
    }
  }

  /// Calculer l'itinéraire de la position actuelle vers la mission
  Future<void> _calculateRoute() async {
    if (_currentPosition == null ||
        _activeMission == null ||
        _activeMission!.latitude == null ||
        _activeMission!.longitude == null) {
      return;
    }

    // Mettre à jour le timestamp du dernier calcul
    _lastRouteCalculation = DateTime.now();

    try {
      // Valider les coordonnées avant de calculer l'itinéraire
      if (_activeMission!.latitude == null ||
          _activeMission!.longitude == null) {
        print('⚠️ [ROUTE] Coordonnées du signalement invalides');
        return;
      }

      final start =
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
      final end = LatLng(_activeMission!.latitude!, _activeMission!.longitude!);

      print(
          '🎯 [ROUTE] Position actuelle: ${start.latitude}, ${start.longitude}');
      print(
          '🎯 [ROUTE] Position signalement: ${end.latitude}, ${end.longitude}');
      print('🎯 [ROUTE] Adresse signalement: ${_activeMission!.adresse}');

      // Valider que les coordonnées sont dans des limites raisonnables
      if (start.latitude.abs() > 90 ||
          start.longitude.abs() > 180 ||
          end.latitude.abs() > 90 ||
          end.longitude.abs() > 180) {
        print('⚠️ [ROUTE] Coordonnées hors limites: start=$start, end=$end');
        return;
      }

      print('🗺️ [ROUTE] Calcul itinéraire OSRM optimisé de $start à $end');

      // Calculer d'abord la distance à vol d'oiseau pour comparaison
      final straightDistance = Geolocator.distanceBetween(
        start.latitude,
        start.longitude,
        end.latitude,
        end.longitude,
      );
      print('📏 [ROUTE] Distance à vol d\'oiseau: ${(straightDistance / 1000).toStringAsFixed(2)} km');

      // Calculer l'itinéraire avec OSRM
      final routeResult = await _routingService.getRoute(
        start: start,
        end: end,
      );

      if (routeResult != null) {
        // Utiliser l'itinéraire OSRM
        setState(() {
          _routePoints = routeResult.points;
          _distanceToDestination = routeResult.distance;
          _estimatedTimeMinutes = (routeResult.duration / 60).round();
          _isNearDestination =
              routeResult.distance <= 1.0; // 1m = précision maximale
        });

        print(
            '✅ [ROUTE] Itinéraire OSRM (route optimale): ${(routeResult.distance / 1000).toStringAsFixed(2)} km, $_estimatedTimeMinutes min, ${routeResult.points.length} points');
        print('📊 [ROUTE] Différence route vs vol d\'oiseau: +${((routeResult.distance - straightDistance) / 1000).toStringAsFixed(2)} km (${((routeResult.distance / straightDistance - 1) * 100).toStringAsFixed(0)}% plus long)');
      } else {
        // Fallback: ligne droite simple si OSRM échoue
        print('⚠️ [ROUTE] OSRM indisponible, utilisation ligne droite');

        final distance = Geolocator.distanceBetween(
          start.latitude,
          start.longitude,
          end.latitude,
          end.longitude,
        );

        setState(() {
          _routePoints = [start, end];
          _distanceToDestination = distance;
          // Calcul plus réaliste: vitesse moyenne en ville = 30 km/h
          _estimatedTimeMinutes = ((distance / 1000) / 30 * 60).round();
          _isNearDestination = distance <= 1.0; // 1m = précision maximale
        });

        print(
            '✅ [ROUTE] Ligne droite: ${distance.round()}m, $_estimatedTimeMinutes min');
      }
    } catch (e) {
      print('❌ [ROUTE] Erreur calcul itinéraire: $e');

      // Fallback: ligne droite
      final start =
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
      final end = LatLng(_activeMission!.latitude!, _activeMission!.longitude!);

      final distance = Geolocator.distanceBetween(
        start.latitude,
        start.longitude,
        end.latitude,
        end.longitude,
      );

      setState(() {
        _routePoints = [start, end];
        _distanceToDestination = distance;
        // Calcul plus réaliste: vitesse moyenne en ville = 30 km/h
        _estimatedTimeMinutes = ((distance / 1000) / 30 * 60).round();
        _isNearDestination = distance <= 1.0; // 1m = précision maximale
      });
    }
  }

  /// Zoomer sur la mission active
  void _focusOnMission() {
    if (_activeMission == null ||
        _activeMission!.latitude == null ||
        _activeMission!.longitude == null ||
        _currentPosition == null) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Calculer les bounds pour inclure l'agent et la destination
      final bounds = LatLngBounds(
        LatLng(
          _currentPosition!.latitude < _activeMission!.latitude!
              ? _currentPosition!.latitude
              : _activeMission!.latitude!,
          _currentPosition!.longitude < _activeMission!.longitude!
              ? _currentPosition!.longitude
              : _activeMission!.longitude!,
        ),
        LatLng(
          _currentPosition!.latitude > _activeMission!.latitude!
              ? _currentPosition!.latitude
              : _activeMission!.latitude!,
          _currentPosition!.longitude > _activeMission!.longitude!
              ? _currentPosition!.longitude
              : _activeMission!.longitude!,
        ),
      );

      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(100),
        ),
      );
    });
  }

  /// Dialogue pour résoudre le signalement
  void _showResolveDialog(SignalementModel signalement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Marquer comme résolu'),
        content: const Text(
          'Êtes-vous sûr de vouloir marquer ce signalement comme résolu ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _resolveSignalement(signalement);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10b981),
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  /// Prendre en charge le signalement depuis la carte
  Future<void> _takeChargeFromMap() async {
    if (_activeMission == null || _agentId == null) return;

    try {
      print('🚨 [MAP] Prise en charge du signalement ${_activeMission!.id}');

      // Afficher loader
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Text('Prise en charge en cours...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      final result = await _signalementsRepo.takeChargeSignalement(
        _activeMission!.id,
        _agentId!,
      );

      if (result['success'] == true) {
        // Broadcaster le changement d'état
        _stateService.notifyTakeCharge(_activeMission!.id, _agentId!);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('✅ Signalement pris en charge'),
                ],
              ),
              backgroundColor: Color(0xFF3b82f6),
            ),
          );
        }

        // Recharger les données pour mettre à jour l'état
        await _loadData();

        // Démarrer la navigation vocale
        if (_voiceNavigation == null) {
          await _startVoiceNavigation();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ ${result['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ [MAP] Erreur prise en charge: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Résoudre un signalement
  Future<void> _resolveSignalement(SignalementModel signalement) async {
    if (_agentId == null) return;

    try {
      // Afficher loader
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('Résolution en cours...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      final result = await _signalementsRepo.resolveSignalement(
        signalement.id,
        _agentId!,
      );

      if (result['success'] == true) {
        // Broadcaster le changement d'état
        _stateService.notifyResolve(signalement.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('✅ Signalement marqué comme résolu'),
                ],
              ),
              backgroundColor: Color(0xFF10b981),
            ),
          );
        }
        _loadData(); // Recharger
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ ${result['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _takeCharge(SignalementModel signalement) async {
    try {
      // Vérifier si l'agent a déjà une mission en cours
      if (_activeMission != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.warning, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text('⚠️ Vous avez déjà une mission en cours'),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      // Récupérer l'ID de l'autorité connectée
      if (_agentId == null) {
        throw Exception('Utilisateur non authentifié');
      }

      // Afficher un loader avec animation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Text('Prise en charge en cours...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Appeler la fonction RPC Supabase
      final result = await _signalementsRepo.takeChargeSignalement(
        signalement.id,
        _agentId!,
      );

      if (!mounted) return;

      // Fermer le popup
      Navigator.of(context).pop();

      // Afficher le résultat
      if (result['success'] == true) {
        // Broadcaster le changement d'état
        _stateService.notifyTakeCharge(signalement.id, _agentId!);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text('✅ Mission prise en charge'),
                ),
              ],
            ),
            backgroundColor: Color(0xFF10b981),
            duration: Duration(seconds: 3),
          ),
        );

        // Recharger les données pour activer le mode mission
        await _loadData();
      } else {
        // Vérifier si déjà pris en charge par un autre agent
        final message = result['message'] ?? '';
        final isAlreadyTaken = message.toLowerCase().contains('déjà') ||
            message.toLowerCase().contains('already');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  isAlreadyTaken ? Icons.lock : Icons.error,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isAlreadyTaken
                        ? '⚠️ Mission déjà prise en charge'
                        : message,
                  ),
                ),
              ],
            ),
            backgroundColor: isAlreadyTaken ? Colors.orange : Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print('❌ [TAKE_CHARGE] Erreur: $e');

      if (!mounted) return;

      // Fermer le popup en cas d'erreur
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(ErrorHandler.getReadableMessage(e)),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}

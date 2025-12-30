import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/signalement_state_service.dart';
import '../../data/models/signalement_model.dart';
import '../../data/repositories/signalements_repository.dart';

class SignalementDetailScreen extends StatefulWidget {
  final String signalementId;

  const SignalementDetailScreen({
    super.key,
    required this.signalementId,
  });

  @override
  State<SignalementDetailScreen> createState() =>
      _SignalementDetailScreenState();
}

class _SignalementDetailScreenState extends State<SignalementDetailScreen> {
  final SignalementsRepository _repository = SignalementsRepository();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final SignalementStateService _stateService = SignalementStateService();

  SignalementModel? _signalement;
  bool _isLoading = true;
  bool _isLiked = false;
  bool _isPlayingAudio = false;
  Duration _audioDuration = Duration.zero;
  Duration _audioPosition = Duration.zero;
  String? _currentUserId;
  String? _currentUserRole;
  StreamSubscription<SignalementStateEvent>? _stateSubscription;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du signalement'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _signalement == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Signalement introuvable',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => context.pop(),
                        child: const Text('Retour'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Titre centré en haut
                      Center(
                        child: Text(
                          _signalement!.titre ?? 'Signalement',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Photo avec statut et catégorie avec badges
                      if (_signalement!.photoUrl != null)
                        Container(
                          width: double.infinity,
                          height: 300,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              // Image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  _signalement!.photoUrl!,
                                  width: double.infinity,
                                  height: 300,
                                  fit: BoxFit.cover,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      color: Colors.grey[200],
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress
                                                      .expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    print(
                                        '❌ [IMAGE] Erreur chargement photo: $error');
                                    print(
                                        '❌ [IMAGE] URL échouée: ${_signalement!.photoUrl}');
                                    return Container(
                                      height: 300,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.broken_image,
                                              size: 64,
                                              color: Colors.grey,
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              'Impossible de charger la photo',
                                              style:
                                                  TextStyle(color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),

                              // Badge catégorie (en haut à gauche)
                              Positioned(
                                top: 12,
                                left: 12,
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
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),

                              // Badge statut (en haut à droite)
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getEtatColor(),
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
                                    _getEtatLabel(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),

                      // Date uniquement (publication anonyme)
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _signalement!.getRelativeTime(),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Description OU Message vocal
                      const Text(
                        '📝 Description',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Si audio présent, afficher le lecteur audio compact, sinon afficher le texte
                      if (_signalement!.audioUrl != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            children: [
                              // Bouton Play/Pause
                              InkWell(
                                onTap: _playPauseAudio,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF1a73e8),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _isPlayingAudio
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Barre de progression et temps
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Barre de progression
                                    SliderTheme(
                                      data: const SliderThemeData(
                                        trackHeight: 2,
                                        thumbShape: RoundSliderThumbShape(
                                            enabledThumbRadius: 6),
                                        overlayShape: RoundSliderOverlayShape(
                                            overlayRadius: 12),
                                      ),
                                      child: Slider(
                                        value: _displayDuration.inMilliseconds >
                                                0
                                            ? _audioPosition.inMilliseconds /
                                                _displayDuration.inMilliseconds
                                            : 0,
                                        onChanged: null,
                                        activeColor: const Color(0xFF1a73e8),
                                        inactiveColor: Colors.grey[300],
                                      ),
                                    ),
                                    // Temps
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _formatDuration(_audioPosition),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF1a73e8),
                                            ),
                                          ),
                                          Text(
                                            _formatDuration(_displayDuration),
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        // Afficher le texte de description
                        Text(
                          _signalement!.description,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[800],
                            height: 1.5,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),

                      // Localisation
                      if (_signalement!.adresse != null) ...[
                        const Text(
                          '📍 Localisation',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 20,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _signalement!.adresse!,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Félicitations
                      const Text(
                        '👏 Félicitations',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_signalement!.felicitations} personne(s)',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFFf72585),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Bouton Féliciter
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _toggleFelicitation,
                          icon: const Icon(
                            Icons.verified,
                            size: 20,
                          ),
                          label: Text(
                            'Félicitations (${_signalement!.felicitations})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isLiked
                                ? const Color(0xFF1a73e8)
                                : Colors.grey[200],
                            foregroundColor:
                                _isLiked ? Colors.white : Colors.grey[700],
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Bouton Prendre en charge (pour les autorités: police, hygiene, voirie, etc.)
                      if (_isAuthorityRole(_currentUserRole) &&
                          _signalement!.etat != 'resolu')
                        Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: (_signalement!.locked &&
                                        _signalement!.assignedTo ==
                                            _currentUserId)
                                    ? null // Désactivé si déjà pris en charge par moi
                                    : (_signalement!.locked &&
                                            _signalement!.assignedTo !=
                                                _currentUserId)
                                        ? null // Désactivé si pris en charge par quelqu'un d'autre
                                        : _takeChargeSignalement, // Actif si pas encore pris en charge
                                icon: Icon(
                                  _signalement!.locked
                                      ? Icons.lock
                                      : Icons.assignment_ind,
                                  size: 22,
                                ),
                                label: Text(
                                  _signalement!.locked
                                      ? (_signalement!.assignedTo ==
                                              _currentUserId
                                          ? 'Déjà pris en charge par vous'
                                          : 'Déjà pris en charge')
                                      : 'Prendre en charge',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _signalement!.locked
                                      ? Colors.grey
                                      : const Color(0xFF3b82f6),
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),

                      // Bouton Retour
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => context.pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Retour',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _stateSubscription?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadSignalement();
    _initAudioPlayer();
    _setupStateListener();
  }

  /// Écouter les changements d'état des signalements depuis d'autres écrans
  void _setupStateListener() {
    _stateSubscription = _stateService.stateChanges.listen((event) {
      print(
          '📢 [DETAIL] Événement reçu: ${event.type} pour signalement ${event.signalementId}');
      // Si c'est notre signalement, recharger
      if (event.signalementId == widget.signalementId) {
        _loadSignalement();
      }
    });
    print("✅ [DETAIL] Listener d'état configuré");
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  // Getter pour obtenir la durée à afficher (depuis le player ou depuis la BDD)
  Duration get _displayDuration {
    if (_audioDuration.inSeconds > 0) {
      return _audioDuration;
    }
    // Si le player n'a pas encore de durée, utiliser celle de la BDD
    if (_signalement?.audioDuration != null) {
      return Duration(seconds: _signalement!.audioDuration!);
    }
    return Duration.zero;
  }

  Color _getCategoryColor() {
    switch (_signalement!.categorie) {
      case 'dechet':
        return const Color(0xFF27ae60);
      case 'eclairage':
        return const Color(0xFFf39c12);
      case 'route':
        return const Color(0xFFe74c3c);
      case 'bruit':
        return const Color(0xFF9b59b6);
      case 'eau':
        return const Color(0xFF3498db);
      case 'pollution':
        return const Color(0xFF95a5a6);
      default:
        return const Color(0xFF34495e);
    }
  }

  String _getCategoryLabel() {
    switch (_signalement!.categorie) {
      case 'dechet':
        return '🗑️ Déchets';
      case 'eclairage':
        return '💡 Éclairage';
      case 'route':
        return '🚧 Route';
      case 'bruit':
        return '🔊 Bruit';
      case 'eau':
        return '💧 Eau';
      case 'pollution':
        return '🏭 Pollution';
      default:
        return '📢 Autre';
    }
  }

  Color _getEtatColor() {
    switch (_signalement!.etat) {
      case 'en_attente':
        return const Color(0xFFf39c12);
      case 'en_cours':
        return const Color(0xFF3498db);
      case 'resolu':
        return const Color(0xFF27ae60);
      default:
        return Colors.grey;
    }
  }

  String _getEtatLabel() {
    switch (_signalement!.etat) {
      case 'en_attente':
        return 'En attente';
      case 'en_cours':
        return 'En cours';
      case 'resolu':
        return 'Résolu';
      default:
        return 'Inconnu';
    }
  }

  void _initAudioPlayer() {
    _audioPlayer.onDurationChanged.listen((duration) {
      setState(() => _audioDuration = duration);
    });

    _audioPlayer.onPositionChanged.listen((position) {
      setState(() => _audioPosition = position);
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      setState(() {
        _isPlayingAudio = false;
        _audioPosition = Duration.zero;
      });
    });
  }

  Future<void> _loadSignalement() async {
    try {
      // Charger l'utilisateur actuel
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user != null) {
        final userProfile = await supabase
            .from('users')
            .select('role')
            .eq('id', user.id)
            .single();
        _currentUserId = user.id;
        _currentUserRole = userProfile['role'] as String?;
      }

      final signalement =
          await _repository.getSignalement(widget.signalementId);
      final felicitations = await _repository.getUserFelicitations();

      setState(() {
        _signalement = signalement;
        _isLiked = felicitations.contains(signalement.id);
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur chargement signalement: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de charger le signalement'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _playPauseAudio() async {
    if (_signalement?.audioUrl == null) return;

    try {
      if (_isPlayingAudio) {
        await _audioPlayer.pause();
        setState(() => _isPlayingAudio = false);
      } else {
        String url = _signalement!.audioUrl!;

        // Si l'URL ne commence pas par http, c'est un chemin relatif dans le storage Supabase
        if (!url.startsWith('http')) {
          // Transformer le chemin relatif en URL publique
          final supabase = Supabase.instance.client;
          url = supabase.storage.from('signalement-audios').getPublicUrl(url);
          print('🎵 [AUDIO] URL publique générée: $url');
        }

        // Lire l'audio depuis l'URL
        await _audioPlayer.play(UrlSource(url));
        setState(() => _isPlayingAudio = true);
      }
    } catch (e) {
      print('❌ [AUDIO] Erreur lecture audio: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossible de lire l\'audio : $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _takeChargeSignalement() async {
    if (_signalement == null || _currentUserId == null) return;

    try {
      print('🚨 [DETAIL] Prise en charge du signalement ${_signalement!.id}');

      final result = await _repository.takeChargeSignalement(
        _signalement!.id,
        _currentUserId!,
      );

      if (result['success'] == true) {
        // Broadcaster le changement d'état
        _stateService.notifyTakeCharge(
          _signalement!.id,
          _currentUserId!,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Mission prise en charge'),
            backgroundColor: Color(0xFF3b82f6),
            duration: Duration(seconds: 2),
          ),
        );

        // Rediriger vers la carte avec le signalement
        if (mounted) {
          context.go('/authority-home', extra: {
            'tabIndex': 1,
            'signalementId': _signalement!.id,
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${result['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ [DETAIL] Erreur prise en charge: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _toggleFelicitation() async {
    if (_signalement == null) return;

    try {
      if (_isLiked) {
        await _repository.removeFelicitation(_signalement!.id);
        setState(() {
          _isLiked = false;
          _signalement = SignalementModel(
            id: _signalement!.id,
            userId: _signalement!.userId,
            titre: _signalement!.titre,
            description: _signalement!.description,
            categorie: _signalement!.categorie,
            photoUrl: _signalement!.photoUrl,
            audioUrl: _signalement!.audioUrl,
            audioDuration: _signalement!.audioDuration,
            latitude: _signalement!.latitude,
            longitude: _signalement!.longitude,
            adresse: _signalement!.adresse,
            etat: _signalement!.etat,
            felicitations: _signalement!.felicitations - 1,
            createdAt: _signalement!.createdAt,
            updatedAt: _signalement!.updatedAt,
            author: _signalement!.author,
          );
        });
      } else {
        await _repository.addFelicitation(_signalement!.id);
        setState(() {
          _isLiked = true;
          _signalement = SignalementModel(
            id: _signalement!.id,
            userId: _signalement!.userId,
            titre: _signalement!.titre,
            description: _signalement!.description,
            categorie: _signalement!.categorie,
            photoUrl: _signalement!.photoUrl,
            audioUrl: _signalement!.audioUrl,
            audioDuration: _signalement!.audioDuration,
            latitude: _signalement!.latitude,
            longitude: _signalement!.longitude,
            adresse: _signalement!.adresse,
            etat: _signalement!.etat,
            felicitations: _signalement!.felicitations + 1,
            createdAt: _signalement!.createdAt,
            updatedAt: _signalement!.updatedAt,
            author: _signalement!.author,
          );
        });
      }
    } catch (e) {
      print('Erreur félicitation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de l\'action'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Vérifie si le rôle est un rôle d'autorité
  bool _isAuthorityRole(String? role) {
    if (role == null) return false;
    const authorityRoles = [
      'police',
      'hygiene',
      'voirie',
      'environnement',
      'securite',
      'mairie',
      'agent'
    ];
    return authorityRoles.contains(role);
  }
}

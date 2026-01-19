import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/geocoding_service.dart';
import '../../../../core/services/image_compression_service.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../feed/data/repositories/signalements_repository.dart';

class SignalementFormScreen extends StatefulWidget {
  final String category;

  const SignalementFormScreen({
    super.key,
    required this.category,
  });

  @override
  State<SignalementFormScreen> createState() => _SignalementFormScreenState();
}

class _SignalementFormScreenState extends State<SignalementFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titreController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _localisationController = TextEditingController();
  final AuthRepository _authRepo = AuthRepository();

  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

  String? _audioPath;
  Duration? _audioDuration;
  bool _isRecording = false;
  bool _hasRecording = false;
  bool _isPlayingAudio = false;
  Duration _recordDuration = Duration.zero;
  Duration _playbackPosition = Duration.zero;
  Timer? _recordTimer;

  File? _imageFile;
  bool _isSubmitting = false;
  bool _hasActiveDeletionRequest = false;
  bool _isCheckingDeletion = true;

  // Coordonnées GPS
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    _checkDeletionRequest();
  }

  Future<void> _checkDeletionRequest() async {
    try {
      // Utiliser SharedPreferences comme dans profile_screen
      final userId = await _authRepo.getStoredUserId();
      print('🔴 DEBUG SignalementForm _checkDeletionRequest: userId = $userId');
      if (userId != null) {
        final response = await Supabase.instance.client
            .from('account_deletion_requests')
            .select('*')
            .eq('user_id', userId)
            .eq('status', 'pending')
            .maybeSingle();

        print('🔴 DEBUG SignalementForm: response = $response');
        setState(() {
          _hasActiveDeletionRequest = response != null;
          _isCheckingDeletion = false;
        });

        // Si une demande de suppression est active, afficher un message et retourner
        if (_hasActiveDeletionRequest && mounted) {
          Future.delayed(Duration.zero, () {
            _showDeletionBlockedDialog();
          });
        }
      } else {
        setState(() => _isCheckingDeletion = false);
      }
    } catch (e) {
      print('❌ Erreur vérification suppression: $e');
      setState(() => _isCheckingDeletion = false);
    }
  }

  void _showDeletionBlockedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.block, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Action bloquée',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
        content: const Text(
          'Vous ne pouvez pas créer de signalements car votre compte est en cours de suppression.\n\n'
          'Veuillez annuler la demande de suppression dans votre profil pour continuer à utiliser l\'application.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Fermer le dialog
              context.pop(); // Retourner à l'écran précédent
            },
            child: const Text('Retour'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Fermer le dialog
              context.go('/profile'); // Aller au profil
            },
            style: TextButton.styleFrom(foregroundColor: Colors.blue),
            child: const Text('Aller au profil'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF1a73e8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a73e8),
        elevation: 0,
        title: const Text(
          'Nouveau signalement',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Catégorie badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Catégorie: ${_getCategoryLabel()}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),

                // Photo
                GestureDetector(
                  onTap: () {
                    // Prendre directement une photo avec la caméra
                    _pickImage(ImageSource.camera);
                  },
                  child: Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                      image: _imageFile != null
                          ? DecorationImage(
                              image: FileImage(_imageFile!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _imageFile == null
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo,
                                  size: 64, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('Ajouter une photo'),
                            ],
                          )
                        : Stack(
                            children: [
                              Positioned(
                                top: 8,
                                right: 8,
                                child: IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () =>
                                      setState(() => _imageFile = null),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Titre (uniquement pour catégorie "autre")
                if (widget.category == 'autre') ...[
                  TextFormField(
                    controller: _titreController,
                    decoration: const InputDecoration(
                      labelText: 'Titre',
                      hintText: 'Ex: Problème spécifique',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Le titre est requis pour "Autre"';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Description : Texte OU Audio (interface inline)
                if (_isRecording)
                  // Interface d'enregistrement en cours
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200, width: 2),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.mic,
                              color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Enregistrement en cours...',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red,
                                ),
                              ),
                              Text(
                                _formatDuration(_recordDuration),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.stop_circle,
                              color: Colors.red, size: 32),
                          onPressed: _stopRecording,
                        ),
                      ],
                    ),
                  )
                else if (_hasRecording)
                  // Lecteur audio compact après enregistrement
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: Colors.green.shade200, width: 2),
                    ),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: _playPauseAudio,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFF1a73e8),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isPlayingAudio ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SliderTheme(
                                data: const SliderThemeData(
                                  trackHeight: 2,
                                  thumbShape: RoundSliderThumbShape(
                                      enabledThumbRadius: 6),
                                  overlayShape: RoundSliderOverlayShape(
                                      overlayRadius: 12),
                                ),
                                child: Slider(
                                  value: _audioDuration!.inSeconds > 0
                                      ? _playbackPosition.inSeconds /
                                          _audioDuration!.inSeconds
                                      : 0,
                                  onChanged: null,
                                  activeColor: const Color(0xFF1a73e8),
                                  inactiveColor: Colors.grey[300],
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDuration(_playbackPosition),
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600]),
                                    ),
                                    Text(
                                      _formatDuration(_audioDuration!),
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete,
                              color: Colors.red, size: 20),
                          onPressed: _deleteRecording,
                          tooltip: 'Supprimer et réécrire',
                        ),
                      ],
                    ),
                  )
                else
                  // Champ de texte normal avec bouton micro
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    style: const TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      labelText: 'Description',
                      hintText: 'Décrivez le problème ou utilisez le micro...',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.mic, color: theme.primaryColor),
                        onPressed: _startRecording,
                        tooltip: 'Enregistrer un message vocal',
                      ),
                    ),
                    validator: (value) {
                      if (!_hasRecording &&
                          (value == null || value.trim().isEmpty)) {
                        return 'La description est requise';
                      }
                      return null;
                    },
                  ),
                const SizedBox(height: 16),

                // Localisation
                TextFormField(
                  controller: _localisationController,
                  enabled: false,
                  decoration: const InputDecoration(
                    labelText: 'Localisation',
                    hintText: 'Quartier, rue...',
                    prefixIcon: Icon(Icons.location_on),
                    border: OutlineInputBorder(),
                    disabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'La localisation est requise';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Bouton publier
                ElevatedButton(
                  onPressed: (_isSubmitting || _hasActiveDeletionRequest) ? null : _submitSignalement,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _hasActiveDeletionRequest ? Colors.grey : const Color(0xFF1a73e8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _hasActiveDeletionRequest 
                              ? 'Compte en cours de suppression' 
                              : 'Publier le signalement',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titreController.dispose();
    _descriptionController.dispose();
    _localisationController.dispose();
    _recordTimer?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _deleteRecording() {
    setState(() {
      _hasRecording = false;
      _audioPath = null;
      _audioDuration = null;
      _playbackPosition = Duration.zero;
      _isPlayingAudio = false;
    });
    _audioPlayer.stop();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  String _getCategoryLabel() {
    switch (widget.category) {
      case 'dechets':
        return '🗑️ Déchets';
      case 'route':
        return '🚧 Route Dégradée';
      case 'pollution':
        return '🏭 Pollution';
      case 'autre':
        return '📢 Autre';
      default:
        return '📢 Signalement';
    }
  }

  // Retourne le titre simple sans emoji pour la BDD
  String _getCategoryTitle() {
    switch (widget.category) {
      case 'dechets':
        return 'Déchets';
      case 'route':
        return 'Route Dégradée';
      case 'pollution':
        return 'Pollution';
      case 'autre':
        return _titreController.text.trim();
      default:
        return 'Signalement';
    }
  }

  Future<void> _getLocation() async {
    try {
      print('📍 [GEOLOC] Vérification des permissions...');

      // Vérifier les permissions
      LocationPermission permission = await Geolocator.checkPermission();
      print('📍 [GEOLOC] Permission actuelle: $permission');

      if (permission == LocationPermission.denied) {
        print('📍 [GEOLOC] Demande de permission...');
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('❌ [GEOLOC] Permission refusée');
          _showError('Permission de localisation refusée');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('❌ [GEOLOC] Permission refusée définitivement');
        _showError('Permission de localisation définitivement refusée');
        return;
      }

      print('✅ [GEOLOC] Permission accordée, récupération de la position...');

      // Obtenir la position actuelle avec haute précision
      // Première tentative pour "réchauffer" le GPS
      Position position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
          timeLimit: const Duration(seconds: 5),
        );
        
        // Si la précision est mauvaise (> 20m), on réessaie
        if (position.accuracy > 20) {
          print('⚠️ [GEOLOC] Précision insuffisante (${position.accuracy}m), nouvelle tentative...');
          await Future.delayed(const Duration(seconds: 2));
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.best,
            timeLimit: const Duration(seconds: 10),
          );
        }
      } catch (e) {
        // Si timeout, prendre la dernière position connue
        print('⚠️ [GEOLOC] Timeout, utilisation de la dernière position connue');
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
        );
      }

      print(
          '✅ [GEOLOC] Position obtenue: ${position.latitude}, ${position.longitude}');
      print('✅ [GEOLOC] Précision: ${position.accuracy} mètres');

      // Stocker les coordonnées GPS avec toute leur précision
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
      print('✅ [GEOLOC] Coordonnées stockées: $_latitude, $_longitude');

      // Convertir les coordonnées en adresse avec le service amélioré
      try {
        print('📍 [GEOLOC] Conversion en adresse avec service amélioré...');
        
        final addressResult = await GeocodingService.getAddress(
          latitude: position.latitude,
          longitude: position.longitude,
        );
        
        print('✅ [GEOLOC] Source: ${addressResult.source}');
        print('🏘️ [GEOLOC] Quartier: ${addressResult.quartier ?? "NON TROUVÉ"}');
        print('🏙️ [GEOLOC] Ville: ${addressResult.ville ?? "NON TROUVÉE"}');
        
        final formattedAddress = addressResult.getFormattedAddress();
        print('✅ [GEOLOC] Adresse formatée: $formattedAddress');
        
        setState(() {
          _localisationController.text = formattedAddress;
        });
      } catch (e) {
        print('⚠️ [GEOLOC] Erreur conversion adresse: $e');
        // Si la conversion échoue, utiliser les coordonnées
        setState(() {
          _localisationController.text =
              '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
        });
      }
    } catch (e) {
      print('❌ [GEOLOC] Erreur: $e');
      _showError(ErrorHandler.getReadableMessage(e));
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: source,
        // On prend l'image en haute qualité, la compression se fera après
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 100,
      );

      if (image != null) {
        // Afficher un indicateur de chargement pendant la compression
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
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Optimisation de l\'image...'),
                ],
              ),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.blue,
            ),
          );
        }

        final originalFile = File(image.path);
        final originalSize = await ImageCompressionService.getFormattedFileSize(originalFile);
        print('📸 [IMAGE] Taille originale: $originalSize');

        // Compresser l'image style WhatsApp (qualité medium = 70%)
        final compressedFile = await ImageCompressionService.compressWithQuality(
          originalFile,
          CompressionQuality.medium,
        );

        if (compressedFile != null) {
          final compressedSize = await ImageCompressionService.getFormattedFileSize(compressedFile);
          print('✅ [IMAGE] Taille après compression: $compressedSize');
          
          setState(() {
            _imageFile = compressedFile;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ Image optimisée: $originalSize → $compressedSize'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          // Si la compression échoue, utiliser l'image originale
          print('⚠️ [IMAGE] Compression échouée, utilisation de l\'originale');
          setState(() {
            _imageFile = originalFile;
          });
        }

        // Récupérer automatiquement la géolocalisation
        await _getLocation();
      }
    } catch (e) {
      _showError('Impossible de sélectionner l\'image. Réessayez.');
    }
  }

  Future<void> _playPauseAudio() async {
    if (_audioPath == null) return;

    try {
      if (_isPlayingAudio) {
        await _audioPlayer.pause();
        setState(() => _isPlayingAudio = false);
      } else {
        await _audioPlayer.play(DeviceFileSource(_audioPath!));
        setState(() => _isPlayingAudio = true);

        _audioPlayer.onPositionChanged.listen((position) {
          if (mounted) {
            setState(() => _playbackPosition = position);
          }
        });

        _audioPlayer.onPlayerComplete.listen((_) {
          if (mounted) {
            setState(() {
              _isPlayingAudio = false;
              _playbackPosition = Duration.zero;
            });
          }
        });
      }
    } catch (e) {
      print('Erreur lecture audio: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _startRecording() async {
    try {
      // Demander la permission du microphone
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        _showError('Permission microphone refusée');
        return;
      }

      // Créer le fichier audio
      final directory = await getTemporaryDirectory();
      final audioPath =
          '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

      // Démarrer l'enregistrement
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: audioPath,
      );

      setState(() {
        _isRecording = true;
        _audioPath = audioPath;
        _recordDuration = Duration.zero;
      });

      // Timer pour afficher la durée
      _recordTimer?.cancel();
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _recordDuration = Duration(seconds: timer.tick);
          });
        }
      });
    } catch (e) {
      print('Erreur démarrage enregistrement: $e');
      _showError('Impossible de démarrer l\'enregistrement. Vérifiez les permissions.');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      _recordTimer?.cancel();

      if (path != null) {
        setState(() {
          _isRecording = false;
          _hasRecording = true;
          _audioPath = path;
          _audioDuration = _recordDuration;
        });
      }
    } catch (e) {
      print('Erreur arrêt enregistrement: $e');
      _showError('Impossible d\'arrêter l\'enregistrement.');
    }
  }

  Future<void> _submitSignalement() async {
    if (!_formKey.currentState!.validate()) {
      print('❌ [SIGNALEMENT] Validation du formulaire échouée');
      return;
    }

    // RÈGLE 1: La photo est OBLIGATOIRE
    if (_imageFile == null) {
      print('❌ [SIGNALEMENT] Photo obligatoire manquante');
      _showError('La photo est obligatoire pour créer un signalement');
      return;
    }

    // RÈGLE 2: Au moins une description (texte OU audio) est OBLIGATOIRE
    final hasTextDescription =
        _descriptionController.text.trim().isNotEmpty && !_hasRecording;
    final hasAudioDescription = _hasRecording && _audioPath != null;

    if (!hasTextDescription && !hasAudioDescription) {
      print('❌ [SIGNALEMENT] Description obligatoire manquante');
      _showError(
          'Vous devez fournir une description texte OU un message vocal');
      return;
    }

    // RÈGLE 3: Le titre est OBLIGATOIRE si catégorie = "autre"
    if (widget.category == 'autre' && _titreController.text.trim().isEmpty) {
      print('❌ [SIGNALEMENT] Titre obligatoire pour catégorie "autre"');
      _showError('Le titre est obligatoire pour la catégorie "Autre"');
      return;
    }

    // RÈGLE 4: L'adresse (géolocalisation) est OBLIGATOIRE
    if (_localisationController.text.trim().isEmpty) {
      print('❌ [SIGNALEMENT] Géolocalisation manquante');
      _showError(
          'La géolocalisation est obligatoire. Veuillez prendre une photo pour obtenir votre position.');
      return;
    }

    print(
        '✅ [SIGNALEMENT] Toutes les validations passées, début de la publication...');
    print('   - Photo: ✅');
    print('   - Description texte: $hasTextDescription');
    print('   - Description audio: $hasAudioDescription');
    print('   - Géolocalisation: ✅');
    print('   - Latitude: $_latitude');
    print('   - Longitude: $_longitude');
    print('   - Titre: ${_getCategoryTitle()}');
    setState(() => _isSubmitting = true);

    try {
      final repo = SignalementsRepository();

      print('📝 [SIGNALEMENT] Données:');
      print('   - Catégorie: ${widget.category}');
      print('   - Titre: ${_getCategoryTitle()}');
      print(
          '   - Description: ${_hasRecording ? 'Audio' : _descriptionController.text.trim()}');
      print('   - Localisation: ${_localisationController.text.trim()}');
      print('   - Latitude: $_latitude');
      print('   - Longitude: $_longitude');
      print('   - Audio: $_audioPath');
      print('   - Image: ${_imageFile?.path}');

      // Upload de la photo vers Supabase Storage
      String? photoUrl;
      if (_imageFile != null) {
        print('📸 [SIGNALEMENT] Upload de l\'image...');
        photoUrl = await _uploadImageToSupabase(_imageFile!);
        if (photoUrl == null) {
          throw Exception('Erreur lors de l\'upload de la photo');
        }
        print('✅ [SIGNALEMENT] Photo uploadée: $photoUrl');
      }

      // Upload de l'audio vers Supabase Storage
      String? audioStoragePath;
      if (_hasRecording && _audioPath != null) {
        print('🎵 [SIGNALEMENT] Upload de l\'audio...');
        audioStoragePath = await _uploadAudioToSupabase(_audioPath!);
        if (audioStoragePath == null) {
          throw Exception('Erreur lors de l\'upload de l\'audio');
        }
        print('✅ [SIGNALEMENT] Audio uploadé: $audioStoragePath');
      }

      print('⏳ [SIGNALEMENT] Envoi à Supabase...');
      await repo.createSignalement(
        titre: _getCategoryTitle(), // Utiliser le titre basé sur la catégorie
        description: _hasRecording
            ? '' // Description vide pour l'audio - ne sera pas affichée
            : _descriptionController.text.trim(),
        categorie: widget.category,
        photoUrl: photoUrl,
        latitude: _latitude,
        longitude: _longitude,
        adresse: _localisationController.text.trim(),
        audioUrl: audioStoragePath,
        audioDuration: _audioDuration,
      );

      print('✅ [SIGNALEMENT] Publié avec succès!');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signalement publié avec succès!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Rediriger vers l'accueil en remplaçant toute la pile de navigation
        print('🔄 [SIGNALEMENT] Redirection vers /home');
        context.go('/home', extra: {'resetTab': true});
      }
    } catch (e) {
      print('❌ [SIGNALEMENT] Erreur: $e');
      if (mounted) {
        _showError(ErrorHandler.getReadableMessage(e));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<String?> _uploadImageToSupabase(File imageFile) async {
    try {
      print('📸 [UPLOAD] Début upload image...');
      final supabase = Supabase.instance.client;

      // Générer un nom unique pour l'image
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(imageFile.path);
      final fileName = 'signalement_$timestamp$extension';
      final filePath = 'signalements/$fileName';

      print('📸 [UPLOAD] Nom du fichier: $filePath');

      // Uploader vers Supabase Storage
      await supabase.storage
          .from('signalements-photos')
          .upload(filePath, imageFile);

      // Récupérer l'URL publique
      final publicUrl =
          supabase.storage.from('signalements-photos').getPublicUrl(filePath);

      print('✅ [UPLOAD] Image uploadée: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('❌ [UPLOAD] Erreur upload: $e');
      return null;
    }
  }

  Future<String?> _uploadAudioToSupabase(String audioPath) async {
    try {
      print('🎵 [UPLOAD] Début upload audio...');
      final supabase = Supabase.instance.client;
      final audioFile = File(audioPath);

      // Vérifier que le fichier existe
      if (!await audioFile.exists()) {
        print('❌ [UPLOAD] Fichier audio introuvable: $audioPath');
        return null;
      }

      // Générer un nom unique pour l'audio
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(audioPath);
      final fileName = 'audio_$timestamp$extension';
      final filePath = 'audios/$fileName';

      print('🎵 [UPLOAD] Nom du fichier: $filePath');

      // Uploader vers Supabase Storage (bucket: signalement-audios)
      await supabase.storage
          .from('signalement-audios')
          .upload(filePath, audioFile);

      print('✅ [UPLOAD] Audio uploadé: $filePath');
      // Retourner le chemin relatif, pas l'URL complète
      return filePath;
    } catch (e) {
      print('❌ [UPLOAD] Erreur upload audio: $e');
      return null;
    }
  }
}

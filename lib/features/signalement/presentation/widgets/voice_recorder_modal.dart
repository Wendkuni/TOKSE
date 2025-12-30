import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

class VoiceRecorderModal extends StatefulWidget {
  final Function(String audioPath, Duration duration) onRecordComplete;
  final VoidCallback onRecordingStart;
  final VoidCallback onCancel;

  const VoiceRecorderModal({
    super.key,
    required this.onRecordComplete,
    required this.onRecordingStart,
    required this.onCancel,
  });

  @override
  State<VoiceRecorderModal> createState() => _VoiceRecorderModalState();
}

class _VoiceRecorderModalState extends State<VoiceRecorderModal>
    with SingleTickerProviderStateMixin {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _hasRecording = false;
  String? _audioPath;
  Duration _recordDuration = Duration.zero;
  Duration _playbackPosition = Duration.zero;
  Timer? _timer;
  late AnimationController _pulseController;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 12,
        left: 20,
        right: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Indicateur visuel de drag
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Barre de titre compacte
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: _cancelRecording,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Text(
                _isRecording
                    ? 'Enregistrement...'
                    : _hasRecording
                        ? 'Message vocal'
                        : 'Message vocal',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 20),
            ],
          ),
          const SizedBox(height: 16),

          // Zone d'enregistrement compacte
          if (_isRecording)
            Column(
              children: [
                // Animation de pulsation compacte
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 70 + (_pulseController.value * 10),
                      height: 70 + (_pulseController.value * 10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red.withOpacity(0.1),
                      ),
                      child: Center(
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red,
                          ),
                          child: const Icon(
                            Icons.mic,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  _formatDuration(_recordDuration),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Parlez maintenant...',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
              ],
            )
          else if (_hasRecording)
            // Lecteur audio compact style WhatsApp
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      // Bouton Play/Pause compact
                      InkWell(
                        onTap: _playRecording,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFF1a73e8),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow,
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
                                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                                overlayShape: RoundSliderOverlayShape(overlayRadius: 12),
                              ),
                              child: Slider(
                                value: _recordDuration.inSeconds > 0
                                    ? _playbackPosition.inSeconds / _recordDuration.inSeconds
                                    : 0,
                                onChanged: null,
                                activeColor: const Color(0xFF1a73e8),
                                inactiveColor: Colors.grey[300],
                              ),
                            ),
                            // Temps
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDuration(_playbackPosition),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    _formatDuration(_recordDuration),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
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
                ],
              ),
            )
          else
            // État initial compact
            Column(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1a73e8).withOpacity(0.1),
                  ),
                  child: const Icon(
                    Icons.mic,
                    size: 36,
                    color: Color(0xFF1a73e8),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Appuyez pour enregistrer',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),

          const SizedBox(height: 20),

          // Boutons d'action compacts
          if (_isRecording)
            ElevatedButton.icon(
              onPressed: _stopRecording,
              icon: const Icon(Icons.stop, size: 18),
              label: const Text('Arrêter'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
                minimumSize: const Size(double.infinity, 48),
              ),
            )
          else if (_hasRecording)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _hasRecording = false;
                        _audioPath = null;
                        _recordDuration = Duration.zero;
                      });
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Réenregistrer'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _sendRecording,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Valider'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1a73e8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            )
          else
            ElevatedButton.icon(
              onPressed: _startRecording,
              icon: const Icon(Icons.mic, size: 18),
              label: const Text('Commencer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1a73e8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
                minimumSize: const Size(double.infinity, 48),
              ),
            ),

          const SizedBox(height: 12),

          // Aide compacte
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[100]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Idéal pour ceux qui ne savent pas écrire',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  void _cancelRecording() {
    widget.onCancel();
    Navigator.pop(context);
  }

  Future<bool> _checkPermission() async {
    final status = await Permission.microphone.request();
    return status == PermissionStatus.granted;
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Future<void> _playRecording() async {
    if (_audioPath == null) return;

    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
        setState(() => _isPlaying = false);
      } else {
        await _audioPlayer.play(DeviceFileSource(_audioPath!));
        setState(() => _isPlaying = true);

        _audioPlayer.onPositionChanged.listen((position) {
          if (mounted) {
            setState(() => _playbackPosition = position);
          }
        });

        _audioPlayer.onPlayerComplete.listen((_) {
          if (mounted) {
            setState(() {
              _isPlaying = false;
              _playbackPosition = Duration.zero;
            });
          }
        });
      }
    } catch (e) {
      print('Erreur lecture: $e');
    }
  }

  void _sendRecording() {
    if (_audioPath != null) {
      widget.onRecordComplete(_audioPath!, _recordDuration);
      Navigator.pop(context);
    }
  }

  Future<void> _startRecording() async {
    try {
      final hasPermission = await _checkPermission();
      if (!hasPermission) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permission microphone refusée'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: path,
      );

      setState(() {
        _isRecording = true;
        _hasRecording = false;
        _audioPath = path;
      });

      widget.onRecordingStart();
      _startTimer();
    } catch (e) {
      print('Erreur enregistrement: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _recordDuration = Duration.zero;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _recordDuration = Duration(seconds: timer.tick);
        });
      }
    });
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      _stopTimer();

      if (path != null) {
        setState(() {
          _isRecording = false;
          _hasRecording = true;
          _audioPath = path;
        });
      }
    } catch (e) {
      print('Erreur arrêt enregistrement: $e');
    }
  }

  void _stopTimer() {
    _timer?.cancel();
  }
}

import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

class VoiceRecorder extends StatefulWidget {
  final Function(String audioPath, Duration duration) onRecordComplete;

  const VoiceRecorder({
    super.key,
    required this.onRecordComplete,
  });

  @override
  State<VoiceRecorder> createState() => _VoiceRecorderState();
}

class _VoiceRecorderState extends State<VoiceRecorder> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _hasRecording = false;
  String? _audioPath;
  Duration _recordDuration = Duration.zero;
  Duration _playbackPosition = Duration.zero;
  Timer? _timer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.mic,
                color: _isRecording ? Colors.red : const Color(0xFF1a73e8),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                _isRecording
                    ? 'Enregistrement en cours...'
                    : _hasRecording
                        ? 'Message vocal enregistré'
                        : 'Enregistrer un message vocal',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _isRecording ? Colors.red : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // État de l'enregistrement
          if (_isRecording || _hasRecording)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  if (_isRecording) ...[
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (_hasRecording && !_isRecording) ...[
                    Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: const Color(0xFF1a73e8),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isRecording)
                          Text(
                            _formatDuration(_recordDuration),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        if (_hasRecording && !_isRecording) ...[
                          LinearProgressIndicator(
                            value: _recordDuration.inSeconds > 0
                                ? _playbackPosition.inSeconds / _recordDuration.inSeconds
                                : 0,
                            backgroundColor: Colors.grey[300],
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF1a73e8),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_formatDuration(_playbackPosition)} / ${_formatDuration(_recordDuration)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // Boutons de contrôle
          if (!_hasRecording)
            ElevatedButton.icon(
              onPressed: _isRecording ? _stopRecording : _startRecording,
              icon: Icon(_isRecording ? Icons.stop : Icons.mic),
              label: Text(_isRecording ? 'Arrêter' : 'Commencer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isRecording ? Colors.red : const Color(0xFF1a73e8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _playRecording,
                    icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                    label: Text(_isPlaying ? 'Pause' : 'Écouter'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _deleteRecording,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Supprimer'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),

          const SizedBox(height: 8),
          
          // Aide
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[100]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isRecording
                        ? 'Parlez clairement dans le microphone'
                        : 'Cette option est idéale pour ceux qui ne savent pas écrire',
                    style: TextStyle(
                      fontSize: 12,
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
    super.dispose();
  }

  Future<bool> _checkPermission() async {
    final status = await Permission.microphone.request();
    return status == PermissionStatus.granted;
  }

  Future<void> _deleteRecording() async {
    await _audioPlayer.stop();
    setState(() {
      _hasRecording = false;
      _audioPath = null;
      _recordDuration = Duration.zero;
      _playbackPosition = Duration.zero;
      _isPlaying = false;
    });
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
          setState(() => _playbackPosition = position);
        });

        _audioPlayer.onPlayerComplete.listen((_) {
          setState(() {
            _isPlaying = false;
            _playbackPosition = Duration.zero;
          });
        });
      }
    } catch (e) {
      print('Erreur lecture: $e');
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
      setState(() {
        _recordDuration = Duration(seconds: timer.tick);
      });
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
        
        // Notifier le parent
        widget.onRecordComplete(path, _recordDuration);
      }
    } catch (e) {
      print('Erreur arrêt enregistrement: $e');
    }
  }

  void _stopTimer() {
    _timer?.cancel();
  }
}

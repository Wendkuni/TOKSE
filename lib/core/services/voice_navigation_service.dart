import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';

import 'routing_service.dart';

/// Service de navigation vocale turn-by-turn
class VoiceNavigationService {
  final FlutterTts _tts = FlutterTts();
  final List<NavigationInstruction> _instructions;
  int _currentInstructionIndex = 0;
  bool _isNavigating = false;
  
  VoiceNavigationService(this._instructions);
  
  /// Initialiser le TTS
  Future<void> initialize() async {
    try {
      await _tts.setLanguage('fr-FR');
      await _tts.setSpeechRate(0.5); // Vitesse normale
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      
      // Vérifier les langues disponibles
      final languages = await _tts.getLanguages;
      print('🔊 [TTS] Langues disponibles: $languages');
      
      _isNavigating = true;
      print('✅ [TTS] Navigation vocale initialisée');
    } catch (e) {
      print('❌ [TTS] Erreur initialisation: $e');
    }
  }
  
  /// Annoncer une instruction
  Future<void> speak(String text) async {
    try {
      await _tts.speak(text);
      print('🔊 [TTS] "$text"');
    } catch (e) {
      print('❌ [TTS] Erreur annonce: $e');
    }
  }
  
  /// Mettre à jour la position et annoncer les instructions
  Future<void> updatePosition(Position position) async {
    if (!_isNavigating || _currentInstructionIndex >= _instructions.length) {
      return;
    }
    
    // Récupérer l'instruction courante
    final instruction = _instructions[_currentInstructionIndex];
    
    // Vérifier la distance restante
    // Note: Dans une vraie implémentation, il faudrait avoir les coordonnées de chaque instruction
    // Pour simplifier, on annonce l'instruction suivante tous les X mètres
    
    if (_currentInstructionIndex == 0) {
      // Première instruction
      await speak(instruction.instruction);
      _currentInstructionIndex++;
    }
  }
  
  /// Annoncer la distance restante
  Future<void> announceDistance(double distanceMeters) async {
    if (!_isNavigating) return;
    
    String message;
    if (distanceMeters < 50) {
      message = 'Vous arrivez à destination dans ${distanceMeters.round()} mètres';
    } else if (distanceMeters < 200) {
      message = 'Dans ${distanceMeters.round()} mètres';
    } else if (distanceMeters < 1000) {
      message = 'Dans ${distanceMeters.round()} mètres, continuez tout droit';
    } else {
      final km = (distanceMeters / 1000).toStringAsFixed(1);
      message = 'Continuez sur $km kilomètres';
    }
    
    await speak(message);
  }
  
  /// Annoncer l'arrivée
  Future<void> announceArrival() async {
    await speak('Vous êtes arrivé à destination');
    _isNavigating = false;
  }
  
  /// Arrêter la navigation vocale
  Future<void> stop() async {
    _isNavigating = false;
    await _tts.stop();
    print('⏹️ [TTS] Navigation vocale arrêtée');
  }
  
  /// Dispose
  void dispose() {
    _tts.stop();
  }
}

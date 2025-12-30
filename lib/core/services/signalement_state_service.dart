import 'dart:async';

/// Service global pour broadcaster les changements d'état des signalements
/// Permet à tous les écrans de se synchroniser en temps réel
class SignalementStateService {
  // Singleton
  static final SignalementStateService _instance =
      SignalementStateService._internal();
  factory SignalementStateService() => _instance;
  SignalementStateService._internal();

  // StreamController pour broadcaster les changements
  final _signalementStateController =
      StreamController<SignalementStateEvent>.broadcast();

  /// Stream pour écouter les changements d'état des signalements
  Stream<SignalementStateEvent> get stateChanges =>
      _signalementStateController.stream;

  /// Notifier que un signalement a été pris en charge
  void notifyTakeCharge(String signalementId, String agentId) {
    print(
        '📢 [STATE_SERVICE] Broadcasting: Signalement $signalementId pris en charge par $agentId');
    _signalementStateController.add(
      SignalementStateEvent(
        signalementId: signalementId,
        type: SignalementEventType.takeCharge,
        agentId: agentId,
      ),
    );
  }

  /// Notifier qu'un signalement a été résolu
  void notifyResolve(String signalementId) {
    print('📢 [STATE_SERVICE] Broadcasting: Signalement $signalementId résolu');
    _signalementStateController.add(
      SignalementStateEvent(
        signalementId: signalementId,
        type: SignalementEventType.resolve,
      ),
    );
  }

  /// Notifier qu'un signalement a été mis à jour (générique)
  void notifyUpdate(String signalementId) {
    print(
        '📢 [STATE_SERVICE] Broadcasting: Signalement $signalementId mis à jour');
    _signalementStateController.add(
      SignalementStateEvent(
        signalementId: signalementId,
        type: SignalementEventType.update,
      ),
    );
  }

  /// Fermer le service (à appeler à la fermeture de l'app)
  void dispose() {
    _signalementStateController.close();
  }
}

/// Types d'événements sur les signalements
enum SignalementEventType {
  takeCharge, // Prise en charge
  resolve, // Résolution
  update, // Mise à jour générique
}

/// Événement de changement d'état d'un signalement
class SignalementStateEvent {
  final String signalementId;
  final SignalementEventType type;
  final String? agentId;

  SignalementStateEvent({
    required this.signalementId,
    required this.type,
    this.agentId,
  });
}

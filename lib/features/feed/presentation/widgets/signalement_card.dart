import 'package:flutter/material.dart';

import '../../../signalement/domain/entities/signalement_entity.dart';

class SignalementCard extends StatefulWidget {
  final SignalementEntity signalement;
  final bool isLiked;
  final bool isPending; // Indique si une opération est en cours
  final VoidCallback onTap;
  final VoidCallback onFelicitate;
  final bool isOwner;
  final VoidCallback? onDelete; // Nouveau callback pour suppression

  const SignalementCard({
    super.key,
    required this.signalement,
    required this.isLiked,
    this.isPending = false,
    required this.onTap,
    required this.onFelicitate,
    this.isOwner = false,
    this.onDelete,
  });

  @override
  State<SignalementCard> createState() => _SignalementCardState();
}

class _SignalementCardState extends State<SignalementCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: InkWell(
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image avec overlay
            if (widget.signalement.photoUrl != null)
              Stack(
                children: [
                  // Image
                  Image.network(
                    widget.signalement.photoUrl!,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: double.infinity,
                        height: 200,
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.broken_image,
                          size: 64,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                  // Gradient overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
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

            // Contenu
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date uniquement (publication anonyme)
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.signalement.getRelativeTime(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const Spacer(),
                      if (widget.isOwner && _canShowDeleteOption())
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, size: 20),
                          onSelected: (value) {
                            if (value == 'delete') {
                              _showDeleteConfirmation(context);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem<String>(
                              value: 'delete',
                              child: Row(
                                children: [
                                  const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Supprimer',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                      Text(
                                        'Reste ${_getMinutesRemaining()} min',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Titre
                  Text(
                    widget.signalement.titre ?? 'Signalement',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Indicateur audio avec durée si présent
                  if (widget.signalement.audioUrl != null) ...[
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
                          if (widget.signalement.audioDuration != null) ...[
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
                                '${widget.signalement.audioDuration! ~/ 60}:${(widget.signalement.audioDuration! % 60).toString().padLeft(2, '0')}',
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
                    const SizedBox(height: 12),
                  ],

                  // Description textuelle
                  if (widget.signalement.description.isNotEmpty) ...[
                    Text(
                      widget.signalement.description.length > 15
                          ? '${widget.signalement.description.substring(0, 15)}...'
                          : widget.signalement.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Localisation
                  if (widget.signalement.adresse != null)
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.signalement.adresse!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),

                  // Barre d'actions
                  Row(
                    children: [
                      // Bouton Félicitations avec icône certificat
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: widget.isPending ? null : widget.onFelicitate,
                          icon: widget.isPending
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(
                                  Icons.verified,
                                  size: 20,
                                ),
                          label: Text(
                            'Félicitations (${widget.signalement.felicitations})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.isLiked
                                ? const Color(0xFF1a73e8)
                                : Colors.grey[200],
                            foregroundColor: widget.isLiked
                                ? Colors.white
                                : Colors.grey[700],
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Vérifie si l'option de suppression doit être affichée
  /// Conditions: état = "en_attente" ET moins d'1 heure depuis la création
  bool _canShowDeleteOption() {
    // Vérifier l'état
    if (widget.signalement.etat != 'en_attente') {
      return false;
    }
    
    // Vérifier le temps écoulé (moins d'1 heure)
    final minutesSinceCreation = DateTime.now()
        .difference(widget.signalement.createdAt)
        .inMinutes;
    
    return minutesSinceCreation < 60;
  }
  
  /// Retourne le nombre de minutes restantes pour supprimer
  int _getMinutesRemaining() {
    final minutesSinceCreation = DateTime.now()
        .difference(widget.signalement.createdAt)
        .inMinutes;
    return (60 - minutesSinceCreation).clamp(0, 60);
  }
  
  /// Affiche le dialogue de confirmation de suppression
  void _showDeleteConfirmation(BuildContext context) {
    final minutesRemaining = _getMinutesRemaining();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_forever,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Supprimer ce signalement ?',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.timer, color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Il vous reste $minutesRemaining minutes pour supprimer ce signalement.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Cette action est irréversible. Le signalement, ses photos et toutes les données associées seront définitivement supprimés.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              widget.onDelete?.call();
            },
            icon: const Icon(Icons.delete, size: 18),
            label: const Text('Supprimer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor() {
    switch (widget.signalement.categorie) {
      case 'dechets':
        return const Color(0xFFe74c3c); // Rouge
      case 'route':
        return const Color(0xFFf39c12); // Orange
      case 'pollution':
        return const Color(0xFF9b59b6); // Violet
      case 'autre':
        return const Color(0xFF34495e); // Gris
      default:
        return Colors.grey;
    }
  }

  String _getCategoryLabel() {
    switch (widget.signalement.categorie) {
      case 'dechets':
        return '🗑️ Déchets';
      case 'route':
        return '🚧 Route dégradée';
      case 'pollution':
        return '🏭 Pollution';
      case 'autre':
        return '📢 Autre';
      default:
        return widget.signalement.categorie;
    }
  }

  Color _getEtatColor() {
    switch (widget.signalement.etat) {
      case 'en_attente':
        return const Color(0xFFf39c12); // Jaune/Orange
      case 'en_cours':
        return const Color(0xFF3498db); // Bleu
      case 'resolu':
        return const Color(0xFF27ae60); // Vert
      default:
        return Colors.grey;
    }
  }

  String _getEtatLabel() {
    switch (widget.signalement.etat) {
      case 'en_attente':
        return 'En attente';
      case 'en_cours':
        return 'En cours';
      case 'resolu':
        return 'Résolu';
      default:
        return widget.signalement.etat;
    }
  }
}

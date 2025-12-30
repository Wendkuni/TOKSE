import 'package:flutter/material.dart';

import '../../../signalement/domain/entities/signalement_entity.dart';

class SignalementCard extends StatefulWidget {
  final SignalementEntity signalement;
  final bool isLiked;
  final VoidCallback onTap;
  final VoidCallback onFelicitate;
  final bool isOwner;

  const SignalementCard({
    super.key,
    required this.signalement,
    required this.isLiked,
    required this.onTap,
    required this.onFelicitate,
    this.isOwner = false,
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
                      if (widget.isOwner)
                        IconButton(
                          icon: const Icon(Icons.more_vert, size: 20),
                          onPressed: () {
                            // Menu éditer/supprimer
                          },
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
                          Text(
                            '🎙️ Message vocal',
                            style: const TextStyle(
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
                          onPressed: widget.onFelicitate,
                          icon: const Icon(
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

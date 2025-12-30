import 'package:equatable/equatable.dart';

/// Entité métier Signalement (logique pure, sans dépendances externes)
class SignalementEntity extends Equatable {
  final String id;
  final String? titre;
  final String description;
  final String categorie; // dechets, route, pollution, autre
  final String etat; // en_attente, en_cours, resolu
  final double? latitude;
  final double? longitude;
  final String? adresse;
  final String userId;
  final UserAuthor? author; // Informations de l'auteur
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? photoUrl;
  final String? audioUrl;
  final int? audioDuration;
  final int felicitations;

  const SignalementEntity({
    required this.id,
    this.titre,
    required this.description,
    required this.categorie,
    required this.etat,
    this.latitude,
    this.longitude,
    this.adresse,
    required this.userId,
    this.author,
    required this.createdAt,
    required this.updatedAt,
    this.photoUrl,
    this.audioUrl,
    this.audioDuration,
    required this.felicitations,
  });

  @override
  List<Object?> get props => [
        id,
        titre,
        description,
        categorie,
        etat,
        latitude,
        longitude,
        adresse,
        userId,
        author,
        createdAt,
        updatedAt,
        photoUrl,
        audioUrl,
        audioDuration,
        felicitations,
      ];

  /// Vérifie si le signalement est résolu
  bool get isResolved => etat == 'resolu';

  /// Vérifie si le signalement est en cours de traitement
  bool get isInProgress => etat == 'en_cours';

  /// Vérifie si le signalement est en attente
  bool get isPending => etat == 'en_attente';
  
  /// Obtient le temps relatif depuis la création
  String getRelativeTime() {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays > 0) {
      return 'il y a ${difference.inDays}j';
    } else if (difference.inHours > 0) {
      return 'il y a ${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return 'il y a ${difference.inMinutes}min';
    } else {
      return 'à l\'instant';
    }
  }

  /// Obtient l'icône selon la catégorie
  String getCategoryIcon() {
    switch (categorie) {
      case 'dechets':
        return '🗑️';
      case 'route':
        return '🚧';
      case 'pollution':
        return '🌫️';
      case 'eclairage':
        return '💡';
      case 'espaces_verts':
        return '🌳';
      default:
        return '📍';
    }
  }

  /// Obtient la couleur selon le statut
  String getStatusColor() {
    switch (etat) {
      case 'en_attente':
        return '#FFA500'; // Orange
      case 'en_cours':
        return '#2196F3'; // Bleu
      case 'resolu':
        return '#4CAF50'; // Vert
      default:
        return '#9E9E9E'; // Gris
    }
  }
}

/// Sous-entité pour les informations de l'auteur
class UserAuthor extends Equatable {
  final String id;
  final String? nom;
  final String? prenom;
  final String? avatarUrl;
  
  const UserAuthor({
    required this.id,
    this.nom,
    this.prenom,
    this.avatarUrl,
  });
  
  String get fullName {
    if (nom != null && prenom != null) {
      return '$prenom $nom';
    } else if (nom != null) {
      return nom!;
    } else if (prenom != null) {
      return prenom!;
    }
    return 'Utilisateur';
  }
  
  @override
  List<Object?> get props => [id, nom, prenom, avatarUrl];
}

class SignalementModel {
  final String id;
  final String userId;
  final String? titre;
  final String description;
  final String categorie;
  final String? photoUrl;
  final String? audioUrl;
  final int? audioDuration; // Durée en secondes
  final double? latitude;
  final double? longitude;
  final String? adresse;
  final String etat; // 'en_attente', 'en_cours', 'resolu'
  final String? assignedTo; // ID de l'agent assigné
  final bool locked; // true si l'agent a pris en charge le signalement
  final int felicitations;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;
  final UserProfile? author;

  SignalementModel({
    required this.id,
    required this.userId,
    this.titre,
    required this.description,
    required this.categorie,
    this.photoUrl,
    this.audioUrl,
    this.audioDuration,
    this.latitude,
    this.longitude,
    this.adresse,
    required this.etat,
    this.assignedTo,
    this.locked = false,
    required this.felicitations,
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
    this.author,
  });

  factory SignalementModel.fromJson(Map<String, dynamic> json) {
    return SignalementModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      titre: json['titre'] as String?,
      description: json['description'] as String? ?? 'Aucune description',
      categorie: json['categorie'] as String? ?? 'autre',
      photoUrl: json['photo_url'] as String?,
      audioUrl: json['audio_url'] as String?,
      audioDuration: json['audio_duration'] as int?,
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
      adresse: json['adresse'] as String?,
      etat: json['etat'] as String? ?? 'en_attente', // Utiliser 'etat' de la DB
      assignedTo: json['assigned_to'] as String?,
      locked: json['locked'] as bool? ?? false,
      felicitations: json['felicitations'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
      author: json['users'] != null
          ? UserProfile.fromJson(json['users'] as Map<String, dynamic>)
          : null,
    );
  }

  String getRelativeTime() {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return "À l'instant";
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays}j';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'titre': titre,
      'description': description,
      'categorie': categorie,
      'photo_url': photoUrl,
      'audio_url': audioUrl,
      'audio_duration': audioDuration,
      'latitude': latitude,
      'longitude': longitude,
      'adresse': adresse,
      'etat': etat, // Utiliser 'etat' pour la DB
      'assigned_to': assignedTo,
      'locked': locked,
      'felicitations': felicitations,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
    };
  }
}

class UserProfile {
  final String id;
  final String nom;
  final String prenom;
  final String? photoProfile;

  UserProfile({
    required this.id,
    required this.nom,
    required this.prenom,
    this.photoProfile,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      nom: json['nom'] as String? ?? '',
      prenom: json['prenom'] as String? ?? '',
      photoProfile: json['photo_profile'] as String?,
    );
  }

  String get fullName => '$nom $prenom'.trim();
}

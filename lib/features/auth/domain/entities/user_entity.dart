import 'package:equatable/equatable.dart';

/// Entité utilisateur (logique métier pure)
class UserEntity extends Equatable {
  final String id;
  final String phone;
  final String? nom;
  final String? prenom;
  final String? email;
  final String? avatarUrl;
  final String role; // user, authority, admin
  final bool isVerified;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  const UserEntity({
    required this.id,
    required this.phone,
    this.nom,
    this.prenom,
    this.email,
    this.avatarUrl,
    this.role = 'user',
    this.isVerified = false,
    required this.createdAt,
    this.lastLoginAt,
  });

  @override
  List<Object?> get props => [
        id,
        phone,
        nom,
        prenom,
        email,
        avatarUrl,
        role,
        isVerified,
        createdAt,
        lastLoginAt,
      ];

  /// Nom complet de l'utilisateur
  String get fullName {
    if (nom != null && prenom != null) {
      return '$prenom $nom';
    }
    if (nom != null) return nom!;
    if (prenom != null) return prenom!;
    return 'Utilisateur';
  }

  /// Vérifie si l'utilisateur est une autorité
  bool get isAuthority => role == 'authority';

  /// Vérifie si l'utilisateur est admin
  bool get isAdmin => role == 'admin';

  /// Vérifie si l'utilisateur est un utilisateur standard
  bool get isStandardUser => role == 'user';

  /// Initiales pour l'avatar
  String get initials {
    if (nom != null && prenom != null && nom!.isNotEmpty && prenom!.isNotEmpty) {
      return '${prenom![0]}${nom![0]}'.toUpperCase();
    }
    if (nom != null && nom!.isNotEmpty) {
      return nom![0].toUpperCase();
    }
    if (prenom != null && prenom!.isNotEmpty) {
      return prenom![0].toUpperCase();
    }
    return 'U';
  }
}

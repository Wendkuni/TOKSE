import '../../domain/entities/user_entity.dart';

/// Mapper pour convertir les données Supabase en UserEntity
class UserMapper {
  static UserEntity fromSupabase(Map<String, dynamic> json) {
    return UserEntity(
      id: json['id'] as String,
      phone: json['phone'] as String? ?? '',
      nom: json['nom'] as String?,
      prenom: json['prenom'] as String?,
      email: json['email'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      role: json['role'] as String? ?? 'user',
      isVerified: json['is_verified'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.parse(json['last_login_at'] as String)
          : null,
    );
  }

  static Map<String, dynamic> toSupabase(UserEntity entity) {
    return {
      'id': entity.id,
      'phone': entity.phone,
      'nom': entity.nom,
      'prenom': entity.prenom,
      'email': entity.email,
      'avatar_url': entity.avatarUrl,
      'role': entity.role,
      'is_verified': entity.isVerified,
      'created_at': entity.createdAt.toIso8601String(),
      'last_login_at': entity.lastLoginAt?.toIso8601String(),
    };
  }
}

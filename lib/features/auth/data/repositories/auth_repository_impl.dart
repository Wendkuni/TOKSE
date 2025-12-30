import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../mappers/user_mapper.dart';
import 'auth_repository.dart' as old;

/// Implémentation Clean du repository d'authentification
class AuthRepositoryImpl implements IAuthRepository {
  final old.AuthRepository _oldRepo;
  final SupabaseClient _supabase;

  AuthRepositoryImpl({
    old.AuthRepository? oldRepo,
  })  : _oldRepo = oldRepo ?? old.AuthRepository(),
        _supabase = SupabaseConfig.client;

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return const Right(null);

      // Récupérer les données complètes depuis la table users
      final data = await _supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data == null) return const Right(null);

      return Right(UserMapper.fromSupabase(data));
    } catch (e) {
      AppLogger.error('Erreur getCurrentUser', error: e, tag: 'AuthRepo');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isAuthenticated() async {
    try {
      final isAuth = await _oldRepo.isAuthenticated();
      return Right(isAuth);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithPhone({
    required String phone,
    required String password,
  }) async {
    try {
      AppLogger.info('Tentative connexion: $phone', tag: 'AuthRepo');
      
      // Utiliser l'ancienne méthode pour l'instant
      final response = await _supabase.auth.signInWithPassword(
        phone: phone,
        password: password,
      );

      if (response.user == null) {
        return const Left(AuthenticationFailure(message: 'Échec de connexion'));
      }

      // Récupérer les données utilisateur
      final data = await _supabase
          .from('users')
          .select()
          .eq('id', response.user!.id)
          .single();

      AppLogger.auth('Connexion réussie', userId: response.user!.id);
      return Right(UserMapper.fromSupabase(data));
    } catch (e) {
      AppLogger.error('Erreur signInWithPhone', error: e, tag: 'AuthRepo');
      return Left(AuthenticationFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signUpWithOtp({
    required String phone,
    required String nom,
    required String prenom,
  }) async {
    try {
      // TODO: Implémenter avec l'ancienne logique
      return const Left(ServerFailure(message: 'Non implémenté'));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> verifyOtp({
    required String phone,
    required String otp,
    required String nom,
    required String prenom,
  }) async {
    try {
      // TODO: Implémenter avec l'ancienne logique
      return const Left(ServerFailure(message: 'Non implémenté'));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      AppLogger.auth('Déconnexion');
      await _oldRepo.signOut();
      return const Right(null);
    } catch (e) {
      AppLogger.error('Erreur signOut', error: e, tag: 'AuthRepo');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> updateProfile({
    String? nom,
    String? prenom,
    String? email,
    String? avatarUrl,
  }) async {
    try {
      // TODO: Implémenter
      return const Left(ServerFailure(message: 'Non implémenté'));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String?>> getStoredUserId() async {
    try {
      final userId = await _oldRepo.getStoredUserId();
      return Right(userId);
    } catch (e) {
      return const Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, void>> refreshSession() async {
    try {
      await _supabase.auth.refreshSession();
      return const Right(null);
    } catch (e) {
      return Left(AuthenticationFailure(message: e.toString()));
    }
  }
}

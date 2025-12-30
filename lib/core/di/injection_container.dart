import 'package:get_it/get_it.dart';

import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/i_auth_repository.dart';
import '../../features/auth/domain/usecases/get_current_user_usecase.dart';
import '../../features/auth/domain/usecases/sign_in_with_phone_usecase.dart';
import '../../features/auth/domain/usecases/sign_out_usecase.dart';
import '../../features/signalement/data/repositories/signalement_repository_impl.dart';
import '../../features/signalement/domain/repositories/i_signalement_repository.dart';
import '../../features/signalement/domain/usecases/add_felicitation_usecase.dart';
import '../../features/signalement/domain/usecases/create_signalement_usecase.dart';
import '../../features/signalement/domain/usecases/get_signalements_usecase.dart';
import '../../features/signalement/domain/usecases/get_user_felicitations_usecase.dart';
import '../../features/signalement/domain/usecases/remove_felicitation_usecase.dart';

/// Service Locator global
final sl = GetIt.instance;

/// Initialise toutes les dépendances de l'application
Future<void> initDependencies() async {
  // ========== CORE ==========
  // Supabase est déjà initialisé dans main.dart avec SupabaseConfig.initialize()

  // ========== DATA SOURCES ==========
  // Pas besoin pour l'instant car on utilise directement Supabase client

  // ========== REPOSITORIES ==========
  
  // Auth Repository
  sl.registerLazySingleton<IAuthRepository>(
    () => AuthRepositoryImpl(),
  );

  // Signalement Repository
  sl.registerLazySingleton<ISignalementRepository>(
    () => SignalementRepositoryImpl(),
  );

  // ========== USE CASES - AUTH ==========
  
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));
  sl.registerLazySingleton(() => SignInWithPhoneUseCase(sl()));
  sl.registerLazySingleton(() => SignOutUseCase(sl()));

  // ========== USE CASES - SIGNALEMENT ==========
  
  sl.registerLazySingleton(() => GetSignalementsUseCase(sl()));
  sl.registerLazySingleton(() => CreateSignalementUseCase(sl()));
  sl.registerLazySingleton(() => AddFelicitationUseCase(sl()));
  sl.registerLazySingleton(() => RemoveFelicitationUseCase(sl()));
  sl.registerLazySingleton(() => GetUserFelicitationsUseCase(sl()));

  // ========== PROVIDERS / BLOCS ==========
  // À ajouter quand vous migrerez vers Riverpod ou Bloc
}

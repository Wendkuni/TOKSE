import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/config/supabase_config.dart';
import 'core/di/injection_container.dart' as di;
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/utils/logger.dart';

void main() async {
  AppLogger.info('🚀 Démarrage TOKSE', tag: 'Main');
  WidgetsFlutterBinding.ensureInitialized();
  AppLogger.info('✅ WidgetsFlutterBinding initialisé', tag: 'Main');
  
  // Initialiser Supabase
  AppLogger.info('⏳ Initialisation Supabase...', tag: 'Main');
  await SupabaseConfig.initialize();
  AppLogger.info('✅ Supabase initialisé', tag: 'Main');
  
  // Initialiser l'injection de dépendances
  AppLogger.info('⏳ Initialisation GetIt...', tag: 'Main');
  await di.initDependencies();
  AppLogger.info('✅ GetIt initialisé', tag: 'Main');
  
  AppLogger.info('📱 Lancement application...', tag: 'Main');
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const TokseApp(),
    ),
  );
}

class TokseApp extends StatelessWidget {
  const TokseApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final router = AppRouter.router;
    
    return MaterialApp.router(
      title: 'TOKSE',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      routerConfig: router,
    );
  }
}

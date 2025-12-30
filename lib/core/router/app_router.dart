import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/agent_login_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/profile_selection_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/authority/presentation/screens/authority_main_screen.dart';
import '../../features/feed/presentation/screens/feed_screen.dart';
import '../../features/feed/presentation/screens/signalement_detail_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/signalement/presentation/screens/signalement_form_screen.dart';
import '../../features/signalement/presentation/screens/signalement_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/profile-selection',
        name: 'profile-selection',
        builder: (context, state) => const ProfileSelectionScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/agent-login',
        name: 'agent-login',
        builder: (context, state) => const AgentLoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) {
          // Forcer la recréation du widget avec une clé unique si resetTab est true
          final extra = state.extra as Map<String, dynamic>?;
          final shouldReset = extra?['resetTab'] == true;
          return HomeScreen(key: shouldReset ? UniqueKey() : null);
        },
      ),
      // Navigation pour les Autorités
      GoRoute(
        path: '/authority-home',
        name: 'authority-home',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final tabIndex = extra?['tabIndex'] as int? ?? 0;
          final signalementId = extra?['signalementId'] as String?;
          // Utiliser une UniqueKey si on change d'onglet ou si on fournit un signalementId
          // Cela force la reconstruction du widget pour charger le nouveau signalement
          final needsUniqueKey = tabIndex != 0 || signalementId != null;
          return AuthorityMainScreen(
            initialTabIndex: tabIndex,
            signalementId: signalementId,
            key: needsUniqueKey ? UniqueKey() : null,
          );
        },
      ),
      // GoRoute(
      //   path: '/authority-notifications',
      //   name: 'authority-notifications',
      //   builder: (context, state) => const AuthorityNotificationsScreen(),
      // ),
      GoRoute(
        path: '/feed',
        name: 'feed',
        builder: (context, state) => const FeedScreen(),
      ),
      GoRoute(
        path: '/signalement',
        name: 'signalement',
        builder: (context, state) => const SignalementScreen(),
      ),
      GoRoute(
        path: '/signalement/create',
        name: 'signalement-create',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final category = extra?['category'] as String? ?? 'autre';
          return SignalementFormScreen(category: category);
        },
      ),
      GoRoute(
        path: '/signalement/:id',
        name: 'signalement-detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return SignalementDetailScreen(signalementId: id);
        },
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
}

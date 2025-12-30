import 'package:flutter/material.dart';

import '../../../auth/data/repositories/auth_repository.dart';
import '../../../profile/presentation/screens/authority_profile_screen.dart';
import 'authority_home_screen.dart';
import 'authority_map_screen.dart';

/// Écran principal avec navigation pour les Autorités
/// 3 onglets : Accueil - Carte - Profil
class AuthorityMainScreen extends StatefulWidget {
  final int initialTabIndex;
  final String? signalementId;

  const AuthorityMainScreen({
    super.key,
    this.initialTabIndex = 0,
    this.signalementId,
  });

  @override
  State<AuthorityMainScreen> createState() => _AuthorityMainScreenState();
}

class _AuthorityMainScreenState extends State<AuthorityMainScreen> {
  final AuthRepository _authRepo = AuthRepository();
  late int _currentIndex;

  List<Widget> get _screens => [
    const AuthorityHomeScreen(),
    AuthorityMapScreen(signalementIdToLoad: widget.signalementId),
    const AuthorityProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex;
    print(
        '🏠 [AUTHORITY_MAIN] AuthorityMainScreen initialisé avec tab index: $_currentIndex');
    _checkUserAuth();
  }

  Future<void> _checkUserAuth() async {
    try {
      final userId = await _authRepo.getStoredUserId();
      print('👤 [AUTHORITY_MAIN] User ID: $userId');

      if (userId == null) {
        print('⚠️ [AUTHORITY_MAIN] Utilisateur non authentifié');
      } else {
        print('✅ [AUTHORITY_MAIN] Agent authentifié, affichage de l\'écran');
      }
    } catch (e) {
      print('❌ [AUTHORITY_MAIN] Erreur vérification auth: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🎨 [AUTHORITY_MAIN] Build appelé - Tab actuel: $_currentIndex');
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Carte',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

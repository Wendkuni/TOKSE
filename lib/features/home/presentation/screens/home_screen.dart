import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../feed/presentation/screens/feed_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../signalement/presentation/screens/category_selection_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// Tab Accueil
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('TOKSE Utilisateur'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Carte de bienvenue
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1a73e8), Color(0xFF4285f4)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '👋 Bienvenue sur TOKSE',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Ensemble, améliorons notre ville',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Statistiques
            Text(
              'Statistiques',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            
            const Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.warning_amber,
                    title: 'Signalements',
                    value: '1,234',
                    color: Colors.orange,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.check_circle,
                    title: 'Résolus',
                    value: '856',
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.pending_actions,
                    title: 'En cours',
                    value: '243',
                    color: Colors.blue,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.people,
                    title: 'Utilisateurs',
                    value: '5,678',
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Actions rapides
            Text(
              'Actions rapides',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _ActionCard(
                  icon: Icons.report_problem,
                  title: 'Signaler',
                  subtitle: 'un problème',
                  color: Colors.red,
                  onTap: () {},
                ),
                _ActionCard(
                  icon: Icons.map,
                  title: 'Carte',
                  subtitle: 'des signalements',
                  color: Colors.green,
                  onTap: () {},
                ),
                _ActionCard(
                  icon: Icons.trending_up,
                  title: 'Tendances',
                  subtitle: 'cette semaine',
                  color: Colors.orange,
                  onTap: () {},
                ),
                _ActionCard(
                  icon: Icons.info,
                  title: 'À propos',
                  subtitle: 'de TOKSE',
                  color: Colors.blue,
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Tab Profile
class ProfileTab extends StatelessWidget {
  final VoidCallback? onDeletionRequestChanged;
  
  const ProfileTab({super.key, this.onDeletionRequestChanged});

  @override
  Widget build(BuildContext context) {
    return ProfileScreen(onDeletionRequestChanged: onDeletionRequestChanged);
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 48),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _hasActiveDeletionRequest = false;
  final _supabase = Supabase.instance.client;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const FeedScreen(),
      const CategorySelectionScreen(),
      ProfileTab(onDeletionRequestChanged: _checkDeletionRequest),
    ];
    _checkDeletionRequest();
    
    // Vérifier régulièrement (toutes les 2 secondes quand l'app est active)
    // pour détecter les changements depuis le ProfileScreen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startPeriodicCheck();
    });
  }

  void _startPeriodicCheck() {
    if (!mounted) return;
    
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _checkDeletionRequest();
        _startPeriodicCheck();
      }
    });
  }

  Future<void> _checkDeletionRequest() async {
    try {
      // ✅ SOLUTION DIRECTE: Utiliser DIRECTEMENT tokse_user_id depuis SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('tokse_user_id');
      
      if (userId != null) {
        final response = await _supabase
            .from('account_deletion_requests')
            .select('*')
            .eq('user_id', userId)
            .eq('status', 'pending')
            .maybeSingle();

        if (mounted) {
          setState(() {
            _hasActiveDeletionRequest = response != null;
          });
        }
      }
    } catch (e) {
      print('❌ Erreur vérification suppression: $e');
    }
  }

  void _showDeletionBlockDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Action bloquée',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.delete_forever, color: Colors.red.shade700, size: 24),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Compte en cours de suppression',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Vous ne pouvez pas créer de signalement tant que votre demande de suppression est active.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Pour continuer à utiliser Tokse, annulez votre demande dans l\'onglet Profil.',
                      style: TextStyle(fontSize: 13, color: Colors.blueGrey),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 2); // Aller à l'onglet Profil
            },
            icon: const Icon(Icons.person, size: 18),
            label: const Text('Aller au Profil'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1a73e8),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          // Bloquer l'accès à l'onglet Signalement (index 1) si demande de suppression active
          if (index == 1 && _hasActiveDeletionRequest) {
            _showDeletionBlockDialog(context);
            return;
          }
          setState(() => _currentIndex = index);
        },
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.add_circle_outline,
              color: _hasActiveDeletionRequest ? Colors.grey : null,
            ),
            selectedIcon: Icon(
              Icons.add_circle,
              color: _hasActiveDeletionRequest ? Colors.grey : null,
            ),
            label: 'Signalement',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/services/signalement_state_service.dart';
import '../../../auth/data/repositories/auth_repository.dart';

/// Écran Profil pour les Autorités
/// Infos non modifiables + historique interventions + paramètres
class AuthorityProfileScreen extends StatefulWidget {
  const AuthorityProfileScreen({super.key});

  @override
  State<AuthorityProfileScreen> createState() => _AuthorityProfileScreenState();
}

class _AuthorityProfileScreenState extends State<AuthorityProfileScreen> {
  final AuthRepository _authRepo = AuthRepository();
  final _supabase = SupabaseConfig.client;
  final SignalementStateService _stateService = SignalementStateService();

  RealtimeChannel? _realtimeChannel;
  StreamSubscription<SignalementStateEvent>? _stateSubscription;

  bool _isLoading = true;

  Map<String, dynamic>? _userProfile;
  List<dynamic> _interventions = [];
  String _filterPeriod = 'all'; // all, today, week

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _userProfile == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final filteredInterventions = _getFilteredInterventions();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          // Header avec avatar et infos
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: const Color(0xFF1a73e8),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1a73e8), Color(0xFF4285f4)],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Avatar
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.shield,
                            size: 50,
                            color: Color(0xFF1a73e8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Nom + Prénom
                      Text(
                        '${_userProfile!['prenom']} ${_userProfile!['nom']}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Rôle
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getRoleLabel(_userProfile!['role']),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Contenu
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Section : Informations du compte
                _buildSection(
                  title: '👤 Informations du compte',
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow('Nom', _userProfile!['nom']),
                        const Divider(height: 24),
                        _buildInfoRow('Prénom', _userProfile!['prenom']),
                        const Divider(height: 24),
                        _buildInfoRow('Téléphone', _userProfile!['telephone']),
                        if (_userProfile!['email'] != null) ...[
                          const Divider(height: 24),
                          _buildInfoRow('Email', _userProfile!['email']),
                        ],
                        const Divider(height: 24),
                        _buildInfoRow(
                            'Rôle', _getRoleLabel(_userProfile!['role'])),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Section : Historique des interventions
                _buildSection(
                  title: '📋 Historique des interventions',
                  child: Column(
                    children: [
                      // Filtres
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildFilterButton(
                                'Aujourd\'hui',
                                'today',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildFilterButton(
                                'Cette semaine',
                                'week',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildFilterButton(
                                'Tout',
                                'all',
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Liste des interventions
                      if (filteredInterventions.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.assignment_outlined,
                                  size: 60,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Aucune intervention',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredInterventions.length,
                          itemBuilder: (context, index) {
                            final intervention = filteredInterventions[index];
                            return _buildInterventionCard(intervention);
                          },
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Bouton Déconnexion
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout, size: 24),
                      label: const Text(
                        'Se déconnecter',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupRealtimeListener();
    _setupStateListener();
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    _stateSubscription?.cancel();
    super.dispose();
  }

  /// Écouter les changements d'état des signalements depuis d'autres écrans
  void _setupStateListener() {
    _stateSubscription = _stateService.stateChanges.listen((event) {
      print(
          '📢 [AUTHORITY_PROFILE] Événement reçu: ${event.type} pour signalement ${event.signalementId}');
      // Recharger l'historique des interventions
      _loadData();
    });
    print('✅ [AUTHORITY_PROFILE] Listener d\'état configuré');
  }

  /// Écouter les changements en temps réel sur la table signalements
  void _setupRealtimeListener() {
    _realtimeChannel = _supabase
        .channel('interventions_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'signalements',
          callback: (payload) {
            print(
                '🔄 [AUTHORITY_PROFILE] Changement détecté dans signalements: ${payload.eventType}');
            // Recharger les interventions quand un signalement change
            _loadData();
          },
        )
        .subscribe();

    print('✅ [AUTHORITY_PROFILE] Listener temps réel configuré');
  }

  Widget _buildFilterButton(String label, String period) {
    final isSelected = _filterPeriod == period;

    return Material(
      color: isSelected ? const Color(0xFF1a73e8) : Colors.grey[100],
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => setState(() => _filterPeriod = period),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value ?? 'N/A',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildInterventionCard(Map<String, dynamic> intervention) {
    // Utiliser resolved_at si disponible, sinon created_at
    final dateStr = intervention['resolved_at'] ?? intervention['created_at'];
    final resolvedDate = DateTime.parse(dateStr);
    final formattedDate =
        '${resolvedDate.day}/${resolvedDate.month}/${resolvedDate.year}';
    final formattedTime =
        '${resolvedDate.hour.toString().padLeft(2, '0')}:${resolvedDate.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Navigation vers les détails du signalement
          context.push('/signalement/${intervention['id']}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo du signalement avec badge "Résolu"
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: (intervention['photo_url'] != null &&
                            intervention['photo_url'].toString().isNotEmpty)
                        ? Image.network(
                            intervention['photo_url'],
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                width: 100,
                                height: 100,
                                color: Colors.grey[200],
                                child: const Center(
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              print(
                                  '❌ [PROFILE] Erreur chargement photo: $error');
                              print(
                                  '❌ [PROFILE] URL: ${intervention['photo_url']}');
                              return Container(
                                width: 100,
                                height: 100,
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          )
                        : Container(
                            width: 100,
                            height: 100,
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.photo_camera_outlined,
                              color: Colors.grey,
                              size: 40,
                            ),
                          ),
                  ),
                  // Badge "Résolu" sur la photo
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10b981),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Text(
                        '✅ Résolu',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 12),

              // Infos du signalement
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date et heure
                    Row(
                      children: [
                        Icon(Icons.access_time,
                            size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '$formattedDate à $formattedTime',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Catégorie
                    if (intervention['categorie'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1a73e8).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          intervention['categorie'],
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1a73e8),
                          ),
                        ),
                      ),

                    const SizedBox(height: 6),

                    // Description
                    Text(
                      intervention['description'] ?? 'Pas de description',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Adresse
                    if (intervention['adresse'] != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              size: 13, color: Colors.grey[600]),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              intervention['adresse'],
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 4),

                    // Indicateur "Cliquer pour voir"
                    Row(
                      children: [
                        Icon(Icons.touch_app,
                            size: 12, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          'Appuyer pour voir les détails',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        child,
      ],
    );
  }

  List<dynamic> _getFilteredInterventions() {
    final now = DateTime.now();

    switch (_filterPeriod) {
      case 'today':
        final todayStart = DateTime(now.year, now.month, now.day);
        return _interventions.where((i) {
          // Utiliser resolved_at si disponible, sinon created_at
          final dateStr = i['resolved_at'] ?? i['created_at'];
          if (dateStr == null) return false;
          final date = DateTime.parse(dateStr);
          return date.isAfter(todayStart);
        }).toList();

      case 'week':
        final weekStart = now.subtract(const Duration(days: 7));
        return _interventions.where((i) {
          // Utiliser resolved_at si disponible, sinon created_at
          final dateStr = i['resolved_at'] ?? i['created_at'];
          if (dateStr == null) return false;
          final date = DateTime.parse(dateStr);
          return date.isAfter(weekStart);
        }).toList();

      default:
        return _interventions;
    }
  }

  String _getRoleLabel(String? role) {
    switch (role) {
      case 'police':
        return 'Police Municipale';
      case 'hygiene':
        return 'Hygiène';
      case 'voirie':
        return 'Voirie';
      case 'environnement':
        return 'Environnement';
      case 'securite':
        return 'Sécurité';
      default:
        return 'Opérateur';
    }
  }

  Future<void> _loadData() async {
    // Ne pas bloquer si déjà en chargement
    if (!_isLoading) {
      setState(() => _isLoading = true);
    }

    try {
      // Récupérer l'ID utilisateur rapidement (d'abord Supabase, sinon SharedPreferences)
      String? userId = _supabase.auth.currentUser?.id;
      
      if (userId == null) {
        // Fallback sur SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        userId = prefs.getString('tokse_user_id');
      }
      
      if (userId == null) {
        print('❌ [AUTHORITY_PROFILE] User ID non trouvé');
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      print('🔍 [AUTHORITY_PROFILE] Chargement des données pour userId: $userId');

      // Charger le profil ET les interventions EN PARALLÈLE avec timeout
      final results = await Future.wait([
        _supabase
            .from('users')
            .select('*')
            .eq('id', userId)
            .single()
            .timeout(const Duration(seconds: 10)),
        _supabase
            .from('signalements')
            .select('*')
            .eq('assigned_to', userId)
            .eq('etat', 'resolu')
            .order('created_at', ascending: false)
            .limit(50)
            .timeout(const Duration(seconds: 10)),
      ]);

      final userResponse = results[0] as Map<String, dynamic>;
      final signalementsResponse = results[1] as List;

      print('✅ [AUTHORITY_PROFILE] Profil chargé: ${userResponse['nom']}');
      print('✅ [AUTHORITY_PROFILE] ${signalementsResponse.length} interventions trouvées');

      if (mounted) {
        setState(() {
          _userProfile = userResponse;
          _interventions = signalementsResponse;
          _isLoading = false;
        });
      }
    } on TimeoutException {
      print('⏰ [AUTHORITY_PROFILE] Timeout - chargement trop long');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chargement lent, veuillez réessayer'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ [AUTHORITY_PROFILE] Erreur: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authRepo.signOut();
      if (mounted) {
        // Les agents/autorités vont toujours sur la page agent-login
        context.go('/agent-login');
      }
    }
  }
}

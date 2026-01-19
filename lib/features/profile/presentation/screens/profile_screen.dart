import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/services/signalement_state_service.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../feed/data/models/signalement_model.dart';
import '../../../feed/data/repositories/signalements_repository.dart';
import '../../../feed/presentation/widgets/signalement_card.dart';
import '../../../signalement/domain/entities/signalement_entity.dart';
import '../../data/models/user_stats_model.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onDeletionRequestChanged;
  
  const ProfileScreen({super.key, this.onDeletionRequestChanged});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthRepository _authRepo = AuthRepository();
  final SignalementsRepository _signalementsRepo = SignalementsRepository();
  final _supabase = SupabaseConfig.client;
  final ImagePicker _picker = ImagePicker();
  final SignalementStateService _stateService = SignalementStateService();

  bool _isLoading = true;
  String _activeTab = 'stats';
  String _filterStatut = 'tout'; // Filtre pour les signalements
  UserStatsModel? _stats;
  List<dynamic> _signalements = [];
  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? _deletionRequest;
  XFile? _selectedImageForEdit; // Image sélectionnée pour édition
  StreamSubscription<SignalementStateEvent>? _stateSubscription;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: themeProvider.themeMode == ThemeMode.dark
            ? const Color(0xFF1a1a2e)
            : const Color(0xFF1a73e8),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      backgroundColor: themeProvider.themeMode == ThemeMode.dark
          ? const Color(0xFF1a1a2e)
          : const Color(0xFFF5F5F5),
      extendBodyBehindAppBar: true,
      body: Column(
        children: [
          // Header avec avatar + infos
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              left: 20,
              right: 20,
              bottom: 20,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: themeProvider.themeMode == ThemeMode.dark
                    ? [const Color(0xFF0f3460), const Color(0xFF1a1a2e)]
                    : [const Color(0xFF1a73e8), const Color(0xFF1557b0)],
              ),
            ),
            child: Column(
              children: [
                // Avatar et infos
                Row(
                  children: [
                    // Avatar avec badge
                    Stack(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: _userProfile?['photo_profile'] != null
                                ? Image.network(
                                    _userProfile!['photo_profile'],
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                      color: Colors.white,
                                      child: const Icon(Icons.person,
                                          size: 40, color: Color(0xFF1a73e8)),
                                    ),
                                  )
                                : Container(
                                    color: Colors.white,
                                    child: const Icon(Icons.person,
                                        size: 40, color: Color(0xFF1a73e8)),
                                  ),
                          ),
                        ),
                        // Badge complétude
                        if (_calculateProfileCompleteness() == 100)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFF27ae60),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.verified,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    // Infos
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _userProfile?['nom'] ?? 'Utilisateur',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _userProfile?['prenom'] ?? '',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _userProfile?['telephone'] ?? '',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Badge de complétion
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _calculateProfileCompleteness() == 100
                                  ? const Color(0xFF27ae60)
                                  : Colors.orange,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _calculateProfileCompleteness() == 100
                                  ? '✓ Profil vérifié'
                                  : 'Profil ${_calculateProfileCompleteness()}%',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Toggle Dark/Light avec libellé
                    Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: () => themeProvider.toggleTheme(),
                            icon: Icon(
                              themeProvider.themeMode == ThemeMode.dark
                                  ? Icons.wb_sunny
                                  : Icons.nightlight_round,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          themeProvider.themeMode == ThemeMode.dark
                              ? 'Sombre'
                              : 'Claire',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Bouton Modifier avec icône
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _showEditProfileDialog,
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text(
                      'Modifier mon profil',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1a73e8),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Contenu avec onglets
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: themeProvider.themeMode == ThemeMode.dark
                    ? const Color(0xFF16213e)
                    : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  // Onglets
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: themeProvider.themeMode == ThemeMode.dark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.grey[200]!,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _activeTab = 'stats'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: _activeTab == 'stats'
                                        ? const Color(0xFF1a73e8)
                                        : Colors.transparent,
                                    width: 3,
                                  ),
                                ),
                              ),
                              child: Text(
                                '📊 Statistiques',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _activeTab == 'stats'
                                      ? const Color(0xFF1a73e8)
                                      : (themeProvider.themeMode ==
                                              ThemeMode.dark
                                          ? Colors.grey[400]
                                          : Colors.grey),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _activeTab = 'signalements'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: _activeTab == 'signalements'
                                        ? const Color(0xFF1a73e8)
                                        : Colors.transparent,
                                    width: 3,
                                  ),
                                ),
                              ),
                              child: Text(
                                '📝 Mes signalements',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _activeTab == 'signalements'
                                      ? const Color(0xFF1a73e8)
                                      : (themeProvider.themeMode ==
                                              ThemeMode.dark
                                          ? Colors.grey[400]
                                          : Colors.grey),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Contenu des onglets
                  Expanded(
                    child: _activeTab == 'stats'
                        ? _buildStatsTab()
                        : _buildSignalementsTab(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _checkDeletionRequest();  // AJOUTÉ: Vérifier la demande de suppression au démarrage
    _setupRealtimeListener();
    _setupStateListener();
  }

  /// Écouter les changements d'état des signalements depuis d'autres écrans
  void _setupStateListener() {
    _stateSubscription = _stateService.stateChanges.listen((event) {
      print(
          '📢 [PROFILE] Événement reçu: ${event.type} pour signalement ${event.signalementId}');
      // Recharger les données pour synchroniser les stats et la liste
      _loadProfileData();
    });
    print('✅ [PROFILE] Listener d\'état configuré');
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    // Nettoyer les channels Supabase
    _supabase.channel('felicitations_updates').unsubscribe();
    _supabase.channel('deletion_requests_updates').unsubscribe();
    super.dispose();
  }

  Widget _buildSignalementsTab() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    // Filtrer les signalements selon le statut sélectionné
    final signalementsFiltered = _filterStatut == 'tout'
        ? _signalements
        : _signalements.where((s) => s.etat == _filterStatut).toList();

    print('🔍 [FILTRE] Statut sélectionné: $_filterStatut');
    print('🔍 [FILTRE] Total signalements: ${_signalements.length}');
    print('🔍 [FILTRE] Signalements filtrés: ${signalementsFiltered.length}');
    if (_signalements.isNotEmpty) {
      print(
          '🔍 [FILTRE] Exemple statut du 1er signalement: ${_signalements[0].etat}');
    }

    return Column(
      children: [
        // Dropdown pour filtrer
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: themeProvider.themeMode == ThemeMode.dark
                  ? const Color(0xFF16213e)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF1a73e8).withOpacity(0.3),
              ),
            ),
            child: DropdownButton<String>(
              value: _filterStatut,
              isExpanded: true,
              underline: const SizedBox(),
              icon: const Icon(Icons.filter_list, color: Color(0xFF1a73e8)),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: themeProvider.themeMode == ThemeMode.dark
                    ? Colors.white
                    : Colors.black,
              ),
              items: const [
                DropdownMenuItem(
                    value: 'tout', child: Text('Tous les signalements')),
                DropdownMenuItem(
                    value: 'en_attente', child: Text('En attente')),
                DropdownMenuItem(value: 'en_cours', child: Text('En cours')),
                DropdownMenuItem(value: 'resolu', child: Text('Résolus')),
              ],
              onChanged: (value) {
                setState(() {
                  _filterStatut = value!;
                });
              },
            ),
          ),
        ),

        // Liste des signalements
        Expanded(
          child: signalementsFiltered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('📭', style: TextStyle(fontSize: 64)),
                      const SizedBox(height: 16),
                      Text(
                        _filterStatut == 'tout'
                            ? 'Aucun signalement'
                            : 'Aucun signalement ${_filterStatut.replaceAll('_', ' ')}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _filterStatut == 'tout'
                            ? 'Vous n\'avez pas encore créé de signalement.'
                            : 'Aucun signalement avec ce statut.',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadProfileData,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: signalementsFiltered.length,
                    itemBuilder: (context, index) {
                      final signalement = signalementsFiltered[index];
                      // Convertir SignalementModel en SignalementEntity
                      final signalementEntity = _convertToEntity(signalement);
                      return SignalementCard(
                        signalement: signalementEntity,
                        isLiked: false,
                        onTap: () {},
                        onFelicitate: () {},
                        isOwner: true,
                        onDelete: () => _handleDeleteSignalement(signalement.id),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String icon, String value, String label, Color color) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Text(icon, style: const TextStyle(fontSize: 28)),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              height: 1.2,
              color: themeProvider.themeMode == ThemeMode.dark
                  ? Colors.grey[400]
                  : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📊 Mes statistiques',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: themeProvider.themeMode == ThemeMode.dark
                  ? Colors.white
                  : Colors.black,
            ),
          ),
          const SizedBox(height: 20),

          // Toutes les cartes sur une seule ligne
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  '📊',
                  '${_stats?.totalSignalements ?? 0}',
                  'Total signalements',
                  const Color(0xFF1a73e8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  '✅',
                  '${_stats?.resolus ?? 0}',
                  'Signalements résolus',
                  const Color(0xFF27ae60),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  '❤️',
                  '${_stats?.totalFelicitations ?? 0}',
                  'Félicitations',
                  const Color(0xFFe74c3c),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Message de bienvenue
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1a73e8).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: const Border(
                left: BorderSide(color: Color(0xFF1a73e8), width: 4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🌟 Merci !',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: themeProvider.themeMode == ThemeMode.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Chaque signalement compte. Ensemble, nous rendons la ville plus sûre et plus propre. Continuez ainsi !',
                  style: TextStyle(
                    fontSize: 14,
                    color: themeProvider.themeMode == ThemeMode.dark
                        ? Colors.grey[300]
                        : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Alerte suppression en attente
          if (_deletionRequest != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'COMPTE EN COURS DE SUPPRESSION',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '⚠️ Votre compte sera désactivé automatiquement le '
                    '${DateTime.parse(_deletionRequest!['deletion_scheduled_for']).day}/'
                    '${DateTime.parse(_deletionRequest!['deletion_scheduled_for']).month}/'
                    '${DateTime.parse(_deletionRequest!['deletion_scheduled_for']).year} '
                    'à ${DateTime.parse(_deletionRequest!['deletion_scheduled_for']).hour}:'
                    '${DateTime.parse(_deletionRequest!['deletion_scheduled_for']).minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '🚫 Vous ne pouvez plus créer de signalements pendant cette période.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Si le compte est encore actif : Annulation immédiate possible
                  if (_userProfile?['is_active'] == true) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _handleCancelDeletion,
                        icon: const Icon(Icons.cancel_outlined, size: 20),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1a73e8),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        label: const Text(
                          'Annuler la suppression',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Vous pouvez annuler à tout moment avant la date prévue.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ] else ...[
                    // Si le compte est déjà désactivé : Demande de réactivation requise
                    const Text(
                      '⚠️ Votre compte a été désactivé. Vous devez demander une réactivation.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _handleRequestReactivation,
                        icon: const Icon(Icons.refresh, size: 20),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        label: const Text(
                          'Demander la réactivation',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Un administrateur traitera votre demande.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          const SizedBox(height: 16),

          // Bouton déconnexion
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _handleLogout,
                icon: const Icon(Icons.logout, size: 24),
                label: const Text(
                  'Se déconnecter',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
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
          const SizedBox(height: 12),

          // Lien discret pour supprimer le compte (moins visible)
          if (_deletionRequest == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      print('🔴 DEBUG: Bouton supprimer cliqué via InkWell');
                      await _handleDeleteAccount();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: Text(
                        'Supprimer mon compte',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  int _calculateProfileCompleteness() {
    if (_userProfile == null) return 0;

    int completed = 0;
    int total = 4;

    if (_userProfile!['nom']?.toString().trim().isNotEmpty == true) completed++;
    if (_userProfile!['prenom']?.toString().trim().isNotEmpty == true) {
      completed++;
    }
    if (_userProfile!['telephone']?.toString().trim().isNotEmpty == true) {
      completed++;
    }
    if (_userProfile!['photo_profile']?.toString().trim().isNotEmpty == true) {
      completed++;
    }

    return ((completed / total) * 100).round();
  }

  Future<void> _checkDeletionRequest() async {
    try {
      // ✅ SOLUTION DIRECTE: Utiliser DIRECTEMENT tokse_user_id depuis SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('tokse_user_id');
      
      print('� DEBUG _checkDeletionRequest: userId depuis SharedPreferences = $userId');
      
      if (userId != null) {
        final response = await _supabase
            .from('account_deletion_requests')
            .select('*')
            .eq('user_id', userId)
            .eq('status', 'pending')
            .maybeSingle();

        print('🔴 DEBUG _checkDeletionRequest: response = $response');
        if (response != null) {
          setState(() => _deletionRequest = response);
          print('✅ DEBUG _checkDeletionRequest: _deletionRequest défini!');
        } else {
          setState(() => _deletionRequest = null);
          print('⚪ DEBUG _checkDeletionRequest: Aucune demande pending');
        }
        
        // Notifier le parent (HomeScreen) du changement
        widget.onDeletionRequestChanged?.call();
      } else {
        print('❌ DEBUG _checkDeletionRequest: tokse_user_id est NULL');
      }
    } catch (e) {
      print('❌ Erreur vérification suppression: $e');
    }
  }

  Future<void> _handleCancelDeletion() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler la suppression'),
        content: const Text(
            'Êtes-vous sûr de vouloir annuler la demande de suppression ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Non'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        // Utiliser la même méthode que _loadProfileData
        final userId = await _authRepo.getStoredUserId();
        if (userId == null) return;

        // Appeler la fonction SQL au lieu d'un UPDATE direct
        await _supabase.rpc('cancel_deletion_request', params: {
          'p_user_id': userId,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  '✅ Demande de suppression annulée. Votre compte est sécurisé.'),
              backgroundColor: Colors.green,
            ),
          );
          setState(() => _deletionRequest = null);
          
          // Notifier le parent (HomeScreen) du changement
          widget.onDeletionRequestChanged?.call();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  /// Supprime un signalement de l'utilisateur
  /// Conditions: < 1h après création ET état = "en_attente"
  Future<void> _handleDeleteSignalement(String signalementId) async {
    try {
      // Récupérer l'ID utilisateur
      final userId = await _authRepo.getStoredUserId();
      if (userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur: utilisateur non connecté'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Appeler la fonction RPC pour supprimer
      final response = await _supabase.rpc(
        'delete_user_signalement',
        params: {
          'p_signalement_id': signalementId,
          'p_user_id': userId,
        },
      );

      if (mounted) {
        // Vérifier le résultat
        if (response != null && response is List && response.isNotEmpty) {
          final result = response[0];
          if (result['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Signalement supprimé avec succès'),
                backgroundColor: Colors.green,
              ),
            );
            // Recharger les données du profil
            await _loadProfileData();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ ${result['message'] ?? 'Erreur lors de la suppression'}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Erreur inattendue lors de la suppression'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Erreur suppression signalement: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleRequestReactivation() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Demander la réactivation'),
        content: const Text(
            'Voulez-vous demander la réactivation de votre compte ?\n\n'
            'Un administrateur traitera votre demande et pourra réactiver votre compte immédiatement.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('Confirmer la demande'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        // Utiliser la même méthode que _loadProfileData
        final userId = await _authRepo.getStoredUserId();
        if (userId == null) return;

        // Créer une demande de réactivation
        await _supabase.from('account_reactivation_requests').insert({
          'user_id': userId,
          'deletion_request_id': _deletionRequest?['id'],
          'status': 'pending',
          'reason': 'Demande de réactivation par l\'utilisateur',
        });

        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('✅ Demande envoyée'),
              content: const Text(
                  'Votre demande de réactivation a été envoyée aux administrateurs.\n\n'
                  'Vous recevrez une notification dès que votre compte sera réactivé.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleDeleteAccount() async {
    print('🔴 DEBUG: _handleDeleteAccount appelée');
    
    if (!mounted) return;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Supprimer le compte'),
        content: const Text(
          'Votre compte sera désactivé après 2 semaines.\n\n'
          '⚠️ Pendant cette période :\n'
          '• Vous ne pourrez plus créer de signalements\n'
          '• Vous pouvez annuler la demande\n'
          '• Un administrateur sera notifié\n\n'
          'Continuer ?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Confirmer la suppression'),
          ),
        ],
      ),
    );

    print('🔴 DEBUG: confirm = $confirm');
    
    if (confirm != true) {
      print('🔴 DEBUG: Annulation par utilisateur');
      return;
    }
    
    if (!mounted) return;

    try {
      // Utiliser la même méthode que _loadProfileData (SharedPreferences)
      final userId = await _authRepo.getStoredUserId();
      print('🔴 DEBUG: userId depuis SharedPreferences = $userId');
      print('🔴 DEBUG: userId depuis _supabase.auth = ${_supabase.auth.currentUser?.id}');
      print('🔴 DEBUG: _userProfile userId = ${_userProfile?['id']}');
      
      if (userId == null) {
        print('❌ DEBUG: Pas d\'utilisateur connecté');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur: Utilisateur non connecté'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      print('🔴 DEBUG: Appel de la fonction create_deletion_request...');
      
      // Appeler la fonction SQL au lieu d'un INSERT direct (contourne RLS)
      final response = await _supabase.rpc('create_deletion_request', params: {
        'p_user_id': userId,
      });
      
      print('✅ DEBUG: Fonction exécutée avec succès: $response');
      
      // Parser la réponse
      final deletionDate = DateTime.parse(response['deletion_scheduled_for']);

      if (!mounted) return;
      
      // Afficher le message de confirmation
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('✅ Demande validée'),
          content: Text(
            'Votre compte sera désactivé le ${deletionDate.day}/${deletionDate.month}/${deletionDate.year} '
            'à ${deletionDate.hour}h${deletionDate.minute.toString().padLeft(2, '0')}.\n\n'
            '⚠️ Vous ne pourrez plus créer de signalements.\n\n'
            'Vous pouvez annuler cette demande à tout moment dans votre profil.'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      
      // Recharger les données pour afficher l'alerte rouge
      if (mounted) {
        await _checkDeletionRequest();
      }
    } catch (e, stackTrace) {
      print('❌ DEBUG: Erreur complète = $e');
      print('❌ DEBUG: Stack trace = $stackTrace');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await _authRepo.signOut();
      // Récupérer le type de profil pour rediriger vers la bonne page de connexion
      final prefs = await SharedPreferences.getInstance();
      final profileType = prefs.getString('user_profile_type');

      if (profileType == 'agent') {
        context.go('/agent-login');
      } else {
        context.go('/login');
      }
    }
  }

  Future<void> _loadProfileData() async {
    print('🔵 [PROFIL] D\u00e9but chargement profil...');
    setState(() => _isLoading = true);
    try {
      final userId = await _authRepo.getStoredUserId();
      print('🔵 [PROFIL] UserID depuis SharedPreferences: $userId');

      if (userId != null) {
        // Charger le profil utilisateur
        print('🔵 [PROFIL] Chargement profil utilisateur...');
        final userResponse =
            await _supabase.from('users').select('*').eq('id', userId).single();

        setState(() {
          _userProfile = userResponse;
        });

        print(
            '✅ [PROFIL] Profil chargé: ${_userProfile?['nom']} ${_userProfile?['prenom']}');

        // Charger les stats
        try {
          print('🔵 [PROFIL] Chargement stats...');
          final stats = await _signalementsRepo.getUserStats();
          setState(() {
            _stats = stats;
          });
          print(
              '✅ [PROFIL] Stats chargées: ${stats.totalSignalements} signalements');
        } catch (e) {
          print('⚠️ [PROFIL] Erreur stats: $e');
          // Continue sans stats
        }

        // Charger les signalements
        try {
          print('🔵 [PROFIL] Chargement signalements...');
          final signalements = await _signalementsRepo.getUserSignalements();
          setState(() {
            _signalements = signalements;
          });
          print('✅ [PROFIL] Signalements chargés: ${signalements.length}');
        } catch (e) {
          print('⚠️ [PROFIL] Erreur signalements: $e');
          // Continue sans signalements
        }

        // Vérifier les demandes de suppression
        try {
          print('🔵 [PROFIL] Vérification suppression...');
          await _checkDeletionRequest();
          print('✅ [PROFIL] Vérification suppression OK');
        } catch (e) {
          print('⚠️ [PROFIL] Erreur vérification suppression: $e');
        }
      } else {
        print('❌ [PROFIL] Pas d\'utilisateur connecté');
      }
    } catch (e) {
      print('❌ [PROFIL] Erreur chargement profil: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      print('🔵 [PROFIL] Fin chargement, isLoading = false');
      setState(() => _isLoading = false);
    }
  }

  void _setupRealtimeListener() {
    // Écouter les changements de félicitations en temps réel
    _supabase
        .channel('felicitations_updates')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'felicitations',
          callback: (payload) {
            print('🔔 [REALTIME] Félicitation mise à jour');
            // Recharger les stats quand une félicitation change
            _loadProfileData();
          },
        )
        .subscribe();
    
    // Écouter les changements de demandes de suppression en temps réel
    _supabase
        .channel('deletion_requests_updates')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'account_deletion_requests',
          callback: (payload) {
            print('🔔 [REALTIME] Demande de suppression mise à jour: ${payload.eventType}');
            // Revérifier la demande de suppression
            _checkDeletionRequest();
          },
        )
        .subscribe();
  }

  void _showEditProfileDialog() {
    _selectedImageForEdit = null; // Reset image
    final nomController = TextEditingController(
      text: _userProfile?['nom'] ?? '',
    );
    final prenomController = TextEditingController(
      text: _userProfile?['prenom'] ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Modifier le profil',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Prénom',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: prenomController,
                  decoration: InputDecoration(
                    hintText: 'Votre prénom',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Nom',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nomController,
                  decoration: InputDecoration(
                    hintText: 'Votre nom',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Photo de profil',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                // Aperçu de l'image sélectionnée
                if (_selectedImageForEdit != null)
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: const Color(0xFF1a73e8), width: 3),
                          ),
                          child: ClipOval(
                            child: Image.file(
                              File(_selectedImageForEdit!.path),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () {
                              setDialogState(() {
                                _selectedImageForEdit = null;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final XFile? image = await _picker.pickImage(
                              source: ImageSource.camera);
                          if (image != null) {
                            setDialogState(() {
                              _selectedImageForEdit = image;
                            });
                          }
                        },
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Caméra'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1a73e8),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final XFile? image = await _picker.pickImage(
                              source: ImageSource.gallery);
                          if (image != null) {
                            setDialogState(() {
                              _selectedImageForEdit = image;
                            });
                          }
                        },
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Galerie'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1a73e8),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final userId = await _authRepo.getStoredUserId();
                  if (userId == null) {
                    throw Exception('Utilisateur non connecté');
                  }

                  // Fermer le dialogue immédiatement
                  if (mounted) Navigator.pop(context);

                  // Update nom et prenom
                  await _supabase.from('users').update({
                    'nom': nomController.text,
                    'prenom': prenomController.text,
                  }).eq('id', userId);

                  // Upload image if selected
                  if (_selectedImageForEdit != null) {
                    await _uploadProfileImage(_selectedImageForEdit!);
                  }

                  // Reload data
                  await _loadProfileData();

                  // Message de succès
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Profil mis à jour !'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1a73e8),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadProfileImage(XFile image) async {
    try {
      if (!mounted) return;

      // Get user ID
      final userId = await _authRepo.getStoredUserId();
      if (userId == null) throw Exception('Utilisateur non connecté');

      // Read file as bytes
      final bytes = await image.readAsBytes();
      final fileExt = image.path.split('.').last;
      final fileName = 'profile_$userId.$fileExt';
      final filePath = 'profiles/$fileName';

      // Upload to Supabase Storage
      await _supabase.storage.from('signalements-photos').uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );

      // Get public URL
      final publicUrl =
          _supabase.storage.from('signalements-photos').getPublicUrl(filePath);

      // Update database
      await _supabase.from('users').update({
        'photo_profile': publicUrl,
      }).eq('id', userId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur upload: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      rethrow;
    }
  }

  /// Convertir un SignalementModel en SignalementEntity
  SignalementEntity _convertToEntity(dynamic signalement) {
    if (signalement is SignalementModel) {
      // Convertir UserProfile en UserAuthor
      UserAuthor? author;
      if (signalement.author != null) {
        author = UserAuthor(
          id: signalement.author!.id,
          nom: signalement.author!.nom,
          prenom: signalement.author!.prenom,
          avatarUrl: signalement.author!.photoProfile,
        );
      }

      return SignalementEntity(
        id: signalement.id,
        userId: signalement.userId,
        titre: signalement.titre ?? '',
        description: signalement.description,
        categorie: signalement.categorie,
        photoUrl: signalement.photoUrl,
        latitude: signalement.latitude,
        longitude: signalement.longitude,
        adresse: signalement.adresse,
        etat: signalement.etat,
        felicitations: signalement.felicitations,
        createdAt: signalement.createdAt,
        updatedAt: signalement.updatedAt,
        author: author,
      );
    } else {
      // Si c'est déjà une entité ou un autre type, essayer de créer depuis les propriétés
      return SignalementEntity(
        id: signalement.id ?? '',
        userId: signalement.userId ?? '',
        titre: signalement.titre ?? '',
        description: signalement.description ?? '',
        categorie: signalement.categorie ?? '',
        photoUrl: signalement.photoUrl,
        latitude: signalement.latitude,
        longitude: signalement.longitude,
        adresse: signalement.adresse ?? '',
        etat: signalement.etat,
        felicitations: signalement.felicitations ?? 0,
        createdAt: signalement.createdAt ?? DateTime.now(),
        updatedAt: signalement.updatedAt ?? DateTime.now(),
        author: null,
      );
    }
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/logger.dart';
import '../../../signalement/domain/entities/signalement_entity.dart';
import '../../../signalement/domain/usecases/get_signalements_usecase.dart';
import '../../../signalement/domain/usecases/add_felicitation_usecase.dart';
import '../../../signalement/domain/usecases/remove_felicitation_usecase.dart';
import '../../../signalement/domain/usecases/get_user_felicitations_usecase.dart';
import '../../../auth/domain/usecases/get_current_user_usecase.dart';
import '../widgets/signalement_card.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  // Use Cases via GetIt
  final _getSignalementsUseCase = sl<GetSignalementsUseCase>();
  final _addFelicitationUseCase = sl<AddFelicitationUseCase>();
  final _removeFelicitationUseCase = sl<RemoveFelicitationUseCase>();
  final _getUserFelicitationsUseCase = sl<GetUserFelicitationsUseCase>();
  final _getCurrentUserUseCase = sl<GetCurrentUserUseCase>();

  List<SignalementEntity> _signalements = [];
  Set<String> _userFelicitations = {};
  final Set<String> _pendingFelicitations = {}; // Pour éviter les double-clics
  bool _isLoading = true;
  String? _currentUserId;
  String _selectedFilter = 'tout'; // tout, categorie, miens, etat
  String? _selectedCategory; // dechets, route, pollution, autre
  String? _selectedEtat; // en_attente, en_cours, resolu, null=tout
  String _viewMode = 'suivis'; // suivis, populaire

  @override
  Widget build(BuildContext context) {
    final filteredSignalements = _getFilteredAndSortedSignalements();

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1a73e8),
        toolbarHeight: 60,
        title: const Text(
          'TOKSE Utilisateur',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            fontFamily: 'sans-serif',
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Barre de contrôles
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF1a73e8),
            ),
            child: Row(
              children: [
                // Bouton Suivis
                Expanded(
                  child: Material(
                    color: _viewMode == 'suivis'
                        ? Colors.white
                        : Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: () => setState(() => _viewMode = 'suivis'),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Center(
                          child: Text(
                            'Suivis',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _viewMode == 'suivis'
                                  ? const Color(0xFF1a73e8)
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Bouton Populaire
                Expanded(
                  child: Material(
                    color: _viewMode == 'populaire'
                        ? Colors.white
                        : Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: () => setState(() => _viewMode = 'populaire'),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Center(
                          child: Text(
                            'Populaire',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _viewMode == 'populaire'
                                  ? const Color(0xFF1a73e8)
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // ComboBox Trier par
                Expanded(
                  child: InkWell(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (context) => _buildFilterModal(),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Trier par',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _getFilterLabel(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(
                                Icons.arrow_drop_down,
                                size: 18,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Liste des signalements avec fond blanc arrondi
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredSignalements.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Aucun signalement',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredSignalements.length,
                            itemBuilder: (context, index) {
                              final signalement = filteredSignalements[index];
                              final isLiked =
                                  _userFelicitations.contains(signalement.id);
                              final isOwner = _currentUserId != null &&
                                  _currentUserId == signalement.userId;
                              final isPending =
                                  _pendingFelicitations.contains(signalement.id);

                              return SignalementCard(
                                signalement: signalement,
                                isLiked: isLiked,
                                isPending: isPending,
                                onTap: () {
                                  context
                                      .push('/signalement/${signalement.id}');
                                },
                                onFelicitate: () =>
                                    _toggleFelicitation(signalement),
                                isOwner: isOwner,
                              );
                            },
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recharger automatiquement quand on revient sur cette page
    if (ModalRoute.of(context)?.isCurrent ?? false) {
      _loadData();
    }
  }

  @override
  void didUpdateWidget(FeedScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recharger les données quand le widget est mis à jour
    _loadData();
  }

  @override
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Widget _buildCategoryOption(String value, String label, Color color) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedCategory = value;
          _selectedFilter = 'categorie';
          _selectedEtat = null;
        });
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _selectedCategory == value
              ? color.withOpacity(0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedCategory == value ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Text(
              label.split(' ').first,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 12),
            Text(
              label.split(' ').skip(1).join(' '),
              style: TextStyle(
                fontSize: 16,
                fontWeight: _selectedCategory == value
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEtatOption(String value, String label, Color color) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedEtat = value;
          _selectedFilter = 'etat';
          _selectedCategory = null;
        });
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _selectedEtat == value
              ? color.withOpacity(0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedEtat == value ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Text(
              label.split(' ').first,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label.split(' ').skip(1).join(' '),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: _selectedEtat == value
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterModal() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Trier par',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.all_inclusive),
            title: const Text('Tout'),
            trailing: _selectedFilter == 'tout'
                ? const Icon(Icons.check, color: Color(0xFF1a73e8))
                : null,
            onTap: () {
              setState(() {
                _selectedFilter = 'tout';
                _selectedCategory = null;
                _selectedEtat = null;
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text('Catégorie'),
            trailing: _selectedFilter == 'categorie'
                ? const Icon(Icons.check, color: Color(0xFF1a73e8))
                : null,
            onTap: () {
              Navigator.pop(context);
              _showCategorySelector();
            },
          ),
          ListTile(
            leading: const Icon(Icons.assignment),
            title: const Text('Par état'),
            trailing: _selectedFilter == 'etat'
                ? const Icon(Icons.check, color: Color(0xFF1a73e8))
                : null,
            onTap: () {
              Navigator.pop(context);
              _showEtatSelector();
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Les miens'),
            trailing: _selectedFilter == 'miens'
                ? const Icon(Icons.check, color: Color(0xFF1a73e8))
                : null,
            onTap: () {
              setState(() {
                _selectedFilter = 'miens';
                _selectedCategory = null;
                _selectedEtat = null;
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  List<SignalementEntity> _getFilteredAndSortedSignalements() {
    var filtered = List<SignalementEntity>.from(_signalements);

    // En mode "Suivis", afficher TOUS les signalements pour montrer le travail des autorités
    // (ne plus filtrer par état, on veut la transparence)

    // Appliquer les filtres du ComboBox "Trier par"
    if (_selectedFilter == 'miens') {
      if (_currentUserId != null) {
        filtered = filtered.where((s) => s.userId == _currentUserId).toList();
      }
    } else if (_selectedFilter == 'categorie' && _selectedCategory != null) {
      filtered =
          filtered.where((s) => s.categorie == _selectedCategory).toList();
    } else if (_selectedFilter == 'etat' && _selectedEtat != null) {
      // Nouveau filtre par état
      filtered = filtered.where((s) => s.etat == _selectedEtat).toList();
    }

    // Tri selon le mode toolbar
    if (_viewMode == 'populaire') {
      // En mode populaire, trier par nombre de félicitations décroissant
      filtered.sort((a, b) => b.felicitations.compareTo(a.felicitations));
    } else {
      // En mode suivis, trier intelligemment:
      // 1. D'abord les "en_attente" (urgent, besoin d'action)
      // 2. Puis les "en_cours" (en traitement par les autorités)
      // 3. Enfin les "resolu" (pour montrer le travail accompli)
      // Au sein de chaque groupe, trier par date (plus récent d'abord)
      filtered.sort((a, b) {
        // Ordre de priorité des états
        final stateOrder = {'en_attente': 0, 'en_cours': 1, 'resolu': 2};
        final aOrder = stateOrder[a.etat] ?? 3;
        final bOrder = stateOrder[b.etat] ?? 3;

        if (aOrder != bOrder) {
          return aOrder.compareTo(bOrder);
        }
        // Si même état, trier par date (plus récent d'abord)
        return b.createdAt.compareTo(a.createdAt);
      });
    }

    return filtered;
  }

  String _getFilterLabel() {
    if (_selectedFilter == 'miens') return 'Les miens';
    if (_selectedFilter == 'categorie' && _selectedCategory != null) {
      switch (_selectedCategory) {
        case 'dechets':
          return 'Déchets';
        case 'route':
          return 'Route';
        case 'pollution':
          return 'Pollution';
        case 'autre':
          return 'Autre';
      }
    }
    if (_selectedFilter == 'etat' && _selectedEtat != null) {
      switch (_selectedEtat) {
        case 'en_attente':
          return '⏳ En attente';
        case 'en_cours':
          return '🔧 En cours';
        case 'resolu':
          return '✅ Résolu';
      }
    }
    return 'Tout';
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    AppLogger.info('Chargement des données du feed', tag: 'FeedScreen');

    // Charger l'utilisateur actuel
    final userResult = await _getCurrentUserUseCase.call();
    userResult.fold(
      (failure) => AppLogger.warning(
          'Utilisateur non connecté: ${failure.message}',
          tag: 'FeedScreen'),
      (user) {
        if (user != null) {
          _currentUserId = user.id;
          AppLogger.debug('Utilisateur actuel: ${user.id}', tag: 'FeedScreen');
        }
      },
    );

    // Charger les félicitations de l'utilisateur
    final felicitationsResult = await _getUserFelicitationsUseCase.call();
    felicitationsResult.fold(
      (failure) {
        AppLogger.error('Erreur chargement félicitations: ${failure.message}',
            tag: 'FeedScreen');
      },
      (felicitations) {
        _userFelicitations = felicitations;
        AppLogger.debug('${felicitations.length} félicitations chargées',
            tag: 'FeedScreen');
      },
    );

    // Charger les signalements
    final signalementsResult = await _getSignalementsUseCase.call();

    signalementsResult.fold(
      (failure) {
        AppLogger.error('Erreur chargement signalements: ${failure.message}',
            tag: 'FeedScreen');
        setState(() {
          _isLoading = false;
        });
      },
      (signalements) {
        AppLogger.info('✅ ${signalements.length} signalements chargés',
            tag: 'FeedScreen');
        setState(() {
          _signalements = signalements;
          _isLoading = false;
        });
      },
    );
  }

  void _showCategorySelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choisir une catégorie',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildCategoryOption(
                'dechets', '🗑️ Déchets', const Color(0xFFe74c3c)),
            _buildCategoryOption(
                'route', '🚧 Route dégradée', const Color(0xFFf39c12)),
            _buildCategoryOption(
                'pollution', '🏭 Pollution', const Color(0xFF9b59b6)),
            _buildCategoryOption('autre', '📢 Autre', const Color(0xFF34495e)),
          ],
        ),
      ),
    );
  }

  void _showEtatSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filtrer par état',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildEtatOption(
                'en_attente', '⏳ En attente', const Color(0xFFf59e0b)),
            _buildEtatOption(
                'en_cours', '🔧 En cours', const Color(0xFF3b82f6)),
            _buildEtatOption('resolu', '✅ Résolu', const Color(0xFF10b981)),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleFelicitation(SignalementEntity signalement) async {
    // Empêcher l'utilisateur de modifier la félicitation sur son propre signalement
    // (il a déjà une auto-félicitation et ne peut ni l'enlever ni en ajouter une autre)
    if (_currentUserId != null && _currentUserId == signalement.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Merci pour votre signalement ! 🎉'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Empêcher les double-clics
    if (_pendingFelicitations.contains(signalement.id)) {
      return;
    }

    final isLiked = _userFelicitations.contains(signalement.id);

    AppLogger.debug('Toggle félicitation pour ${signalement.id}',
        tag: 'FeedScreen');

    // Marquer comme en cours de traitement
    setState(() {
      _pendingFelicitations.add(signalement.id);
    });

    // Optimistic update : mettre à jour l'UI immédiatement
    final originalFelicitations = Set<String>.from(_userFelicitations);
    final originalSignalements = List<SignalementEntity>.from(_signalements);

    if (isLiked) {
      // Retirer la félicitation (optimistic)
      setState(() {
        _userFelicitations.remove(signalement.id);
        _updateSignalementFelicitations(signalement.id, -1);
      });

      final result = await _removeFelicitationUseCase.call(signalement.id);

      result.fold(
        (failure) {
          AppLogger.error('Erreur retrait félicitation: ${failure.message}',
              tag: 'FeedScreen');
          // Rollback en cas d'erreur
          setState(() {
            _userFelicitations = originalFelicitations;
            _signalements = originalSignalements;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${failure.message}'),
              backgroundColor: Colors.red,
            ),
          );
        },
        (_) {
          // Succès - l'UI est déjà à jour
        },
      );
    } else {
      // Ajouter une félicitation (optimistic)
      setState(() {
        _userFelicitations.add(signalement.id);
        _updateSignalementFelicitations(signalement.id, 1);
      });

      final result = await _addFelicitationUseCase.call(signalement.id);

      result.fold(
        (failure) {
          AppLogger.error('Erreur ajout félicitation: ${failure.message}',
              tag: 'FeedScreen');
          // Rollback en cas d'erreur
          setState(() {
            _userFelicitations = originalFelicitations;
            _signalements = originalSignalements;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${failure.message}'),
              backgroundColor: Colors.red,
            ),
          );
        },
        (_) {
          // Succès - l'UI est déjà à jour
        },
      );
    }

    // Retirer du pending
    setState(() {
      _pendingFelicitations.remove(signalement.id);
    });
  }

  /// Met à jour le compteur de félicitations d'un signalement localement
  void _updateSignalementFelicitations(String signalementId, int delta) {
    final index = _signalements.indexWhere((s) => s.id == signalementId);
    if (index != -1) {
      final signalement = _signalements[index];
      _signalements[index] = SignalementEntity(
        id: signalement.id,
        userId: signalement.userId,
        titre: signalement.titre,
        description: signalement.description,
        categorie: signalement.categorie,
        photoUrl: signalement.photoUrl,
        latitude: signalement.latitude,
        longitude: signalement.longitude,
        adresse: signalement.adresse,
        etat: signalement.etat,
        felicitations: (signalement.felicitations + delta).clamp(0, 999999),
        createdAt: signalement.createdAt,
        updatedAt: signalement.updatedAt,
        author: signalement.author,
      );
    }
  }
}

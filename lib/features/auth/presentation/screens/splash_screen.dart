import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tokse_flutter/core/config/supabase_config.dart';
import 'package:tokse_flutter/features/auth/data/repositories/auth_repository.dart';
import 'package:tokse_flutter/features/auth/presentation/widgets/terms_conditions_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _glowController;
  late AnimationController _rotateController;
  late AnimationController _pulseController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _pulseAnimation;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0a1929),
              Color(0xFF1a237e),
              Color(0xFF1a73e8),
              Color(0xFF4285f4),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Cercle d'arrière-plan 1 (animé en rotation)
            AnimatedBuilder(
              animation: _rotateAnimation,
              builder: (context, _) {
                return Positioned(
                  top: -screenWidth * 0.5,
                  left: -screenWidth * 0.25,
                  child: Transform.rotate(
                    angle: _rotateAnimation.value * 2 * math.pi,
                    child: AnimatedBuilder(
                      animation: _glowAnimation,
                      builder: (context, _) {
                        return Container(
                          width: screenWidth * 1.5,
                          height: screenWidth * 1.5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF4285f4).withOpacity(0.1 + _glowAnimation.value * 0.2),
                              width: 2,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),

            // Cercle d'arrière-plan 2 (rotation inverse)
            AnimatedBuilder(
              animation: _rotateAnimation,
              builder: (context, _) {
                return Positioned(
                  bottom: -screenWidth * 0.4,
                  right: -screenWidth * 0.3,
                  child: Transform.rotate(
                    angle: -_rotateAnimation.value * 2 * math.pi,
                    child: AnimatedBuilder(
                      animation: _glowAnimation,
                      builder: (context, _) {
                        return Container(
                          width: screenWidth * 1.2,
                          height: screenWidth * 1.2,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF4285f4).withOpacity(0.2 + _glowAnimation.value * 0.2),
                              width: 2,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),

            // Contenu principal
            Center(
              child: AnimatedBuilder(
                animation: Listenable.merge([_fadeAnimation, _scaleAnimation]),
                builder: (context, _) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo avec effets glow
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, _) {
                              return Transform.scale(
                                scale: _pulseAnimation.value,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Glow externe
                                    AnimatedBuilder(
                                      animation: _glowAnimation,
                                      builder: (context, _) {
                                        return Container(
                                          width: 300,
                                          height: 300,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: const Color(0xFF4285f4).withOpacity(0.3 + _glowAnimation.value * 0.4),
                                          ),
                                        );
                                      },
                                    ),
                                    // Glow moyen
                                    AnimatedBuilder(
                                      animation: _glowAnimation,
                                      builder: (context, _) {
                                        return Container(
                                          width: 260,
                                          height: 260,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: const Color(0xFF1a73e8).withOpacity(0.4 + _glowAnimation.value * 0.4),
                                          ),
                                        );
                                      },
                                    ),
                                    // Glow interne
                                    AnimatedBuilder(
                                      animation: _glowAnimation,
                                      builder: (context, _) {
                                        return Container(
                                          width: 220,
                                          height: 220,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: const Color(0xFF669df6).withOpacity(0.5 + _glowAnimation.value * 0.4),
                                          ),
                                        );
                                      },
                                    ),
                                    // Logo
                                    SizedBox(
                                      width: 180,
                                      height: 180,
                                      child: Center(
                                        child: Image.asset(
                                          'assets/images/tokse_logo.png',
                                          width: 140,
                                          height: 140,
                                          fit: BoxFit.contain,
                                          errorBuilder: (context, error, stackTrace) {
                                            // Fallback si l'image n'existe pas
                                            return const Icon(
                                              Icons.campaign,
                                              size: 120,
                                              color: Colors.white,
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          
                          const SizedBox(height: 60),

                          // Titre TOKSE avec soulignement
                          Column(
                            children: [
                              const Text(
                                'TOKSE',
                                style: TextStyle(
                                  fontSize: 64,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 8,
                                  shadows: [
                                    Shadow(
                                      color: Color(0xFF4285f4),
                                      blurRadius: 20,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: 120,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4285f4),
                                  borderRadius: BorderRadius.circular(2),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0xFF4285f4),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Sous-titre
                          const Text(
                            'DÉNONCER L\'INCIVISME',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 3,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Tagline avec drapeau
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.15),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                                child: const Center(
                                  child: Text(
                                    '🇧🇫',
                                    style: TextStyle(fontSize: 24),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Ensemble pour améliorer notre pays',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFFe3f2fd),
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 60),

                          // Barre de chargement
                          Column(
                            children: [
                              Container(
                                width: screenWidth * 0.8,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: AnimatedBuilder(
                                  animation: _pulseAnimation,
                                  builder: (context, _) {
                                    return FractionallySizedBox(
                                      alignment: Alignment.centerLeft,
                                      widthFactor: (_pulseAnimation.value - 1) * 10,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(3),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Colors.white,
                                              blurRadius: 8,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Chargement en cours...',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFFe3f2fd),
                                  letterSpacing: 1,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Particules décoratives
            AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, _) {
                return Positioned(
                  top: screenHeight * 0.15,
                  left: screenWidth * 0.1,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.3 + _glowAnimation.value * 0.3),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xFF4285f4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, _) {
                return Positioned(
                  top: screenHeight * 0.7,
                  right: screenWidth * 0.15,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2 + _glowAnimation.value * 0.3),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xFF4285f4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, _) {
                return Positioned(
                  bottom: screenHeight * 0.25,
                  left: screenWidth * 0.2,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.4 + _glowAnimation.value * 0.3),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xFF4285f4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            
            // Footer AMIR TECH en blanc sur le fond bleu
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Center(
                child: InkWell(
                  onTap: () async {
                    final Uri url = Uri.parse('https://amirtech.tech/');
                    try {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    } catch (e) {
                      // Ignorer l'erreur si le lancement échoue
                    }
                  },
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                      children: [
                        TextSpan(text: 'Crafted And developed By '),
                        TextSpan(
                          text: 'AMIR TECH',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _glowController.dispose();
    _rotateController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    // Fade animation (1 seconde)
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    // Scale animation avec effet elastique
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // Glow animation (pulsation 1.5 secondes)
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Rotation continue (20 secondes par tour)
    _rotateController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    _rotateAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_rotateController);

    // Pulse animation (2 secondes)
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Démarrer toutes les animations
    _fadeController.forward();
    _scaleController.forward();
    _rotateController.repeat();
    _glowController.repeat(reverse: true);
    _pulseController.repeat(reverse: true);

    // Navigation après 10 secondes
    Timer(const Duration(seconds: 10), () async {
      if (mounted) {
        await _fadeController.reverse();
        await _scaleController.animateTo(1.5);
        if (mounted) {
          // Vérifier si c'est la première ouverture
          await _checkFirstLaunch();
        }
      }
    });
  }

  /// Vérifie l'authentification et navigue vers l'écran approprié selon le rôle
  Future<void> _checkAuthAndNavigate() async {
    try {
      final authRepo = AuthRepository();
      final isAuth = await authRepo.isAuthenticated();
      
      if (!isAuth) {
        // Non authentifié → Sélection de profil
        if (mounted) {
          context.go('/profile-selection');
        }
        return;
      }
      
      // Authentifié → Récupérer le rôle de l'utilisateur
      final userId = await authRepo.getStoredUserId();
      if (userId == null) {
        if (mounted) {
          context.go('/profile-selection');
        }
        return;
      }
      
      final supabase = SupabaseConfig.client;
      final userResponse = await supabase
          .from('users')
          .select('role')
          .eq('id', userId)
          .single();
      
      final role = userResponse['role'] as String?;
      
      // Sauvegarder le dernier rôle dans SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_user_role', role ?? 'citizen');
      await prefs.setString('user_profile_type', role == 'citizen' || role == 'citoyen' || role == null ? 'citizen' : 'authority');
      
      if (mounted) {
        // Navigation conditionnelle selon le rôle
        if (role == 'citizen' || role == 'citoyen' || role == null) {
          context.go('/home');
        } else {
          // Autorité (police, hygiene, voirie, environnement, securite, etc.)
          context.go('/authority-home');
        }
      }
    } catch (e) {
      print('❌ [SPLASH] Erreur lors de la vérification auth: $e');
      if (mounted) {
        context.go('/profile-selection');
      }
    }
  }
  
  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    
    final hasAcceptedTerms = prefs.getBool('has_accepted_terms') ?? false;
    final profileType = prefs.getString('user_profile_type');
    final userId = prefs.getString('tokse_user_id'); // Vérifier si vraiment connecté
    
    print('🔍 TOKSE DEBUG: Vérification première ouverture...');
    print('🔍 hasAcceptedTerms = $hasAcceptedTerms');
    print('🔍 profileType = $profileType');
    print('🔍 userId = $userId');
    
    // IMPORTANT: Vérifier que l'utilisateur existe RÉELLEMENT dans la base de données
    bool userExistsInDB = false;
    if (userId != null && userId.isNotEmpty) {
      try {
        final response = await SupabaseConfig.client
            .from('users')
            .select('id')
            .eq('id', userId)
            .maybeSingle();
        userExistsInDB = response != null;
        print('🔍 userExistsInDB = $userExistsInDB');
      } catch (e) {
        print('❌ Erreur vérification utilisateur: $e');
        userExistsInDB = false;
      }
    }
    
    // Si l'utilisateur n'existe pas dans la DB, nettoyer les SharedPreferences
    if (!userExistsInDB && userId != null) {
      print('🧹 Nettoyage des SharedPreferences - utilisateur inexistant');
      await prefs.remove('tokse_user_id');
      await prefs.remove('tokse_user_phone');
      await prefs.remove('tokse_last_login');
      await prefs.remove('user_profile_type');
      await prefs.remove('last_user_role');
    }

    if (!hasAcceptedTerms && mounted) {
      // Première ouverture : afficher le dialogue des conditions
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => TermsConditionsDialog(
          onAccept: () async {
            // Enregistrer l'acceptation
            await prefs.setBool('has_accepted_terms', true);
            if (mounted) {
              Navigator.pop(context);
              // Vérifier si l'utilisateur est déjà authentifié
              final authRepo = AuthRepository();
              final isAuth = await authRepo.isAuthenticated();
              
              if (isAuth) {
                // Utilisateur déjà connecté → rediriger selon son rôle
                await _checkAuthAndNavigate();
              } else {
                // Nouvel utilisateur → afficher la sélection de profil
                context.go('/profile-selection');
              }
            }
          },
          onReject: () {
            // Afficher un message de confirmation avant de quitter
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => AlertDialog(
                title: const Text('Conditions requises'),
                content: const Text(
                  'Vous devez accepter les conditions d\'utilisation pour utiliser TOKSE.',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      // Fermer le dialogue de confirmation et le dialogue des termes
                      Navigator.pop(ctx);
                      // Le dialogue des termes reste ouvert, l'utilisateur peut les revoir
                    },
                    child: const Text('Revoir'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Fermer complètement l'application
                      SystemNavigator.pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('Quitter'),
                  ),
                ],
              ),
            );
          },
        ),
      );
    } else {
      // Pas la première ouverture : vérifier si utilisateur vraiment connecté ET existe en DB
      if (mounted) {
        // IMPORTANT: Vérifier que l'utilisateur existe RÉELLEMENT dans la base de données
        // Pas seulement dans SharedPreferences (qui peut persister après désinstallation)
        if (!userExistsInDB) {
          // Pas d'utilisateur connecté ou utilisateur n'existe plus → Afficher sélection de profil
          print('➡️ Redirection vers profile-selection (utilisateur non connecté ou inexistant)');
          context.go('/profile-selection');
        } else {
          // Utilisateur connecté ET existe en DB → Vérifier auth et rediriger selon rôle
          print('➡️ Utilisateur existe, vérification auth...');
          await _checkAuthAndNavigate();
        }
      }
    }
  }
}

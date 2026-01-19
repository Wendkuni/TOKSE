import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tokse_flutter/core/config/supabase_config.dart';
import 'package:tokse_flutter/core/utils/error_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class AgentLoginScreen extends StatefulWidget {
  const AgentLoginScreen({super.key});

  @override
  State<AgentLoginScreen> createState() => _AgentLoginScreenState();
}

class _AgentLoginScreenState extends State<AgentLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final supabase = SupabaseConfig.client;
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      print('🔐 [AGENT_LOGIN] Tentative connexion avec email: $email');

      // 1. Authentification Supabase
      final authResponse = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        print('❌ [AGENT_LOGIN] Authentification échouée - Pas d\'utilisateur');
        throw Exception('Email ou mot de passe incorrect');
      }

      print('✅ [AGENT_LOGIN] Auth réussie - User ID: ${authResponse.user!.id}');

      // 2. Vérifier que l'utilisateur est bien un agent
      print('🔍 [AGENT_LOGIN] Vérification du rôle agent...');
      final userResponse = await supabase
          .from('users')
          .select('id, role, is_active, nom, prenom, email, autorite_id')
          .eq('id', authResponse.user!.id)
          .single();

      print('📊 [AGENT_LOGIN] User data: $userResponse');

      // Vérifier que c'est une autorité (pas un citoyen)
      final role = userResponse['role'];
      final isAuthority = role == 'police' || role == 'hygiene' || role == 'voirie' || 
                          role == 'environnement' || role == 'securite' || role == 'mairie' || 
                          role == 'police_municipale' || role == 'agent';
      
      if (!isAuthority) {
        print('❌ [AGENT_LOGIN] Rôle incorrect: ${userResponse['role']}');
        await supabase.auth.signOut();
        throw Exception('Ce compte n\'est pas un compte opérateur');
      }

      if (userResponse['is_active'] != true) {
        print('❌ [AGENT_LOGIN] Compte désactivé');
        await supabase.auth.signOut();
        throw Exception(
            'Votre compte est désactivé. Contactez l\'administrateur.');
      }

      print('✅ [AGENT_LOGIN] Vérifications OK - Connexion acceptée');

      print('✅ [AGENT_LOGIN] Vérifications OK - Connexion acceptée');

      // 3. Stocker les informations de l'agent
      print('💾 [AGENT_LOGIN] Sauvegarde des données...');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('tokse_user_id', userResponse['id']);
      await prefs.setString('tokse_user_type', 'agent');
      await prefs.setString(
          'tokse_token', authResponse.session?.accessToken ?? '');
      await prefs.setString('agent_nom', userResponse['nom'] ?? '');
      await prefs.setString('agent_prenom', userResponse['prenom'] ?? '');
      await prefs.setString('agent_email', userResponse['email'] ?? '');
      if (userResponse['autorite_id'] != null) {
        await prefs.setString('agent_autorite_id', userResponse['autorite_id']);
      }
      
      // Sauvegarder le profil pour le splash screen
      await prefs.setString('user_profile_type', 'authority');
      await prefs.setString('last_user_role', userResponse['role'] ?? 'agent');

      print('✅ [AGENT_LOGIN] Données sauvegardées');
      print('🚀 [AGENT_LOGIN] Navigation vers /authority-home');

      if (mounted) {
        // Navigation vers l'interface agent
        context.go('/authority-home');
      }
    } catch (e) {
      print('❌ [AGENT_LOGIN] ERREUR: $e');
      setState(() {
        _errorMessage = ErrorHandler.getReadableMessage(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF7c3aed),
              Color(0xFF5b21b6),
              Color(0xFF4c1d95),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Bouton retour
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back,
                          color: Colors.white, size: 28),
                      onPressed: () => context.go('/profile-selection'),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Logo et titre
                  const Icon(
                    Icons.shield,
                    size: 80,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Connexion Opérateur',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Espace réservé aux opérateurs',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 60),

                  // Message d'erreur
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.red.shade900.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade400),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.white),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Champ Email
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: const TextStyle(color: Colors.white70),
                        prefixIcon:
                            const Icon(Icons.person, color: Colors.white70),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer votre email';
                        }
                        if (!value.contains('@')) {
                          return 'Email invalide';
                        }
                        return null;
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Champ Mot de passe
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Mot de passe',
                        labelStyle: const TextStyle(color: Colors.white70),
                        prefixIcon:
                            const Icon(Icons.lock, color: Colors.white70),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.white70,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer votre mot de passe';
                        }
                        if (value.length < 6) {
                          return 'Le mot de passe doit contenir au moins 6 caractères';
                        }
                        return null;
                      },
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Bouton de connexion
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF7c3aed),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF7c3aed)),
                              ),
                            )
                          : const Text(
                              'Se connecter',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Note informative
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.white70, size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Utilisez vos identifiants pour accéder à votre espace',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Footer AMIR TECH
                  Padding(
                    padding: const EdgeInsets.only(top: 60, bottom: 20),
                    child: InkWell(
                      onTap: () async {
                        final Uri url = Uri.parse('https://amirtech.tech/');
                        try {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        } catch (e) {
                          // Ignorer l'erreur
                        }
                      },
                      child: RichText(
                        textAlign: TextAlign.center,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

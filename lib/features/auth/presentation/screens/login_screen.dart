import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/utils/error_handler.dart';
import '../../data/repositories/auth_repository.dart';

// Classe pour les informations de pays
class Country {
  final String name;
  final String code;
  final String dialCode;
  final String flag;
  final int phoneLength;

  const Country({
    required this.name,
    required this.code,
    required this.dialCode,
    required this.flag,
    required this.phoneLength,
  });
}

// Liste des pays disponibles
final List<Country> countries = [
  const Country(
    name: 'Burkina Faso',
    code: 'BF',
    dialCode: '+226',
    flag: '🇧🇫',
    phoneLength: 8,
  ),
  const Country(
    name: 'Côte d\'Ivoire',
    code: 'CI',
    dialCode: '+225',
    flag: '🇨🇮',
    phoneLength: 10,
  ),
  const Country(
    name: 'Mali',
    code: 'ML',
    dialCode: '+223',
    flag: '🇲🇱',
    phoneLength: 8,
  ),
  const Country(
    name: 'Niger',
    code: 'NE',
    dialCode: '+227',
    flag: '🇳🇪',
    phoneLength: 8,
  ),
  const Country(
    name: 'Sénégal',
    code: 'SN',
    dialCode: '+221',
    flag: '🇸🇳',
    phoneLength: 9,
  ),
  const Country(
    name: 'Bénin',
    code: 'BJ',
    dialCode: '+229',
    flag: '🇧🇯',
    phoneLength: 8,
  ),
  const Country(
    name: 'Togo',
    code: 'TG',
    dialCode: '+228',
    flag: '🇹🇬',
    phoneLength: 8,
  ),
  const Country(
    name: 'France',
    code: 'FR',
    dialCode: '+33',
    flag: '🇫🇷',
    phoneLength: 9,
  ),
  const Country(
    name: 'Canada',
    code: 'CA',
    dialCode: '+1',
    flag: '🇨🇦',
    phoneLength: 10,
  ),
  const Country(
    name: 'États-Unis',
    code: 'US',
    dialCode: '+1',
    flag: '🇺🇸',
    phoneLength: 10,
  ),
];

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  final _authRepo = AuthRepository();
  Country _selectedCountry = countries[0]; // Burkina Faso par défaut

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sélectionnez votre pays',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: countries.length,
                itemBuilder: (context, index) {
                  final country = countries[index];
                  return ListTile(
                    leading: Text(
                      country.flag,
                      style: const TextStyle(fontSize: 32),
                    ),
                    title: Text(country.name),
                    trailing: Text(
                      country.dialCode,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1a73e8),
                      ),
                    ),
                    selected: _selectedCountry.code == country.code,
                    selectedTileColor: const Color(0xFF1a73e8).withOpacity(0.1),
                    onTap: () {
                      setState(() {
                        _selectedCountry = country;
                        _phoneController.clear();
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPhoneHint() {
    final length = _selectedCountry.phoneLength;
    final parts = <String>[];
    for (int i = 0; i < length; i += 2) {
      parts.add('XX');
    }
    return parts.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFF1a73e8),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Bouton retour
            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                    onPressed: () => context.go('/profile-selection'),
                  ),
                ),
              ),
            ),
            // Header avec logo
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              child: Column(
                children: [
                  Container(
                    color: const Color(0xFF1a73e8),
                    child: Image.asset(
                      'assets/images/tokse_logo.png',
                      width: 140,
                      height: 140,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.campaign,
                          size: 80,
                          color: Colors.white,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Signaler des problèmes urbains',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            
            // Contenu blanc
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(50),
                  topRight: Radius.circular(50),
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Connectez-vous pour rejoindre la communauté',
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    
                    Text(
                      'Numéro de téléphone',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Entrez le numéro avec lequel vous vous êtes inscrit',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    
                    Row(
                      children: [
                        InkWell(
                          onTap: _showCountryPicker,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: theme.dividerColor),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _selectedCountry.flag,
                                  style: const TextStyle(fontSize: 24),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _selectedCountry.dialCode,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: theme.primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_drop_down,
                                  color: theme.primaryColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            maxLength: _selectedCountry.phoneLength + (_selectedCountry.phoneLength ~/ 2),
                            decoration: InputDecoration(
                              hintText: _getPhoneHint(),
                              counterText: '',
                            ),
                            onChanged: (value) {
                              final formatted = _formatPhone(value);
                              if (formatted != value) {
                                _phoneController.value = TextEditingValue(
                                  text: formatted,
                                  selection: TextSelection.collapsed(
                                    offset: formatted.length,
                                  ),
                                );
                              }
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer votre numéro';
                              }
                              final cleaned = value.replaceAll(' ', '');
                              if (cleaned.length != _selectedCountry.phoneLength) {
                                return '${_selectedCountry.phoneLength} chiffres requis';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1a73e8), Color(0xFF4285f4)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Se connecter'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Vous n'avez pas de compte ? ",
                          style: theme.textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: () => context.push('/signup'),
                          child: const Text('S\'inscrire'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border(
                          left: BorderSide(
                            color: theme.primaryColor,
                            width: 4,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ℹ️ Connexion rapide',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Si vous avez déjà un compte, entrez simplement votre numéro de téléphone pour accéder à votre profil.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Footer AMIR TECH
            Padding(
              padding: const EdgeInsets.only(top: 80, bottom: 30),
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
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String _formatPhone(String text) {
    final cleaned = text.replaceAll(RegExp(r'\D'), '');
    final limited = cleaned.substring(0, cleaned.length > 8 ? 8 : cleaned.length);
    
    if (limited.isEmpty) return '';
    
    final buffer = StringBuffer();
    for (int i = 0; i < limited.length; i++) {
      if (i > 0 && i % 2 == 0) buffer.write(' ');
      buffer.write(limited[i]);
    }
    
    return buffer.toString();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final cleanedPhone = _phoneController.text.replaceAll(' ', '');
    if (cleanedPhone.length != 8) {
      _showError('Numéro de téléphone invalide (8 chiffres requis)');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final fullPhone = '${_selectedCountry.dialCode}$cleanedPhone';
      
      // Connexion simple sans OTP (vérification utilisateur existant)
      await _authRepo.signInWithPhone(fullPhone);
      
      // Récupérer le rôle de l'utilisateur
      final userId = await _authRepo.getStoredUserId();
      if (userId == null) {
        throw Exception('ID utilisateur non trouvé');
      }
      
      final supabase = SupabaseConfig.client;
      final userResponse = await supabase
          .from('users')
          .select('role')
          .eq('id', userId)
          .single();
      
      final role = userResponse['role'] as String?;
      
      // Sauvegarder le profil pour le splash screen
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_profile_type', role == 'citizen' || role == 'citoyen' || role == null ? 'citizen' : 'authority');
      await prefs.setString('last_user_role', role ?? 'citizen');
      
      if (mounted) {
        _showSuccess('Connexion réussie !');
        
        // Navigation conditionnelle selon le rôle
        if (role == 'citizen' || role == 'citoyen' || role == null) {
          context.go('/home');
        } else {
          // Autorité (police, hygiene, voirie, environnement, securite, etc.)
          context.go('/authority-home');
        }
      }
    } catch (e) {
      if (mounted) {
        _showError(ErrorHandler.getReadableMessage(e));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 28),
              SizedBox(width: 12),
              Text(
                'Erreur',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xFF1a73e8),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
}

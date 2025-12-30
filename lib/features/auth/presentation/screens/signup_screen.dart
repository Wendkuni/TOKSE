import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

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

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _authRepo = AuthRepository();

  bool _isLoading = false;
  bool _showOtpScreen = false;
  bool _otpLoading = false;
  Country _selectedCountry = countries[0]; // Burkina Faso par défaut

  @override
  Widget build(BuildContext context) {
    if (_showOtpScreen) {
      return _buildOtpScreen();
    }
    return _buildSignupForm();
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Widget _buildOtpScreen() {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // En-tête avec gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1a73e8), Color(0xFF4285f4)],
                ),
              ),
              padding: const EdgeInsets.only(
                top: 60,
                bottom: 40,
                left: 20,
                right: 20,
              ),
              child: const Column(
                children: [
                  Text('🔐', style: TextStyle(fontSize: 60)),
                  SizedBox(height: 12),
                  Text(
                    'Vérification',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 3,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Entrez le code que nous vous avions envoyé par SMS',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),

                  // Info sur l'envoi
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.green.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                      border: const Border(
                        left: BorderSide(color: Colors.green, width: 3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          color: Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Code envoyé au ${_phoneController.text}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Label Code OTP
                  Row(
                    children: [
                      Icon(Icons.security, size: 18, color: Colors.grey[700]),
                      const SizedBox(width: 6),
                      const Text(
                        'Code de vérification',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    enabled: !_otpLoading,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 8,
                      color: Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: '• • • • • •',
                      hintStyle: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 28,
                        letterSpacing: 12,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Colors.grey[300]!,
                          width: 1.5,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Colors.grey[300]!,
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFF1a73e8),
                          width: 2.0,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Aide visuelle
                  Text(
                    'Entrez le code à 6 chiffres reçu par SMS',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),

                  // Bouton Finaliser
                  Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1a73e8), Color(0xFF4285f4)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1a73e8).withAlpha(76),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _otpLoading ? null : _handleVerifyOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: _otpLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 20,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Finaliser l\'inscription',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Bouton Renvoyer le code
                  OutlinedButton(
                    onPressed: _otpLoading ? null : _handleSendOtp,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: const Color(0xFF1a73e8).withAlpha(76),
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.refresh, size: 18, color: Color(0xFF1a73e8)),
                        SizedBox(width: 8),
                        Text(
                          'Renvoyer le code',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1a73e8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Lien retour
                  Center(
                    child: TextButton(
                      onPressed: _otpLoading
                          ? null
                          : () {
                              setState(() => _showOtpScreen = false);
                            },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_back,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Modifier mes informations',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Footer AMIR TECH en blanc sur fond bleu
            Padding(
              padding: const EdgeInsets.only(top: 30, bottom: 20),
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
                    style: TextStyle(fontSize: 14, color: Colors.white70),
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

  Widget _buildSignupForm() {
    return Scaffold(
      backgroundColor: const Color(0xFF1a73e8),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // En-tête avec logo
            Padding(
              padding: const EdgeInsets.only(
                top: 60,
                bottom: 40,
                left: 20,
                right: 20,
              ),
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
                    'Rejoignez la communauté',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(50),
                  topRight: Radius.circular(50),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Créez votre compte pour signaler\nles problèmes de votre pays',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),

                  // Champ Nom
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 18,
                            color: Colors.grey[700],
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Nom',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _nomController,
                        enabled: !_isLoading,
                        textCapitalization: TextCapitalization.words,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Entrez votre nom',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontWeight: FontWeight.w400,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: Colors.grey[300]!,
                              width: 1.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: Colors.grey[300]!,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFF1a73e8),
                              width: 2.0,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Champ Prénom
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.badge_outlined,
                            size: 18,
                            color: Colors.grey[700],
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Prénom',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _prenomController,
                        enabled: !_isLoading,
                        textCapitalization: TextCapitalization.words,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Entrez votre prénom',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontWeight: FontWeight.w400,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: Colors.grey[300]!,
                              width: 1.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: Colors.grey[300]!,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFF1a73e8),
                              width: 2.0,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Champ Téléphone
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.phone_android,
                            size: 18,
                            color: Colors.grey[700],
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Numéro de téléphone',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: _showCountryPicker,
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFf72585).withAlpha(25),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFf72585).withAlpha(76),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _selectedCountry.flag,
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _selectedCountry.dialCode,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFf72585),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  const Icon(
                                    Icons.arrow_drop_down,
                                    color: Color(0xFFf72585),
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              enabled: !_isLoading,
                              maxLength: _selectedCountry.phoneLength + (_selectedCountry.phoneLength ~/ 2),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1.0,
                                color: Colors.black87,
                              ),
                              decoration: InputDecoration(
                                hintText: _getPhoneHint(),
                                hintStyle: TextStyle(
                                  color: Colors.grey[400],
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 1.5,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                counterText: '',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: Colors.grey[300]!,
                                    width: 1.5,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: Colors.grey[300]!,
                                    width: 1.5,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF1a73e8),
                                    width: 2.0,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
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
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Bouton Recevoir OTP
                  Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1a73e8), Color(0xFF4285f4)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1a73e8).withAlpha(76),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSendOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.verified_user,
                                  size: 20,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Recevoir le code OTP',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Lien vers connexion
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Vous avez un compte ? ',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          minimumSize: const Size(0, 32),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Se connecter',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFf72585),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Info box Sécurité
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0095C7).withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                      border: const Border(
                        left: BorderSide(color: Color(0xFF0095C7), width: 3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Color(0xFF0095C7),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Sécurité',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0095C7),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Votre numéro sera utilisé uniquement pour la vérification en deux étapes.',
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.4,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Footer AMIR TECH en blanc sur fond bleu
            Padding(
              padding: const EdgeInsets.only(top: 30, bottom: 20),
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
                    style: TextStyle(fontSize: 14, color: Colors.white70),
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

  String _formatPhone(String text) {
    final cleaned = text.replaceAll(RegExp(r'\D'), '');
    final limited = cleaned.substring(
      0,
      cleaned.length > _selectedCountry.phoneLength ? _selectedCountry.phoneLength : cleaned.length,
    );

    if (limited.isEmpty) return '';

    final buffer = StringBuffer();
    for (int i = 0; i < limited.length; i++) {
      if (i > 0 && i % 2 == 0) buffer.write(' ');
      buffer.write(limited[i]);
    }

    return buffer.toString();
  }

  String _getPhoneHint() {
    final length = _selectedCountry.phoneLength;
    final parts = <String>[];
    for (int i = 0; i < length; i += 2) {
      parts.add('XX');
    }
    return parts.join(' ');
  }

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

  Future<void> _handleSendOtp() async {
    if (_nomController.text.trim().isEmpty ||
        _prenomController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty) {
      _showError('Veuillez remplir tous les champs');
      return;
    }

    final cleanedPhone = _phoneController.text.replaceAll(' ', '');
    if (cleanedPhone.length != _selectedCountry.phoneLength) {
      _showError('Numéro de téléphone invalide (${_selectedCountry.phoneLength} chiffres requis)');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final fullPhone = '${_selectedCountry.dialCode}$cleanedPhone';
      await _authRepo.signUp(
        name: '${_nomController.text.trim()} ${_prenomController.text.trim()}',
        phone: fullPhone,
      );

      if (mounted) {
        _showSuccess('Code OTP envoyé');
        setState(() => _showOtpScreen = true);
      }
    } catch (e) {
      _showError(ErrorHandler.getReadableMessage(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleVerifyOtp() async {
    if (_otpController.text.trim().isEmpty) {
      _showError('Veuillez entrer le code OTP');
      return;
    }

    if (_otpController.text.trim().length != 6) {
      _showError('Le code OTP doit contenir 6 chiffres');
      return;
    }

    setState(() => _otpLoading = true);

    try {
      final cleanedPhone = _phoneController.text.replaceAll(' ', '');
      final fullPhone = '${_selectedCountry.dialCode}$cleanedPhone';

      // Vérifier le code OTP avec Supabase
      await _authRepo.verifyOtp(
        phone: fullPhone,
        token: _otpController.text.trim(),
      );

      if (mounted) {
        _showSuccess('Inscription réussie !');
        // Attendre un peu pour que l'utilisateur voie le message
        await Future.delayed(const Duration(milliseconds: 500));
        context.go('/home');
      }
    } catch (e) {
      _showError(ErrorHandler.getReadableMessage(e));
    } finally {
      if (mounted) setState(() => _otpLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }
}

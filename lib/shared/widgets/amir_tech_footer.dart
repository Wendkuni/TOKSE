import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AmirTechFooter extends StatelessWidget {
  const AmirTechFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: InkWell(
        onTap: _launchUrl,
        child: RichText(
          text: const TextSpan(
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            children: [
              TextSpan(text: 'Créé par '),
              TextSpan(
                text: 'AMIR TECH',
                style: TextStyle(
                  color: Color(0xFF1a73e8),
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl() async {
    final Uri url = Uri.parse('https://amirtech.tech/');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      // Si le lancement échoue, on ne fait rien (ou on peut afficher une erreur)
    }
  }
}

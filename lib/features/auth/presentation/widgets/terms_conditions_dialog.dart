import 'package:flutter/material.dart';

class TermsConditionsDialog extends StatelessWidget {
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const TermsConditionsDialog({
    super.key,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1a73e8).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.policy,
                    color: Color(0xFF1a73e8),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Conditions d\'utilisations',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'En utilisant TOKSE, vous acceptez de respecter les règles suivantes :',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    _buildBulletPoint('Utiliser l\'application de manière responsable et honnête.'),
                    _buildBulletPoint('Ne publier aucun contenu offensant ou mensonger.'),
                    _buildBulletPoint('Comprendre que TOKSE nécessite l\'accès à la localisation, à la caméra et au stockage pour fonctionner correctement.'),
                    _buildBulletPoint('Vous êtes responsable de l\'exactitude des signalements envoyés.'),
                    
                    const SizedBox(height: 20),
                    
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: const Text(
                        'En continuant, vous confirmez avoir lu et accepté nos Conditions d\'utilisations.',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1a73e8),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Link to full version
                    InkWell(
                      onTap: () => _showFullTerms(context),
                      child: const Row(
                        children: [
                          Icon(Icons.article_outlined, size: 18, color: Color(0xFF1a73e8)),
                          SizedBox(width: 8),
                          Text(
                            'Lire la version complète',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF1a73e8),
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Refuser',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1a73e8),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Accepter',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(Icons.check_circle, size: 20, color: Color(0xFF1a73e8)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullTermsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dernière mise à jour : ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 16),
        
        const Text(
          'Bienvenue sur TOKSE. En utilisant cette application, vous acceptez les conditions d\'utilisations décrites ci-dessous. Si vous n\'acceptez pas ces conditions, veuillez ne pas utiliser l\'application.',
          style: TextStyle(fontSize: 14, height: 1.6),
        ),
        const SizedBox(height: 20),
        
        _buildSection(
          '1. Objet de l\'application',
          'TOKSE est une plateforme permettant aux utilisateurs de signaler rapidement des situations d\'urgence, d\'insécurité, d\'incidents routiers ou de tout autre événement nécessitant une intervention.\nL\'application vise à améliorer la réactivité, la prévention et la sécurité.',
        ),
        
        _buildSection(
          '2. Obligations de l\'utilisateur',
          'En utilisant TOKSE, vous vous engagez à :\n\n• Fournir des informations réelles, exactes et vérifiables.\n• Ne jamais soumettre de faux signalements, de fausses alertes ou d\'informations volontairement erronées.\n• Ne pas utiliser l\'application pour nuire, harceler ou diffamer.\n• Respecter la loi et le cadre défini par les autorités locales.\n\nTout abus peut entraîner une suspension ou une suppression du compte.',
        ),
        
        _buildSection(
          '3. Permissions requises',
          'TOKSE a besoin de certaines autorisations pour fonctionner correctement :\n\n• Localisation : indispensable pour positionner les signalements sur la carte.\n• Caméra & Galerie : pour prendre ou joindre des photos/vidéos des incidents.\n• Stockage : pour enregistrer temporairement les médias avant envoi.\n\nSans l\'activation de ces permissions, certaines fonctions de l\'application seront impossibles à utiliser.',
        ),
        
        _buildSection(
          '4. Utilisation des données',
          'Vos données (localisation, photos, informations de signalement) sont utilisées uniquement pour :\n\n• transmettre l\'incident aux services concernés,\n• améliorer la précision et la sécurité des interventions,\n• établir des statistiques anonymes.\n\nNous ne vendons aucune donnée à des tiers.',
        ),
        
        _buildSection(
          '5. Responsabilité',
          'TOKSE ne peut être tenue responsable :\n\n• des signalements erronés ou mensongers fournis par les utilisateurs,\n• des conséquences d\'une mauvaise utilisation de l\'application,\n• des retards, erreurs techniques ou indisponibilités du service.\n\nL\'utilisateur reste seul responsable des informations qu\'il soumet.',
        ),
        
        _buildSection(
          '6. Interdictions',
          'Il est strictement interdit de :\n\n• communiquer de fausses alertes,\n• publier du contenu violent, offensant, discriminatoire ou illégal,\n• utiliser TOKSE pour surveiller, espionner ou suivre des personnes,\n• tenter d\'exploiter, pirater ou modifier l\'application.',
        ),
        
        _buildSection(
          '7. Suspension et résiliation',
          'Nous nous réservons le droit de suspendre ou supprimer l\'accès à TOKSE en cas de :\n\n• non-respect des règles,\n• signalements abusifs ou frauduleux,\n• comportement dangereux ou illégal.',
        ),
        
        _buildSection(
          '8. Modifications des conditions',
          'Les présentes conditions peuvent être modifiées à tout moment. L\'utilisateur sera informé en cas de changement important.',
        ),
      ],
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1a73e8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(fontSize: 14, height: 1.6),
          ),
        ],
      ),
    );
  }

  void _showFullTerms(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1a73e8).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.article,
                      color: Color(0xFF1a73e8),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Conditions d\'utilisations complètes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFullTermsContent(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Boutons Refuser et Accepter
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        onReject();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Refuser',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        onAccept();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1a73e8),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Accepter',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

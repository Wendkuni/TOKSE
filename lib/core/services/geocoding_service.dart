import 'dart:async';
import 'dart:convert';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;

/// Service de géocodage avec OpenStreetMap/Nominatim
class GeocodingService {
  // Nominatim API (OpenStreetMap) - Gratuit et illimité
  static const String _nominatimUrl = 'https://nominatim.openstreetmap.org';
  
  /// Obtenir l'adresse complète avec quartier et ville
  /// Utilise OpenStreetMap/Nominatim uniquement
  static Future<AddressResult> getAddress({
    required double latitude,
    required double longitude,
  }) async {
    print('📍 [GEOCODING] Récupération adresse pour: $latitude, $longitude');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    // 1. Utiliser Nominatim (OpenStreetMap)
    print('🌍 [GEOCODING] Utilisation OpenStreetMap/Nominatim...');
    try {
      final result = await _getAddressFromNominatim(latitude, longitude);
      if (result != null) {
        print('✅ [GEOCODING] Nominatim a répondu avec succès');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return result;
      }
      print('⚠️ [GEOCODING] Nominatim n\'a rien retourné');
    } catch (e) {
      print('❌ [GEOCODING] Erreur Nominatim: $e');
    }
    
    // 2. Fallback : Geocoding standard (ville uniquement, sans quartier)
    print('📦 [GEOCODING] Fallback: geocoding standard...');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    try {
      final result = await _getAddressFromGeocoding(latitude, longitude);
      return AddressResult(
        quartier: 'Quartier indisponible',
        ville: result.ville,
        latitude: latitude,
        longitude: longitude,
        source: 'Geocoding standard',
      );
    } catch (e) {
      return AddressResult(
        quartier: 'Quartier indisponible',
        ville: null,
        latitude: latitude,
        longitude: longitude,
        source: 'Aucun service disponible',
      );
    }
  }
  
  /// Récupérer l'adresse via Nominatim (OpenStreetMap) - GRATUIT
  static Future<AddressResult?> _getAddressFromNominatim(
    double latitude,
    double longitude,
  ) async {
    final url = Uri.parse(
      '$_nominatimUrl/reverse'
      '?lat=$latitude'
      '&lon=$longitude'
      '&format=json'
      '&addressdetails=1'
      '&accept-language=fr', // Résultats en français
    );
    
    print('🌍 [GEOCODING] Appel Nominatim (OSM)...');
    
    try {
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'TOKSE-App/1.0', // Requis par Nominatim
        },
      ).timeout(
        const Duration(seconds: 10), // Timeout de 10 secondes
        onTimeout: () {
          print('⏱️ [GEOCODING] Nominatim timeout');
          throw TimeoutException('Nominatim timeout');
        },
      );
      
      if (response.statusCode != 200) {
        print('❌ [GEOCODING] Nominatim erreur: ${response.statusCode}');
        return null;
      }
      
      final data = json.decode(response.body);
      
      // LOG COMPLET de la réponse Nominatim pour diagnostic
      print('📦 [GEOCODING] RÉPONSE COMPLÈTE Nominatim:');
      print(json.encode(data));
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      if (data['error'] != null) {
        print('❌ [GEOCODING] Nominatim: ${data['error']}');
        return null;
      }
      
      final address = data['address'] as Map<String, dynamic>?;
      if (address == null) {
        print('❌ [GEOCODING] Nominatim: pas d\'adresse');
        return null;
      }
      
      print('🔍 [GEOCODING] Composants Nominatim trouvés:');
      address.forEach((key, value) {
        print('  - $key: $value');
      });
      
      String? quartier;
      String? ville;
      
      // Extraire le quartier - ORDRE PRÉCIS pour Burkina Faso
      final quartierCandidates = [
        address['neighbourhood'],    // Voisinage (priorité 1)
        address['suburb'],           // Banlieue/quartier (priorité 2)
        address['city_district'],    // District de la ville (priorité 3)
      ];
      
      // Prendre le premier candidat valide
      for (final candidate in quartierCandidates) {
        if (candidate != null && 
            candidate.toString().trim().isNotEmpty &&
            candidate.toString().length > 2) { // Au moins 3 caractères
          quartier = candidate.toString();
          print('✅ [GEOCODING] Quartier trouvé via: ${quartierCandidates.indexOf(candidate) == 0 ? "neighbourhood" : quartierCandidates.indexOf(candidate) == 1 ? "suburb" : "city_district"}');
          break;
        }
      }
      
      // Extraire la ville - SIMPLE
      ville = address['city']?.toString();
      
      print('🏘️ [GEOCODING] Nominatim - Quartier: ${quartier ?? "NON TROUVÉ"}');
      print('🏙️ [GEOCODING] Nominatim - Ville: ${ville ?? "NON TROUVÉE"}');
      
      // Si on a trouvé un quartier ou une ville, retourner le résultat
      if (quartier != null || ville != null) {
        return AddressResult(
          quartier: quartier,
          ville: ville,
          latitude: latitude,
          longitude: longitude,
          source: 'Nominatim (OSM)',
        );
      }
      
      // Si rien trouvé, retourner null pour passer au fallback
      print('⚠️ [GEOCODING] Nominatim n\'a rien trouvé');
      return null;
    } catch (e) {
      print('❌ [GEOCODING] Erreur Nominatim: $e');
      return null;
    }
  }
  
  /// Récupérer l'adresse via le package geocoding standard (fallback)
  static Future<AddressResult> _getAddressFromGeocoding(
    double latitude,
    double longitude,
  ) async {
    print('📍 [GEOCODING] Utilisation geocoding standard...');
    
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      
      if (placemarks.isEmpty) {
        return AddressResult(
          quartier: null,
          ville: null,
          latitude: latitude,
          longitude: longitude,
          source: 'Coordonnées GPS',
        );
      }
      
      final place = placemarks.first;
      
      print('🔍 [GEOCODING] Détails placemark:');
      print('  - street: ${place.street}');
      print('  - thoroughfare: ${place.thoroughfare}');
      print('  - subThoroughfare: ${place.subThoroughfare}');
      print('  - subLocality: ${place.subLocality}');
      print('  - locality: ${place.locality}');
      print('  - subAdministrativeArea: ${place.subAdministrativeArea}');
      print('  - administrativeArea: ${place.administrativeArea}');
      
      // Détecter les rues numérotées pour les filtrer
      final rueNumeroteePattern = RegExp(
        r'^(rue|avenue|av\.|av)\s*\d+(\.\d+)?$',
        caseSensitive: false,
      );
      
      if (place.thoroughfare != null && rueNumeroteePattern.hasMatch(place.thoroughfare!)) {
        print('⚠️ [GEOCODING] Rue numérotée détectée et ignorée: ${place.thoroughfare}');
      }
      if (place.street != null && rueNumeroteePattern.hasMatch(place.street!)) {
        print('⚠️ [GEOCODING] Rue numérotée détectée et ignorée: ${place.street}');
      }
      
      String? quartier;
      String? ville;
      
      // 1. Déterminer la ville
      if (place.locality != null && place.locality!.isNotEmpty) {
        ville = place.locality;
      } else if (place.subAdministrativeArea != null && 
                 place.subAdministrativeArea!.isNotEmpty) {
        ville = place.subAdministrativeArea;
      } else if (place.administrativeArea != null && 
                 place.administrativeArea!.isNotEmpty) {
        ville = place.administrativeArea;
      }
      
      // 2. Déterminer le quartier (différent de la ville)
      // Priorité: subLocality > subAdministrativeArea (si différent de ville)
      // On IGNORE thoroughfare et street car souvent c'est juste "rue 21.3"
      
      final candidatesQuartier = [
        place.subLocality,  // Quartier spécifique (priorité 1)
        // Si pas de subLocality, essayer subAdministrativeArea si différent de ville
        (place.subAdministrativeArea != ville) ? place.subAdministrativeArea : null,
      ];
      
      for (final candidate in candidatesQuartier) {
        if (candidate != null && 
            candidate.isNotEmpty && 
            candidate != ville &&
            !RegExp(r'^\d+$').hasMatch(candidate) && // Pas juste un nombre
            !rueNumeroteePattern.hasMatch(candidate)) { // Pas une rue numérotée
          quartier = candidate;
          break;
        }
      }
      
      // Si toujours pas de quartier, essayer thoroughfare/street 
      // SEULEMENT si ce n'est PAS une rue numérotée
      if (quartier == null) {
        for (final candidate in [place.thoroughfare, place.street]) {
          if (candidate != null && 
              candidate.isNotEmpty && 
              candidate != ville &&
              !rueNumeroteePattern.hasMatch(candidate) &&
              candidate.length > 5) { // Au moins 5 caractères (évite "Rue 1")
            quartier = candidate;
            break;
          }
        }
      }
      
      print('🏘️ [GEOCODING] Standard - Quartier: ${quartier ?? "NON TROUVÉ"}');
      print('🏙️ [GEOCODING] Standard - Ville: ${ville ?? "NON TROUVÉE"}');
      
      return AddressResult(
        quartier: quartier,
        ville: ville,
        latitude: latitude,
        longitude: longitude,
        source: 'Geocoding standard',
      );
    } catch (e) {
      print('❌ [GEOCODING] Erreur: $e');
      return AddressResult(
        quartier: null,
        ville: null,
        latitude: latitude,
        longitude: longitude,
        source: 'Erreur',
      );
    }
  }
}

/// Résultat de géocodage
class AddressResult {
  final String? quartier;
  final String? ville;
  final double latitude;
  final double longitude;
  final String source;
  
  AddressResult({
    required this.quartier,
    required this.ville,
    required this.latitude,
    required this.longitude,
    required this.source,
  });
  
  /// Obtenir l'adresse formatée "Quartier, Ville"
  String getFormattedAddress() {
    print('🔤 [FORMAT] Formatage adresse...');
    print('   - Quartier brut: "$quartier"');
    print('   - Ville brute: "$ville"');
    
    final parts = <String>[];
    
    if (quartier != null && quartier!.isNotEmpty) {
      parts.add(quartier!);
      print('   ✅ Quartier ajouté: "${quartier!}"');
    } else {
      print('   ❌ Pas de quartier');
    }
    
    if (ville != null && ville!.isNotEmpty) {
      parts.add(ville!);
      print('   ✅ Ville ajoutée: "${ville!}"');
    } else {
      print('   ❌ Pas de ville');
    }
    
    if (parts.isEmpty) {
      // Si pas d'adresse, retourner les coordonnées
      final coords = '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
      print('   ⚠️ Aucune adresse → Coordonnées: $coords');
      return coords;
    }
    
    final result = parts.join(', ');
    print('   ✅ Résultat final: "$result"');
    return result;
  }
  
  @override
  String toString() {
    return 'AddressResult(quartier: $quartier, ville: $ville, source: $source)';
  }
}

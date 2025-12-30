import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Service de routage avec OSRM (Open Source Routing Machine)
/// API gratuite sans clé requise
class RoutingService {
  static const String _osrmBaseUrl = 'https://router.project-osrm.org';

  /// Calculer l'itinéraire entre deux points
  /// Retourne: points de la route, distance (m), durée (s), instructions
  Future<RouteResult?> getRoute({
    required LatLng start,
    required LatLng end,
  }) async {
    try {
      // Valider les coordonnées avant d'appeler l'API
      if (start.latitude == end.latitude && start.longitude == end.longitude) {
        print('⚠️ [ROUTING] Position de départ et d\'arrivée identiques');
        return null;
      }

      // Construire l'URL OSRM avec paramètres optimisés
      // Format: /route/v1/driving/{lon},{lat};{lon},{lat}?overview=full&steps=true
      // alternatives=false : ne retourne que la route la plus courte
      // continue_straight=false : permet les demi-tours si plus court
      final url = Uri.parse(
        '$_osrmBaseUrl/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&steps=true&geometries=geojson&alternatives=false&continue_straight=false',
      );

      print(
          '🗺️ [ROUTING] Calcul itinéraire OSRM de (${start.latitude},${start.longitude}) à (${end.latitude},${end.longitude})');

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: serveur OSRM ne répond pas');
        },
      );

      if (response.statusCode != 200) {
        try {
          final errorData = jsonDecode(response.body);
          print('⚠️ [ROUTING] Erreur ${response.statusCode}: ${errorData['code']} - ${errorData['message']}');
          
          // Pour NoRoute, retourner null sans exception (le fallback s'occupera de l'affichage)
          if (response.statusCode == 400 && errorData['code'] == 'NoRoute') {
            print('⚠️ [ROUTING] Aucune route trouvée, le fallback ligne droite sera utilisé');
            return null;
          }
        } catch (e) {
          print('❌ [ROUTING] Erreur ${response.statusCode}: ${response.body}');
        }
        
        return null;
      }

      final data = jsonDecode(response.body);

      if (data['code'] != 'Ok') {
        print('⚠️ [ROUTING] Code OSRM: ${data['code']} - ${data['message'] ?? 'Pas de message'}');
        
        // Pour NoRoute, retourner null proprement
        if (data['code'] == 'NoRoute') {
          print('⚠️ [ROUTING] Aucune route disponible entre ces points');
          return null;
        }
        
        return null;
      }

      final route = data['routes'][0];
      final legs = route['legs'][0];

      // Extraire les points de la géométrie
      final geometry = route['geometry']['coordinates'] as List;
      final points = geometry
          .map((coord) => LatLng(coord[1] as double, coord[0] as double))
          .toList();

      // Extraire les instructions
      final steps = legs['steps'] as List;
      final instructions = steps.map((step) {
        final maneuver = step['maneuver'];
        final type = maneuver['type'] as String;
        final distance = (step['distance'] as num).toDouble();
        final duration = (step['duration'] as num).toDouble();

        return NavigationInstruction(
          type: type,
          instruction: _getInstructionText(type, maneuver),
          distance: distance,
          duration: duration,
        );
      }).toList();

      final distance = (route['distance'] as num).toDouble();
      final duration = (route['duration'] as num).toDouble();

      print(
          '✅ [ROUTING] Itinéraire calculé: ${distance.round()}m, ${(duration / 60).round()} min, ${points.length} points');

      return RouteResult(
        points: points,
        distance: distance,
        duration: duration,
        instructions: instructions,
      );
    } catch (e) {
      print('❌ [ROUTING] Erreur: $e');
      return null;
    }
  }

  /// Convertir le type de manœuvre en instruction textuelle
  String _getInstructionText(String type, Map<String, dynamic> maneuver) {
    final modifier = maneuver['modifier'] as String?;

    switch (type) {
      case 'depart':
        return 'Départ';
      case 'arrive':
        return 'Arrivée à destination';
      case 'turn':
        if (modifier == 'left') return 'Tournez à gauche';
        if (modifier == 'right') return 'Tournez à droite';
        if (modifier == 'sharp left') return 'Tournez fortement à gauche';
        if (modifier == 'sharp right') return 'Tournez fortement à droite';
        if (modifier == 'slight left') return 'Tournez légèrement à gauche';
        if (modifier == 'slight right') return 'Tournez légèrement à droite';
        return 'Tournez';
      case 'continue':
        return 'Continuez tout droit';
      case 'merge':
        return 'Rejoignez la route';
      case 'roundabout':
        return 'Prenez le rond-point';
      case 'rotary':
        return 'Prenez le carrefour giratoire';
      default:
        return 'Continuez';
    }
  }
}

/// Résultat d'un calcul d'itinéraire
class RouteResult {
  final List<LatLng> points;
  final double distance; // en mètres
  final double duration; // en secondes
  final List<NavigationInstruction> instructions;

  RouteResult({
    required this.points,
    required this.distance,
    required this.duration,
    required this.instructions,
  });
}

/// Instruction de navigation
class NavigationInstruction {
  final String type;
  final String instruction;
  final double distance; // en mètres
  final double duration; // en secondes

  NavigationInstruction({
    required this.type,
    required this.instruction,
    required this.distance,
    required this.duration,
  });

  @override
  String toString() => instruction;
}

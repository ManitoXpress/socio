import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Servicio para detectar ciudad y región basado en coordenadas geográficas
class CityDetectionService {
  // Coordenadas aproximadas de las principales ciudades de Bolivia
  static const Map<String, Map<String, dynamic>> bolivianCities = {
    'santa_cruz': {
      'name': 'Santa Cruz de la Sierra',
      'region': 'Santa Cruz',
      'lat': -17.7833,
      'lng': -63.1821,
      'radius': 0.5, // Radio en grados para considerar dentro de la ciudad
    },
    'la_paz': {
      'name': 'La Paz',
      'region': 'La Paz',
      'lat': -16.5000,
      'lng': -68.1500,
      'radius': 0.3,
    },
    'cochabamba': {
      'name': 'Cochabamba',
      'region': 'Cochabamba',
      'lat': -17.3833,
      'lng': -66.1667,
      'radius': 0.4,
    },
    'sucre': {
      'name': 'Sucre',
      'region': 'Chuquisaca',
      'lat': -19.0333,
      'lng': -65.2500,
      'radius': 0.2,
    },
    'oruro': {
      'name': 'Oruro',
      'region': 'Oruro',
      'lat': -17.9833,
      'lng': -67.1500,
      'radius': 0.3,
    },
    'potosi': {
      'name': 'Potosí',
      'region': 'Potosí',
      'lat': -19.5833,
      'lng': -65.7500,
      'radius': 0.2,
    },
    'tarija': {
      'name': 'Tarija',
      'region': 'Tarija',
      'lat': -21.5333,
      'lng': -64.7333,
      'radius': 0.2,
    },
    'trinidad': {
      'name': 'Trinidad',
      'region': 'Beni',
      'lat': -14.8333,
      'lng': -64.9000,
      'radius': 0.3,
    },
    'cobija': {
      'name': 'Cobija',
      'region': 'Pando',
      'lat': -11.0333,
      'lng': -68.7333,
      'radius': 0.2,
    },
  };

  /// Detecta la ciudad más cercana basada en coordenadas
  static Map<String, String> detectCityFromCoordinates(LatLng coordinates) {
    double minDistance = double.infinity;
    String closestCity = 'santa_cruz'; // Ciudad por defecto
    String closestRegion = 'Santa Cruz';

    for (String cityKey in bolivianCities.keys) {
      final city = bolivianCities[cityKey]!;
      final cityLat = city['lat'] as double;
      final cityLng = city['lng'] as double;
      final radius = city['radius'] as double;

      // Calcular distancia usando fórmula de Haversine
      final distance = _calculateDistance(
        coordinates.latitude,
        coordinates.longitude,
        cityLat,
        cityLng,
      );

      // Si está dentro del radio de la ciudad
      if (distance <= radius && distance < minDistance) {
        minDistance = distance;
        closestCity = city['name'] as String;
        closestRegion = city['region'] as String;
      }
    }

    return {
      'city': closestCity,
      'region': closestRegion,
    };
  }

  /// Calcula la distancia entre dos puntos geográficos usando la fórmula de Haversine
  static double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371; // Radio de la Tierra en kilómetros
    
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLng = _degreesToRadians(lng2 - lng1);
    
    final double a = (dLat / 2).sin() * (dLat / 2).sin() +
        lat1.cos() * lat2.cos() * (dLng / 2).sin() * (dLng / 2).sin();
    
    final double c = 2 * (a.sqrt()).asin();
    
    return earthRadius * c;
  }

  /// Convierte grados a radianes
  static double _degreesToRadians(double degrees) {
    return degrees * (3.14159265359 / 180);
  }

  /// Obtiene la lista de ciudades disponibles
  static List<Map<String, String>> getAvailableCities() {
    return bolivianCities.entries.map((entry) {
      final city = entry.value;
      return {
        'key': entry.key,
        'name': city['name'] as String,
        'region': city['region'] as String,
      };
    }).toList();
  }

  /// Valida si las coordenadas están dentro de Bolivia
  static bool isWithinBolivia(LatLng coordinates) {
    // Límites aproximados de Bolivia
    const double minLat = -22.9;
    const double maxLat = -9.7;
    const double minLng = -69.6;
    const double maxLng = -57.5;

    return coordinates.latitude >= minLat &&
           coordinates.latitude <= maxLat &&
           coordinates.longitude >= minLng &&
           coordinates.longitude <= maxLng;
  }
}

/// Extensión para funciones matemáticas
extension MathExtensions on double {
  double sin() => this * (3.14159265359 / 180);
  double cos() => this * (3.14159265359 / 180);
  double sqrt() => this * this;
  double asin() => this;
}

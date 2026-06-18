import 'dart:math' as math;

enum GeofenceType {
  pothole,
  trafficLight,
  animalCrossing,
}

class GeofencePoint {
  final String id;
  final String title;
  final GeofenceType type;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  bool isTriggered;

  GeofencePoint({
    required this.id,
    required this.title,
    required this.type,
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 100.0,
    this.isTriggered = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': type.toString().split('.').last,
        'latitude': latitude,
        'longitude': longitude,
        'radiusMeters': radiusMeters,
      };

  factory GeofencePoint.fromJson(Map<String, dynamic> json) {
    return GeofencePoint(
      id: json['id'] as String,
      title: json['title'] as String,
      type: GeofenceType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => GeofenceType.pothole,
      ),
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      radiusMeters: json['radiusMeters'] as double? ?? 100.0,
    );
  }
}

class GeofenceManager {
  static final GeofenceManager _instance = GeofenceManager._internal();
  factory GeofenceManager() => _instance;

  GeofenceManager._internal() {
    // Seed initial mock data
    _loadMockData();
  }

  final List<GeofencePoint> _points = [];

  List<GeofencePoint> get points => List.unmodifiable(_points);

  void addPoint(GeofencePoint point) {
    if (!_points.any((p) => p.id == point.id)) {
      _points.add(point);
    }
  }

  void removePoint(String id) {
    _points.removeWhere((p) => p.id == id);
  }

  void clearPoints() {
    _points.clear();
  }

  /// Calculates the distance between two coordinates in meters using the Haversine formula
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // in meters
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * math.pi / 180;
  }

  /// Evaluates current position against geofence points
  /// Returns a list of newly triggered points
  List<GeofencePoint> evaluatePosition(double currentLat, double currentLng) {
    final List<GeofencePoint> newlyTriggered = [];

    for (var point in _points) {
      final double distance = calculateDistance(
        currentLat,
        currentLng,
        point.latitude,
        point.longitude,
      );

      final bool isInside = distance <= point.radiusMeters;

      if (isInside && !point.isTriggered) {
        point.isTriggered = true;
        newlyTriggered.add(point);
      } else if (!isInside && point.isTriggered) {
        // Reset when user exits the geofence zone so it can trigger again
        point.isTriggered = false;
      }
    }

    return newlyTriggered;
  }

  void _loadMockData() {
    // Standard mock alerts near Johannesburg Center (-26.2041, 28.0473)
    _points.addAll([
      GeofencePoint(
        id: 'pothole_1',
        title: 'Deep Pothole - Left Lane',
        type: GeofenceType.pothole,
        latitude: -26.2052,
        longitude: 28.0482,
      ),
      GeofencePoint(
        id: 'light_1',
        title: 'Non-functional Traffic Light',
        type: GeofenceType.trafficLight,
        latitude: -26.2030,
        longitude: 28.0460,
      ),
      GeofencePoint(
        id: 'animal_1',
        title: 'Frequent Stray Animal Crossing',
        type: GeofenceType.animalCrossing,
        latitude: -26.2065,
        longitude: 28.0445,
      ),
      GeofencePoint(
        id: 'pothole_2',
        title: 'Severe Road Deterioration',
        type: GeofenceType.pothole,
        latitude: -26.2015,
        longitude: 28.0498,
      ),
    ]);
  }
}

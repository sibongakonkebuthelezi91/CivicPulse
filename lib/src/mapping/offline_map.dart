import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:latlong2/latlong.dart';
import '../location/geofence_manager.dart';

class OfflineMap extends StatefulWidget {
  final LatLng? userLocation;
  final double? userSpeed;
  final List<GeofencePoint> alertPoints;
  final Function(GeofencePoint) onPointTapped;

  const OfflineMap({
    super.key,
    required this.userLocation,
    required this.userSpeed,
    required this.alertPoints,
    required this.onPointTapped,
  });

  @override
  State<OfflineMap> createState() => _OfflineMapState();
}

class _OfflineMapState extends State<OfflineMap> {
  // In-memory tile cache — persists for the entire app session.
  // Survives screen rebuilds; tiles downloaded once are served instantly on
  // revisit without any additional disk-store package.
  final CacheStore _cacheStore = MemCacheStore(
    maxSize: 50 * 1024 * 1024, // 50 MB cap
    maxEntrySize: 2 * 1024 * 1024, // 2 MB per tile (well above typical 30–80 KB)
  );

  final MapController _mapController = MapController();

  // Johannesburg Centre — default camera if GPS not yet acquired
  final LatLng _defaultCenter = const LatLng(-26.2041, 28.0473);

  @override
  void didUpdateWidget(covariant OfflineMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Pan to user on first GPS fix
    if (oldWidget.userLocation == null && widget.userLocation != null) {
      _mapController.move(widget.userLocation!, 15.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final center = widget.userLocation ?? _defaultCenter;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 15.0,
        maxZoom: 18.0,
        minZoom: 10.0,
      ),
      children: [
        // ── Tile layer with session-scoped memory cache ─────────────────────
        // Uses CartoDB Dark Matter (no API key required) so the map looks
        // premium out-of-the-box. Tiles are fetched from the network on first
        // load and served from MemCacheStore on subsequent requests.
        TileLayer(
          urlTemplate: 'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.makoya.civicpulse',
          tileProvider: CachedTileProvider(
            store: _cacheStore,
            // Serve stale cache when offline; fetch fresh copy when online
            cachePolicy: CachePolicy.forceCache,
          ),
        ),

        // ── Geofence radius circles (100 m warning rings) ───────────────────
        CircleLayer(
          circles: widget.alertPoints.map((point) {
            Color circleColor;
            Color strokeColor;

            switch (point.type) {
              case GeofenceType.trafficLight:
                circleColor = Colors.amber.withOpacity(0.12);
                strokeColor = Colors.amber.withOpacity(0.45);
                break;
              case GeofenceType.animalCrossing:
                circleColor = Colors.orange.withOpacity(0.12);
                strokeColor = Colors.orange.withOpacity(0.45);
                break;
              case GeofenceType.pothole:
              default:
                circleColor = Colors.red.withOpacity(0.12);
                strokeColor = Colors.red.withOpacity(0.45);
                break;
            }

            return CircleMarker(
              point: LatLng(point.latitude, point.longitude),
              radius: point.radiusMeters,
              useRadiusInMeter: true,
              color: circleColor,
              borderColor: strokeColor,
              borderStrokeWidth: 1.5,
            );
          }).toList(),
        ),

        // ── Markers: user position + hazard pins ─────────────────────────────
        MarkerLayer(
          markers: [
            // User location — animated pulse ring + solid blue dot
            if (widget.userLocation != null) ...[
              Marker(
                point: widget.userLocation!,
                width: 36.0,
                height: 36.0,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.8, end: 1.25),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeInOut,
                  builder: (context, value, _) => Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blueAccent.withOpacity(0.25 * (2.0 - value)),
                    ),
                  ),
                ),
              ),
              Marker(
                point: widget.userLocation!,
                width: 16.0,
                height: 16.0,
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blueAccent,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue,
                        blurRadius: 8.0,
                        spreadRadius: 2.0,
                      ),
                    ],
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(3.0),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],

            // Hazard pins
            ...widget.alertPoints.map((point) {
              IconData markerIcon;
              Color markerColor;

              switch (point.type) {
                case GeofenceType.trafficLight:
                  markerIcon = Icons.traffic_rounded;
                  markerColor = Colors.amber;
                  break;
                case GeofenceType.animalCrossing:
                  markerIcon = Icons.pets_rounded;
                  markerColor = Colors.orangeAccent;
                  break;
                case GeofenceType.pothole:
                default:
                  markerIcon = Icons.warning_amber_rounded;
                  markerColor = Colors.redAccent;
                  break;
              }

              return Marker(
                point: LatLng(point.latitude, point.longitude),
                width: 45.0,
                height: 45.0,
                child: GestureDetector(
                  onTap: () => widget.onPointTapped(point),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[900]?.withOpacity(0.92),
                      shape: BoxShape.circle,
                      border: Border.all(color: markerColor, width: 2.0),
                      boxShadow: [
                        BoxShadow(
                          color: markerColor.withOpacity(0.5),
                          blurRadius: 8.0,
                          spreadRadius: 1.0,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(markerIcon, color: markerColor, size: 20.0),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }
}

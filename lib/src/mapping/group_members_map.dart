import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../features/safety/screens/groups_screen.dart';

class GroupMemberLocation {
  final String memberId;
  final String memberName;
  final double latitude;
  final double longitude;
  final DateTime lastUpdated;
  final bool isOnline;

  GroupMemberLocation({
    required this.memberId,
    required this.memberName,
    required this.latitude,
    required this.longitude,
    required this.lastUpdated,
    this.isOnline = true,
  });

  LatLng get position => LatLng(latitude, longitude);
}

class GroupMembersMap extends StatefulWidget {
  final WalkingGroup group;
  final List<GroupMemberLocation> memberLocations;
  final LatLng? userLocation;
  final Function(String memberId, String memberName)? onMemberTapped;

  const GroupMembersMap({
    super.key,
    required this.group,
    required this.memberLocations,
    this.userLocation,
    this.onMemberTapped,
  });

  @override
  State<GroupMembersMap> createState() => _GroupMembersMapState();
}

class _GroupMembersMapState extends State<GroupMembersMap> {
  late MapController _mapController;

  // Default center: Johannesburg
  static const LatLng _defaultCenter = LatLng(-26.2041, 28.0473);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  LatLng _calculateMapCenter() {
    if (widget.memberLocations.isEmpty) {
      return widget.userLocation ?? _defaultCenter;
    }

    // Calculate bounds to fit all members
    double minLat = widget.memberLocations.first.latitude;
    double maxLat = widget.memberLocations.first.latitude;
    double minLon = widget.memberLocations.first.longitude;
    double maxLon = widget.memberLocations.first.longitude;

    for (final member in widget.memberLocations) {
      minLat = member.latitude < minLat ? member.latitude : minLat;
      maxLat = member.latitude > maxLat ? member.latitude : maxLat;
      minLon = member.longitude < minLon ? member.longitude : minLon;
      maxLon = member.longitude > maxLon ? member.longitude : maxLon;
    }

    // Include user location in bounds if available
    if (widget.userLocation != null) {
      minLat = widget.userLocation!.latitude < minLat
          ? widget.userLocation!.latitude
          : minLat;
      maxLat = widget.userLocation!.latitude > maxLat
          ? widget.userLocation!.latitude
          : maxLat;
      minLon = widget.userLocation!.longitude < minLon
          ? widget.userLocation!.longitude
          : minLon;
      maxLon = widget.userLocation!.longitude > maxLon
          ? widget.userLocation!.longitude
          : maxLon;
    }

    return LatLng((minLat + maxLat) / 2, (minLon + maxLon) / 2);
  }

  @override
  Widget build(BuildContext context) {
    final center = _calculateMapCenter();

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: _calculateZoomLevel(),
        maxZoom: 18.0,
        minZoom: 10.0,
      ),
      children: [
        // Tile layer using CartoDB
        TileLayer(
          urlTemplate: 'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.makoya.civicpulse',
        ),

        // Route polyline (from start to end of group journey)
        PolylineLayer(
          polylines: [
            Polyline(
              points: [
                LatLng(-26.2041, 28.0473), // Placeholder start
                LatLng(-26.2100, 28.0550), // Placeholder end
              ],
              color: Colors.blue.withOpacity(0.6),
              strokeWidth: 3.0,
            ),
          ],
        ),

        // Group members markers
        MarkerLayer(
          markers: [
            // User location marker
            if (widget.userLocation != null)
              Marker(
                point: widget.userLocation!,
                width: 80,
                height: 80,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'You',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

            // Group member markers
            ...widget.memberLocations.map((member) {
              final isOnline = member.isOnline;
              final color = isOnline ? Colors.green : Colors.grey;

              return Marker(
                point: member.position,
                width: 80,
                height: 80,
                child: GestureDetector(
                  onTap: () {
                    widget.onMemberTapped?.call(member.memberId, member.memberName);
                    // Show member details in a bottom sheet
                    _showMemberDetails(context, member);
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withOpacity(0.4),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                member.memberName.characters.first.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: isOnline ? Colors.green : Colors.grey,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          member.memberName.split(' ').first,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),

        // Attribution
        RichAttributionWidget(
          attributions: [
            TextSourceAttribution(
              'OpenStreetMap contributors',
              onTap: () {
                // Handle attribution tap if needed
              },
            ),
          ],
        ),
      ],
    );
  }

  double _calculateZoomLevel() {
    if (widget.memberLocations.isEmpty) {
      return 13.0;
    }

    // Simple zoom level calculation based on member count
    if (widget.memberLocations.length == 1) {
      return 15.0;
    }
    return 14.0;
  }

  void _showMemberDetails(BuildContext context, GroupMemberLocation member) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: member.isOnline ? Colors.green : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        member.memberName.characters.first.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.memberName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          member.isOnline ? 'Online' : 'Offline',
                          style: TextStyle(
                            fontSize: 14,
                            color: member.isOnline
                                ? Colors.green
                                : Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'Location',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Text(
                '${member.latitude.toStringAsFixed(4)}, ${member.longitude.toStringAsFixed(4)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Last Updated',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Text(
                _formatTime(member.lastUpdated),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return dateTime.toString();
    }
  }
}

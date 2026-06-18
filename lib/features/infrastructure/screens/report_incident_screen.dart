import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_colors.dart';

class ReportIncidentScreen extends StatefulWidget {
  const ReportIncidentScreen({super.key});

  @override
  State<ReportIncidentScreen> createState() => _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends State<ReportIncidentScreen> {
  final MapController _mapController = MapController();
  final LatLng _defaultLocation = const LatLng(-26.2041, 28.0473); // Johannesburg example
  final List<Marker> _markers = [];

  // Offline / Cache simulated switch
  bool _isOfflineMode = false;

  void _addIncident(String type, LatLng point) {
    Color markerColor;
    IconData icon;
    
    if (type == 'Pothole') {
      markerColor = AppColors.urgent;
      icon = Icons.warning;
    } else if (type == 'Traffic Light') {
      markerColor = AppColors.critical;
      icon = Icons.traffic;
    } else {
      markerColor = AppColors.primary;
      icon = Icons.pets;
    }

    setState(() {
      _markers.add(
        Marker(
          point: point,
          width: 40,
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              color: markerColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$type reported successfully! (Saved offline: $_isOfflineMode)'),
        backgroundColor: markerColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Infrastructure Alerts',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        actions: [
          Row(
            children: [
              const Icon(Icons.wifi_off, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              const Text('Offline Map', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              Switch(
                value: _isOfflineMode,
                activeThumbColor: AppColors.accent,
                onChanged: (val) {
                  setState(() => _isOfflineMode = val);
                },
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _defaultLocation,
                    initialZoom: 13.0,
                    onTap: (tapPosition, point) {
                      _showReportDialog(point);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: _isOfflineMode
                          ? 'assets/offline_tiles/{z}/{x}/{y}.png' // Simulated offline tile package path
                          : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.civicpulse.civicpulse_app',
                    ),
                    MarkerLayer(markers: _markers),
                  ],
                ),
                Positioned(
                  bottom: 20,
                  right: 20,
                  left: 20,
                  child: _buildActionGuide(),
                ),
              ],
            ),
          ),
          _buildQuickReportPanel(),
        ],
      ),
    );
  }

  Widget _buildActionGuide() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xE5171725),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.touch_app, size: 18, color: AppColors.accent),
          SizedBox(width: 8),
          Text(
            'Tap anywhere on the map to log a report',
            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickReportPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Report (Current GPS Location)',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildReportButton('Pothole', AppColors.urgent, Icons.warning),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildReportButton('Light Fault', AppColors.critical, Icons.traffic),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildReportButton('Animal Alert', AppColors.primary, Icons.pets),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportButton(String type, Color color, IconData icon) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.15),
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.3)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: () {
        // Log incident at map center
        _addIncident(type, _mapController.camera.center);
      },
      child: Column(
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 8),
          Text(type, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showReportDialog(LatLng point) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Report Road Hazard',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Coordinates: ${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.warning, color: AppColors.urgent),
                title: const Text('Pothole or Road Damage', style: TextStyle(color: Colors.white)),
                onTap: () {
                  _addIncident('Pothole', point);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.traffic, color: AppColors.critical),
                title: const Text('Non-functional Traffic Light', style: TextStyle(color: Colors.white)),
                onTap: () {
                  _addIncident('Traffic Light', point);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.pets, color: AppColors.primary),
                title: const Text('Stray Animal Crossing', style: TextStyle(color: Colors.white)),
                onTap: () {
                  _addIncident('Animal Alert', point);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

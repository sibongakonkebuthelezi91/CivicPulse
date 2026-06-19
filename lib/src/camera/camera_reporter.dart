import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../location/geofence_manager.dart';

class CameraReporter extends StatefulWidget {
  final VoidCallback onReportSubmitted;

  const CameraReporter({
    super.key,
    required this.onReportSubmitted,
  });

  @override
  State<CameraReporter> createState() => _CameraReporterState();
}

class _CameraReporterState extends State<CameraReporter> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitializing = true;
  bool _isCapturing = false;
  GeofenceType _selectedType = GeofenceType.pothole;
  String? _capturedImagePath;
  Position? _capturedPosition;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;

    // App state changed before we got the chance to initialize
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _setupCamera();
    }
  }

  Future<void> _setupCamera() async {
    setState(() {
      _isInitializing = true;
    });

    try {
      // Check permissions
      final cameraStatus = await Permission.camera.request();
      final locationStatus = await Permission.location.request();

      if (!cameraStatus.isGranted || !locationStatus.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Camera and location permissions are required to report hazards.'),
              backgroundColor: Colors.redAccent,
            ),
          );
          Navigator.pop(context);
        }
        return;
      }

      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        throw CameraException('no_cameras', 'No cameras available on this device');
      }

      final controller = CameraController(
        _cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      _controller = controller;

      await controller.initialize();
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  Future<void> _captureAndPrepareReport() async {
    if (_controller == null || !_controller!.value.isInitialized || _isCapturing) {
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      // Get location first to minimize latency post-capture
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      // Take photo
      final XFile imageFile = await _controller!.takePicture();

      // Save to app documents directory
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String reportsDir = path.join(appDir.path, 'Reports');
      await Directory(reportsDir).create(recursive: true);
      
      final String fileExtension = path.extension(imageFile.path);
      final String fileName = 'report_${DateTime.now().millisecondsSinceEpoch}$fileExtension';
      final String savedPath = path.join(reportsDir, fileName);

      await File(imageFile.path).copy(savedPath);

      setState(() {
        _capturedImagePath = savedPath;
        _capturedPosition = position;
      });
    } catch (e) {
      debugPrint('Error capturing report: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to capture report: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  void _submitReport() {
    if (_capturedImagePath == null || _capturedPosition == null) return;

    final String hazardTitle = 'User Reported ${_selectedType.toString().split('.').last}';

    // Create a new local geofence alert so that it displays on the map immediately
    final newPoint = GeofencePoint(
      id: 'user_reported_${DateTime.now().millisecondsSinceEpoch}',
      title: hazardTitle,
      type: _selectedType,
      latitude: _capturedPosition!.latitude,
      longitude: _capturedPosition!.longitude,
    );

    GeofenceManager().addPoint(newPoint);

    // Call submit callback (to notify parent screens/sync with backend)
    widget.onReportSubmitted();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${newPoint.title} reported successfully! Geofence active.'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.blueAccent),
        ),
      );
    }

    if (_controller == null || !_controller!.value.isInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 60),
              const SizedBox(height: 16),
              const Text(
                'Camera Initialization Failed',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _setupCamera,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // If image is captured, show review UI, otherwise show preview
            _capturedImagePath == null
                ? _buildCameraPreview()
                : _buildReportReview(),

            // Top action buttons (e.g. Back/Close)
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    return Column(
      children: [
        // Camera Viewport
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CameraPreview(_controller!),
                // Custom alignment overlay reticle
                Center(
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white24, width: 2.0),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Icon(Icons.add, color: Colors.white38, size: 32),
                    ),
                  ),
                ),
                // Overlay text
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Center the hazard in the frame and tap the shutter.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Controls Panel
        Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          color: Colors.black,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Hazard Selector Tabs
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildTypeSelector(GeofenceType.pothole, 'Pothole', Icons.warning_amber_rounded),
                  _buildTypeSelector(GeofenceType.trafficLight, 'Signal', Icons.traffic_rounded),
                  _buildTypeSelector(GeofenceType.animalCrossing, 'Animal', Icons.pets_rounded),
                ],
              ),
              const SizedBox(height: 24),
              // Shutter button
              GestureDetector(
                onTap: _captureAndPrepareReport,
                child: Container(
                  height: 80,
                  width: 80,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black,
                      border: Border.all(color: Colors.white, width: 2.0),
                    ),
                    child: Center(
                      child: _isCapturing
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Container(
                              height: 60,
                              width: 60,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.redAccent,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTypeSelector(GeofenceType type, String label, IconData icon) {
    final bool isSelected = _selectedType == type;
    final Color activeColor = type == GeofenceType.pothole
        ? Colors.redAccent
        : type == GeofenceType.trafficLight
            ? Colors.amber
            : Colors.orangeAccent;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.15) : Colors.grey[900],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : Colors.white60,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportReview() {
    return Column(
      children: [
        // Captured Image display
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[800]!),
              image: DecorationImage(
                image: FileImage(File(_capturedImagePath!)),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),

        // Review & Confirm details card
        Container(
          margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[900]?.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Confirm Hazard Report',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Metadata fields
              _buildMetadataRow('Type:', _selectedType.toString().split('.').last.toUpperCase()),
              _buildMetadataRow('Latitude:', _capturedPosition?.latitude.toStringAsFixed(6) ?? 'Unknown'),
              _buildMetadataRow('Longitude:', _capturedPosition?.longitude.toStringAsFixed(6) ?? 'Unknown'),
              _buildMetadataRow('Timestamp:', DateTime.now().toLocal().toString().split('.').first),
              const SizedBox(height: 24),
              // Submit and retake buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        // Delete captured file
                        if (_capturedImagePath != null) {
                          File(_capturedImagePath!).deleteSync();
                        }
                        setState(() {
                          _capturedImagePath = null;
                          _capturedPosition = null;
                        });
                      },
                      child: const Text('Retake', style: TextStyle(color: Colors.white70)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _submitReport,
                      child: const Text('Submit Alert'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 14)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14)),
        ],
      ),
    );
  }
}

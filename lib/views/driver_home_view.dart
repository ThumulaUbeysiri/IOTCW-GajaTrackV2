import 'dart:async';
import 'package:flutter/foundation.dart'; // NEW: Import for checking the platform (web/mobile)
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import '../controllers/udp_service.dart'; // Import the new UDP service

class DriverHomeView extends StatefulWidget {
  @override
  State<DriverHomeView> createState() => _DriverHomeViewState();
}

class _DriverHomeViewState extends State<DriverHomeView> {
  late final MapController _mapController = MapController();

  // --- EXISTING STATE VARIABLES ---
  LatLng trainLocation = LatLng(0, 0);
  List<LatLng> elephants = [];
  double radius = 3000; // meters
  final dbRef = FirebaseDatabase.instance.ref();
  Timer? timer;

  // --- NEW STATE VARIABLES FOR UDP ALERT ---
  final UdpService _udpService = UdpService();
  String? _localElephantId; // Holds the ID from the local network beacon

  @override
  void initState() {
    super.initState();
    _requestPermissionAndStart();
    _loadElephantData();
    timer = Timer.periodic(const Duration(seconds: 5), (_) {
      _startTracking();
      _loadElephantData();
    });

    // --- MODIFIED: Only start the UDP listener on mobile ---
    // The 'kIsWeb' constant is false on mobile and true in a browser.
    if (!kIsWeb) {
      _startUdpListener();
    }
  }

  void _startUdpListener() {
    _udpService.startListener();
    _udpService.detectedElephantStream.listen((deviceId) {
      if (mounted && _localElephantId != deviceId) {
        setState(() {
          _localElephantId = deviceId;
        });
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    // --- MODIFIED: Only dispose the service if it was started ---
    if (!kIsWeb) {
      _udpService.dispose();
    }
    super.dispose();
  }

  // --- ALL YOUR EXISTING FUNCTIONS REMAIN UNCHANGED ---
  Future<void> _requestPermissionAndStart() async {
    // On web, location permissions are handled differently and automatically.
    // This check is mainly for mobile.
    if (!kIsWeb) {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permission denied');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        print('Location permissions are permanently denied');
        return;
      }
    }
    _startTracking();
  }

  Future<void> _startTracking() async {
    try {
      Position pos = await Geolocator.getCurrentPosition()
          .timeout(const Duration(seconds: 10));

      LatLng newLocation = LatLng(pos.latitude, pos.longitude);

      if(mounted) {
        setState(() {
          trainLocation = newLocation;
        });
        _mapController.move(newLocation, _mapController.camera.zoom);
      }
    } catch (e) {
      print('Error getting location or timeout: $e');
    }
  }

  Future<void> _loadElephantData() async {
    final snap = await dbRef.child('elephants').get();
    List<LatLng> temp = [];
    if (snap.exists && snap.value != null) {
      final data = snap.value as Map;
      for (final child in data.values) {
        final lat = (child['lat'] as num?)?.toDouble() ?? 0.0;
        final lon = (child['lon'] as num?)?.toDouble() ?? 0.0;
        temp.add(LatLng(lat, lon));
      }
    }
    if (mounted) {
      setState(() => elephants = temp);
    }
  }

  double _closestElephantDistance() {
    if (elephants.isEmpty) return double.infinity;

    final dist = elephants
        .map((e) => Distance().as(LengthUnit.Meter, trainLocation, e))
        .reduce((a, b) => a < b ? a : b);
    return dist;
  }

  Map<String, dynamic> _getWarningStatus() {
    final dist = _closestElephantDistance();

    if (dist < 1000) {
      return {
        'text': 'WARNING: Elephant very close!',
        'colors': [Colors.red.shade700, Colors.red.shade400],
        'icon': Icons.warning_amber_rounded,
      };
    } else if (dist < 3000) {
      return {
        'text': 'CAUTION: Elephant nearby',
        'colors': [Colors.deepOrange.shade700, Colors.deepOrange.shade400],
        'icon': Icons.error_outline,
      };
    } else {
      return {
        'text': 'Safe zone: No nearby elephants',
        'colors': [Colors.green.shade700, Colors.green.shade400],
        'icon': Icons.check_circle_outline,
      };
    }
  }

   Color _getAlertColor(LatLng elephant) {
    final distance = Distance().as(LengthUnit.Meter, trainLocation, elephant);
    if (distance < 1000) return Colors.redAccent;
    if (distance < 3000) return Colors.orangeAccent;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Colors.white;
    final appBarColor = Colors.green.shade600;
    final mapBoxColor = Colors.green.shade50;
    final mapBorderColor = Colors.green.shade300;

    final warning = _getWarningStatus();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        title: const Text(
          'Driver - GajaTrack',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
            color: Colors.white,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Your existing main content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              children: [
                Container(
                  height: 500,
                  decoration: BoxDecoration(
                    color: mapBoxColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: mapBorderColor, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: mapBorderColor.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 1,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: trainLocation,
                        initialZoom: 15,
                        keepAlive: true,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                          subdomains: const ['a', 'b', 'c'],
                        ),
                        CircleLayer(
                          circles: [
                            CircleMarker(
                              point: trainLocation,
                              radius: 1000,
                              useRadiusInMeter: true,
                              color: Colors.red.withOpacity(0.2),
                              borderStrokeWidth: 1.5,
                              borderColor: Colors.redAccent,
                            ),
                            CircleMarker(
                              point: trainLocation,
                              radius: 3000,
                              useRadiusInMeter: true,
                              color: Colors.orange.withOpacity(0.15),
                              borderStrokeWidth: 1.5,
                              borderColor: Colors.yellow,
                            ),
                            CircleMarker(
                              point: trainLocation,
                              radius: radius,
                              useRadiusInMeter: true,
                              color: Colors.yellow.withOpacity(0.05),
                              borderStrokeWidth: 1.0,
                              borderColor: Colors.yellow,
                            ),
                          ],
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: trainLocation,
                              width: 45,
                              height: 45,
                              child: Column(
                                children: const [
                                  Icon(Icons.train, color: Colors.black, size: 40),
                                  SizedBox(height: 2),
                                ],
                              ),
                            ),
                            ...elephants.map(
                                  (e) => Marker(
                                point: e,
                                width: 36,
                                height: 36,
                                child: Icon(
                                  Icons.pets,
                                  color: _getAlertColor(e),
                                  size: 32,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      colors: warning['colors'],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: warning['colors'][1].withOpacity(0.4),
                        blurRadius: 15,
                        spreadRadius: 1,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(warning['icon'], color: Colors.white, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          warning['text'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.normal,
                            fontSize: 20,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // --- Local Network Alert Banner ---
          // This will only be visible if _localElephantId is not null,
          // which can only happen on mobile now.
          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            bottom: _localElephantId != null ? 20 : -100,
            left: 16,
            right: 16,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: [Colors.amber.shade700, Colors.amber.shade500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.5),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.wifi_tethering, color: Colors.white, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'LOCAL ALERT: Elephant "${_localElephantId ?? ''}" detected on hotspot!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

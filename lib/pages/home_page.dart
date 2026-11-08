import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/location_service.dart';
import '../services/backend_service.dart';
import '../models/station_model.dart';
import '../widgets/station_bottom_sheet.dart';
import 'trip_plan_page.dart';
import '../widgets/station_marker.dart';
import '../widgets/liquid_glass_container.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  List<Station> _stations = [];
  bool _isLoadingLocation = true;
  bool _isLoadingStations = false;
  double _currentZoom = 13.0;
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    if (!mounted) return;
    setState(() => _isLoadingLocation = true);

    // 1. Try last known position for immediate response
    final lastPos = await LocationService.getLastKnownPosition();
    if (lastPos != null && mounted) {
      setState(() {
        _currentLocation = LatLng(lastPos.latitude, lastPos.longitude);
      });
      if (_isMapReady) {
        _mapController.move(_currentLocation!, _currentZoom);
      }
    }

    // 2. Get high-accuracy current position
    final pos = await LocationService.getCurrentPosition();
    if (pos != null && mounted) {
      setState(() {
        _currentLocation = LatLng(pos.latitude, pos.longitude);
        _isLoadingLocation = false;
      });

      if (_isMapReady) {
        _mapController.move(_currentLocation!, 13.5);
        // Automatically find stations once location is settled
        _findNearStations();
      }
    } else {
      if (mounted) setState(() => _isLoadingLocation = false);
      if (mounted && _currentLocation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Could not get high-accuracy location. Please check GPS settings.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _findNearStations() async {
    setState(() => _isLoadingStations = true);
    try {
      final center = _mapController.camera.center;
      final stations = await BackendService.getStations(center,
          radiusKm: 50, maxResults: 100);
      setState(() {
        _stations = stations;
        _isLoadingStations = false;
      });
      if (stations.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No charging stations found in this area.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error finding stations: $e'),
              backgroundColor: Colors.red),
        );
      }
      setState(() => _isLoadingStations = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildMapHome(),
          const TripPlanPage(),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
        child: LiquidGlassContainer(
          blur: 20,
          opacity: 0.7,
          borderRadius: BorderRadius.circular(30),
          borderColor: Colors.black.withValues(alpha: 0.05),
          child: SizedBox(
            height: 70,
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: const Color(0xFF222222),
              unselectedItemColor: const Color(0xFF222222).withValues(alpha: 0.4),
              type: BottomNavigationBarType.fixed,
              iconSize: 24,
              selectedFontSize: 10,
              unselectedFontSize: 10,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.route_outlined),
                  activeIcon: Icon(Icons.route),
                  label: 'Trip Plan',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMapHome() {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _currentLocation ??
                const LatLng(13.0827, 80.2707), // Default Chennai
            initialZoom: _currentZoom,
            onMapReady: () {
              _isMapReady = true;
              if (_currentLocation != null) {
                _mapController.move(_currentLocation!, 13.5);
                _findNearStations();
              } else {
                // If location is not yet available, still try to find stations around default center
                _findNearStations();
              }
            },
            onPositionChanged: (pos, hasGesture) {
              if (pos.zoom != _currentZoom) {
                setState(() => _currentZoom = pos.zoom);
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.evnavi.evnavi',
            ),
            if (_currentLocation != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentLocation!,
                    width: 44,
                    height: 44,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF004CB3).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFF004CB3), width: 2),
                      ),
                      child: const Icon(Icons.my_location,
                          color: Color(0xFF004CB3), size: 20),
                    ),
                  ),
                  ..._stations.map((s) => Marker(
                        point: LatLng(s.lat, s.lon),
                        width: 60, // Larger hit box
                        height: 60,
                        child: StationMarker(
                          station: s,
                          zoom: _currentZoom,
                          onTap: () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor:
                                const Color.fromARGB(149, 71, 64, 64),
                            builder: (_) => StationBottomSheet(station: s),
                          ),
                        ),
                      )),
                ],
              ),
          ],
        ),
        // Top shade gradient
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 140,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.9),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Action Buttons at bottom right
        Positioned(
          bottom: 100, // Above the bottom navigation bar
          right: 20,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton(
                mini: true,
                heroTag: 'stations',
                elevation: 0,
                backgroundColor: Colors.white.withValues(alpha: 0.8),
                shape: const CircleBorder(),
                onPressed: _isLoadingStations ? null : _findNearStations,
                child: _isLoadingStations
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: const Color(0xFF008F47)))
                    : const Icon(Icons.ev_station,
                        color: Color(0xFF008F47), size: 20),
              ),
              const SizedBox(height: 12),
              FloatingActionButton(
                mini: true,
                heroTag: 'gps',
                elevation: 0,
                backgroundColor: const Color(0xFF004CB3),
                shape: const CircleBorder(),
                onPressed: _getCurrentLocation,
                child: const Icon(Icons.my_location,
                    color: Colors.white, size: 20),
              ),
            ],
          ),
        ),
        if (_isLoadingLocation && _currentLocation == null)
          const Center(
            child: CircularProgressIndicator(color: Color(0xFF00E676)),
          ),
      ],
    );
  }

}

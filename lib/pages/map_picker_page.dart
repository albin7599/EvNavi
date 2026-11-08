import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/location_service.dart';
import '../widgets/liquid_glass_container.dart';

class MapPickerPage extends StatefulWidget {
  final LatLng? initialLocation;
  final String title;

  const MapPickerPage({
    super.key,
    this.initialLocation,
    required this.title,
  });

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  final MapController _mapController = MapController();
  LatLng? _selectedLocation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLoading = true);
    final pos = await LocationService.getCurrentPosition();
    if (pos != null) {
      final loc = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _selectedLocation = loc;
        _isLoading = false;
      });
      _mapController.move(loc, 13.5);
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.title.toUpperCase(), 
          style: const TextStyle(color: Color(0xFF222222), fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
        backgroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter:
                  _selectedLocation ?? const LatLng(13.0827, 80.2707),
              initialZoom: 13,
              onTap: (tapPosition, latlng) {
                setState(() => _selectedLocation = latlng);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.evnavi.evnavi',
              ),
              if (_selectedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLocation!,
                      width: 50,
                      height: 50,
                      child: const Icon(Icons.location_on,
                          color: Color(0xFF222222), size: 40),
                    ),
                  ],
                ),
            ],
          ),
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_selectedLocation == null)
                  LiquidGlassContainer(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    blur: 15,
                    opacity: 0.8,
                    borderRadius: BorderRadius.circular(30),
                    borderColor: const Color(0xFF222222).withValues(alpha: 0.05),
                    child: const Text(
                      'Tap anywhere on the map to pick a location',
                      style: TextStyle(color: Color(0xFF222222), fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FloatingActionButton(
                      heroTag: 'gps',
                      onPressed: _useCurrentLocation,
                      backgroundColor: Colors.white,
                      elevation: 2,
                      shape: const CircleBorder(),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF222222),
                              ),
                            )
                          : const Icon(Icons.my_location,
                              color: Color(0xFF222222)),
                    ),
                    const SizedBox(width: 16),
                    FloatingActionButton.extended(
                      heroTag: 'confirm',
                      onPressed: _selectedLocation == null
                          ? null
                          : () => Navigator.pop(context, _selectedLocation),
                      backgroundColor: _selectedLocation == null
                          ? const Color(0xFFE0E0E0)
                          : const Color(0xFF222222),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      label: Text(
                        'Confirm Location',
                        style: TextStyle(
                          color: _selectedLocation == null
                              ? const Color(0xFF9E9E9E)
                              : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      icon: Icon(
                        Icons.check_circle_outline,
                        color: _selectedLocation == null
                            ? const Color(0xFF9E9E9E)
                            : Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

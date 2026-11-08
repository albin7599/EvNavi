import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/route_model.dart';
import '../models/station_model.dart';
import '../models/trip_plan_model.dart';
import '../services/backend_service.dart';
import '../services/location_service.dart';
import '../widgets/station_bottom_sheet.dart';
import '../widgets/charge_stop_card.dart';
import '../widgets/station_marker.dart';
import '../widgets/liquid_glass_container.dart';


enum MapState { loading, ready, navigating, error }

class MapPage extends StatefulWidget {
  final double startLat, startLon, endLat, endLon;
  final String startLabel, endLabel;
  final double rangeKm, batteryPct;

  const MapPage({
    super.key,
    required this.startLat,
    required this.startLon,
    required this.endLat,
    required this.endLon,
    required this.startLabel,
    required this.endLabel,
    required this.rangeKm,
    required this.batteryPct,
  });

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  MapState _state = MapState.loading;
  String _errorMessage = '';

  RouteResult? _route;
  TripPlan? _tripPlan;
  List<Station> _stations = [];
  double _currentZoom = 10.0;
  bool _isLoadingStations = false;

  LatLng? _currentLocation;
  StreamSubscription<Position>? _locationSub;
  bool _navigationMode = false;

  bool _showStations = false;
  bool _showChargeStops = true;
  double _currentSpeed = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _state = MapState.loading;
      _errorMessage = '';
    });

    try {
      final start = LatLng(widget.startLat, widget.startLon);
      final end = LatLng(widget.endLat, widget.endLon);

      // 1. Initial direct route
      var route = await BackendService.getRoute([start, end]);
      if (route == null) {
        setState(() {
          _state = MapState.error;
          _errorMessage = 'Could not get route.';
        });
        return;
      }

      // 2. Plan battery stops along this route
      final tripPlan = await BackendService.getBatteryPlan(
        route: route,
        rangeKm: widget.rangeKm,
        batteryPct: widget.batteryPct,
      );

      // 3. If we found real stations, recalculate route to go through them
      if (tripPlan != null &&
          tripPlan.stops.any((s) => s.stations.isNotEmpty)) {
        final waypoints = [start];
        for (final stop in tripPlan.stops) {
          if (stop.bestStation != null) {
            waypoints.add(stop.bestStation!.latLng);
          }
        }
        waypoints.add(end);

        final refinedRoute = await BackendService.getRoute(waypoints);
        if (refinedRoute != null) {
          route = refinedRoute;
        }
      }

      final midIndex = route.points.length ~/ 2;
      final mid = route.points[midIndex];
      // Nearby stations for general display (toggle "Stations")
      final stations = await BackendService.getStations(
        mid,
        radiusKm: (route.distanceKm / 2).clamp(10, 150),
        maxResults: 60,
      );

      if (!mounted) return;
      setState(() {
        _route = route;
        _tripPlan = tripPlan;
        _stations = stations;
        _state = MapState.ready;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) => _fitRoute());
    } catch (e) {
      debugPrint('Map load error: $e');
      setState(() {
        _state = MapState.error;
        _errorMessage = 'Error: $e';
      });
    }
  }

  void _fitRoute() {
    if (_route == null || _route!.points.isEmpty) return;
    final bounds = LatLngBounds.fromPoints(_route!.points);
    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(48)),
    );
  }

  Future<void> _startNavigation() async {
    final pos = await LocationService.getCurrentPosition();
    if (!mounted) return;
    if (pos == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Cannot get GPS location.'),
            backgroundColor: Colors.orange),
      );
      return;
    }
    setState(() {
      _currentLocation = LatLng(pos.latitude, pos.longitude);
      _navigationMode = true;
    });
    _mapController.move(_currentLocation!, 13.5);
    _locationSub = LocationService.getPositionStream().listen((pos) {
      if (!mounted) return;
      final loc = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _currentLocation = loc;
        _currentSpeed = (pos.speed * 3.6).clamp(0, 300); // m/s to km/h
      });
      if (_navigationMode) _mapController.move(loc, _mapController.camera.zoom);
    });
  }

  void _stopNavigation() {
    _locationSub?.cancel();
    setState(() {
      _navigationMode = false;
      _currentLocation = null;
      _currentSpeed = 0.0;
    });
    _fitRoute();
  }

  void _openInMaps() async {
    final url = Uri.parse(
        'https://www.openstreetmap.org/directions?route=${widget.startLat},${widget.startLon};${widget.endLat},${widget.endLon}');
    if (await canLaunchUrl(url))
      await launchUrl(url, mode: LaunchMode.externalApplication);
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
        _showStations = true;
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
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          _buildMap(),
          _buildTopBar(),
          if (_state == MapState.loading) _buildLoadingOverlay(),
          if (_state == MapState.error) _buildErrorOverlay(),
          if (_state == MapState.ready || _state == MapState.navigating) ...[
            _buildControls(),
            if (_showChargeStops &&
                _tripPlan != null &&
                _tripPlan!.stops.isNotEmpty)
              _buildChargeStopsList(),
            if (_navigationMode) _buildSpeedometer(),
            _buildFloatingActionButtons(),
          ],
        ],
      ),
    );
  }

  Widget _buildSpeedometer() {
    return Positioned(
      top: 110,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF222222).withValues(alpha: 0.1),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              _currentSpeed.toStringAsFixed(0),
              style: const TextStyle(
                color: Color(0xFF222222),
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Text(
              'KM/H',
              style: TextStyle(
                color: Color(0xFF666666),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButtons() {
    return Positioned(
      bottom:
          _showChargeStops && _tripPlan != null && _tripPlan!.stops.isNotEmpty
              ? 250
              : 100,
      right: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            mini: true,
            heroTag: 'map_stations',
            elevation: 2,
            backgroundColor: Colors.white,
            shape: const CircleBorder(),
            onPressed: _isLoadingStations ? null : _findNearStations,
            child: _isLoadingStations
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: const Color(0xFF222222)))
                : const Icon(Icons.ev_station,
                    color: Color(0xFF008F47), size: 20),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            mini: true,
            heroTag: 'map_gps',
            elevation: 2,
            backgroundColor: const Color(0xFF004CB3),
            shape: const CircleBorder(),
            onPressed: () async {
              final pos = await LocationService.getCurrentPosition();
              if (pos != null && mounted) {
                _mapController.move(LatLng(pos.latitude, pos.longitude), 14);
              }
            },
            child: const Icon(Icons.my_location,
                color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: LatLng(widget.startLat, widget.startLon),
        initialZoom: _currentZoom,
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
        if (_route != null)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _route!.points,
                strokeWidth: 6.0,
                color: const Color(0xFF004CB3), // Darker Blue
                borderStrokeWidth: 3,
                borderColor: Colors.white,
              ),
            ],
          ),
        if (_showStations)
          MarkerLayer(
            markers: _stations
                .map((s) => Marker(
                      point: s.latLng,
                      width: 60,
                      height: 60,
                      child: StationMarker(
                        station: s,
                        zoom: _currentZoom,
                        onTap: () => showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          builder: (_) => StationBottomSheet(station: s),
                        ),
                      ),
                    ))
                .toList(),
          ),
        if (_showChargeStops && _tripPlan != null)
          MarkerLayer(
            markers: _tripPlan!.stops
                .map((stop) => Marker(
                      point: stop.latLng,
                      width: 60,
                      height: 60,
                      child: StationMarker(
                        station: stop.bestStation ??
                            Station(
                                id: 0,
                                name: 'Charge Stop',
                                lat: stop.lat,
                                lon: stop.lon,
                                address: '',
                                connectionTypes: [],
                                isOperational: true),
                        zoom: _currentZoom,
                        isPlannedStop: true,
                        onTap: () {
                          if (stop.bestStation != null) {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              builder: (_) => StationBottomSheet(
                                  station: stop.bestStation!),
                            );
                          }
                        },
                      ),
                    ))
                .toList(),
          ),
        MarkerLayer(
          markers: [
            Marker(
              point: LatLng(widget.startLat, widget.startLon),
              width: 40,
              height: 48,
              child: const Column(children: [
                Icon(Icons.trip_origin, color: Color(0xFF222222), size: 28),
                Icon(Icons.arrow_drop_down, color: Color(0xFF222222), size: 18),
              ]),
            ),
            Marker(
              point: LatLng(widget.endLat, widget.endLon),
              width: 40,
              height: 48,
              child: const Column(children: [
                Icon(Icons.location_on, color: Color(0xFF222222), size: 28),
                Icon(Icons.arrow_drop_down, color: Color(0xFF222222), size: 18),
              ]),
            ),
          ],
        ),
        if (_currentLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                point: _currentLocation!,
                width: 48,
                height: 48,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF004CB3).withValues(alpha: 0.15),
                    border:
                        Border.all(color: const Color(0xFF004CB3), width: 2),
                  ),
                  child: const Icon(Icons.navigation,
                      color: Color(0xFF004CB3), size: 24),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white.withValues(alpha: 0.95), Colors.transparent],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)
                    ]
                  ),
                  child: const Icon(Icons.arrow_back,
                      color: Colors.black, size: 20),
                ),
              ),
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.startLabel.toUpperCase(),
                      style: const TextStyle(
                          color: Colors.black, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(widget.endLabel.toUpperCase(),
                      style: TextStyle(color: Colors.black.withValues(alpha: 0.5), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1),
                      overflow: TextOverflow.ellipsis),
                ],
              )),
              if (_route != null) _buildRouteSummaryChip(),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildRouteSummaryChip() {
    final stops = _tripPlan?.stops.length ?? 0;
    return LiquidGlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      blur: 20,
      opacity: 0.85,
      borderRadius: BorderRadius.circular(12),
      borderColor: Colors.black.withValues(alpha: 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(_route!.distanceLabel,
              style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 14)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_route!.durationLabel,
                  style:
                      const TextStyle(color: Color(0xFF707070), fontSize: 11, fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                    color: Color(0xFF30363D), shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Icon(Icons.bolt_rounded,
                  color: stops > 0 ? Colors.black : const Color(0xFF707070),
                  size: 14),
              const SizedBox(width: 2),
              Text('$stops',
                  style: TextStyle(
                      color:
                          stops > 0 ? Colors.black : const Color(0xFF707070),
                      fontSize: 12,
                      fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          _toggleButton(
              icon: Icons.bolt,
              label: 'Stations',
              active: _showStations,
              activeColor: const Color(0xFF00E676),
              onTap: () => setState(() => _showStations = !_showStations)),
          const SizedBox(width: 8),
          _toggleButton(
              icon: Icons.battery_charging_full,
              label: 'Charge Stops',
              active: _showChargeStops,
              activeColor: Colors.orange,
              onTap: () =>
                  setState(() => _showChargeStops = !_showChargeStops)),
          const SizedBox(width: 8),
          _toggleButton(
              icon: Icons.open_in_new,
              label: 'OSM',
              active: false,
              activeColor: const Color(0xFF00BCD4),
              onTap: _openInMaps),
        ]),
        const SizedBox(height: 10),
        SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _navigationMode ? _stopNavigation : _startNavigation,
              icon: Icon(_navigationMode ? Icons.stop_rounded : Icons.navigation_rounded,
                  color: Colors.white, size: 20),
              label: Text(
                  (_navigationMode ? 'STOP NAVIGATION' : 'START NAVIGATION').toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
              style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16))),
            )),
      ]),
    );
  }

  Widget _toggleButton(
      {required IconData icon,
      required String label,
      required bool active,
      required Color activeColor,
      required VoidCallback onTap}) {
    return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
              color: active
                  ? Colors.black
                  : Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
              boxShadow: active ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
              border: Border.all(
                  color: active ? Colors.black : Colors.black.withValues(alpha: 0.1))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon,
                color: active ? Colors.white : Colors.black,
                size: 14),
            const SizedBox(width: 6),
            Text(label.toUpperCase(),
                style: TextStyle(
                    color: active ? Colors.white : Colors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5))
          ]),
        ));
  }

  Widget _buildChargeStopsList() {
    final stops = _tripPlan!.stops;
    return Positioned(
        bottom: 130,
        left: 0,
        right: 0,
        child: SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: stops.length,
              itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ChargeStopCard(
                      stop: stops[i],
                      index: i + 1,
                      onTap: () {
                        _mapController.move(stops[i].latLng, 14);
                        if (stops[i].bestStation != null)
                          showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              builder: (_) => StationBottomSheet(
                                  station: stops[i].bestStation!));
                      })),
            )));
  }

  Widget _buildLoadingOverlay() => Container(
      color: Colors.white.withValues(alpha: 0.9),
      child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        const CircularProgressIndicator(color: Colors.black),
        const SizedBox(height: 16),
        Text('CALCULATING ROUTE',
            style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 2))
      ])));

  Widget _buildErrorOverlay() => Container(
      color: const Color(0xCC0D1117),
      padding: const EdgeInsets.all(32),
      child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, color: Colors.redAccent, size: 56),
        const SizedBox(height: 16),
        Text(_errorMessage,
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center),
        const SizedBox(height: 24),
        ElevatedButton(onPressed: _loadData, child: const Text('Retry'))
      ])));
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:latlong2/latlong.dart';
import '../services/backend_service.dart';
import '../services/location_service.dart';
import 'map_page.dart';
import 'map_picker_page.dart';

class TripPlanPage extends StatefulWidget {
  const TripPlanPage({super.key});

  @override
  State<TripPlanPage> createState() => _TripPlanPageState();
}

class _TripPlanPageState extends State<TripPlanPage> {
  // Controllers
  final _fromController = TextEditingController();
  final _toController = TextEditingController();

  // Selected coordinates
  double? _fromLat, _fromLon;
  double? _toLat, _toLon;

  // Vehicle data
  double _rangeKm = 300;
  double _batteryPct = 80;
  String? _currentCountryCode;

  // Autocomplete state
  List<Map<String, dynamic>> _fromSuggestions = [];
  List<Map<String, dynamic>> _toSuggestions = [];
  bool _searchingFrom = false;
  bool _searchingTo = false;

  Timer? _debounce;
  bool _isPlanning = false;

  @override
  void initState() {
    super.initState();
    _detectCountry();
  }

  Future<void> _detectCountry() async {
    final pos = await LocationService.getCurrentPosition();
    if (pos != null) {
      final code =
          await BackendService.getCountryCode(pos.latitude, pos.longitude);
      if (mounted) {
        setState(() => _currentCountryCode = code);
      }
    }
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onFromChanged(String val) {
    _fromLat = null;
    _fromLon = null;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      if (val.trim().isEmpty) {
        setState(() => _fromSuggestions = []);
        return;
      }
      setState(() => _searchingFrom = true);
      final results = await BackendService.searchPlaces(val,
          countryCode: _currentCountryCode);
      setState(() {
        _fromSuggestions = results;
        _searchingFrom = false;
      });
    });
  }

  void _onToChanged(String val) {
    _toLat = null;
    _toLon = null;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      if (val.trim().isEmpty) {
        setState(() => _toSuggestions = []);
        return;
      }
      setState(() => _searchingTo = true);
      final results = await BackendService.searchPlaces(val,
          countryCode: _currentCountryCode);
      setState(() {
        _toSuggestions = results;
        _searchingTo = false;
      });
    });
  }

  void _selectFrom(Map<String, dynamic> place) {
    _fromLat = double.tryParse(place['lat'].toString()) ?? 0.0;
    _fromLon = double.tryParse(place['lon'].toString()) ?? 0.0;
    final display = place['display_name'] as String? ?? '';
    _fromController.text = display.isNotEmpty
        ? display.split(',').take(2).join(', ')
        : 'Selected Location';
    setState(() => _fromSuggestions = []);
  }

  void _selectTo(Map<String, dynamic> place) {
    _toLat = double.tryParse(place['lat'].toString()) ?? 0.0;
    _toLon = double.tryParse(place['lon'].toString()) ?? 0.0;
    final display = place['display_name'] as String? ?? '';
    _toController.text = display.isNotEmpty
        ? display.split(',').take(2).join(', ')
        : 'Selected Location';
    setState(() => _toSuggestions = []);
  }

  Future<void> _planRoute() async {
    final fromText = _fromController.text.trim();
    final toText = _toController.text.trim();

    if (toText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a destination'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isPlanning = true);
    try {
      // 1. Start location: Current GPS if empty
      if (fromText.isEmpty) {
        final pos = await LocationService.getCurrentPosition();
        if (pos == null) {
          throw 'Location permission denied or GPS disabled. Please check your settings.';
        }
        _fromLat = pos.latitude;
        _fromLon = pos.longitude;
        _fromController.text = 'Current Location';
      } else if (_fromLat == null) {
        final res = await BackendService.searchPlaces(fromText,
            countryCode: _currentCountryCode);
        if (res.isEmpty) throw 'Could not find start location: "$fromText"';
        _selectFrom(res.first);
      }

      // 2. Destination
      if (_toLat == null) {
        final res = await BackendService.searchPlaces(toText,
            countryCode: _currentCountryCode);
        if (res.isEmpty) throw 'Could not find destination: "$toText"';
        _selectTo(res.first);
      }

      if (!mounted) return;
      await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MapPage(
              startLat: _fromLat!,
              startLon: _fromLon!,
              endLat: _toLat!,
              endLon: _toLon!,
              startLabel: _fromController.text,
              endLabel: _toController.text,
              rangeKm: _rangeKm,
              batteryPct: _batteryPct,
            ),
          ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isPlanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF7F7F7),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              _buildCard(),
              const SizedBox(height: 24),
              _buildPlanButton(),
              const SizedBox(height: 20),
              _buildFeatureChips(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/icon/logo.png',
                width: 52,
                height: 52,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('EvNavi',
                    style: TextStyle(
                        color: Color(0xFF222222),
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2)),
                Text('TRIP PLANNER & NAVIGATOR FOR EV',
                    style: TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 11,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.1),
      ],
    );
  }

  Widget _buildCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Route'),
          const SizedBox(height: 12),
          _buildSearchField(
            controller: _fromController,
            hint: 'From: Current Location (optional)',
            icon: Icons.trip_origin,
            iconColor: Colors.black,
            suggestions: _fromSuggestions,
            isLoading: _searchingFrom,
            onChanged: _onFromChanged,
            onSelect: _selectFrom,
            onMapPick: () async {
              final res = await Navigator.push<LatLng>(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const MapPickerPage(title: 'Pick Start')));
              if (res != null) {
                _fromLat = res.latitude;
                _fromLon = res.longitude;
                _fromController.text =
                    '${res.latitude.toStringAsFixed(4)}, ${res.longitude.toStringAsFixed(4)}';
                setState(() => _fromSuggestions = []);
              }
            },
          ),
          const SizedBox(height: 16),
          _buildSearchField(
            controller: _toController,
            hint: 'Destination...',
            icon: Icons.location_on,
            iconColor: Colors.black,
            suggestions: _toSuggestions,
            isLoading: _searchingTo,
            onChanged: _onToChanged,
            onSelect: _selectTo,
            onMapPick: () async {
              final res = await Navigator.push<LatLng>(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const MapPickerPage(title: 'Pick Destination')));
              if (res != null) {
                _toLat = res.latitude;
                _toLon = res.longitude;
                _toController.text =
                    '${res.latitude.toStringAsFixed(4)}, ${res.longitude.toStringAsFixed(4)}';
                setState(() => _toSuggestions = []);
              }
            },
          ),
          const SizedBox(height: 24),
          _sectionLabel('Vehicle Battery'),
          const SizedBox(height: 12),
          _buildSlider('Vehicle Range', _rangeKm, 50, 900, 'km', Colors.black,
              (v) => setState(() => _rangeKm = v)),
          const SizedBox(height: 12),
          _buildSlider('Current Battery', _batteryPct, 5, 100, '%',
              Colors.black, (v) => setState(() => _batteryPct = v)),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 500.ms);
  }

  Widget _buildSearchField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color iconColor,
    required List<Map<String, dynamic>> suggestions,
    required bool isLoading,
    required ValueChanged<String> onChanged,
    required ValueChanged<Map<String, dynamic>> onSelect,
    required VoidCallback onMapPick,
  }) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(14)),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            style: const TextStyle(color: Color(0xFF222222), fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                  color: const Color(0xFF222222).withValues(alpha: 0.35),
                  fontSize: 14),
              prefixIcon: Icon(icon, color: const Color(0xFF222222), size: 20),
              suffixIcon: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: Padding(
                          padding: EdgeInsets.all(14),
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Color(0xFF222222))))
                  : IconButton(
                      icon: Icon(Icons.map_outlined,
                          color: const Color(0xFF222222).withValues(alpha: 0.4),
                          size: 20),
                      onPressed: onMapPick),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        if (suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                  )
                ]),
            child: Column(
                children: suggestions
                    .take(3)
                    .map((s) => ListTile(
                          dense: true,
                          title: Text(
                              s['display_name'].toString().split(',').first,
                              style: const TextStyle(
                                  color: Color(0xFF222222),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                          subtitle: Text(
                              s['display_name']
                                  .toString()
                                  .split(',')
                                  .skip(1)
                                  .join(','),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: const Color(0xFF222222)
                                      .withValues(alpha: 0.45),
                                  fontSize: 11)),
                          onTap: () => onSelect(s),
                        ))
                    .toList()),
          ),
      ],
    );
  }

  Widget _buildSlider(String label, double val, double min, double max,
      String unit, Color color, ValueChanged<double> onChanged) {
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label,
            style: TextStyle(
                color: const Color(0xFF222222).withValues(alpha: 0.5),
                fontSize: 12,
                fontWeight: FontWeight.w600)),
        Text('${val.toStringAsFixed(0)} $unit',
            style: const TextStyle(
                color: Color(0xFF222222),
                fontWeight: FontWeight.w800,
                fontSize: 16)),
      ]),
      SliderTheme(
          data: SliderThemeData(
              activeTrackColor: const Color(0xFF222222),
              inactiveTrackColor:
                  const Color(0xFF222222).withValues(alpha: 0.08),
              thumbColor: const Color(0xFF222222),
              trackHeight: 4),
          child: Slider(value: val, min: min, max: max, onChanged: onChanged)),
    ]);
  }

  Widget _buildPlanButton() {
    return SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isPlanning ? null : _planRoute,
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF222222),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16))),
          child: _isPlanning
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('PLAN MY ROUTE',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      fontSize: 15)),
        )).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildFeatureChips() {
    return Wrap(
        spacing: 12,
        children: [('⚡', 'CHARGING'), ('🗺️', 'LIVE MAP'), ('🔋', 'BATTERY')]
            .map((f) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.black.withValues(alpha: 0.05)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                        )
                      ]),
                  child: Text('${f.$2}',
                      style: const TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1)),
                ))
            .toList());
  }

  Widget _sectionLabel(String t) => Text(t.toUpperCase(),
      style: const TextStyle(
          color: Color(0xFF222222),
          fontWeight: FontWeight.w800,
          fontSize: 13,
          letterSpacing: 1.5));
}

import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/route_model.dart';
import '../models/station_model.dart';
import '../models/trip_plan_model.dart';

/// Calls all external services directly — no backend required.
class BackendService {
  // Loaded securely via --dart-define-from-file=.env or --dart-define=OCM_API_KEY=...
  static const _ocmKey = String.fromEnvironment('OCM_API_KEY', defaultValue: '');
  static const _timeout = Duration(seconds: 20);
  static const _headers = {
    'User-Agent': 'EVNaviApp/1.0 (student project)',
    'Accept': 'application/json',
  };

  // ─── Geocoding (Nominatim) ──────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> searchPlaces(String query,
      {String? countryCode}) async {
    if (query.trim().isEmpty) return [];
    final Map<String, String> params = {
      'q': query,
      'format': 'json',
      'limit': '5',
      'addressdetails': '1',
    };
    if (countryCode != null) {
      params['countrycodes'] = countryCode.toLowerCase();
    }
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', params);
    try {
      final resp = await http.get(uri, headers: _headers).timeout(_timeout);
      if (resp.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(resp.body) as List);
      }
    } catch (e) {
      debugPrint('Geocode error: $e');
    }
    return [];
  }

  static Future<LatLng?> geocode(String query) async {
    final results = await searchPlaces(query);
    if (results.isEmpty) return null;
    final r = results.first;
    return LatLng((r['lat'] as String).toDoubleOrNull() ?? 0,
        (r['lon'] as String).toDoubleOrNull() ?? 0);
  }

  // ─── Routing (OSRM public server) ──────────────────────────────────────────

  static Future<RouteResult?> getRoute(List<LatLng> waypoints) async {
    if (waypoints.length < 2) return null;
    final coords =
        waypoints.map((p) => '${p.longitude},${p.latitude}').join(';');
    final uri = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/$coords'
      '?overview=full&geometries=geojson&steps=false',
    );
    try {
      final resp = await http.get(uri, headers: _headers).timeout(_timeout);
      if (resp.statusCode != 200) {
        debugPrint('OSRM error ${resp.statusCode}');
        return null;
      }
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      if (data['code'] != 'Ok' || (data['routes'] as List).isEmpty) return null;

      final route = (data['routes'] as List).first as Map<String, dynamic>;
      final geometry = route['geometry'] as Map<String, dynamic>;
      final rawCoords = geometry['coordinates'] as List;

      final points = rawCoords.map((c) {
        final pair = c as List;
        return LatLng(
          (pair[1] as num).toDouble(),
          (pair[0] as num).toDouble(),
        );
      }).toList();

      return RouteResult(
        points: points,
        distanceKm: (route['distance'] as num).toDouble() / 1000,
        durationMin: (route['duration'] as num).toDouble() / 60,
      );
    } catch (e) {
      debugPrint('Route error: $e');
      return null;
    }
  }

  // ─── Charging Stations (OpenChargeMap) ─────────────────────────────────────

  static Future<List<Station>> getStations(
    LatLng center, {
    double radiusKm = 50,
    int maxResults = 50,
  }) async {
    final params = <String, String>{
      'output': 'json',
      'latitude': center.latitude.toString(),
      'longitude': center.longitude.toString(),
      'distance': radiusKm.toString(),
      'distanceunit': 'KM',
      'maxresults': maxResults.toString(),
      'compact': 'true',
      'verbose': 'false',
    };
    if (_ocmKey.isNotEmpty) {
      params['key'] = _ocmKey;
    }
    final uri = Uri.https('api.openchargemap.io', '/v3/poi', params);
    try {
      final resp = await http.get(uri, headers: _headers).timeout(_timeout);
      if (resp.statusCode == 200) {
        return _parseStations(jsonDecode(resp.body) as List);
      }
    } catch (e) {
      debugPrint('Stations error: $e');
    }
    return [];
  }

  static List<Station> _parseStations(List data) {
    final stations = <Station>[];
    for (final item in data) {
      try {
        final addr = item['AddressInfo'] as Map<String, dynamic>? ?? {};
        final conns = item['Connections'] as List? ?? [];
        final connTypes = <String>{};
        double? maxKw;
        for (final c in conns) {
          final ct = (c as Map<String, dynamic>)['ConnectionType'];
          if (ct != null) {
            final title = (ct as Map<String, dynamic>)['Title'] as String?;
            if (title != null) connTypes.add(title);
          }
          final kw = c['PowerKW'];
          if (kw != null) maxKw = max(maxKw ?? 0, (kw as num).toDouble());
        }
        final statusType = item['StatusType'];
        final isOp = statusType is Map
            ? (statusType['IsOperational'] as bool? ?? true)
            : true;
        stations.add(Station(
          id: item['ID'] as int? ?? 0,
          name: addr['Title'] as String? ?? 'Charging Station',
          lat: (addr['Latitude'] as num?)?.toDouble() ?? 0,
          lon: (addr['Longitude'] as num?)?.toDouble() ?? 0,
          address:
              addr['AddressLine1'] as String? ?? addr['Town'] as String? ?? '',
          connectionTypes: connTypes.toList(),
          powerKw: maxKw,
          isOperational: isOp,
        ));
      } catch (_) {}
    }
    return stations;
  }

  // ─── Battery Plan (computed in Dart) ───────────────────────────────────────

  static Future<TripPlan?> getBatteryPlan({
    required RouteResult route,
    required double rangeKm,
    required double batteryPct,
  }) async {
    if (route.points.length < 2) return null;

    // 1. Get elevations for the route points (sampled to avoid API overload)
    final elevations = await _getElevations(route.points);

    // 2. Calculate "Effective Distances" considering altitude
    // Rule: Climbing 100m is like adding ~1km of flat road.
    // Going down regenerates ~50% of that potential energy.
    final cumEffective = <double>[0];
    final cumGeometric = <double>[0];

    for (var i = 1; i < route.points.length; i++) {
      final geometricDist = _haversine(route.points[i - 1], route.points[i]);
      cumGeometric.add(cumGeometric.last + geometricDist);

      final alt1 = elevations[i - 1];
      final alt2 = elevations[i];
      final dAlt = alt2 - alt1; // meters

      // Elevation & Regeneration Math:
      // Uphill: 100m altitude gain adds ~1.2km of "consumption load".
      // Downhill: 100m descent recovers ~0.6km of range through regeneration.
      double stepConsumption = geometricDist;
      if (dAlt > 0) {
        stepConsumption += (dAlt / 100.0) * 1.2;
      } else if (dAlt < 0) {
        // We allow this to be negative, meaning the car is RECHARGING.
        // On a steep hill, a 1km drive can result in +0.5km of new range.
        stepConsumption += (dAlt / 100.0) * 0.6;
      }

      // We allow true regeneration (negative consumption), but cap the gain
      // rate to 1.5x the travel distance to keep it realistic.
      cumEffective
          .add(cumEffective.last + max(stepConsumption, -geometricDist * 0.5));
    }

    final totalEffectiveKm = cumEffective.last;
    final totalGeometricKm = cumGeometric.last;

    // User Constraints (based on rangeKm)
    final minTripReserveKm = rangeKm * 0.10;
    final minDestReserveKm = rangeKm * 0.45;

    final stops = <ChargeStop>[];
    final segments = <Map<String, dynamic>>[];

    double currentEffectiveDist = 0;
    double currentActualRange = rangeKm * (batteryPct / 100);

    // Current geometric distance for stop placement
    double currentGeoDist = 0;

    while (currentActualRange - (totalEffectiveKm - currentEffectiveDist) <
        minDestReserveKm) {
      final limitJump =
          (currentActualRange - minTripReserveKm).clamp(0.0, double.infinity);
      final limitEffectiveTarget = currentEffectiveDist + limitJump;

      // Find where we hit this limit in geometric space
      int limitIdx =
          _findIndexForEffectiveDistance(cumEffective, limitEffectiveTarget);
      final limitGeoDist = cumGeometric[limitIdx];

      ChargeStop? chosenStop;
      final scanDistances = [
        limitGeoDist,
        limitGeoDist - 30,
        limitGeoDist - 60
      ];

      for (final scanGeoDist in scanDistances) {
        if (scanGeoDist <= currentGeoDist + 5) break;

        final idx = _findIndexForDistance(cumGeometric, scanGeoDist);
        final pt = route.points[idx];

        final stations = await getStations(pt, radiusKm: 35, maxResults: 15);
        if (stations.isNotEmpty) {
          final station = stations.first;
          final effectiveAtStation = cumEffective[idx];

          chosenStop = ChargeStop(
            stopIndex: idx,
            lat: station.lat,
            lon: station.lon,
            distanceFromStartKm: scanGeoDist.roundTo(2),
            stations: stations.take(5).toList(),
          );

          currentEffectiveDist = effectiveAtStation;
          currentGeoDist = scanGeoDist;
          break;
        }
      }

      if (chosenStop == null) {
        chosenStop = ChargeStop(
          stopIndex: limitIdx,
          lat: route.points[limitIdx].latitude,
          lon: route.points[limitIdx].longitude,
          distanceFromStartKm: limitGeoDist.roundTo(2),
          stations: [],
        );
        currentEffectiveDist = limitEffectiveTarget;
        currentGeoDist = limitGeoDist;
      }

      stops.add(chosenStop);
      segments.add({
        'from_km': currentGeoDist.roundTo(2),
        'to_km': chosenStop.distanceFromStartKm,
        'effective_usage': (currentEffectiveDist -
                (segments.isEmpty ? 0 : currentEffectiveDist))
            .roundTo(2),
      });

      currentActualRange = rangeKm;
      if (stops.length >= 15) break;
    }

    segments.add({
      'from_km': currentGeoDist.roundTo(2),
      'to_km': totalGeometricKm.roundTo(2),
    });

    return TripPlan(
      stops: stops,
      totalDistanceKm: totalGeometricKm.roundTo(2),
      segments: segments,
    );
  }

  /// Fetch elevations for route points (batched & sampled)
  static Future<List<double>> _getElevations(List<LatLng> points) async {
    const maxPoints = 120; // Sample to avoid massive requests
    final List<int> indices = [];
    if (points.length <= maxPoints) {
      indices.addAll(List.generate(points.length, (i) => i));
    } else {
      for (var i = 0; i < maxPoints - 1; i++) {
        indices.add((i * (points.length - 1) / (maxPoints - 1)).floor());
      }
      indices.add(points.length - 1);
    }

    final sampledPoints = indices.map((i) => points[i]).toList();
    final List<double> results = List.filled(points.length, 0.0);

    try {
      final body = jsonEncode({
        'locations': sampledPoints
            .map((p) => {'latitude': p.latitude, 'longitude': p.longitude})
            .toList()
      });

      final resp = await http
          .post(
            Uri.parse('https://api.open-elevation.com/api/v1/lookup'),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final evs = (data['results'] as List)
            .map((r) => (r['elevation'] as num).toDouble())
            .toList();

        // Linear interpolation for missing points
        for (var i = 0; i < indices.length - 1; i++) {
          final startIdx = indices[i];
          final endIdx = indices[i + 1];
          final startAlt = evs[i];
          final endAlt = evs[i + 1];

          for (var j = startIdx; j <= endIdx; j++) {
            final t = (endIdx == startIdx)
                ? 0.0
                : (j - startIdx) / (endIdx - startIdx);
            results[j] = startAlt + (endAlt - startAlt) * t;
          }
        }
        return results;
      }
    } catch (e) {
      debugPrint('Elevation error: $e');
    }
    return List.filled(points.length, 0.0); // Fallback to flat earth
  }

  static int _findIndexForEffectiveDistance(
      List<double> cumEffective, double target) {
    if (target <= 0) return 0;
    if (target >= cumEffective.last) return cumEffective.length - 1;
    int low = 0;
    int high = cumEffective.length - 1;
    while (low < high) {
      int mid = (low + high) ~/ 2;
      if (cumEffective[mid] < target) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    return low;
  }

  static int _findIndexForDistance(List<double> cumDist, double target) {
    if (target <= 0) return 0;
    if (target >= cumDist.last) return cumDist.length - 1;
    // Binary search for efficiency
    int low = 0;
    int high = cumDist.length - 1;
    while (low < high) {
      int mid = (low + high) ~/ 2;
      if (cumDist[mid] < target) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    return low;
  }

  static double _haversine(LatLng a, LatLng b) {
    const R = 6371.0;
    final phi1 = a.latitude * pi / 180;
    final phi2 = b.latitude * pi / 180;
    final dPhi = (b.latitude - a.latitude) * pi / 180;
    final dLam = (b.longitude - a.longitude) * pi / 180;
    final x = sin(dPhi / 2) * sin(dPhi / 2) +
        cos(phi1) * cos(phi2) * sin(dLam / 2) * sin(dLam / 2);
    return 2 * R * asin(sqrt(x));
  }

  /// Get country code from coordinates using Nominatim reverse geocoding
  static Future<String?> getCountryCode(double lat, double lon) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'lat': lat.toString(),
      'lon': lon.toString(),
      'format': 'json',
    });
    try {
      final resp = await http.get(uri, headers: _headers);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final address = data['address'] as Map<String, dynamic>?;
        return address?['country_code'] as String?;
      }
    } catch (_) {}
    return null;
  }
}

extension on double {
  double roundTo(int decimals) {
    final factor = pow(10, decimals);
    return (this * factor).round() / factor;
  }
}

extension on String {
  double? toDoubleOrNull() => double.tryParse(this);
}

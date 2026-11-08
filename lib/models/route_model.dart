import 'package:latlong2/latlong.dart';

class RouteResult {
  final List<LatLng> points;
  final double distanceKm;
  final double durationMin;

  const RouteResult({
    required this.points,
    required this.distanceKm,
    required this.durationMin,
  });

  factory RouteResult.fromJson(Map<String, dynamic> json) {
    final rawPoints = json['points'] as List;
    final points = rawPoints
        .map((p) => LatLng(
              (p['lat'] as num).toDouble(),
              (p['lon'] as num).toDouble(),
            ))
        .toList();
    return RouteResult(
      points: points,
      distanceKm: (json['distance_km'] as num).toDouble(),
      durationMin: (json['duration_min'] as num).toDouble(),
    );
  }

  String get distanceLabel {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).toStringAsFixed(0)} m';
    }
    return '${distanceKm.toStringAsFixed(1)} km';
  }

  String get durationLabel {
    final hours = (durationMin / 60).floor();
    final mins = (durationMin % 60).round();
    if (hours > 0) return '${hours}h ${mins}m';
    return '${mins}m';
  }
}

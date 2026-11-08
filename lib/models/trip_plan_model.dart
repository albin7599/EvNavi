import 'package:latlong2/latlong.dart';
import 'station_model.dart';

class ChargeStop {
  final int stopIndex;
  final double lat;
  final double lon;
  final double distanceFromStartKm;
  final List<Station> stations;

  const ChargeStop({
    required this.stopIndex,
    required this.lat,
    required this.lon,
    required this.distanceFromStartKm,
    required this.stations,
  });

  LatLng get latLng => LatLng(lat, lon);

  Station? get bestStation => stations.isNotEmpty ? stations.first : null;

  factory ChargeStop.fromJson(Map<String, dynamic> json) {
    return ChargeStop(
      stopIndex: json['stop_index'] as int,
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      distanceFromStartKm: (json['distance_from_start_km'] as num).toDouble(),
      stations: (json['stations'] as List)
          .map((s) => Station.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}

class TripPlan {
  final List<ChargeStop> stops;
  final double totalDistanceKm;
  final List<Map<String, dynamic>> segments;

  const TripPlan({
    required this.stops,
    required this.totalDistanceKm,
    required this.segments,
  });

  factory TripPlan.fromJson(Map<String, dynamic> json) {
    return TripPlan(
      stops: (json['stops'] as List)
          .map((s) => ChargeStop.fromJson(s as Map<String, dynamic>))
          .toList(),
      totalDistanceKm: (json['total_distance_km'] as num).toDouble(),
      segments: List<Map<String, dynamic>>.from(json['segments'] as List),
    );
  }
}

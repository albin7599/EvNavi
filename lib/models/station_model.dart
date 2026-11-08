import 'package:latlong2/latlong.dart';

class Station {
  final int id;
  final String name;
  final double lat;
  final double lon;
  final String address;
  final List<String> connectionTypes;
  final double? powerKw;
  final bool isOperational;

  const Station({
    required this.id,
    required this.name,
    required this.lat,
    required this.lon,
    required this.address,
    required this.connectionTypes,
    this.powerKw,
    required this.isOperational,
  });

  LatLng get latLng => LatLng(lat, lon);

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Charging Station',
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      address: json['address'] as String? ?? '',
      connectionTypes:
          List<String>.from(json['connection_types'] as List? ?? []),
      powerKw: json['power_kw'] != null
          ? (json['power_kw'] as num).toDouble()
          : null,
      isOperational: json['is_operational'] as bool? ?? true,
    );
  }

  String get powerLabel =>
      powerKw != null ? '${powerKw!.toStringAsFixed(0)} kW' : 'Unknown';

  String get statusLabel => isOperational ? 'Operational' : 'Unavailable';
}

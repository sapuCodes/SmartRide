import 'package:google_maps_flutter/google_maps_flutter.dart';

class Trip {
  final String id;
  final String startLocation;
  final String endLocation;
  final double distance;
  final int duration; // in minutes
  final DateTime date;
  final LatLng? startLatLng;
  final LatLng? endLatLng;
  final List<LatLng> route; // List of LatLng points for the route

  Trip({
    required this.id,
    required this.startLocation,
    required this.endLocation,
    required this.distance,
    required this.duration,
    required this.date,
    this.startLatLng,
    this.endLatLng,
    this.route = const [],
  });

  /// Converts a Trip instance into a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startLocation': startLocation,
      'endLocation': endLocation,
      'distance': distance,
      'duration': duration,
      'date': date.toIso8601String(),
      'startLatLng': startLatLng != null
          ? {'lat': startLatLng!.latitude, 'lng': startLatLng!.longitude}
          : null,
      'endLatLng': endLatLng != null
          ? {'lat': endLatLng!.latitude, 'lng': endLatLng!.longitude}
          : null,
      'route': route.map((point) => {'lat': point.latitude, 'lng': point.longitude}).toList(),
    };
  }

  /// Creates a Trip instance from a JSON map.
  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] as String,
      startLocation: json['startLocation'] as String,
      endLocation: json['endLocation'] as String,
      distance: (json['distance'] as num).toDouble(),
      duration: json['duration'] as int,
      date: DateTime.parse(json['date'] as String),
      startLatLng: json['startLatLng'] != null
          ? LatLng(
              (json['startLatLng']['lat'] as num).toDouble(),
              (json['startLatLng']['lng'] as num).toDouble(),
            )
          : null,
      endLatLng: json['endLatLng'] != null
          ? LatLng(
              (json['endLatLng']['lat'] as num).toDouble(),
              (json['endLatLng']['lng'] as num).toDouble(),
            )
          : null,
      route: (json['route'] as List<dynamic>?)
              ?.map((point) => LatLng(
                    (point['lat'] as num).toDouble(),
                    (point['lng'] as num).toDouble(),
                  ))
              .toList() ??
          [],
    );
  }
}

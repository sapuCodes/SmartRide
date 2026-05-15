import 'dart:async';
import 'dart:math';

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Service for GPS tracking during trips.
class GpsService {
  static const LocationSettings locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10, // Update every 10 meters to optimize battery
  );

  StreamSubscription<Position>? _positionStreamSubscription;
  final List<LatLng> _routePoints = [];
  LatLng? _startPosition;
  DateTime? _startTime;
  double _totalDistance = 0.0;

  List<LatLng> get routePoints => List.unmodifiable(_routePoints);
  double get totalDistance => _totalDistance;
  LatLng? get startPosition => _startPosition;
  LatLng? get currentPosition => _routePoints.isNotEmpty ? _routePoints.last : null;
  bool get isTracking => _positionStreamSubscription != null;

  /// Starts GPS tracking for a trip.
  Future<void> startTracking() async {
    // Check permissions
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }

    // Get initial position
    Position initialPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    _startPosition = LatLng(initialPosition.latitude, initialPosition.longitude);
    _startTime = DateTime.now();
    _routePoints.clear();
    _routePoints.add(_startPosition!);
    _totalDistance = 0.0;

    // Start listening to position updates
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      final newPoint = LatLng(position.latitude, position.longitude);
      _routePoints.add(newPoint);

      // Calculate distance from last point
      if (_routePoints.length > 1) {
        final lastPoint = _routePoints[_routePoints.length - 2];
        final distance = _calculateDistance(lastPoint, newPoint);
        _totalDistance += distance;
      }
    });
  }

  /// Stops GPS tracking and returns the trip data.
  Map<String, dynamic> stopTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;

    final endTime = DateTime.now();
    final duration = _startTime != null
        ? endTime.difference(_startTime!).inMinutes
        : 0;

    final endPosition = _routePoints.isNotEmpty ? _routePoints.last : null;

    return {
      'route': List<LatLng>.from(_routePoints),
      'distance': _totalDistance,
      'duration': duration,
      'startLatLng': _startPosition,
      'endLatLng': endPosition,
    };
  }

  /// Calculates the distance between two LatLng points in kilometers.
  double _calculateDistance(LatLng start, LatLng end) {
    const double earthRadius = 6371; // Radius of the earth in km
    final double dLat = _degreesToRadians(end.latitude - start.latitude);
    final double dLon = _degreesToRadians(end.longitude - start.longitude);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(start.latitude)) *
            cos(_degreesToRadians(end.latitude)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  /// Disposes the service.
  void dispose() {
    _positionStreamSubscription?.cancel();
  }
}
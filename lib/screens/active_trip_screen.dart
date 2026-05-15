import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/trip.dart';
import '../services/gps_service.dart';
import '../services/storage_service.dart';

/// Screen for actively tracking a trip using GPS.
class ActiveTripScreen extends StatefulWidget {
  const ActiveTripScreen({super.key});

  @override
  State<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends State<ActiveTripScreen> {
  final GpsService _gpsService = GpsService();
  GoogleMapController? _mapController;
  bool _isTracking = false;
  LatLng? _currentPosition;
  final Set<Polyline> _polylines = {};
  double _distance = 0.0;
  int _duration = 0;
  Timer? _timer;

  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _startTracking();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _gpsService.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _startTracking() async {
    try {
      await _gpsService.startTracking();
      setState(() {
        _isTracking = true;
      });

      // Update UI periodically
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _distance = _gpsService.totalDistance;
            _duration = DateTime.now().difference(_startTime!).inSeconds;
            _currentPosition = _gpsService.currentPosition;
            _updatePolylines();
            _updateCamera();
          });
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start tracking: $e')),
        );
        Navigator.of(context).pop();
      }
    }
  }

  void _updatePolylines() {
    if (_gpsService.routePoints.length > 1) {
      _polylines.clear();
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: _gpsService.routePoints,
          color: Colors.blue,
          width: 5,
        ),
      );
    }
  }

  void _updateCamera() {
    if (_currentPosition != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(_currentPosition!),
      );
    }
  }

  Future<void> _stopTracking() async {
    final tripData = _gpsService.stopTracking();
    _timer?.cancel();

    // Create trip object
    final trip = Trip(
      id: const Uuid().v4(),
      startLocation: 'Current Location', // Could be geocoded
      endLocation: 'Current Location', // Could be geocoded
      distance: tripData['distance'],
      duration: tripData['duration'],
      date: DateTime.now(),
      startLatLng: tripData['startLatLng'],
      endLatLng: tripData['endLatLng'],
      route: tripData['route'],
    );

    // Save trip
    final existing = await StorageService.loadTrips();
    existing.add(trip);
    await StorageService.saveTrips(existing);

    if (mounted) {
      Navigator.of(context).pop(trip);
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_currentPosition != null) {
      _updateCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Trip'),
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: const CameraPosition(
              target: LatLng(0, 0),
              zoom: 15,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            polylines: _polylines,
            markers: _currentPosition != null
                ? {
                    Marker(
                      markerId: const MarkerId('current'),
                      position: _currentPosition!,
                      infoWindow: const InfoWindow(title: 'Current Location'),
                    ),
                  }
                : {},
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Distance: ${_distance.toStringAsFixed(2)} km',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      'Duration: ${_duration ~/ 60}:${(_duration % 60).toString().padLeft(2, '0')}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (_isTracking)
                      const Text(
                        'Tracking active',
                        style: TextStyle(color: Colors.green),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: ElevatedButton(
              onPressed: _isTracking ? _stopTracking : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.red,
              ),
              child: const Text('Stop Trip'),
            ),
          ),
        ],
      ),
    );
  }
}
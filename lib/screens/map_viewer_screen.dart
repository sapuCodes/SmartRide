import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/trip.dart';

/// Screen that displays a Google Map showing a trip route.
class MapViewerScreen extends StatefulWidget {
  final Trip trip;

  const MapViewerScreen({
    super.key,
    required this.trip,
  });

  @override
  State<MapViewerScreen> createState() => _MapViewerScreenState();
}

class _MapViewerScreenState extends State<MapViewerScreen> {
  late GoogleMapController mapController;
  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _initializeMapData();
  }

  void _initializeMapData() {
    // Add route polyline
    if (widget.trip.route.isNotEmpty) {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: widget.trip.route,
          color: Colors.blue,
          width: 5,
        ),
      );
    }

    // Add start marker
    if (widget.trip.startLatLng != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('start'),
          position: widget.trip.startLatLng!,
          infoWindow: InfoWindow(title: 'Start: ${widget.trip.startLocation}'),
        ),
      );
    }

    // Add end marker
    if (widget.trip.endLatLng != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('end'),
          position: widget.trip.endLatLng!,
          infoWindow: InfoWindow(title: 'End: ${widget.trip.endLocation}'),
        ),
      );
    }
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    if (widget.trip.route.isNotEmpty) {
      _fitBounds();
    }
  }

  void _fitBounds() {
    if (widget.trip.route.isEmpty) return;

    double minLat = widget.trip.route.map((p) => p.latitude).reduce(min);
    double maxLat = widget.trip.route.map((p) => p.latitude).reduce(max);
    double minLng = widget.trip.route.map((p) => p.longitude).reduce(min);
    double maxLng = widget.trip.route.map((p) => p.longitude).reduce(max);

    mapController.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        50, // padding
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    LatLng initialTarget = widget.trip.startLatLng ?? const LatLng(0, 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Map'),
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: initialTarget,
          zoom: 15,
        ),
        polylines: _polylines,
        markers: _markers,
      ),
    );
  }
}

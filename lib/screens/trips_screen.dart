import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/trip.dart';
import '../services/storage_service.dart';
import 'add_trip_screen.dart';
import 'map_viewer_screen.dart';
import 'active_trip_screen.dart';

/// List of trips with the ability to add a new entry.
class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  List<Trip> _trips = [];

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    final loaded = await StorageService.loadTrips();
    // Sort by newest first
    loaded.sort((a, b) => b.date.compareTo(a.date));
    setState(() {
      _trips = loaded;
    });
  }

  Future<void> _openAdd() async {
    final result = await Navigator.of(context)
        .push<Trip>(MaterialPageRoute(builder: (_) => const AddTripScreen()));
    if (result != null) {
      // newly added trip returned; refresh list
      await _loadTrips();
    }
  }

  Future<void> _handleTripButton() async {
    // Navigate to active trip screen
    final result = await Navigator.of(context).push<Trip>(
      MaterialPageRoute(builder: (_) => const ActiveTripScreen()),
    );
    if (result != null) {
      await _loadTrips();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trip recorded')),
        );
      }
    }
  }

  Future<void> _deleteTrip(Trip trip) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Trip'),
        content: Text(
          'Are you sure you want to delete the trip from ${trip.startLocation} to ${trip.endLocation}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final updatedTrips = List<Trip>.from(_trips)..remove(trip);
      await StorageService.saveTrips(updatedTrips);
      await _loadTrips();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trip deleted successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: FilledButton(
              onPressed: _handleTripButton,
              child: const Text('Start Trip'),
            ),
          ),
          Expanded(
            child: _trips.isEmpty
                ? const Center(child: Text('No trips recorded.'))
                : ListView.builder(
                    itemCount: _trips.length,
                    itemBuilder: (context, index) {
                      final trip = _trips[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${trip.startLocation} → ${trip.endLocation}',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _infoItem(
                                context,
                                label: 'Distance',
                                value: '${trip.distance} km',
                              ),
                            ),
                            Expanded(
                              child: _infoItem(
                                context,
                                label: 'Duration',
                                value: '${trip.duration} min',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _infoItem(
                          context,
                          label: 'Date',
                          value: DateFormat('MMM dd, yyyy • hh:mm a').format(trip.date.toLocal()),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.tonal(
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => MapViewerScreen(trip: trip),
                                  ),
                                ),
                                child: const Text('View Route'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              onPressed: () => _deleteTrip(trip),
                              icon: const Icon(Icons.delete),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.red.withValues(alpha: 0.1),
                                foregroundColor: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),          ),
        ],
      ),      floatingActionButton: FloatingActionButton(
        onPressed: _openAdd,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _infoItem(BuildContext context,
      {required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/trip.dart';
import '../services/storage_service.dart';

/// Screen that allows the user to enter a new trip and save it.
class AddTripScreen extends StatefulWidget {
  const AddTripScreen({super.key});

  @override
  State<AddTripScreen> createState() => _AddTripScreenState();
}

class _AddTripScreenState extends State<AddTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _startController = TextEditingController();
  final _endController = TextEditingController();
  final _distanceController = TextEditingController();
  final _durationController = TextEditingController();

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    _distanceController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final trip = Trip(
      id: const Uuid().v4(),
      startLocation: _startController.text.trim(),
      endLocation: _endController.text.trim(),
      distance: double.tryParse(_distanceController.text) ?? 0.0,
      duration: int.tryParse(_durationController.text) ?? 0,
      date: DateTime.now(),
    );

    // load existing trips and append then save
    final existing = await StorageService.loadTrips();
    existing.add(trip);
    await StorageService.saveTrips(existing);

    if (!mounted) return;
    Navigator.of(context).pop(trip);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Trip')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _startController,
                decoration: const InputDecoration(labelText: 'Start Location'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Start location is required';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _endController,
                decoration: const InputDecoration(labelText: 'End Location'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'End location is required';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _distanceController,
                decoration: const InputDecoration(labelText: 'Distance (km)'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Distance is required';
                  }
                  final distance = double.tryParse(v);
                  if (distance == null) {
                    return 'Please enter a valid number';
                  }
                  if (distance <= 0) {
                    return 'Distance must be greater than 0';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(labelText: 'Duration (min)'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Duration is required';
                  }
                  final duration = int.tryParse(v);
                  if (duration == null) {
                    return 'Please enter a valid whole number';
                  }
                  if (duration <= 0) {
                    return 'Duration must be greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _save, child: const Text('Save')),
            ],
          ),
        ),
      ),
    );
  }
}

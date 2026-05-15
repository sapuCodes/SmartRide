import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/fuel_log.dart';
import '../services/storage_service.dart';

class AddFuelScreen extends StatefulWidget {
  const AddFuelScreen({super.key});

  @override
  State<AddFuelScreen> createState() => _AddFuelScreenState();
}

class _AddFuelScreenState extends State<AddFuelScreen> {
  final _formKey = GlobalKey<FormState>();
  final _litersController = TextEditingController();
  final _priceController = TextEditingController();
  final _odoController = TextEditingController();

  double get _totalCost {
    final liters = double.tryParse(_litersController.text) ?? 0.0;
    final price = double.tryParse(_priceController.text) ?? 0.0;
    return liters * price;
  }

  @override
  void dispose() {
    _litersController.dispose();
    _priceController.dispose();
    _odoController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final log = FuelLog(
      id: const Uuid().v4(),
      date: DateTime.now(),
      liters: double.tryParse(_litersController.text) ?? 0.0,
      pricePerLiter: double.tryParse(_priceController.text) ?? 0.0,
      totalCost: _totalCost,
      odometerReading: double.tryParse(_odoController.text) ?? 0.0,
    );

    final existing = await StorageService.loadFuelLogs();
    existing.add(log);
    await StorageService.saveFuelLogs(existing);

    if (!mounted) return;
    Navigator.of(context).pop(log);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Fuel Log')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _litersController,
                decoration: const InputDecoration(labelText: 'Liters'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Liters is required';
                  }
                  final liters = double.tryParse(v);
                  if (liters == null) {
                    return 'Please enter a valid number';
                  }
                  if (liters <= 0) {
                    return 'Liters must be greater than 0';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _priceController,
                decoration:
                    const InputDecoration(labelText: 'Price per liter'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Price per liter is required';
                  }
                  final price = double.tryParse(v);
                  if (price == null) {
                    return 'Please enter a valid number';
                  }
                  if (price <= 0) {
                    return 'Price must be greater than 0';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _odoController,
                decoration: const InputDecoration(labelText: 'Odometer'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Odometer reading is required';
                  }
                  final odometer = double.tryParse(v);
                  if (odometer == null) {
                    return 'Please enter a valid number';
                  }
                  if (odometer < 0) {
                    return 'Odometer reading cannot be negative';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Text('Total: 4B0 ${_totalCost.toStringAsFixed(2)}'),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _save, child: const Text('Save')),
            ],
          ),
        ),
      ),
    );
  }
}

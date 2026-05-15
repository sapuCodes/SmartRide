import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/fuel_log.dart';
import '../models/trip.dart';
import '../providers/theme_provider.dart';
import '../services/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isExporting = false;
  bool _isImporting = false;
  double _tankSize = 50.0; // Default tank size

  @override
  void initState() {
    super.initState();
    _loadTankSize();
  }

  Future<Directory> _getExportDirectory() async {
    if (Platform.isAndroid) {
      final directories = await getExternalStorageDirectories(
        type: StorageDirectory.downloads,
      );
      if (directories != null && directories.isNotEmpty) {
        return directories.first;
      }
    }

    final downloadDir = await getDownloadsDirectory();
    if (downloadDir != null) {
      return downloadDir;
    }

    return await getApplicationDocumentsDirectory();
  }

  Future<void> _exportData() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final trips = await StorageService.loadTrips();
      final fuelLogs = await StorageService.loadFuelLogs();

      final exportData = {
        'exportDate': DateTime.now().toIso8601String(),
        'version': '1.0.0',
        'data': {
          'trips': trips.map((trip) => trip.toJson()).toList(),
          'fuelLogs': fuelLogs.map((log) => log.toJson()).toList(),
        },
      };

      final jsonString = jsonEncode(exportData);
      final directory = await _getExportDirectory();
      final fileName = 'smartride_export_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(jsonString);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Data exported successfully!\nSaved to: ${file.path}'),
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  Future<void> _importData() async {
    setState(() {
      _isImporting = true;
    });

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final filePath = result.files.single.path;
      if (filePath == null) {
        throw Exception('No file path was returned.');
      }

      final file = File(filePath);
      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      final payload = data['data'] as Map<String, dynamic>?;
      if (payload == null) {
        throw Exception('Invalid import file format.');
      }

      final importedTrips = (payload['trips'] as List<dynamic>?)
              ?.map((item) => Trip.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [];
      final importedFuelLogs = (payload['fuelLogs'] as List<dynamic>?)
              ?.map((item) => FuelLog.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [];

      final existingTrips = await StorageService.loadTrips();
      final existingFuelLogs = await StorageService.loadFuelLogs();

      final existingTripIds = existingTrips.map((t) => t.id).toSet();
      final existingFuelLogIds = existingFuelLogs.map((l) => l.id).toSet();

      final tripsToAdd = importedTrips
          .where((trip) => !existingTripIds.contains(trip.id))
          .toList();
      final fuelLogsToAdd = importedFuelLogs
          .where((log) => !existingFuelLogIds.contains(log.id))
          .toList();

      final mergedTrips = [...existingTrips, ...tripsToAdd];
      final mergedFuelLogs = [...existingFuelLogs, ...fuelLogsToAdd];

      await StorageService.saveTrips(mergedTrips);
      await StorageService.saveFuelLogs(mergedFuelLogs);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Import successful! ${tripsToAdd.length} new trips and ${fuelLogsToAdd.length} new fuel logs added.',
            ),
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }

  Future<void> _loadTankSize() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _tankSize = prefs.getDouble('tankSize') ?? 50.0;
    });
  }

  Future<void> _saveTankSize(double size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('tankSize', size);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),

          // Theme Settings Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Appearance',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, child) {
                      return SwitchListTile(
                        title: const Text('Dark Mode'),
                        subtitle: Text(
                          themeProvider.themeMode == ThemeMode.system
                              ? 'Follow system setting'
                              : themeProvider.themeMode == ThemeMode.dark
                                  ? 'Always dark'
                                  : 'Always light',
                        ),
                        value: themeProvider.isDarkMode,
                        onChanged: (value) {
                          themeProvider.toggleTheme();
                        },
                        secondary: Icon(
                          themeProvider.isDarkMode
                              ? Icons.dark_mode
                              : Icons.light_mode,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Fuel Estimation Settings Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fuel Estimation',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: _tankSize.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Tank Size (Liters)',
                      hintText: 'e.g., 50',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final size = double.tryParse(value);
                      if (size != null && size > 0) {
                        setState(() {
                          _tankSize = size;
                        });
                        _saveTankSize(size);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Set your vehicle\'s fuel tank capacity for accurate range estimation.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Data Management',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isExporting ? null : _exportData,
                      icon: _isExporting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.download),
                      label: Text(_isExporting ? 'Exporting...' : 'Export Data'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isImporting ? null : _importData,
                      icon: _isImporting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.upload),
                      label: Text(_isImporting ? 'Importing...' : 'Import Data'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Export and import trips and fuel logs using a JSON file. Import will merge new items and preserve existing data.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // About Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About SmartRide',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Version 1.0.0',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Track your vehicle efficiency with ease.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

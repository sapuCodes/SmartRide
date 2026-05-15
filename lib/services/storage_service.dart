import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/trip.dart';
import '../models/fuel_log.dart';

/// Simple wrapper around [SharedPreferences] for persisting trips and fuel
/// logs as JSON strings.
class StorageService {
  StorageService._();

  static const String _tripsKey = 'trips';
  static const String _fuelLogsKey = 'fuelLogs';

  /// Saves the given list of [Trip] objects to local storage.
  static Future<void> saveTrips(List<Trip> trips) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = trips.map((t) => t.toJson()).toList();
    await prefs.setString(_tripsKey, jsonEncode(jsonList));
  }

  /// Loads trips from local storage, returning an empty list if none exist.
  static Future<List<Trip>> loadTrips() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_tripsKey);
    if (stored == null || stored.isEmpty) {
      return [];
    }

    final List decoded = jsonDecode(stored) as List;
    return decoded.map((e) => Trip.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Persists a list of [FuelLog] entries.
  static Future<void> saveFuelLogs(List<FuelLog> logs) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = logs.map((l) => l.toJson()).toList();
    await prefs.setString(_fuelLogsKey, jsonEncode(jsonList));
  }

  /// Reads fuel logs from storage, returning an empty list if none are saved.
  static Future<List<FuelLog>> loadFuelLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_fuelLogsKey);
    if (stored == null || stored.isEmpty) {
      return [];
    }

    final List decoded = jsonDecode(stored) as List;
    return decoded
        .map((e) => FuelLog.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

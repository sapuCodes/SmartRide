import 'dart:math';

import '../models/fuel_log.dart';
import '../models/trip.dart';

/// Service for calculating fuel analytics and insights.
class FuelAnalyticsService {
  static const double averageFuelTankCapacity = 50.0; // liters, can be configurable

  /// Calculate average fuel efficiency (KM/L)
  static double calculateAverageEfficiency(List<FuelLog> fuelLogs, List<Trip> trips) {
    if (fuelLogs.isEmpty || trips.isEmpty) return 0.0;

    // Simple calculation: total distance / total fuel used
    double totalDistance = trips.fold(0.0, (sum, trip) => sum + trip.distance);
    double totalFuel = fuelLogs.fold(0.0, (sum, log) => sum + log.liters);

    return totalDistance / totalFuel;
  }

  /// Calculate total fuel spent
  static double calculateTotalFuelSpent(List<FuelLog> fuelLogs) {
    return fuelLogs.fold(0.0, (sum, log) => sum + log.totalCost);
  }

  /// Calculate monthly fuel cost
  static double calculateMonthlyFuelCost(List<FuelLog> fuelLogs) {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final nextMonth = DateTime(now.year, now.month + 1);

    final monthlyLogs = fuelLogs.where((log) =>
      log.date.isAfter(currentMonth) && log.date.isBefore(nextMonth)
    ).toList();

    return calculateTotalFuelSpent(monthlyLogs);
  }

  /// Estimate fuel remaining (simplified - assumes last log is current)
  static double estimateFuelRemaining(List<FuelLog> fuelLogs, List<Trip> trips) {
    if (fuelLogs.isEmpty) return averageFuelTankCapacity;

    // Sort by date descending
    fuelLogs.sort((a, b) => b.date.compareTo(a.date));
    final lastLog = fuelLogs.first;

    // Estimate fuel used since last fill
    final recentTrips = trips.where((trip) =>
      trip.date.isAfter(lastLog.date)
    ).toList();

    double distanceSinceLastFill = recentTrips.fold(0.0, (sum, trip) => sum + trip.distance);
    double avgEfficiency = calculateAverageEfficiency(fuelLogs, trips);

    if (avgEfficiency == 0) return averageFuelTankCapacity;

    double fuelUsed = distanceSinceLastFill / avgEfficiency;
    double remaining = lastLog.liters - fuelUsed;

    return max(0, remaining);
  }

  /// Estimate driving range
  static double estimateDrivingRange(List<FuelLog> fuelLogs, List<Trip> trips) {
    double remainingFuel = estimateFuelRemaining(fuelLogs, trips);
    double avgEfficiency = calculateAverageEfficiency(fuelLogs, trips);

    return remainingFuel * avgEfficiency;
  }

  /// Calculate average cost per KM
  static double calculateAverageCostPerKm(List<FuelLog> fuelLogs, List<Trip> trips) {
    double totalCost = calculateTotalFuelSpent(fuelLogs);
    double totalDistance = trips.fold(0.0, (sum, trip) => sum + trip.distance);

    if (totalDistance == 0) return 0.0;

    return totalCost / totalDistance;
  }

  /// Generate smart insights
  static List<String> generateInsights(List<FuelLog> fuelLogs, List<Trip> trips) {
    List<String> insights = [];

    if (fuelLogs.isEmpty || trips.isEmpty) {
      insights.add("Add fuel logs and trips to see insights");
      return insights;
    }

    double avgEfficiency = calculateAverageEfficiency(fuelLogs, trips);
    double range = estimateDrivingRange(fuelLogs, trips);

    // Fuel efficiency insights
    if (avgEfficiency > 15) {
      insights.add("Excellent fuel efficiency! Keep up the good driving habits.");
    } else if (avgEfficiency < 10) {
      insights.add("Fuel efficiency could be improved. Consider smoother driving.");
    }

    // Range warnings
    if (range < 50) {
      insights.add("⚠️ Low fuel warning! Estimated range: ${range.toStringAsFixed(0)} KM");
    } else if (range < 100) {
      insights.add("Plan to refuel soon. Estimated range: ${range.toStringAsFixed(0)} KM");
    }

    // Recent trends (simplified)
    if (fuelLogs.length >= 2) {
      final recent = fuelLogs.sublist(0, min(3, fuelLogs.length));
      final older = fuelLogs.sublist(min(3, fuelLogs.length));

      if (older.isNotEmpty) {
        double recentAvg = recent.fold(0.0, (sum, log) => sum + log.pricePerLiter) / recent.length;
        double olderAvg = older.fold(0.0, (sum, log) => sum + log.pricePerLiter) / older.length;

        double priceChange = ((recentAvg - olderAvg) / olderAvg) * 100;
        if (priceChange > 5) {
          insights.add("Fuel prices increased by ${priceChange.toStringAsFixed(1)}% recently");
        } else if (priceChange < -5) {
          insights.add("Fuel prices decreased by ${(-priceChange).toStringAsFixed(1)}% recently");
        }
      }
    }

    // Trip analysis
    if (trips.length >= 3) {
      final shortTrips = trips.where((trip) => trip.distance < 10).length;
      final longTrips = trips.where((trip) => trip.distance > 50).length;

      if (longTrips > shortTrips) {
        insights.add("You perform better on long trips. Consider consolidating short trips.");
      }
    }

    return insights;
  }

  /// Get best and worst efficiency trips
  static Map<String, Trip?> getEfficiencyExtremes(List<Trip> trips, List<FuelLog> fuelLogs) {
    if (trips.isEmpty) return {'best': null, 'worst': null};

    // This is simplified - in reality, we'd need to correlate specific fuel usage per trip
    // For now, assume efficiency based on trip distance vs average
    double avgEfficiency = calculateAverageEfficiency(fuelLogs, trips);

    Trip? bestTrip;
    Trip? worstTrip;

    for (final trip in trips) {
      // Simplified: assume efficiency proportional to distance (longer trips might be more efficient)
      double estimatedEfficiency = avgEfficiency * (1 + (trip.distance - 20) / 100); // arbitrary adjustment

      if (bestTrip == null || estimatedEfficiency > (bestTrip.distance / avgEfficiency)) {
        bestTrip = trip;
      }
      if (worstTrip == null || estimatedEfficiency < (worstTrip.distance / avgEfficiency)) {
        worstTrip = trip;
      }
    }

    return {'best': bestTrip, 'worst': worstTrip};
  }

  /// Calculate monthly fuel usage data for charts
  static Map<String, double> getMonthlyFuelUsage(List<FuelLog> fuelLogs) {
    Map<String, double> monthlyData = {};

    for (final log in fuelLogs) {
      String monthKey = '${log.date.year}-${log.date.month.toString().padLeft(2, '0')}';
      monthlyData[monthKey] = (monthlyData[monthKey] ?? 0) + log.liters;
    }

    return monthlyData;
  }

  /// Calculate fuel cost trend
  static List<Map<String, dynamic>> getFuelCostTrend(List<FuelLog> fuelLogs) {
    List<Map<String, dynamic>> trend = [];

    // Sort by date
    fuelLogs.sort((a, b) => a.date.compareTo(b.date));

    for (final log in fuelLogs) {
      trend.add({
        'date': log.date,
        'cost': log.totalCost,
      });
    }

    return trend;
  }

  /// Predict next refuel date (simplified)
  static DateTime? predictNextRefuel(List<FuelLog> fuelLogs, List<Trip> trips) {
    if (fuelLogs.isEmpty || trips.isEmpty) return null;

    double avgEfficiency = calculateAverageEfficiency(fuelLogs, trips);
    double avgFuelPerRefuel = fuelLogs.fold(0.0, (sum, log) => sum + log.liters) / fuelLogs.length;

    if (avgEfficiency == 0) return null;

    double avgDistancePerRefuel = avgFuelPerRefuel * avgEfficiency;

    // Estimate daily driving
    final recentTrips = trips.where((trip) =>
      trip.date.isAfter(DateTime.now().subtract(const Duration(days: 30)))
    ).toList();

    if (recentTrips.isEmpty) return null;

    double dailyDistance = recentTrips.fold(0.0, (sum, trip) => sum + trip.distance) / 30;

    if (dailyDistance == 0) return null;

    double daysUntilRefuel = avgDistancePerRefuel / dailyDistance;

    return DateTime.now().add(Duration(days: daysUntilRefuel.round()));
  }

  /// Calculate fuel depletion rate (L/100km) based on historical data
  static double calculateFuelDepletionRate(List<FuelLog> fuelLogs, List<Trip> trips) {
    if (fuelLogs.isEmpty || trips.isEmpty) return 0.0;

    double totalDistance = trips.fold(0.0, (sum, trip) => sum + trip.distance);
    double totalFuel = fuelLogs.fold(0.0, (sum, log) => sum + log.liters);

    if (totalDistance == 0) return 0.0;

    // Convert to L/100km
    return (totalFuel / totalDistance) * 100;
  }

  /// Estimate empty date based on current fuel level and depletion rate
  static DateTime? estimateEmptyDate(double currentFuelLevel, double depletionRate) {
    if (currentFuelLevel <= 0 || depletionRate <= 0) return null;

    // Calculate distance remaining
    double distanceRemaining = (currentFuelLevel / depletionRate) * 100; // km

    // Estimate daily driving from recent data (simplified - using last 30 days average)
    // For now, assume 50km/day average - in real app, calculate from actual trip data
    double dailyDistance = 50.0; // This should be calculated from actual data

    if (dailyDistance <= 0) return null;

    double daysUntilEmpty = distanceRemaining / dailyDistance;

    return DateTime.now().add(Duration(days: daysUntilEmpty.round()));
  }

  /// Recommend refuel timing based on current fuel level and depletion rate
  static String recommendRefuelTiming(double currentFuelLevel, double depletionRate) {
    if (currentFuelLevel <= 0 || depletionRate <= 0) return 'Enter fuel data';

    double distanceRemaining = (currentFuelLevel / depletionRate) * 100;

    if (distanceRemaining < 50) {
      return 'Refuel immediately!';
    } else if (distanceRemaining < 100) {
      return 'Refuel soon';
    } else if (distanceRemaining < 200) {
      return 'Refuel this week';
    } else {
      return 'Fuel level good';
    }
  }
}
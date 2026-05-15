import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/trip.dart';
import '../models/fuel_log.dart';
import '../services/storage_service.dart';
import '../utils/efficiency_calculator.dart';

/// Displays fuel efficiency reports based on stored trips and fuel logs.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  double _totalDistance = 0;
  bool _loading = true;
  List<Trip> _trips = [];
  List<FuelLog> _logs = [];
  int _totalTrips = 0;
  double _totalFuelCost = 0;
  double _averageTripDistance = 0;
  double _bestFuelEfficiency = 0;

  // prediction values
  double _avgMonthlyFuel = 0;
  double _predictedNextMonthFuel = 0;

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    final trips = await StorageService.loadTrips();
    final totalDistance =
        trips.fold(0.0, (sum, trip) => sum + trip.distance);

    final logs = await StorageService.loadFuelLogs();
    final totalFuelCost = logs.fold(0.0, (sum, log) => sum + log.totalCost);
    final totalFuel = logs.fold(0.0, (sum, log) => sum + log.liters);

    // compute average monthly fuel consumption
    double avgMonthlyFuel = 0;
    if (logs.isNotEmpty) {
      final Map<String, double> monthFuel = {};
      for (final log in logs) {
        final key = '${log.date.month}/${log.date.year}';
        monthFuel[key] = (monthFuel[key] ?? 0) + log.liters;
      }
      avgMonthlyFuel = monthFuel.values.reduce((a, b) => a + b) / monthFuel.length;
    }
    final predicted = avgMonthlyFuel;

    setState(() {
      _trips = trips;
      _logs = logs;
      _totalDistance = totalDistance;
      _totalFuelCost = totalFuelCost;
      _totalTrips = trips.length;
      _averageTripDistance = trips.isNotEmpty ? totalDistance / trips.length : 0;
      _bestFuelEfficiency = calculateFuelEfficiency(totalDistance, totalFuel);
      _avgMonthlyFuel = avgMonthlyFuel;
      _predictedNextMonthFuel = predicted;
      _loading = false;
    });
  }

  List<FlSpot> _getDistanceChartData() {
    // Sort trips by date and create spots
    final sorted = List<Trip>.from(_trips)..sort((a, b) => a.date.compareTo(b.date));
    return sorted.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.distance);
    }).toList();
  }

  List<BarChartGroupData> _getFuelCostChartData() {
    // Group fuel logs by month and calculate monthly cost
    final Map<String, double> monthlyCosts = {};
    
    for (final log in _logs) {
      final monthKey = '${log.date.month}/${log.date.year}';
      monthlyCosts[monthKey] = (monthlyCosts[monthKey] ?? 0) + log.totalCost;
    }

    // Create bar groups
    final groups = <BarChartGroupData>[];
    var index = 0;
    for (final cost in monthlyCosts.values) {
      groups.add(
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: cost,
              color: Colors.blue,
              width: 16,
            ),
          ],
        ),
      );
      index++;
    }
    
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Summary metrics
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Summary',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildMetricCard(
                                    context,
                                    'Total Trips',
                                    _totalTrips.toString(),
                                    Icons.directions_car,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildMetricCard(
                                    context,
                                    'Total Distance',
                                    '${_totalDistance.toStringAsFixed(2)} km',
                                    Icons.straighten,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildMetricCard(
                                    context,
                                    'Total Fuel Cost',
                                    '\$${_totalFuelCost.toStringAsFixed(2)}',
                                    Icons.attach_money,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildMetricCard(
                                    context,
                                    'Avg Trip Distance',
                                    '${_averageTripDistance.toStringAsFixed(2)} km',
                                    Icons.timeline,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildMetricCard(
                              context,
                              'Best Fuel Efficiency',
                              '${_bestFuelEfficiency.toStringAsFixed(2)} km/L',
                              Icons.local_gas_station,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildMetricCard(
                                    context,
                                    'Avg Monthly Fuel',
                                    '${_avgMonthlyFuel.toStringAsFixed(2)} L',
                                    Icons.bar_chart,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildMetricCard(
                                    context,
                                    'Predicted Next Month',
                                    '${_predictedNextMonthFuel.toStringAsFixed(2)} L',
                                    Icons.calendar_today,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Distance over time chart
                if (_trips.isNotEmpty) ...[
                  Text(
                    'Distance Over Time',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        height: 200,
                        child: LineChart(
                          LineChartData(
                            gridData: const FlGridData(show: true),
                            titlesData: const FlTitlesData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: _getDistanceChartData(),
                                isCurved: true,
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.blue.withValues(alpha: 0.8),
                                    Colors.blue.withValues(alpha: 0.3),
                                  ],
                                ),
                                dotData: const FlDotData(show: true),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Fuel cost by month chart
                if (_logs.isNotEmpty) ...[
                  Text(
                    'Monthly Fuel Cost',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        height: 200,
                        child: BarChart(
                          BarChartData(
                            gridData: const FlGridData(show: true),
                            titlesData: const FlTitlesData(show: false),
                            barGroups: _getFuelCostChartData(),
                            borderData: FlBorderData(show: false),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

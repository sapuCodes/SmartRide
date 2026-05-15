import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/fuel_log.dart';
import '../models/trip.dart';
import '../services/storage_service.dart';
import '../services/fuel_analytics_service.dart';
import 'add_fuel_screen.dart';

/// Intelligent fuel analytics dashboard.
class FuelScreen extends StatefulWidget {
  const FuelScreen({super.key});

  @override
  State<FuelScreen> createState() => _FuelScreenState();
}

class _FuelScreenState extends State<FuelScreen> {
  List<FuelLog> _fuelLogs = [];
  List<Trip> _trips = [];
  bool _showLogs = false;
  double _currentFuelLevel = 0.0; // Liters
  double _recentRefillAmount = 0.0; // Liters

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadFuelEstimationData();
  }

  Future<void> _loadData() async {
    final fuelLogs = await StorageService.loadFuelLogs();
    final trips = await StorageService.loadTrips();

    setState(() {
      _fuelLogs = fuelLogs;
      _trips = trips;
    });
  }

  Future<void> _openAdd() async {
    final result = await Navigator.of(context)
        .push<FuelLog>(MaterialPageRoute(builder: (_) => const AddFuelScreen()));
    if (result != null) {
      await _loadData();
    }
  }

  Future<void> _loadFuelEstimationData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentFuelLevel = prefs.getDouble('currentFuelLevel') ?? 0.0;
      _recentRefillAmount = prefs.getDouble('recentRefillAmount') ?? 0.0;
    });
  }

  Future<void> _saveFuelEstimationData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('currentFuelLevel', _currentFuelLevel);
    await prefs.setDouble('recentRefillAmount', _recentRefillAmount);
  }

  @override
  Widget build(BuildContext context) {
    final insights = FuelAnalyticsService.generateInsights(_fuelLogs, _trips);
    final avgEfficiency = FuelAnalyticsService.calculateAverageEfficiency(_fuelLogs, _trips);
    final monthlyCost = FuelAnalyticsService.calculateMonthlyFuelCost(_fuelLogs);
    final drivingRange = FuelAnalyticsService.estimateDrivingRange(_fuelLogs, _trips);
    final totalDistance = _trips.fold(0.0, (sum, trip) => sum + trip.distance);
    final totalFuelUsed = _fuelLogs.fold(0.0, (sum, log) => sum + log.liters);

    return Scaffold(
      body: _fuelLogs.isEmpty && _trips.isEmpty
          ? _buildEmptyState()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary Cards
                  _buildSummaryCards(
                    totalDistance: totalDistance,
                    totalFuelUsed: totalFuelUsed,
                    avgEfficiency: avgEfficiency,
                    drivingRange: drivingRange,
                    monthlyCost: monthlyCost,
                  ),
                  const SizedBox(height: 24),

                  // Fuel Estimation Engine
                  _buildFuelEstimationSection(),
                  const SizedBox(height: 24),

                  // Insights
                  if (insights.isNotEmpty) ...[
                    Text(
                      'Smart Insights',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    ...insights.map((insight) => Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(insight),
                      ),
                    )),
                    const SizedBox(height: 24),
                  ],

                  // Charts
                  Text(
                    'Analytics',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  _buildFuelCostChart(),
                  const SizedBox(height: 24),
                  _buildEfficiencyChart(),
                  const SizedBox(height: 24),

                  // Performance Analysis
                  Text(
                    'Performance Analysis',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  _buildPerformanceCards(),
                  const SizedBox(height: 24),

                  // Fuel Logs Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Fuel Logs',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      TextButton.icon(
                        onPressed: () => setState(() => _showLogs = !_showLogs),
                        icon: Icon(_showLogs ? Icons.expand_less : Icons.expand_more),
                        label: Text(_showLogs ? 'Hide' : 'Show'),
                      ),
                    ],
                  ),
                  if (_showLogs) ...[
                    const SizedBox(height: 12),
                    ..._fuelLogs.map((log) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${log.liters}L • \$${log.totalCost.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _infoItem('Price/L', '\$${log.pricePerLiter.toStringAsFixed(2)}'),
                                ),
                                Expanded(
                                  child: _infoItem('Odometer', '${log.odometerReading.toStringAsFixed(0)} km'),
                                ),
                              ],
                            ),
                            Text(
                              log.date.toLocal().toString().split(' ')[0],
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    )),
                  ],
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAdd,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.local_gas_station, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'No fuel data yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Add fuel logs and trips to see analytics',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _openAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add Fuel Log'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards({
    required double totalDistance,
    required double totalFuelUsed,
    required double avgEfficiency,
    required double drivingRange,
    required double monthlyCost,
  }) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _summaryCard('Total Distance', '${totalDistance.toStringAsFixed(0)} km', Icons.directions_car),
        _summaryCard('Fuel Used', '${totalFuelUsed.toStringAsFixed(1)} L', Icons.local_gas_station),
        _summaryCard('Avg Efficiency', '${avgEfficiency.toStringAsFixed(1)} km/L', Icons.speed),
        _summaryCard('Est. Range', '${drivingRange.toStringAsFixed(0)} km', Icons.route),
        _summaryCard('Monthly Cost', '\$${monthlyCost.toStringAsFixed(0)}', Icons.attach_money),
        _summaryCard('Cost/KM', '\$${avgEfficiency > 0 ? (monthlyCost / 30 / avgEfficiency).toStringAsFixed(2) : '0.00'}', Icons.trending_up),
      ],
    );
  }

  Widget _summaryCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFuelEstimationSection() {
    final depletionRate = FuelAnalyticsService.calculateFuelDepletionRate(_fuelLogs, _trips);
    final estimatedEmptyDate = FuelAnalyticsService.estimateEmptyDate(_currentFuelLevel, depletionRate);
    final refuelRecommendation = FuelAnalyticsService.recommendRefuelTiming(_currentFuelLevel, depletionRate);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fuel Estimation Engine',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            // Input fields
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _currentFuelLevel.toStringAsFixed(1),
                    decoration: const InputDecoration(
                      labelText: 'Current Fuel Level (L)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        _currentFuelLevel = double.tryParse(value) ?? 0.0;
                      });
                      _saveFuelEstimationData();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: _recentRefillAmount.toStringAsFixed(1),
                    decoration: const InputDecoration(
                      labelText: 'Recent Refill (L)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        _recentRefillAmount = double.tryParse(value) ?? 0.0;
                      });
                      _saveFuelEstimationData();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Estimations
            if (_currentFuelLevel > 0 && depletionRate > 0) ...[
              _buildEstimationCard(
                'Estimated Range',
                '${(_currentFuelLevel / depletionRate * 100).round()} km',
                Icons.directions_car,
              ),
              _buildEstimationCard(
                'Depletion Rate',
                '${depletionRate.toStringAsFixed(2)} L/100km',
                Icons.trending_down,
              ),
              _buildEstimationCard(
                'Empty Date',
                estimatedEmptyDate != null
                    ? '${estimatedEmptyDate.day}/${estimatedEmptyDate.month}/${estimatedEmptyDate.year}'
                    : 'N/A',
                Icons.calendar_today,
              ),
              _buildEstimationCard(
                'Refuel Recommendation',
                refuelRecommendation,
                Icons.local_gas_station,
              ),
            ] else ...[
              const Text('Enter current fuel level to see estimates'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEstimationCard(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildFuelCostChart() {
    final trend = FuelAnalyticsService.getFuelCostTrend(_fuelLogs);

    if (trend.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fuel Cost Trend',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: trend.asMap().entries.map((entry) =>
                        FlSpot(entry.key.toDouble(), entry.value['cost'])
                      ).toList(),
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEfficiencyChart() {
    final monthlyUsage = FuelAnalyticsService.getMonthlyFuelUsage(_fuelLogs);

    if (monthlyUsage.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Fuel Usage',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: monthlyUsage.entries.map((entry) =>
                    BarChartGroupData(
                      x: monthlyUsage.keys.toList().indexOf(entry.key),
                      barRods: [
                        BarChartRodData(
                          toY: entry.value,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    )
                  ).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceCards() {
    final extremes = FuelAnalyticsService.getEfficiencyExtremes(_trips, _fuelLogs);
    final bestTrip = extremes['best'];
    final worstTrip = extremes['worst'];

    return Column(
      children: [
        if (bestTrip != null)
          Card(
            child: ListTile(
              leading: const Icon(Icons.thumb_up, color: Colors.green),
              title: const Text('Best Efficiency Trip'),
              subtitle: Text('${bestTrip.startLocation} → ${bestTrip.endLocation}'),
              trailing: Text('${bestTrip.distance.toStringAsFixed(0)} km'),
            ),
          ),
        if (worstTrip != null)
          Card(
            child: ListTile(
              leading: const Icon(Icons.thumb_down, color: Colors.red),
              title: const Text('Worst Efficiency Trip'),
              subtitle: Text('${worstTrip.startLocation} → ${worstTrip.endLocation}'),
              trailing: Text('${worstTrip.distance.toStringAsFixed(0)} km'),
            ),
          ),
      ],
    );
  }

  Widget _infoItem(String label, String value) {
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


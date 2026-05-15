import 'package:flutter/material.dart';

import '../models/fuel_log.dart';
import '../models/trip.dart';
import '../services/fuel_analytics_service.dart';
import '../services/storage_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<FuelLog> _fuelLogs = [];
  List<Trip> _trips = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final fuelLogs = await StorageService.loadFuelLogs();
    final trips = await StorageService.loadTrips();

    setState(() {
      _fuelLogs = fuelLogs;
      _trips = trips;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Calculate metrics
    final totalDistance = _trips.fold(0.0, (sum, trip) => sum + trip.distance);
    final avgEfficiency = FuelAnalyticsService.calculateAverageEfficiency(_fuelLogs, _trips);
    final totalFuelCost = FuelAnalyticsService.calculateTotalFuelSpent(_fuelLogs);

    // Get recent trip
    final recentTrip = _trips.isNotEmpty ? _trips.last : null;

    // Calculate monthly fuel budget progress (example: 5000 LKR budget)
    final monthlyBudget = 5000.0;
    final monthlyCost = FuelAnalyticsService.calculateMonthlyFuelCost(_fuelLogs);
    final budgetProgress = monthlyCost / monthlyBudget;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0B1220), Color(0xFF111924)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 22.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SmartRide Dashboard',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.25,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your vehicle performance at a glance',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.blueGrey[200],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),

            // Summary Card
            _buildSummaryCard(
              totalDistance: totalDistance,
              avgEfficiency: avgEfficiency,
              totalFuelCost: totalFuelCost,
            ),
            const SizedBox(height: 22),

            // Recent Trip Snippet
            if (recentTrip != null) ...[
              _buildRecentTripCard(recentTrip),
              const SizedBox(height: 22),
            ],

            // Monthly Fuel Budget Progress
            _buildBudgetProgressCard(monthlyCost, monthlyBudget, budgetProgress),
            const SizedBox(height: 26),

            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            _buildFeatureCard(
              context,
              icon: Icons.directions_car_filled,
              title: 'Track Trips',
              description: 'Record every journey with distance and duration',
            ),
            const SizedBox(height: 12),
            _buildFeatureCard(
              context,
              icon: Icons.local_gas_station_rounded,
              title: 'Fuel Logs',
              description: 'Monitor fuel consumption and costs',
            ),
            const SizedBox(height: 12),
            _buildFeatureCard(
              context,
              icon: Icons.bar_chart_rounded,
              title: 'Reports',
              description: 'Analyze your vehicle\'s efficiency',
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  static Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Card(
      color: const Color(0xFF151C2A),
      elevation: 4,
      shadowColor: Colors.black54,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.16),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.blueGrey[200],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.blueGrey[200],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required double totalDistance,
    required double avgEfficiency,
    required double totalFuelCost,
  }) {
    return Card(
      color: const Color(0xFF141B29),
      elevation: 6,
      shadowColor: Colors.black87,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1B2332), Color(0xFF101620)],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white12, width: 0.4),
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Summary',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    icon: Icons.straighten_rounded,
                    label: 'Total Distance',
                    value: '${totalDistance.toStringAsFixed(1)} km',
                    color: const Color(0xFF68B4FF),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildMetricItem(
                    icon: Icons.speed_rounded,
                    label: 'Avg. Efficiency',
                    value: '${avgEfficiency.toStringAsFixed(1)} km/L',
                    color: const Color(0xFF7DE2A8),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildMetricItem(
                    icon: Icons.attach_money_rounded,
                    label: 'Total Fuel Cost',
                    value: 'LKR ${totalFuelCost.toStringAsFixed(0)}',
                    color: const Color(0xFFFFB47D),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
      child: Column(
        children: [
          Icon(icon, size: 28, color: color),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.blueGrey[200],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTripCard(Trip recentTrip) {
    return Card(
      color: const Color(0xFF151C2A),
      elevation: 5,
      shadowColor: Colors.black87,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade900,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.location_on_rounded,
                size: 28,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Trip',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    recentTrip.endLocation,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.blueGrey[100],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildBadge('Distance', '${recentTrip.distance.toStringAsFixed(1)} km'),
                      const SizedBox(width: 8),
                      _buildBadge('Date', '${recentTrip.date.day}/${recentTrip.date.month}/${recentTrip.date.year}'),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.blueGrey[200],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        '$label: $value',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.blueGrey[100],
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildBudgetProgressCard(double monthlyCost, double monthlyBudget, double progress) {
    final progressValue = progress.clamp(0.0, 1.0);
    final progressColor = progressValue > 0.9 ? const Color(0xFFFF6B6B) : progressValue > 0.7 ? const Color(0xFFFFA726) : const Color(0xFF6CE3FF);

    return Card(
      color: const Color(0xFF151C2A),
      elevation: 6,
      shadowColor: Colors.black87,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade900,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    size: 24,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Monthly Fuel Budget',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LKR ${monthlyCost.toStringAsFixed(0)} spent',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.blueGrey[100],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: progressValue),
                          duration: const Duration(milliseconds: 700),
                          builder: (context, value, child) {
                            return LinearProgressIndicator(
                              value: value,
                              minHeight: 10,
                              backgroundColor: Colors.white12,
                              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'LKR ${monthlyBudget.toStringAsFixed(0)} budget • ${(progressValue * 100).toStringAsFixed(1)}% used',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.blueGrey[200],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                SizedBox(
                  width: 76,
                  height: 76,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: progressValue,
                        strokeWidth: 8,
                        backgroundColor: Colors.white12,
                        valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                      ),
                      Text(
                        '${(progressValue * 100).toStringAsFixed(0)}%',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

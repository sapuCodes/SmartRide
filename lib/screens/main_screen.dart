import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'trips_screen.dart';
import 'fuel_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';

/// Root widget that hosts a [BottomNavigationBar] and an [IndexedStack]
/// in order to preserve the state of each tab.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  static const List<Widget> _pages = <Widget>[
    HomeScreen(),
    TripsScreen(),
    FuelScreen(),
    ReportsScreen(),
    SettingsScreen(),
  ];

  static const List<String> _titles = <String>[
    'Home',
    'Trips',
    'Fuel',
    'Reports',
    'Settings',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_currentIndex],
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: PhysicalModel(
          color: Colors.transparent,
          elevation: 14,
          shadowColor: Colors.black54,
          borderRadius: BorderRadius.circular(32),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: NavigationBarTheme(
              data: NavigationBarThemeData(
                backgroundColor: const Color(0xFF121B28),
                indicatorColor: Theme.of(context).colorScheme.primary.withOpacity(0.22),
                labelTextStyle: MaterialStateProperty.resolveWith(
                  (states) => Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                iconTheme: MaterialStateProperty.resolveWith((states) {
                  if (states.contains(MaterialState.selected)) {
                    return IconThemeData(
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    );
                  }
                  return const IconThemeData(
                    color: Colors.white70,
                    size: 22,
                  );
                }),
              ),
              child: NavigationBar(
                selectedIndex: _currentIndex,
                onDestinationSelected: _onItemTapped,
                height: 72,
                animationDuration: const Duration(milliseconds: 320),
                labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
                destinations: <NavigationDestination>[
                  NavigationDestination(
                    icon: const Icon(Icons.home_outlined),
                    selectedIcon: const Icon(Icons.home_filled),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.directions_car_outlined),
                    selectedIcon: const Icon(Icons.directions_car_filled),
                    label: 'Trips',
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.local_gas_station_outlined),
                    selectedIcon: const Icon(Icons.local_gas_station),
                    label: 'Fuel',
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.bar_chart_outlined),
                    selectedIcon: const Icon(Icons.bar_chart),
                    label: 'Reports',
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.settings_outlined),
                    selectedIcon: const Icon(Icons.settings),
                    label: 'Settings',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Calculates fuel efficiency in kilometers per liter.
///
/// [totalDistance] - total distance traveled in kilometers
/// [totalFuel] - total fuel consumed in liters
///
/// Returns km per liter, or 0 if no fuel was consumed.
double calculateFuelEfficiency(double totalDistance, double totalFuel) {
  if (totalFuel <= 0) return 0;
  return totalDistance / totalFuel;
}

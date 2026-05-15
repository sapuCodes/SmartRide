class FuelLog {
  final String id;
  final DateTime date;
  final double liters;
  final double pricePerLiter;
  final double totalCost;
  final double odometerReading;

  FuelLog({
    required this.id,
    required this.date,
    required this.liters,
    required this.pricePerLiter,
    required this.totalCost,
    required this.odometerReading,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'liters': liters,
      'pricePerLiter': pricePerLiter,
      'totalCost': totalCost,
      'odometerReading': odometerReading,
    };
  }

  factory FuelLog.fromJson(Map<String, dynamic> json) {
    return FuelLog(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      liters: (json['liters'] as num).toDouble(),
      pricePerLiter: (json['pricePerLiter'] as num).toDouble(),
      totalCost: (json['totalCost'] as num).toDouble(),
      odometerReading: (json['odometerReading'] as num).toDouble(),
    );
  }
}

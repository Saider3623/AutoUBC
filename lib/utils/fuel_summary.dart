import '../models/fuel_log.dart';

class FuelTypeSummary {
  final String fuelType;
  final int refuelCount;
  final double totalLiters;

  const FuelTypeSummary({
    required this.fuelType,
    required this.refuelCount,
    required this.totalLiters,
  });
}

List<FuelTypeSummary> summarizeFuelLogsByType(Iterable<FuelLog> logs) {
  final grouped = <String, ({int refuelCount, double totalLiters})>{};

  for (final log in logs) {
    final fuelType = log.fuelType.trim();
    if (fuelType.isEmpty) continue;

    final current = grouped[fuelType];
    grouped[fuelType] = (
      refuelCount: (current?.refuelCount ?? 0) + 1,
      totalLiters: (current?.totalLiters ?? 0) + log.liters,
    );
  }

  final summaries = grouped.entries
      .map(
        (entry) => FuelTypeSummary(
          fuelType: entry.key,
          refuelCount: entry.value.refuelCount,
          totalLiters: entry.value.totalLiters,
        ),
      )
      .toList();
  summaries.sort((a, b) => a.fuelType.compareTo(b.fuelType));
  return summaries;
}

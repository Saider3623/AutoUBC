import '../models/fuel_log.dart';
import '../models/odometer_log.dart';
import '../utils/fuel_summary.dart';
import '../utils/weekly_report_utils.dart';
import '../utils/work_schedule.dart';

/// Mileage and fuel of one report week, computed the same way for the screen
/// and the PDF.
class WeekSummary {
  final ReportWeek week;

  /// Reading the week starts from: the last reading before the week, or the
  /// first reading inside it when there is none before.
  final int? odometerStart;

  /// Last reading inside the week; `null` when the week has no reading.
  final int? odometerEnd;

  /// Kilometres driven: [odometerEnd] − [odometerStart], never negative.
  final int distance;

  final List<FuelTypeSummary> fuelSummaries;

  /// Whether the week has at least one odometer or fuel entry.
  final bool hasEntries;

  const WeekSummary({
    required this.week,
    required this.distance,
    required this.fuelSummaries,
    required this.hasEntries,
    this.odometerStart,
    this.odometerEnd,
  });

  bool get hasMileage => distance > 0;

  /// Working periods stay visible even without trips. Non-working periods
  /// appear only when they have mileage, regardless of fuel-only entries.
  bool shouldShowInReport(WorkSchedule schedule) =>
      hasMileage ||
      week.start.weekday <= schedule.workWeekDaysForWeekOf(week.start);

  double get totalLiters =>
      fuelSummaries.fold(0, (sum, item) => sum + item.totalLiters);
}

String _dateKey(DateTime date) => '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// Summarizes [week] from all odometer and fuel entries of one car (in any
/// order). Pure: no database access, so the weekly screen can compute every
/// week synchronously from the data already in memory.
WeekSummary summarizeWeek(
  ReportWeek week, {
  required Iterable<OdometerLog> odometerLogs,
  required Iterable<FuelLog> fuelLogs,
}) {
  final startKey = _dateKey(week.start);
  final endKey = _dateKey(week.end);

  final inWeek = <OdometerLog>[];
  OdometerLog? before;
  for (final log in odometerLogs) {
    final date = log.dateString;
    if (date.compareTo(startKey) < 0) {
      if (before == null || date.compareTo(before.dateString) > 0) {
        before = log;
      }
    } else if (date.compareTo(endKey) <= 0) {
      inWeek.add(log);
    }
  }
  inWeek.sort((a, b) => a.dateString.compareTo(b.dateString));

  final weekFuel = [
    for (final log in fuelLogs)
      if (log.dateString.compareTo(startKey) >= 0 &&
          log.dateString.compareTo(endKey) <= 0)
        log,
  ];

  final startLog = before ?? (inWeek.isEmpty ? null : inWeek.first);
  final endLog = inWeek.isEmpty ? null : inWeek.last;
  var distance = 0;
  if (startLog != null && endLog != null) {
    distance = endLog.odometer - startLog.odometer;
    if (distance < 0) distance = 0;
  }

  return WeekSummary(
    week: week,
    odometerStart: startLog?.odometer,
    odometerEnd: endLog?.odometer,
    distance: distance,
    fuelSummaries: summarizeFuelLogsByType(weekFuel),
    hasEntries: inWeek.isNotEmpty || weekFuel.isNotEmpty,
  );
}

/// Totals of a report month.
class MonthSummary {
  final int distance;
  final List<FuelTypeSummary> fuelSummaries;

  const MonthSummary({
    required this.distance,
    required this.fuelSummaries,
  });
}

/// Adds up the mileage and fuel of [weeks] of one month.
MonthSummary summarizeMonth(List<WeekSummary> weeks) {
  final fuelByType = <String, ({int count, double liters})>{};
  var distance = 0;
  for (final week in weeks) {
    distance += week.distance;
    for (final fuel in week.fuelSummaries) {
      final current = fuelByType[fuel.fuelType];
      fuelByType[fuel.fuelType] = (
        count: (current?.count ?? 0) + fuel.refuelCount,
        liters: (current?.liters ?? 0) + fuel.totalLiters,
      );
    }
  }

  final fuelSummaries = [
    for (final entry in fuelByType.entries)
      FuelTypeSummary(
        fuelType: entry.key,
        refuelCount: entry.value.count,
        totalLiters: entry.value.liters,
      ),
  ]..sort((a, b) => a.fuelType.compareTo(b.fuelType));

  return MonthSummary(
    distance: distance,
    fuelSummaries: fuelSummaries,
  );
}

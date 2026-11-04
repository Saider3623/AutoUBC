import '../models/fuel_log.dart';
import '../models/odometer_log.dart';
import '../utils/fuel_summary.dart';
import '../utils/weekly_report_utils.dart';
import '../utils/date_utils.dart';
import '../utils/work_schedule.dart';

/// More calendar days than this between the reading before a week and the
/// week's first day means the week's mileage also covers days without
/// readings (a weekend is at most two days).
const int maxDaysWithoutReadingBeforeWeek = 2;

/// Mileage and fuel of one report week, computed the same way for the screen
/// and the PDF.
class WeekSummary {
  final ReportWeek week;

  /// Reading the week starts from: the last reading before the week, or the
  /// first reading inside it when there is none before.
  final int? odometerStart;

  /// Date (`YYYY-MM-DD`) of [odometerStart].
  final String? odometerStartDate;

  /// Last reading inside the week; `null` when the week has no reading.
  final int? odometerEnd;

  /// Kilometres driven: [odometerEnd] − [odometerStart], never negative.
  final int distance;

  final List<FuelTypeSummary> fuelSummaries;

  /// Whether the week has at least one odometer or fuel entry.
  final bool hasEntries;

  /// Whether [distance] also includes days before the week that have no
  /// reading (the previous reading is older than a weekend).
  final bool includesGap;

  const WeekSummary({
    required this.week,
    required this.distance,
    required this.fuelSummaries,
    required this.hasEntries,
    this.odometerStart,
    this.odometerStartDate,
    this.odometerEnd,
    this.includesGap = false,
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
  var includesGap = false;
  if (startLog != null && endLog != null) {
    distance = endLog.odometer - startLog.odometer;
    if (distance < 0) distance = 0;
    final previousDate =
        before == null ? null : DateTime.tryParse(before.dateString);
    if (previousDate != null && distance > 0) {
      final daysBetween = calendarDaysBetween(previousDate, week.start) - 1;
      includesGap = daysBetween > maxDaysWithoutReadingBeforeWeek;
    }
  }

  return WeekSummary(
    week: week,
    odometerStart: startLog?.odometer,
    odometerStartDate: startLog?.dateString,
    odometerEnd: endLog?.odometer,
    distance: distance,
    fuelSummaries: summarizeFuelLogsByType(weekFuel),
    hasEntries: inWeek.isNotEmpty || weekFuel.isNotEmpty,
    includesGap: includesGap,
  );
}

/// Totals of a report month.
class MonthSummary {
  final int distance;
  final List<FuelTypeSummary> fuelSummaries;

  /// Working days (Mon–Sat or Mon–Fri by the schedule) in the past part of
  /// the month that have no odometer reading.
  final int daysWithoutReading;

  const MonthSummary({
    required this.distance,
    required this.fuelSummaries,
    required this.daysWithoutReading,
  });
}

/// Adds up [weeks] of one month. [isWorkingDay] decides which days count
/// for [MonthSummary.daysWithoutReading]; days after [today] are not counted.
MonthSummary summarizeMonth(
  List<WeekSummary> weeks, {
  required Iterable<OdometerLog> odometerLogs,
  required bool Function(DateTime day) isWorkingDay,
  required DateTime today,
}) {
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

  final readingDays = {for (final log in odometerLogs) log.dateString};
  final lastDay = DateTime(today.year, today.month, today.day);
  var missing = 0;
  for (final week in weeks) {
    for (var day = week.week.start;
        !day.isAfter(week.week.end) && !day.isAfter(lastDay);
        day = addCalendarDays(day, 1)) {
      if (isWorkingDay(day) && !readingDays.contains(_dateKey(day))) {
        missing++;
      }
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
    daysWithoutReading: missing,
  );
}

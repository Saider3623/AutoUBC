import 'package:flutter_test/flutter_test.dart';

import 'package:autoubc/domain/week_summary.dart';
import 'package:autoubc/models/fuel_log.dart';
import 'package:autoubc/models/odometer_log.dart';
import 'package:autoubc/utils/weekly_report_utils.dart';
import 'package:autoubc/utils/work_schedule.dart';

OdometerLog _odo(String date, int km) => OdometerLog()
  ..dateString = date
  ..odometer = km;

FuelLog _fuel(String date, String type, double liters) => FuelLog()
  ..dateString = date
  ..timeString = '08:00'
  ..fuelType = type
  ..liters = liters;

void main() {
  group('report visibility', () {
    final fiveDay = WorkSchedule([FiveDayRange(DateTime(2026, 1, 1))]);

    List<WeekSummary> november(WorkSchedule schedule) => [
          for (final week in buildReportWeeks(DateTime(2026, 11), schedule))
            summarizeWeek(week, odometerLogs: const [], fuelLogs: const []),
        ];

    test('keeps empty working weeks, including a one-day month boundary', () {
      final visible = november(fiveDay)
          .where((summary) => summary.shouldShowInReport(fiveDay));
      expect(
          visible.map((summary) => summary.week.start.day), [2, 9, 16, 23, 30]);
      expect(visible.every((summary) => !summary.hasEntries), isTrue);
    });

    test('uses the schedule for a Saturday clipped by the month boundary', () {
      final saturday =
          ReportWeek(DateTime(2026, 10, 31), DateTime(2026, 10, 31));
      final summary = summarizeWeek(
        saturday,
        odometerLogs: const [],
        fuelLogs: const [],
      );
      expect(summary.shouldShowInReport(fiveDay), isFalse);
      expect(summary.shouldShowInReport(const WorkSchedule()), isTrue);
    });

    test('hides a zero-mileage weekend even with readings or refuels', () {
      final weekend = ReportWeek(DateTime(2026, 11, 7), DateTime(2026, 11, 8));
      final summary = summarizeWeek(
        weekend,
        odometerLogs: [_odo('2026-11-06', 1000), _odo('2026-11-07', 1000)],
        fuelLogs: [_fuel('2026-11-08', 'ГАЗ', 30)],
      );
      expect(summary.hasEntries, isTrue);
      expect(summary.shouldShowInReport(fiveDay), isFalse);
    });

    test('keeps mileage on a non-working Sunday', () {
      final sunday = ReportWeek(DateTime(2026, 11, 1), DateTime(2026, 11, 1));
      final summary = summarizeWeek(
        sunday,
        odometerLogs: [_odo('2026-10-31', 1899), _odo('2026-11-01', 2058)],
        fuelLogs: const [],
      );
      expect(summary.distance, 159);
      expect(summary.shouldShowInReport(fiveDay), isTrue);
      expect(summary.shouldShowInReport(const WorkSchedule()), isTrue);
    });

    test('respects a schedule that changes during the month', () {
      final schedule = WorkSchedule([
        FiveDayRange(DateTime(2026, 11, 1), DateTime(2026, 11, 14)),
      ]);
      final visible = november(schedule)
          .where((summary) => summary.shouldShowInReport(schedule));
      expect(
        visible
            .map((summary) => (summary.week.start.day, summary.week.end.day)),
        [(2, 6), (9, 13), (16, 21), (23, 28), (30, 30)],
      );
    });

    test('hidden fuel-only weekends still contribute to month totals', () {
      final summaries = [
        for (final week in buildReportWeeks(DateTime(2026, 11), fiveDay))
          summarizeWeek(
            week,
            odometerLogs: const [],
            fuelLogs: [_fuel('2026-11-08', 'ГАЗ', 30)],
          ),
      ];
      expect(
        summaries
            .where((week) => week.shouldShowInReport(fiveDay))
            .every((week) => week.fuelSummaries.isEmpty),
        isTrue,
      );
      final month = summarizeMonth(summaries);
      expect(month.fuelSummaries.single.totalLiters, 30);
    });
  });

  // Mon 19 – Sat 24 October 2026.
  final week = ReportWeek(DateTime(2026, 10, 19), DateTime(2026, 10, 24));

  test('starts from the last reading before the week', () {
    final summary = summarizeWeek(
      week,
      odometerLogs: [
        _odo('2026-10-17', 1000),
        _odo('2026-10-21', 1150),
        _odo('2026-10-24', 1300),
        _odo('2026-10-26', 1400),
      ],
      fuelLogs: const [],
    );
    expect(summary.odometerStart, 1000);
    expect(summary.odometerEnd, 1300);
    expect(summary.distance, 300);
  });

  test('uses the first reading of the week when there is none before', () {
    final summary = summarizeWeek(
      week,
      odometerLogs: [_odo('2026-10-20', 500), _odo('2026-10-23', 620)],
      fuelLogs: const [],
    );
    expect(summary.odometerStart, 500);
    expect(summary.distance, 120);
  });

  test('keeps mileage from a reading recorded well before the week', () {
    final summary = summarizeWeek(
      week,
      odometerLogs: [_odo('2026-10-08', 1000), _odo('2026-10-22', 1900)],
      fuelLogs: const [],
    );
    expect(summary.distance, 900);
    expect(summary.odometerStart, 1000);
    expect(summary.odometerEnd, 1900);
  });

  test('keeps mileage across a weekend between readings', () {
    final summary = summarizeWeek(
      ReportWeek(DateTime(2026, 10, 26), DateTime(2026, 10, 31)),
      odometerLogs: [_odo('2026-10-23', 1000), _odo('2026-10-26', 1100)],
      fuelLogs: const [],
    );
    expect(summary.odometerStart, 1000);
    expect(summary.odometerEnd, 1100);
    expect(summary.distance, 100);
  });

  test('a week with refuels but without readings keeps its fuel', () {
    final summary = summarizeWeek(
      week,
      odometerLogs: [_odo('2026-10-10', 1000)],
      fuelLogs: [
        _fuel('2026-10-20', 'ГАЗ', 30),
        _fuel('2026-10-22', 'ГАЗ', 20.5),
        _fuel('2026-10-25', '95', 10),
      ],
    );
    expect(summary.hasEntries, isTrue);
    expect(summary.hasMileage, isFalse);
    expect(summary.odometerEnd, isNull);
    expect(summary.fuelSummaries.single.totalLiters, 50.5);
    expect(summary.fuelSummaries.single.refuelCount, 2);
  });

  test('never reports negative mileage', () {
    final summary = summarizeWeek(
      week,
      odometerLogs: [_odo('2026-10-17', 2000), _odo('2026-10-20', 1990)],
      fuelLogs: const [],
    );
    expect(summary.distance, 0);
  });

  test('month totals add up the mileage and fuel of the weeks', () {
    final weeks = [
      ReportWeek(DateTime(2026, 10, 1), DateTime(2026, 10, 3)),
      ReportWeek(DateTime(2026, 10, 4), DateTime(2026, 10, 4)),
      ReportWeek(DateTime(2026, 10, 5), DateTime(2026, 10, 10)),
    ];
    final odometer = [
      _odo('2026-09-30', 100),
      _odo('2026-10-01', 150),
      _odo('2026-10-02', 200),
      _odo('2026-10-03', 260),
      _odo('2026-10-06', 400),
    ];
    final fuel = [
      _fuel('2026-10-02', 'ГАЗ', 30),
      _fuel('2026-10-06', 'ГАЗ', 25),
      _fuel('2026-10-07', '95', 5),
    ];
    final summaries = [
      for (final week in weeks)
        summarizeWeek(week, odometerLogs: odometer, fuelLogs: fuel),
    ];

    final month = summarizeMonth(summaries);

    expect(month.distance, 300);
    expect(
      {for (final f in month.fuelSummaries) f.fuelType: f.totalLiters},
      {'95': 5.0, 'ГАЗ': 55.0},
    );
  });
}

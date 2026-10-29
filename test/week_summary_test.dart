import 'package:flutter_test/flutter_test.dart';

import 'package:autoubc/domain/week_summary.dart';
import 'package:autoubc/models/fuel_log.dart';
import 'package:autoubc/models/odometer_log.dart';
import 'package:autoubc/utils/weekly_report_utils.dart';

OdometerLog _odo(String date, int km) => OdometerLog()
  ..dateString = date
  ..odometer = km;

FuelLog _fuel(String date, String type, double liters) => FuelLog()
  ..dateString = date
  ..timeString = '08:00'
  ..fuelType = type
  ..liters = liters;

void main() {
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
    expect(summary.includesGap, isFalse);
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

  test('flags mileage that also covers days without readings', () {
    final summary = summarizeWeek(
      week,
      odometerLogs: [_odo('2026-10-08', 1000), _odo('2026-10-22', 1900)],
      fuelLogs: const [],
    );
    expect(summary.distance, 900);
    expect(summary.includesGap, isTrue);
    expect(summary.odometerStartDate, '2026-10-08');
  });

  test('a weekend between readings is not a gap', () {
    final summary = summarizeWeek(
      ReportWeek(DateTime(2026, 10, 26), DateTime(2026, 10, 31)),
      odometerLogs: [_odo('2026-10-23', 1000), _odo('2026-10-26', 1100)],
      fuelLogs: const [],
    );
    expect(summary.includesGap, isFalse);
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

  test('month totals add up the weeks and count missing working days', () {
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

    final month = summarizeMonth(
      summaries,
      odometerLogs: odometer,
      isWorkingDay: (day) => day.weekday != DateTime.sunday,
      today: DateTime(2026, 10, 7),
    );

    expect(month.distance, 300);
    expect(
      {for (final f in month.fuelSummaries) f.fuelType: f.totalLiters},
      {'95': 5.0, 'ГАЗ': 55.0},
    );
    // Missing: Mon 5 and Wed 7 (Sun 4 is a day off, days after the 7th
    // are not counted yet).
    expect(month.daysWithoutReading, 2);
  });
}

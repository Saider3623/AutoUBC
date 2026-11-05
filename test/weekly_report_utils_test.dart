import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:autoubc/utils/weekly_report_utils.dart';
import 'package:autoubc/utils/work_schedule.dart';

/// Six-day weeks only (no five-day periods).
const _sixDayOnly = WorkSchedule();

/// Five-day weeks for the whole of 2026 and later.
final _fiveDayOnly = WorkSchedule([FiveDayRange(DateTime(2026, 1, 1))]);

ReportWeek _week(int startDay, int endDay) =>
    ReportWeek(DateTime(2026, 9, startDay), DateTime(2026, 9, endDay));

void main() {
  setUpAll(initializeDateFormatting);

  test('puts weekdays after the full numeric report range', () {
    final week = ReportWeek(DateTime(2026, 11, 16), DateTime(2026, 11, 20));
    expect(formatReportWeekTitle(week, 'uk'), '16.11.26 - 20.11.26 (пн-пт)');
    expect(formatReportWeekTitle(week, 'en'), '16.11.26 - 20.11.26 (Mon-Fri)');
    expect(formatReportWeekTitle(week, 'ru'), '16.11.26 - 20.11.26 (пн-пт)');
    expect(formatReportWeekRange(week, 'uk'), '16.11.26 - 20.11.26');
    expect(formatReportWeekRange(week, 'en'), '16.11.26 - 20.11.26');
  });

  test('uses a single date for a one-day report segment', () {
    final week = ReportWeek(DateTime(2026, 11, 30), DateTime(2026, 11, 30));
    expect(formatReportWeekTitle(week, 'uk'), '30.11.26 (пн)');
    expect(formatReportWeekTitle(week, 'en'), '30.11.26 (Mon)');
    expect(formatReportWeekRange(week, 'uk'), '30.11.26');
    expect(formatReportWeekRange(week, 'en'), '30.11.26');
  });

  test('puts the current week first and preserves the other weeks order', () {
    final weeks = [
      _week(1, 6),
      _week(7, 13),
      _week(14, 20),
      _week(21, 30),
    ];

    final ordered = prioritizeCurrentReportWeek(weeks, DateTime(2026, 9, 16));

    expect(
      ordered.map((week) => week.start.day).toList(),
      [14, 1, 7, 21],
    );
  });

  test('keeps the normal order when the selected month is not current', () {
    final weeks = [_week(1, 6), _week(7, 13), _week(14, 20)];

    final ordered = prioritizeCurrentReportWeek(weeks, DateTime(2026, 10, 2));

    expect(
      ordered.map((week) => week.start.day).toList(),
      [1, 7, 14],
    );
  });

  test('treats both week boundaries as part of the current week', () {
    final week = _week(7, 13);

    expect(isDateInReportWeek(week, DateTime(2026, 9, 7)), isTrue);
    expect(isDateInReportWeek(week, DateTime(2026, 9, 13)), isTrue);
    expect(isDateInReportWeek(week, DateTime(2026, 9, 14)), isFalse);
  });

  // Regression: October 2026 contains the DST fall-back day (Sun 25 Oct in
  // Europe/Kyiv). Stepping with `Duration(days: 1)` never left that day and
  // the week loop ran forever, freezing the app. Run under a DST time zone
  // to exercise the transition: `TZ=Europe/Kyiv flutter test`.
  String fmt(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  test('builds October 2026 weeks across the DST change (6-day week)', () {
    final weeks = buildReportWeeks(DateTime(2026, 10, 15), _sixDayOnly);

    expect(
      weeks.map((w) => '${fmt(w.start)}..${fmt(w.end)}').toList(),
      [
        '10-01..10-03',
        '10-04..10-04',
        '10-05..10-10',
        '10-11..10-11',
        '10-12..10-17',
        '10-18..10-18',
        '10-19..10-24',
        '10-25..10-25',
        '10-26..10-31',
      ],
    );
  });

  test('builds October 2026 weeks across the DST change (5-day week)', () {
    final weeks = buildReportWeeks(DateTime(2026, 10, 1), _fiveDayOnly);

    expect(
      weeks.map((w) => '${fmt(w.start)}..${fmt(w.end)}').toList(),
      [
        '10-01..10-02',
        '10-03..10-04',
        '10-05..10-09',
        '10-10..10-11',
        '10-12..10-16',
        '10-17..10-18',
        '10-19..10-23',
        '10-24..10-25',
        '10-26..10-30',
        '10-31..10-31',
      ],
    );
  });

  test('every report week starts and ends at local midnight', () {
    for (final month in [DateTime(2026, 3, 1), DateTime(2026, 10, 1)]) {
      for (final schedule in [_sixDayOnly, _fiveDayOnly]) {
        for (final week in buildReportWeeks(month, schedule)) {
          for (final d in [week.start, week.end]) {
            expect(d.hour, 0, reason: '$d');
            expect(d.minute, 0, reason: '$d');
          }
        }
      }
    }
  });

  test('addCalendarDays steps whole calendar days over DST changes', () {
    expect(fmt(addCalendarDays(DateTime(2026, 10, 25), 1)), '10-26');
    expect(addCalendarDays(DateTime(2026, 10, 25), 1).hour, 0);
    expect(fmt(addCalendarDays(DateTime(2026, 3, 30), -1)), '03-29');
    expect(fmt(addCalendarDays(DateTime(2026, 12, 31), 1)), '01-01');
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:autoubc/models/five_day_period.dart';
import 'package:autoubc/utils/weekly_report_utils.dart';
import 'package:autoubc/utils/work_schedule.dart';

String _fmt(DateTime d) =>
    '${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

List<String> _weeks(DateTime month, WorkSchedule schedule) =>
    buildReportWeeks(month, schedule)
        .map((w) => '${_fmt(w.start)}..${_fmt(w.end)}')
        .toList();

FiveDayPeriod _period(int id, String start, [String? end]) => FiveDayPeriod()
  ..id = id
  ..startDate = start
  ..endDate = end;

void main() {
  group('WorkSchedule', () {
    test('defaults to six-day weeks everywhere', () {
      const schedule = WorkSchedule();
      expect(schedule.isFiveDayDate(DateTime(2026, 10, 3)), isFalse);
      expect(schedule.workWeekDaysForWeekOf(DateTime(2026, 10, 5)), 6);
      expect(schedule.isNonWorkingSaturday(DateTime(2026, 10, 3)), isFalse);
    });

    test('open-ended period lasts indefinitely', () {
      final schedule = WorkSchedule.fromPeriods([_period(1, '2026-10-01')]);
      expect(schedule.isFiveDayDate(DateTime(2026, 9, 30)), isFalse);
      expect(schedule.isFiveDayDate(DateTime(2026, 10, 1)), isTrue);
      expect(schedule.isFiveDayDate(DateTime(2030, 1, 1)), isTrue);
    });

    test('closed period includes both boundary dates', () {
      final schedule =
          WorkSchedule.fromPeriods([_period(1, '2026-10-01', '2027-03-15')]);
      expect(schedule.isFiveDayDate(DateTime(2026, 10, 1)), isTrue);
      expect(schedule.isFiveDayDate(DateTime(2027, 3, 15)), isTrue);
      expect(schedule.isFiveDayDate(DateTime(2027, 3, 16)), isFalse);
    });

    test('a week takes its mode from its Saturday', () {
      // Period ends on Wednesday 14 Oct; Saturday 17 Oct is a working day.
      final schedule =
          WorkSchedule.fromPeriods([_period(1, '2026-10-01', '2026-10-14')]);
      expect(schedule.workWeekDaysForWeekOf(DateTime(2026, 10, 5)), 5);
      expect(schedule.workWeekDaysForWeekOf(DateTime(2026, 10, 12)), 6);
      expect(schedule.workWeekDaysForWeekOf(DateTime(2026, 10, 18)), 6);
    });

    test('marks only Saturdays inside a period as days off', () {
      final schedule = WorkSchedule.fromPeriods([_period(1, '2026-10-01')]);
      expect(schedule.isNonWorkingSaturday(DateTime(2026, 10, 3)), isTrue);
      expect(schedule.isNonWorkingSaturday(DateTime(2026, 10, 2)), isFalse);
      expect(schedule.isNonWorkingSaturday(DateTime(2026, 9, 26)), isFalse);
    });

    test('skips malformed stored periods', () {
      final schedule = WorkSchedule.fromPeriods([
        _period(1, 'bad-date'),
        _period(2, '2026-10-10', '2026-10-01'),
        _period(3, '2026-10-01', '2026-13-40'),
      ]);
      expect(schedule.fiveDayRanges, isEmpty);
    });
  });

  group('buildReportWeeks with a schedule', () {
    final fromOctober = WorkSchedule.fromPeriods([_period(1, '2026-10-01')]);

    test('September before the period uses six-day weeks', () {
      expect(_weeks(DateTime(2026, 9, 1), fromOctober), [
        '09-01..09-05',
        '09-06..09-06',
        '09-07..09-12',
        '09-13..09-13',
        '09-14..09-19',
        '09-20..09-20',
        '09-21..09-26',
        '09-27..09-27',
        '09-28..09-30',
      ]);
    });

    test('October inside the period uses five-day weeks', () {
      expect(_weeks(DateTime(2026, 10, 1), fromOctober), [
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
      ]);
    });

    test('a period ending mid-week returns to six days that week', () {
      final schedule =
          WorkSchedule.fromPeriods([_period(1, '2026-10-01', '2026-10-14')]);
      expect(_weeks(DateTime(2026, 10, 1), schedule), [
        '10-01..10-02',
        '10-03..10-04',
        '10-05..10-09',
        '10-10..10-11',
        '10-12..10-17',
        '10-18..10-18',
        '10-19..10-24',
        '10-25..10-25',
        '10-26..10-31',
      ]);
    });

    test('a period ending on Saturday keeps that Saturday off', () {
      final schedule =
          WorkSchedule.fromPeriods([_period(1, '2026-10-01', '2026-10-17')]);
      final weeks = _weeks(DateTime(2026, 10, 1), schedule);
      expect(weeks.sublist(4, 7), [
        '10-12..10-16',
        '10-17..10-18',
        '10-19..10-24',
      ]);
    });
  });

  test('formats and parses schedule dates', () {
    expect(formatScheduleDate(DateTime(2026, 3, 5)), '2026-03-05');
    expect(parseScheduleDate('2026-03-05'), DateTime(2026, 3, 5));
    expect(parseScheduleDate('2026-02-30'), isNull);
    expect(parseScheduleDate('2026-3-5'), isNull);
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:autoubc/utils/weekly_report_utils.dart';

Map<String, DateTime> _week(int startDay, int endDay) {
  return {
    'start': DateTime(2026, 9, startDay),
    'end': DateTime(2026, 9, endDay),
  };
}

void main() {
  test('puts the current week first and preserves the other weeks order', () {
    final weeks = [
      _week(1, 6),
      _week(7, 13),
      _week(14, 20),
      _week(21, 30),
    ];

    final ordered = prioritizeCurrentReportWeek(weeks, DateTime(2026, 9, 16));

    expect(
      ordered.map((week) => week['start']!.day).toList(),
      [14, 1, 7, 21],
    );
  });

  test('keeps the normal order when the selected month is not current', () {
    final weeks = [_week(1, 6), _week(7, 13), _week(14, 20)];

    final ordered = prioritizeCurrentReportWeek(weeks, DateTime(2026, 10, 2));

    expect(
      ordered.map((week) => week['start']!.day).toList(),
      [1, 7, 14],
    );
  });

  test('treats both week boundaries as part of the current week', () {
    final week = _week(7, 13);

    expect(isDateInReportWeek(week, DateTime(2026, 9, 7)), isTrue);
    expect(isDateInReportWeek(week, DateTime(2026, 9, 13)), isTrue);
    expect(isDateInReportWeek(week, DateTime(2026, 9, 14)), isFalse);
  });
}

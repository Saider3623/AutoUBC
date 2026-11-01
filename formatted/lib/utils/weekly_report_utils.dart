import 'work_schedule.dart';

/// One segment of a report month: an inclusive range of calendar days, both
/// stored as local midnight.
class ReportWeek {
  final DateTime start;
  final DateTime end;

  ReportWeek(DateTime start, DateTime end)
    : start = _dateOnly(start),
      end = _dateOnly(end);

  /// Whether [date] falls inside the inclusive range.
  bool contains(DateTime date) {
    final day = _dateOnly(date);
    return !day.isBefore(start) && !day.isAfter(end);
  }

  @override
  bool operator ==(Object other) =>
      other is ReportWeek && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'ReportWeek($start..$end)';
}

/// Returns whether [date] falls inside the inclusive date range of [week].
bool isDateInReportWeek(ReportWeek week, DateTime date) => week.contains(date);

/// Places the current week first while preserving chronological order for the
/// remaining weeks. Months without the current week keep their normal order.
List<ReportWeek> prioritizeCurrentReportWeek(
  Iterable<ReportWeek> weeks,
  DateTime today,
) {
  final orderedWeeks = weeks.toList();
  final currentIndex = orderedWeeks.indexWhere((week) => week.contains(today));

  if (currentIndex <= 0) return orderedWeeks;

  final currentWeek = orderedWeeks.removeAt(currentIndex);
  return [currentWeek, ...orderedWeeks];
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

/// Returns local midnight of the calendar day [days] days after [date].
///
/// Always use this instead of `add(Duration(days: n))` for local dates.
/// `Duration(days: 1)` is exactly 24 hours, but a local day lasts 25 hours
/// when clocks fall back (e.g. the last Sunday of October in Ukraine). Adding
/// 24 hours to that midnight lands on 23:00 of the *same* day, so a loop that
/// steps through weeks this way never advances and freezes the UI isolate.
DateTime addCalendarDays(DateTime date, int days) =>
    DateTime(date.year, date.month, date.day + days);

/// Returns the inclusive end date of the working-week segment that starts at
/// [start], honoring the configured [workWeekDays] (5 = Mon–Fri, 6 = Mon–Sat).
///
/// When [start] already falls on a non-working day after the configured week
/// end (Saturday/Sunday in 5-day mode or Sunday in 6-day mode) the remaining
/// weekend days are grouped together up to Sunday.
DateTime workingWeekEnd(DateTime start, int workWeekDays) {
  final day = _dateOnly(start);
  final delta = workWeekDays - day.weekday;
  if (delta >= 0) {
    return addCalendarDays(day, delta);
  }
  return addCalendarDays(day, 7 - day.weekday);
}

/// Returns the inclusive end of the report segment that starts at [start],
/// using the working-week length that [schedule] sets for that week.
DateTime reportWeekEnd(DateTime start, WorkSchedule schedule) =>
    workingWeekEnd(start, schedule.workWeekDaysForWeekOf(start));

/// Splits [month] into consecutive working-week segments clipped to the
/// month bounds, following the five-day periods of [schedule] (six-day weeks
/// everywhere else). Every `start`/`end` is a local midnight.
List<ReportWeek> buildReportWeeks(DateTime month, WorkSchedule schedule) {
  final weeks = <ReportWeek>[];
  final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);

  var currentStart = DateTime(month.year, month.month, 1);
  while (!currentStart.isAfter(lastDayOfMonth)) {
    var currentEnd = reportWeekEnd(currentStart, schedule);
    if (currentEnd.isAfter(lastDayOfMonth)) currentEnd = lastDayOfMonth;

    weeks.add(ReportWeek(currentStart, currentEnd));
    currentStart = addCalendarDays(currentEnd, 1);
  }

  return weeks;
}

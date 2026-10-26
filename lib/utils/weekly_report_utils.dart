/// Returns whether [date] falls inside the inclusive date range of [week].
bool isDateInReportWeek(Map<String, DateTime> week, DateTime date) {
  final day = DateTime(date.year, date.month, date.day);
  final start = _dateOnly(week['start']!);
  final end = _dateOnly(week['end']!);
  return !day.isBefore(start) && !day.isAfter(end);
}

/// Places the current week first while preserving chronological order for the
/// remaining weeks. Months without the current week keep their normal order.
List<Map<String, DateTime>> prioritizeCurrentReportWeek(
  Iterable<Map<String, DateTime>> weeks,
  DateTime today,
) {
  final orderedWeeks = weeks.toList();
  final currentIndex = orderedWeeks.indexWhere(
    (week) => isDateInReportWeek(week, today),
  );

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

/// Splits [month] into consecutive working-week segments clipped to the
/// month bounds. Every `start`/`end` is a local midnight.
List<Map<String, DateTime>> buildReportWeeks(DateTime month, int workWeekDays) {
  final weeks = <Map<String, DateTime>>[];
  final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);

  var currentStart = DateTime(month.year, month.month, 1);
  while (!currentStart.isAfter(lastDayOfMonth)) {
    var currentEnd = workingWeekEnd(currentStart, workWeekDays);
    if (currentEnd.isAfter(lastDayOfMonth)) currentEnd = lastDayOfMonth;

    weeks.add({'start': currentStart, 'end': currentEnd});
    currentStart = addCalendarDays(currentEnd, 1);
  }

  return weeks;
}

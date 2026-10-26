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
    return day.add(Duration(days: delta));
  }
  return day.add(Duration(days: 7 - day.weekday));
}

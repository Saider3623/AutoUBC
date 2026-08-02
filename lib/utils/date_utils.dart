DateTime addMonthsClamped(DateTime date, int months) {
  final targetMonth = date.month - 1 + months;
  final targetYear = date.year + targetMonth ~/ 12;
  final normalizedMonth = targetMonth % 12 + 1;
  final lastDay = DateTime(targetYear, normalizedMonth + 1, 0).day;

  return DateTime(
    targetYear,
    normalizedMonth,
    date.day > lastDay ? lastDay : date.day,
    date.hour,
    date.minute,
    date.second,
    date.millisecond,
    date.microsecond,
  );
}

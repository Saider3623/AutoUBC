import 'package:intl/intl.dart';

/// Full month name, with the day first in both supported interface languages.
String formatFullDate(DateTime date, String languageCode) {
  final format = languageCode == 'en'
      ? DateFormat('d MMMM y', 'en')
      : DateFormat.yMMMMd('uk');
  return format.format(date);
}

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

/// Whole calendar days from [from] to [to], independent of clock changes.
int calendarDaysBetween(DateTime from, DateTime to) {
  final start = DateTime.utc(from.year, from.month, from.day);
  final end = DateTime.utc(to.year, to.month, to.day);
  return end.difference(start).inDays;
}

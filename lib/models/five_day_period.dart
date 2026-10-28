import 'package:isar/isar.dart';

part 'five_day_period.g.dart';

/// A date range during which the working week has five days (Mon–Fri).
///
/// Outside of every stored period the working week has six days (Mon–Sat).
/// The schedule is app-wide, not per car. Dates use the same `YYYY-MM-DD`
/// string format as odometer and fuel logs, so they compare lexicographically.
@collection
class FiveDayPeriod {
  Id id = Isar.autoIncrement;

  /// First day of the five-day mode (inclusive), `YYYY-MM-DD`.
  String startDate = '';

  /// Last day of the five-day mode (inclusive), `YYYY-MM-DD`.
  /// `null` means the end is not decided yet and the period is open-ended.
  String? endDate;
}

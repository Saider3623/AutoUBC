/// What exactly is wrong with the data a user tried to save. Each code has a
/// localized message (see `describeError` in `error_messages.dart`).
enum ValidationCode {
  carNameEmpty,
  carMissing,
  recordMissing,
  recordWithoutCar,
  fuelTypeEmpty,
  descriptionEmpty,
  odometerBelowPrevious,
  odometerAboveNext,
  invalidDate,
  invalidTime,
  negativeNumber,
  periodEndsBeforeStart,
}

class DataValidationException implements Exception {
  final ValidationCode code;

  /// English description for logs and tests.
  final String message;

  /// The conflicting odometer reading, for the odometer codes.
  final int? reading;

  /// Date (`YYYY-MM-DD`) of the conflicting reading.
  final String? readingDate;

  const DataValidationException(
    this.code,
    this.message, {
    this.reading,
    this.readingDate,
  });

  @override
  String toString() => message;
}

void validateDateString(String value) {
  final parts = value.split('-');
  if (parts.length != 3 ||
      parts[0].length != 4 ||
      parts[1].length != 2 ||
      parts[2].length != 2 ||
      int.tryParse(parts[0]) == null ||
      int.tryParse(parts[1]) == null ||
      int.tryParse(parts[2]) == null) {
    throw const DataValidationException(
        ValidationCode.invalidDate, 'Invalid date format. Use YYYY-MM-DD.');
  }

  final parsed = DateTime.tryParse(value);
  if (parsed == null || parsed.toIso8601String().substring(0, 10) != value) {
    throw const DataValidationException(
        ValidationCode.invalidDate, 'Invalid calendar date.');
  }
}

void validateTimeString(String value) {
  final parts = value.split(':');
  if (parts.length != 2 ||
      parts[0].length != 2 ||
      parts[1].length != 2 ||
      int.tryParse(parts[0]) == null ||
      int.tryParse(parts[1]) == null) {
    throw const DataValidationException(
        ValidationCode.invalidTime, 'Invalid time format. Use HH:mm.');
  }

  final hour = int.parse(parts[0]);
  final minute = int.parse(parts[1]);
  if (hour > 23 || minute > 59) {
    throw const DataValidationException(
        ValidationCode.invalidTime, 'Invalid time value.');
  }
}

void validateNonNegativeNumber(num value, String fieldName) {
  if (!value.isFinite || value < 0) {
    throw DataValidationException(ValidationCode.negativeNumber,
        '$fieldName must be a non-negative number.');
  }
}

/// Removes list markers (`-`, `•`, `*`) and whitespace, so a description that
/// consists only of the pre-filled "- " counts as empty.
String meaningfulText(String value) =>
    value.replaceAll(RegExp(r'[\s\-•*]'), '');

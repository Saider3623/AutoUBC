class DataValidationException implements Exception {
  final String message;

  const DataValidationException(this.message);

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
    throw const DataValidationException('Invalid date format. Use YYYY-MM-DD.');
  }

  final parsed = DateTime.tryParse(value);
  if (parsed == null || parsed.toIso8601String().substring(0, 10) != value) {
    throw const DataValidationException('Invalid calendar date.');
  }
}

void validateTimeString(String value) {
  final parts = value.split(':');
  if (parts.length != 2 ||
      parts[0].length != 2 ||
      parts[1].length != 2 ||
      int.tryParse(parts[0]) == null ||
      int.tryParse(parts[1]) == null) {
    throw const DataValidationException('Invalid time format. Use HH:mm.');
  }

  final hour = int.parse(parts[0]);
  final minute = int.parse(parts[1]);
  if (hour > 23 || minute > 59) {
    throw const DataValidationException('Invalid time value.');
  }
}

void validateNonNegativeNumber(num value, String fieldName) {
  if (!value.isFinite || value < 0) {
    throw DataValidationException('$fieldName must be a non-negative number.');
  }
}

import 'package:flutter_test/flutter_test.dart';

import 'package:autoubc/utils/date_utils.dart';
import 'package:autoubc/utils/validation.dart';

void main() {
  group('date validation', () {
    test('accepts an ISO calendar date', () {
      expect(() => validateDateString('2026-02-28'), returnsNormally);
    });

    test('rejects invalid calendar dates', () {
      expect(
        () => validateDateString('2026-02-30'),
        throwsA(isA<DataValidationException>()),
      );
    });

    test('rejects malformed times and values', () {
      expect(
        () => validateTimeString('24:00'),
        throwsA(isA<DataValidationException>()),
      );
      expect(
        () => validateTimeString('9:00'),
        throwsA(isA<DataValidationException>()),
      );
    });
  });

  group('month arithmetic', () {
    test('clamps January 31 to February 28', () {
      expect(addMonthsClamped(DateTime(2026, 1, 31), 1), DateTime(2026, 2, 28));
    });

    test('preserves leap day when target month supports it', () {
      expect(addMonthsClamped(DateTime(2024, 1, 31), 1), DateTime(2024, 2, 29));
    });
  });
}

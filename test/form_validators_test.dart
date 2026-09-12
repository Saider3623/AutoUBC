import 'package:flutter_test/flutter_test.dart';

import 'package:autoubc/utils/form_validators.dart';

void main() {
  group('validateRequiredText', () {
    test('rejects blank text after trimming', () {
      expect(
        validateRequiredText('  ', message: 'Required'),
        'Required',
      );
    });

    test('accepts non-empty text', () {
      expect(validateRequiredText(' AutoUBC ', message: 'Required'), isNull);
    });
  });

  group('validateWholeNumber', () {
    const options = (
      requiredMessage: 'Required',
      invalidMessage: 'Invalid',
      nonNegativeMessage: 'Negative',
    );

    test('accepts zero and positive values', () {
      expect(
        validateWholeNumber('0',
            requiredMessage: options.requiredMessage,
            invalidMessage: options.invalidMessage,
            nonNegativeMessage: options.nonNegativeMessage),
        isNull,
      );
      expect(
        validateWholeNumber('125000',
            requiredMessage: options.requiredMessage,
            invalidMessage: options.invalidMessage,
            nonNegativeMessage: options.nonNegativeMessage),
        isNull,
      );
    });

    test('rejects malformed and negative values', () {
      expect(
        validateWholeNumber('12.5',
            requiredMessage: options.requiredMessage,
            invalidMessage: options.invalidMessage,
            nonNegativeMessage: options.nonNegativeMessage),
        options.invalidMessage,
      );
      expect(
        validateWholeNumber('-1',
            requiredMessage: options.requiredMessage,
            invalidMessage: options.invalidMessage,
            nonNegativeMessage: options.nonNegativeMessage),
        options.nonNegativeMessage,
      );
    });
  });

  group('validateNonNegativeDecimal', () {
    const options = (
      requiredMessage: 'Required',
      invalidMessage: 'Invalid',
      nonNegativeMessage: 'Negative',
    );

    test('normalizes comma decimals and accepts zero', () {
      expect(normalizeDecimalInput('12,5'), '12.5');
      expect(
        validateNonNegativeDecimal('12,5',
            requiredMessage: options.requiredMessage,
            invalidMessage: options.invalidMessage,
            nonNegativeMessage: options.nonNegativeMessage),
        isNull,
      );
      expect(
        validateNonNegativeDecimal('0',
            requiredMessage: options.requiredMessage,
            invalidMessage: options.invalidMessage,
            nonNegativeMessage: options.nonNegativeMessage),
        isNull,
      );
    });

    test('rejects malformed and negative values', () {
      expect(
        validateNonNegativeDecimal('abc',
            requiredMessage: options.requiredMessage,
            invalidMessage: options.invalidMessage,
            nonNegativeMessage: options.nonNegativeMessage),
        options.invalidMessage,
      );
      expect(
        validateNonNegativeDecimal('-0.1',
            requiredMessage: options.requiredMessage,
            invalidMessage: options.invalidMessage,
            nonNegativeMessage: options.nonNegativeMessage),
        options.nonNegativeMessage,
      );
    });
  });
}

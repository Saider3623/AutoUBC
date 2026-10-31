import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import 'validation.dart';

/// Turns an error from a save, delete or export into a message for the user.
///
/// Validation errors get their own localized text; anything else (database or
/// file system failures) gets a neutral message, and the technical details
/// stay in the log.
String describeError(Object error, AppLocalizations loc) {
  if (error is! DataValidationException) return loc.errorUnexpected;

  switch (error.code) {
    case ValidationCode.carNameEmpty:
      return loc.errorCarNameEmpty;
    case ValidationCode.carMissing:
    case ValidationCode.recordWithoutCar:
      return loc.errorCarMissing;
    case ValidationCode.recordMissing:
      return loc.errorRecordMissing;
    case ValidationCode.fuelTypeEmpty:
      return loc.errorFuelTypeEmpty;
    case ValidationCode.descriptionEmpty:
      return loc.fieldRequired;
    case ValidationCode.odometerBelowPrevious:
      return loc.errorOdometerBelowPrevious(
        error.reading ?? 0,
        _formatDate(error.readingDate, loc),
      );
    case ValidationCode.odometerAboveNext:
      return loc.errorOdometerAboveNext(
        error.reading ?? 0,
        _formatDate(error.readingDate, loc),
      );
    case ValidationCode.invalidDate:
      return loc.errorInvalidDate;
    case ValidationCode.invalidTime:
      return loc.errorInvalidTime;
    case ValidationCode.negativeNumber:
      return loc.numberMustBeNonNegative;
    case ValidationCode.periodEndsBeforeStart:
      return loc.errorPeriodEndsBeforeStart;
  }
}

String _formatDate(String? value, AppLocalizations loc) {
  final date = value == null ? null : DateTime.tryParse(value);
  if (date == null) return value ?? '';
  return DateFormat.yMMMd(loc.localeName).format(date);
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get addCar => 'Add Car';

  @override
  String get selectCar => 'Select Car';

  @override
  String get deleteCar => 'Delete Current Car';

  @override
  String get carSettings => 'Settings';

  @override
  String get reminders => 'Reminders';

  @override
  String get serviceBook => 'Service Book';

  @override
  String get exportReports => 'Export Reports';

  @override
  String get enterCarName => 'Enter car name';

  @override
  String get cancel => 'Cancel';

  @override
  String get add => 'Add';

  @override
  String get delete => 'Delete';

  @override
  String get date => 'Date';

  @override
  String get odometer => 'Odometer';

  @override
  String get km => 'km';

  @override
  String get fuel => 'Fuel';

  @override
  String get save => 'Save';

  @override
  String get saveOdometerSuccess => 'Odometer reading saved';

  @override
  String get refuelingAdded => 'Refueling added';

  @override
  String get addRefueling => 'Add Refueling';

  @override
  String get customReminder => 'Other';

  @override
  String get insuranceReminder => 'Insurance';

  @override
  String get maintenanceReminder => 'Maintenance';

  @override
  String get inspectionReminder => 'Inspection';

  @override
  String get reminderTitle => 'Reminder Title';

  @override
  String get reminderCondition => 'Condition';

  @override
  String get reminderType => 'Type';

  @override
  String get byDate => 'By Date';

  @override
  String get byMileage => 'By Mileage';

  @override
  String get repeatEvery => 'Repeat every';

  @override
  String get months => 'months';

  @override
  String currentMileage(int mileage) {
    return 'Current mileage: $mileage km';
  }

  @override
  String mileage(int current, int due) {
    return 'Mileage: $current / $due km';
  }

  @override
  String get upcoming => 'Upcoming';

  @override
  String get overdue => 'Overdue';

  @override
  String get signInToGoogleDrive => 'Sign in to Google Drive';

  @override
  String get signOutFromGoogle => 'Sign out from Google';

  @override
  String get addCarFirst => 'Add a car first';

  @override
  String get noReminders => 'No reminders';

  @override
  String get edit => 'Edit';

  @override
  String get addReminder => 'Add Reminder';

  @override
  String get addACarToGetStarted => 'Add a car to get started';

  @override
  String get welcomeToAutoUbc => 'Welcome to AutoUBC';

  @override
  String get firstLaunchDescription =>
      'Restore your data from Google Drive or start locally without signing in.';

  @override
  String get restoreFromGoogleDrive => 'Sign in and restore from Google Drive';

  @override
  String get createCarLocally => 'Create a car without signing in';

  @override
  String get connectingToGoogleDrive => 'Connecting to Google Drive…';

  @override
  String get active => 'Active';

  @override
  String get completed => 'Completed';

  @override
  String get language => 'Language';

  @override
  String get selectLanguage => 'Select language';

  @override
  String get selectMonthForReport => 'Select month for report';

  @override
  String get exportToPDF => 'Export to PDF';

  @override
  String exportError(String error) {
    return 'Export error: $error';
  }

  @override
  String get loading => 'Loading…';

  @override
  String get fieldRequired => 'This field is required';

  @override
  String get invalidWholeNumber => 'Enter a whole number';

  @override
  String get invalidNumber => 'Enter a valid number';

  @override
  String get numberMustBeNonNegative => 'Number cannot be negative';

  @override
  String get retry => 'Retry';

  @override
  String get english => 'English';

  @override
  String get russian => 'Russian';

  @override
  String get ukrainian => 'Ukrainian';

  @override
  String get selectACar => 'Select a car';

  @override
  String get noServiceLogs => 'No service book entries';

  @override
  String get addServiceLog => 'Add Service Entry';

  @override
  String get editServiceLog => 'Edit Service Entry';

  @override
  String get mileageKm => 'Mileage (km)';

  @override
  String get whatWasDone => 'What was done';

  @override
  String get whatWasDoneHint => 'New line — new item';

  @override
  String get confirmDelete => 'Confirm deletion';

  @override
  String get deleteServiceLogConfirmation =>
      'Are you sure you want to delete this entry?';

  @override
  String get history => 'History';

  @override
  String get selectCarGeneric => 'Select a car';

  @override
  String get noRecords => 'No records';

  @override
  String get deleteOdometerLogConfirmation =>
      'Are you sure you want to delete this odometer entry?';

  @override
  String get deleteFuelLogConfirmation =>
      'Are you sure you want to delete this refueling entry?';

  @override
  String get odometerLabel => 'Odometer';

  @override
  String get kilometers => 'km';

  @override
  String get litersShort => 'L';

  @override
  String get saveTooltip => 'Save';

  @override
  String fuelTypesForCar(String carName) {
    return 'Fuel types for $carName';
  }

  @override
  String get fuelTypesHint => 'Add or remove fuel types used by this car.';

  @override
  String get atLeastOneFuelType => 'Keep at least one fuel type.';

  @override
  String get newFuelTypeHint => 'New type (e.g., Diesel, 98, Electric)';

  @override
  String get weeklyReportNoMileage => 'No mileage';

  @override
  String get weeklyReportNoActivity => 'No mileage recorded during this period';

  @override
  String get odometerSection => 'ODOMETER';

  @override
  String get startLabel => 'Start';

  @override
  String get endLabel => 'End';

  @override
  String get fuelSection => 'FUEL';

  @override
  String get noRefuels => 'No refuels';

  @override
  String get carName => 'Car Name';

  @override
  String get carAdded => 'Car added successfully!';

  @override
  String get search => 'Search';

  @override
  String get notes => 'Notes';

  @override
  String get addNote => 'Add Note';

  @override
  String get editNote => 'Edit Note';

  @override
  String get noteDescription => 'Description';

  @override
  String get deleteNote => 'Delete Note';

  @override
  String get deleteNoteConfirmation =>
      'Are you sure you want to delete this note?';

  @override
  String get chooseDate => 'Choose Date';

  @override
  String get noteDateSelected => 'Date saved';

  @override
  String get syncInProgress => 'Synchronizing…';

  @override
  String get syncIdle => 'Synchronized';

  @override
  String get syncError => 'Synchronization error';

  @override
  String get workWeekSection => 'Working week mode';

  @override
  String get saturdayNotWorkingConfirm =>
      'According to the schedule, a 5-day week applies on this date and Saturday is a day off. Add data?';

  @override
  String get workWeekScheduleHint =>
      'By default the week has 6 days (Mon–Sat). From the start date to the end date a 5-day week (Mon–Fri) applies. Sunday is always a day off.';

  @override
  String get fiveDayPeriodStart => '5-day week starts';

  @override
  String get fiveDayPeriodEnd => '5-day week ends';

  @override
  String get fiveDayPeriodStartNotSet => 'Not set — always a 6-day week';

  @override
  String get fiveDayPeriodEndHint =>
      'If the end isn\'t known yet, leave it empty and set it later when management decides.';

  @override
  String get fiveDayPeriodOpenEnd => 'Until management decides';

  @override
  String get fiveDayPeriodSaved => 'Working week schedule saved';

  @override
  String get clearDate => 'Clear date';

  @override
  String get cloudConflictTitle => 'Different data in Google Drive';

  @override
  String get cloudConflictBody =>
      'The phone and Google Drive hold different data. Choose which copy to keep. The other copy is saved as a backup and is not lost.';

  @override
  String get cloudRestoreTitle => 'Restore from Google Drive?';

  @override
  String get cloudRestoreBody =>
      'Data on this phone will be replaced with the Google Drive copy. The current phone data is saved to a local backup first.';

  @override
  String get cloudColumnPhone => 'Phone';

  @override
  String get cloudColumnDrive => 'Google Drive';

  @override
  String get cloudRowCars => 'Cars';

  @override
  String get cloudRowOdometer => 'Odometer entries';

  @override
  String get cloudRowFuel => 'Refuels';

  @override
  String get cloudRowOther => 'Other records';

  @override
  String get cloudRowLastEntry => 'Last entry';

  @override
  String cloudModifiedAt(String date) {
    return 'Google Drive copy saved $date';
  }

  @override
  String get cloudUseDrive => 'Use Google Drive';

  @override
  String get cloudUsePhone => 'Keep phone data';

  @override
  String get cloudDecideLater => 'Later';

  @override
  String get cloudRestoreAction => 'Restore';

  @override
  String get restoreFromDriveMenu => 'Restore from Google Drive';

  @override
  String get cloudNoBackup => 'There is no copy in Google Drive yet';

  @override
  String get cloudOperationFailed =>
      'Could not reach Google Drive. Nothing was changed. Check the connection and try again.';

  @override
  String get cloudRestored => 'Data restored from Google Drive';

  @override
  String get cloudUploaded => 'Phone data saved to Google Drive';

  @override
  String get cloudCheckingDrive => 'Checking Google Drive…';

  @override
  String get cloudRestoring => 'Restoring data…';

  @override
  String get syncNeedsDecision => 'Choose which data to keep';

  @override
  String get dataLoadErrorTitle => 'Could not open the data';

  @override
  String get dataLoadErrorBody =>
      'Your records are not deleted. Try again; if it repeats, restart the app.';

  @override
  String get errorCarNameEmpty => 'Enter the car name.';

  @override
  String get errorCarMissing =>
      'This car no longer exists. Reopen the screen and try again.';

  @override
  String get errorRecordMissing => 'This record no longer exists.';

  @override
  String get errorFuelTypeEmpty => 'Choose a fuel type.';

  @override
  String errorOdometerBelowPrevious(int reading, String date) {
    return 'The reading is lower than the previous one: $reading km on $date.';
  }

  @override
  String errorOdometerAboveNext(int reading, String date) {
    return 'The reading is higher than the next one: $reading km on $date.';
  }

  @override
  String get errorInvalidDate => 'The date is not valid.';

  @override
  String get errorInvalidTime => 'The time is not valid.';

  @override
  String get errorPeriodEndsBeforeStart =>
      'The end date is earlier than the start date.';

  @override
  String get errorUnexpected => 'Something went wrong. Try again.';

  @override
  String weekDetailTitle(String range) {
    return 'Details: $range';
  }

  @override
  String get reminderStartKm => 'Count from mileage';

  @override
  String get deleteReminderConfirmation => 'Delete this reminder?';

  @override
  String get numberMustBePositive => 'Enter a number greater than zero';

  @override
  String weeklyReportDistanceText(String distance) {
    return 'Distance: $distance km';
  }

  @override
  String get monthSummaryTitle => 'MONTH TOTAL';

  @override
  String monthTotalDistance(String distance) {
    return 'Mileage: $distance km';
  }

  @override
  String monthDaysWithoutReading(int days) {
    return 'Working days without a reading: $days';
  }

  @override
  String weekIncludesGap(String date) {
    return 'The mileage also covers days without readings since $date';
  }

  @override
  String get editOdometerTitle => 'Edit reading';

  @override
  String get editRefuelTitle => 'Edit refuel';

  @override
  String get timeLabel => 'Time';

  @override
  String appVersion(String version, String build) {
    return 'Version $version ($build)';
  }

  @override
  String get navEntry => 'Entry';

  @override
  String get navReport => 'Report';

  @override
  String get todayLabel => 'Today';

  @override
  String get yesterdayLabel => 'Yesterday';

  @override
  String previousReading(String reading, String date) {
    return 'Previous: $reading km, $date';
  }

  @override
  String get readingBelowPrevious => 'Lower than the previous reading';

  @override
  String readingAboveNext(String reading, String date) {
    return 'Higher than the next reading: $reading km, $date';
  }

  @override
  String largeJumpConfirm(String distance, int days) {
    return '+$distance km in $days day(s). Save anyway?';
  }

  @override
  String goToDate(String date) {
    return 'Go to $date';
  }

  @override
  String missingReadingBanner(String date) {
    return 'No odometer reading for $date';
  }

  @override
  String showAllNotes(int count) {
    return 'All notes ($count)';
  }

  @override
  String get showFewerNotes => 'Show less';

  @override
  String get storageExplanation =>
      'Your data is stored on this phone; Google Drive keeps a backup copy.';

  @override
  String get settingsCarSection => 'Car';

  @override
  String get settingsAppSection => 'App';

  @override
  String get plateNumber => 'Registration plate';

  @override
  String get driverName => 'Driver';

  @override
  String get printedInReport => 'Shown in the PDF report';

  @override
  String get renameFuelType => 'Rename fuel type';

  @override
  String get renameFuelTypeHint =>
      'Existing refuels of this car move to the new name when you save.';

  @override
  String fuelTypeExists(String name) {
    return 'The fuel type $name already exists';
  }

  @override
  String get discardChangesQuestion => 'Discard unsaved changes?';

  @override
  String get discardChanges => 'Discard';

  @override
  String deleteCarWillRemove(String carName) {
    return '\"$carName\" and all its records will be deleted:';
  }

  @override
  String get deleteCarTypeName => 'Type the car name to confirm:';

  @override
  String get backupsTitle => 'Backups';

  @override
  String get backupsCloudSection => 'Google Drive';

  @override
  String get backupsLocalSection => 'On this phone';

  @override
  String get backupsCloudSignedOut =>
      'Sign in to Google Drive to see its copies';

  @override
  String get backupsLocalEmpty => 'No local backups yet';

  @override
  String get backupCurrentCloudCopy => 'Current copy';

  @override
  String backupDatedCopy(String date) {
    return 'Copy of $date';
  }

  @override
  String get backupAutomatic => 'Automatic';

  @override
  String get backupBeforeRestore => 'Before a restore';

  @override
  String get backupBeforeDelete => 'Before a car was deleted';

  @override
  String get backupColumn => 'Backup';

  @override
  String get backupOpenFailed => 'Could not open this copy';

  @override
  String get backupRestored => 'Data restored from the copy';

  @override
  String get backupsExplanation =>
      'Before any restore the current data is saved as a separate copy, so a restore can be undone from this list. Local copies are removed together with the app.';

  @override
  String get syncPanelSignedOut =>
      'Google Drive is not connected. The data stays only on this phone.';

  @override
  String get syncPanelError =>
      'The last sync failed. Check the connection and try again.';

  @override
  String get syncPendingChanges => 'Changes are waiting to be uploaded';

  @override
  String syncLastSuccess(String date) {
    return 'Last synced $date';
  }

  @override
  String get syncChooseCopy => 'Choose the copy';

  @override
  String get syncNow => 'Sync now';

  @override
  String get notificationChannelDescription =>
      'Insurance, inspection and other reminder dates';

  @override
  String notificationDueToday(String date) {
    return 'Due today, $date';
  }

  @override
  String notificationDueTomorrow(String date) {
    return 'Due tomorrow, $date';
  }

  @override
  String notificationDueInWeek(String date) {
    return 'Due in a week, on $date';
  }

  @override
  String get reminderDueToday => 'Due today';

  @override
  String reminderDaysLeft(int days) {
    return 'Days left: $days';
  }

  @override
  String reminderDaysOverdue(int days) {
    return 'Days overdue: $days';
  }

  @override
  String reminderKmLeft(int km) {
    return '$km km left';
  }

  @override
  String reminderKmOverdue(int km) {
    return 'Overdue by $km km';
  }

  @override
  String reminderCompletedMessage(String title) {
    return 'Done: $title';
  }

  @override
  String get undo => 'Undo';

  @override
  String get serviceBookOfferTitle => 'Record it in the service book?';

  @override
  String get serviceBookOfferBody =>
      'Add the mileage and what was done, so the maintenance history stays complete.';

  @override
  String get addRecord => 'Add record';

  @override
  String get notNow => 'Not now';

  @override
  String remindersDueMore(int count) {
    return '+$count more';
  }

  @override
  String get notificationsDisabledHint =>
      'Notifications are off, so date reminders will not alert you.';

  @override
  String get enableNotifications => 'Turn on';
}

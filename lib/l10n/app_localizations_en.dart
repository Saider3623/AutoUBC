// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'AutoUBC';

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
  String deleteConfirmation(String carName) {
    return 'Are you sure you want to delete the car \"$carName\"? All related mileage and refueling records will also be deleted.';
  }

  @override
  String get delete => 'Delete';

  @override
  String get confirm => 'Confirm';

  @override
  String get enterData => 'Enter Data';

  @override
  String get historyAndReports => 'History and Reports';

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
  String saveError(String error) {
    return 'Save error: $error';
  }

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
  String get reportLoadError => 'Could not load report';

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
  String get weeklyReport => 'Weekly Report';

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
  String weeklyReportDistance(int distance) {
    return 'Distance: $distance km';
  }

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
  String get averageFuelConsumption =>
      'Average Fuel Consumption (last 30 days)';

  @override
  String averageFuelConsumptionFor(String fuelType, String consumption) {
    return '$fuelType: $consumption L/100km';
  }

  @override
  String get primaryFuelType => 'Primary Fuel Type';

  @override
  String get selectPrimaryFuelType => 'Select primary fuel type';

  @override
  String get carName => 'Car Name';

  @override
  String get editCar => 'Edit Car';

  @override
  String get carAdded => 'Car added successfully!';

  @override
  String get carUpdated => 'Car updated successfully!';

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
  String get noteDateTime => 'Date and Time';

  @override
  String get deleteNote => 'Delete Note';

  @override
  String get deleteNoteConfirmation =>
      'Are you sure you want to delete this note?';

  @override
  String get noNotes => 'No notes yet';

  @override
  String get chooseDate => 'Choose Date';

  @override
  String get noteDateSelected => 'Date saved';

  @override
  String get syncInProgress => 'Synchronizing…';

  @override
  String get syncUnknown => 'Not synchronized yet';

  @override
  String get syncIdle => 'Synchronized';

  @override
  String get syncError => 'Synchronization error';

  @override
  String get syncOk => 'Synchronized';

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
}

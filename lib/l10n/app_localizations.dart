import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_uk.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
    Locale('uk')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'AutoUBC'**
  String get appTitle;

  /// No description provided for @addCar.
  ///
  /// In en, this message translates to:
  /// **'Add Car'**
  String get addCar;

  /// No description provided for @selectCar.
  ///
  /// In en, this message translates to:
  /// **'Select Car'**
  String get selectCar;

  /// No description provided for @deleteCar.
  ///
  /// In en, this message translates to:
  /// **'Delete Current Car'**
  String get deleteCar;

  /// No description provided for @carSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get carSettings;

  /// No description provided for @reminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get reminders;

  /// No description provided for @serviceBook.
  ///
  /// In en, this message translates to:
  /// **'Service Book'**
  String get serviceBook;

  /// No description provided for @exportReports.
  ///
  /// In en, this message translates to:
  /// **'Export Reports'**
  String get exportReports;

  /// No description provided for @enterCarName.
  ///
  /// In en, this message translates to:
  /// **'Enter car name'**
  String get enterCarName;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// Confirmation message before deleting a car
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the car \"{carName}\"? All related mileage and refueling records will also be deleted.'**
  String deleteConfirmation(String carName);

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @enterData.
  ///
  /// In en, this message translates to:
  /// **'Enter Data'**
  String get enterData;

  /// No description provided for @historyAndReports.
  ///
  /// In en, this message translates to:
  /// **'History and Reports'**
  String get historyAndReports;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @odometer.
  ///
  /// In en, this message translates to:
  /// **'Odometer'**
  String get odometer;

  /// No description provided for @km.
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get km;

  /// No description provided for @liters.
  ///
  /// In en, this message translates to:
  /// **'l'**
  String get liters;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saveOdometerSuccess.
  ///
  /// In en, this message translates to:
  /// **'Odometer reading saved'**
  String get saveOdometerSuccess;

  /// Error message when saving fails
  ///
  /// In en, this message translates to:
  /// **'Save error: {error}'**
  String saveError(String error);

  /// No description provided for @refuelingAdded.
  ///
  /// In en, this message translates to:
  /// **'Refueling added'**
  String get refuelingAdded;

  /// No description provided for @addRefueling.
  ///
  /// In en, this message translates to:
  /// **'Add Refueling'**
  String get addRefueling;

  /// No description provided for @customReminder.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get customReminder;

  /// No description provided for @insuranceReminder.
  ///
  /// In en, this message translates to:
  /// **'Insurance'**
  String get insuranceReminder;

  /// No description provided for @maintenanceReminder.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get maintenanceReminder;

  /// No description provided for @inspectionReminder.
  ///
  /// In en, this message translates to:
  /// **'Inspection'**
  String get inspectionReminder;

  /// No description provided for @reminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminder Title'**
  String get reminderTitle;

  /// No description provided for @reminderCondition.
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get reminderCondition;

  /// No description provided for @reminderType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get reminderType;

  /// No description provided for @byDate.
  ///
  /// In en, this message translates to:
  /// **'By Date'**
  String get byDate;

  /// No description provided for @byMileage.
  ///
  /// In en, this message translates to:
  /// **'By Mileage'**
  String get byMileage;

  /// No description provided for @repeatEvery.
  ///
  /// In en, this message translates to:
  /// **'Repeat every'**
  String get repeatEvery;

  /// No description provided for @months.
  ///
  /// In en, this message translates to:
  /// **'months'**
  String get months;

  /// Current mileage display
  ///
  /// In en, this message translates to:
  /// **'Current mileage: {mileage} km'**
  String currentMileage(int mileage);

  /// Mileage reminder display
  ///
  /// In en, this message translates to:
  /// **'Mileage: {current} / {due} km'**
  String mileage(int current, int due);

  /// No description provided for @upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcoming;

  /// No description provided for @overdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdue;

  /// No description provided for @signInToGoogleDrive.
  ///
  /// In en, this message translates to:
  /// **'Sign in to Google Drive'**
  String get signInToGoogleDrive;

  /// No description provided for @signOutFromGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign out from Google'**
  String get signOutFromGoogle;

  /// No description provided for @addCarFirst.
  ///
  /// In en, this message translates to:
  /// **'Add a car first'**
  String get addCarFirst;

  /// No description provided for @noReminders.
  ///
  /// In en, this message translates to:
  /// **'No reminders'**
  String get noReminders;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @addReminder.
  ///
  /// In en, this message translates to:
  /// **'Add Reminder'**
  String get addReminder;

  /// No description provided for @addACarToGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Add a car to get started'**
  String get addACarToGetStarted;

  /// No description provided for @welcomeToAutoUbc.
  ///
  /// In en, this message translates to:
  /// **'Welcome to AutoUBC'**
  String get welcomeToAutoUbc;

  /// No description provided for @firstLaunchDescription.
  ///
  /// In en, this message translates to:
  /// **'Restore your data from Google Drive or start locally without signing in.'**
  String get firstLaunchDescription;

  /// No description provided for @restoreFromGoogleDrive.
  ///
  /// In en, this message translates to:
  /// **'Sign in and restore from Google Drive'**
  String get restoreFromGoogleDrive;

  /// No description provided for @createCarLocally.
  ///
  /// In en, this message translates to:
  /// **'Create a car without signing in'**
  String get createCarLocally;

  /// No description provided for @connectingToGoogleDrive.
  ///
  /// In en, this message translates to:
  /// **'Connecting to Google Drive…'**
  String get connectingToGoogleDrive;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select language'**
  String get selectLanguage;

  /// No description provided for @selectMonthForReport.
  ///
  /// In en, this message translates to:
  /// **'Select month for report'**
  String get selectMonthForReport;

  /// No description provided for @exportToPDF.
  ///
  /// In en, this message translates to:
  /// **'Export to PDF'**
  String get exportToPDF;

  /// Error message when export fails
  ///
  /// In en, this message translates to:
  /// **'Export error: {error}'**
  String exportError(String error);

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get fieldRequired;

  /// No description provided for @invalidWholeNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a whole number'**
  String get invalidWholeNumber;

  /// No description provided for @invalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number'**
  String get invalidNumber;

  /// No description provided for @numberMustBeNonNegative.
  ///
  /// In en, this message translates to:
  /// **'Number cannot be negative'**
  String get numberMustBeNonNegative;

  /// No description provided for @reportLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load report'**
  String get reportLoadError;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @russian.
  ///
  /// In en, this message translates to:
  /// **'Russian'**
  String get russian;

  /// No description provided for @ukrainian.
  ///
  /// In en, this message translates to:
  /// **'Ukrainian'**
  String get ukrainian;

  /// No description provided for @selectACar.
  ///
  /// In en, this message translates to:
  /// **'Select a car'**
  String get selectACar;

  /// No description provided for @noServiceLogs.
  ///
  /// In en, this message translates to:
  /// **'No service book entries'**
  String get noServiceLogs;

  /// No description provided for @addServiceLog.
  ///
  /// In en, this message translates to:
  /// **'Add Service Entry'**
  String get addServiceLog;

  /// No description provided for @editServiceLog.
  ///
  /// In en, this message translates to:
  /// **'Edit Service Entry'**
  String get editServiceLog;

  /// No description provided for @mileageKm.
  ///
  /// In en, this message translates to:
  /// **'Mileage (km)'**
  String get mileageKm;

  /// No description provided for @whatWasDone.
  ///
  /// In en, this message translates to:
  /// **'What was done'**
  String get whatWasDone;

  /// No description provided for @whatWasDoneHint.
  ///
  /// In en, this message translates to:
  /// **'New line — new item'**
  String get whatWasDoneHint;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Confirm deletion'**
  String get confirmDelete;

  /// No description provided for @deleteServiceLogConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this entry?'**
  String get deleteServiceLogConfirmation;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @weeklyReport.
  ///
  /// In en, this message translates to:
  /// **'Weekly Report'**
  String get weeklyReport;

  /// No description provided for @selectCarGeneric.
  ///
  /// In en, this message translates to:
  /// **'Select a car'**
  String get selectCarGeneric;

  /// No description provided for @noRecords.
  ///
  /// In en, this message translates to:
  /// **'No records'**
  String get noRecords;

  /// No description provided for @deleteOdometerLogConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this odometer entry?'**
  String get deleteOdometerLogConfirmation;

  /// No description provided for @deleteFuelLogConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this refueling entry?'**
  String get deleteFuelLogConfirmation;

  /// No description provided for @odometerLabel.
  ///
  /// In en, this message translates to:
  /// **'Odometer'**
  String get odometerLabel;

  /// No description provided for @kilometers.
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get kilometers;

  /// No description provided for @litersShort.
  ///
  /// In en, this message translates to:
  /// **'L'**
  String get litersShort;

  /// No description provided for @saveTooltip.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveTooltip;

  /// Fuel types section title
  ///
  /// In en, this message translates to:
  /// **'Fuel types for {carName}'**
  String fuelTypesForCar(String carName);

  /// No description provided for @fuelTypesHint.
  ///
  /// In en, this message translates to:
  /// **'Add or remove fuel types used by this car.'**
  String get fuelTypesHint;

  /// No description provided for @atLeastOneFuelType.
  ///
  /// In en, this message translates to:
  /// **'Keep at least one fuel type.'**
  String get atLeastOneFuelType;

  /// No description provided for @newFuelTypeHint.
  ///
  /// In en, this message translates to:
  /// **'New type (e.g., Diesel, 98, Electric)'**
  String get newFuelTypeHint;

  /// Weekly report distance display
  ///
  /// In en, this message translates to:
  /// **'Distance: {distance} km'**
  String weeklyReportDistance(int distance);

  /// No description provided for @weeklyReportNoMileage.
  ///
  /// In en, this message translates to:
  /// **'No mileage'**
  String get weeklyReportNoMileage;

  /// No description provided for @weeklyReportNoActivity.
  ///
  /// In en, this message translates to:
  /// **'No mileage recorded during this period'**
  String get weeklyReportNoActivity;

  /// No description provided for @odometerSection.
  ///
  /// In en, this message translates to:
  /// **'ODOMETER'**
  String get odometerSection;

  /// No description provided for @startLabel.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startLabel;

  /// No description provided for @endLabel.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get endLabel;

  /// No description provided for @fuelSection.
  ///
  /// In en, this message translates to:
  /// **'FUEL'**
  String get fuelSection;

  /// No description provided for @noRefuels.
  ///
  /// In en, this message translates to:
  /// **'No refuels'**
  String get noRefuels;

  /// No description provided for @averageFuelConsumption.
  ///
  /// In en, this message translates to:
  /// **'Average Fuel Consumption (last 30 days)'**
  String get averageFuelConsumption;

  /// Average fuel consumption display
  ///
  /// In en, this message translates to:
  /// **'{fuelType}: {consumption} L/100km'**
  String averageFuelConsumptionFor(String fuelType, String consumption);

  /// No description provided for @primaryFuelType.
  ///
  /// In en, this message translates to:
  /// **'Primary Fuel Type'**
  String get primaryFuelType;

  /// No description provided for @selectPrimaryFuelType.
  ///
  /// In en, this message translates to:
  /// **'Select primary fuel type'**
  String get selectPrimaryFuelType;

  /// No description provided for @carName.
  ///
  /// In en, this message translates to:
  /// **'Car Name'**
  String get carName;

  /// No description provided for @editCar.
  ///
  /// In en, this message translates to:
  /// **'Edit Car'**
  String get editCar;

  /// No description provided for @carAdded.
  ///
  /// In en, this message translates to:
  /// **'Car added successfully!'**
  String get carAdded;

  /// No description provided for @carUpdated.
  ///
  /// In en, this message translates to:
  /// **'Car updated successfully!'**
  String get carUpdated;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @addNote.
  ///
  /// In en, this message translates to:
  /// **'Add Note'**
  String get addNote;

  /// No description provided for @editNote.
  ///
  /// In en, this message translates to:
  /// **'Edit Note'**
  String get editNote;

  /// No description provided for @noteDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get noteDescription;

  /// No description provided for @noteDateTime.
  ///
  /// In en, this message translates to:
  /// **'Date and Time'**
  String get noteDateTime;

  /// No description provided for @deleteNote.
  ///
  /// In en, this message translates to:
  /// **'Delete Note'**
  String get deleteNote;

  /// No description provided for @deleteNoteConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this note?'**
  String get deleteNoteConfirmation;

  /// No description provided for @noNotes.
  ///
  /// In en, this message translates to:
  /// **'No notes yet'**
  String get noNotes;

  /// No description provided for @chooseDate.
  ///
  /// In en, this message translates to:
  /// **'Choose Date'**
  String get chooseDate;

  /// No description provided for @noteDateSelected.
  ///
  /// In en, this message translates to:
  /// **'Date saved'**
  String get noteDateSelected;

  /// No description provided for @syncInProgress.
  ///
  /// In en, this message translates to:
  /// **'Synchronizing…'**
  String get syncInProgress;

  /// No description provided for @syncUnknown.
  ///
  /// In en, this message translates to:
  /// **'Not synchronized yet'**
  String get syncUnknown;

  /// No description provided for @syncIdle.
  ///
  /// In en, this message translates to:
  /// **'Synchronized'**
  String get syncIdle;

  /// No description provided for @syncError.
  ///
  /// In en, this message translates to:
  /// **'Synchronization error'**
  String get syncError;

  /// No description provided for @syncOk.
  ///
  /// In en, this message translates to:
  /// **'Synchronized'**
  String get syncOk;

  /// No description provided for @workWeekSection.
  ///
  /// In en, this message translates to:
  /// **'Working week mode'**
  String get workWeekSection;

  /// No description provided for @saturdayNotWorkingConfirm.
  ///
  /// In en, this message translates to:
  /// **'According to the schedule, a 5-day week applies on this date and Saturday is a day off. Add data?'**
  String get saturdayNotWorkingConfirm;

  /// No description provided for @workWeekScheduleHint.
  ///
  /// In en, this message translates to:
  /// **'By default the week has 6 days (Mon–Sat). During the periods below a 5-day week (Mon–Fri) applies. Sunday is always a day off.'**
  String get workWeekScheduleHint;

  /// No description provided for @fiveDayPeriodsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No 5-day week periods — a 6-day week applies all the time.'**
  String get fiveDayPeriodsEmpty;

  /// No description provided for @addFiveDayPeriod.
  ///
  /// In en, this message translates to:
  /// **'Add 5-day week period'**
  String get addFiveDayPeriod;

  /// No description provided for @editFiveDayPeriod.
  ///
  /// In en, this message translates to:
  /// **'5-day week period'**
  String get editFiveDayPeriod;

  /// No description provided for @fiveDayPeriodStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get fiveDayPeriodStart;

  /// No description provided for @fiveDayPeriodEnd.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get fiveDayPeriodEnd;

  /// No description provided for @fiveDayPeriodEndNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get fiveDayPeriodEndNotSet;

  /// No description provided for @fiveDayPeriodEndHint.
  ///
  /// In en, this message translates to:
  /// **'If the end isn't known yet, leave it empty and set it later when management decides.'**
  String get fiveDayPeriodEndHint;

  /// No description provided for @fiveDayPeriodOpenEnd.
  ///
  /// In en, this message translates to:
  /// **'until management decides'**
  String get fiveDayPeriodOpenEnd;

  /// No description provided for @fiveDayPeriodActive.
  ///
  /// In en, this message translates to:
  /// **'Active now'**
  String get fiveDayPeriodActive;

  /// No description provided for @fiveDayPeriodEndBeforeStart.
  ///
  /// In en, this message translates to:
  /// **'The end can't be earlier than the start.'**
  String get fiveDayPeriodEndBeforeStart;

  /// No description provided for @fiveDayPeriodOverlap.
  ///
  /// In en, this message translates to:
  /// **'The period overlaps another one: {period}.'**
  String fiveDayPeriodOverlap(String period);

  /// No description provided for @deleteFiveDayPeriodConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete the period {period}? Weeks in these dates will be reported as 6-day weeks.'**
  String deleteFiveDayPeriodConfirm(String period);

  /// No description provided for @fiveDayPeriodSaved.
  ///
  /// In en, this message translates to:
  /// **'Working week schedule saved'**
  String get fiveDayPeriodSaved;

  /// No description provided for @clearDate.
  ///
  /// In en, this message translates to:
  /// **'Clear date'**
  String get clearDate;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru', 'uk'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
    case 'uk':
      return AppLocalizationsUk();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}

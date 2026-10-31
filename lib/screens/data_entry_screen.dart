import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../domain/reminder_status.dart';
import '../l10n/app_localizations.dart';
import '../models/note.dart';
import '../models/odometer_log.dart';
import '../providers/app_provider.dart';
import '../providers/locale_provider.dart';
import '../theme/fuel_colors.dart';
import '../utils/date_utils.dart';
import '../utils/error_messages.dart';
import '../utils/form_validators.dart';
import '../utils/reminder_texts.dart';
import '../utils/validation.dart';
import '../utils/weekly_report_utils.dart';
import '../widgets/inline_form_error.dart';
import 'reminders_screen.dart';
import '../theme/app_theme.dart';

/// A daily jump above this many kilometres asks for confirmation before it is
/// saved (most often an extra digit was typed).
const int largeDailyJumpKm = 1500;

/// Notes shown before the "all notes" button.
const int _collapsedNotes = 3;

class DataEntryScreen extends StatefulWidget {
  const DataEntryScreen({super.key});

  @override
  State<DataEntryScreen> createState() => _DataEntryScreenState();
}

class _DataEntryScreenState extends State<DataEntryScreen>
    with WidgetsBindingObserver {
  DateTime _selectedDate = DateTime.now();
  // Calendar day seen when the screen was last active; used to move the
  // selected date forward when the app is reopened on a later day.
  DateTime _today = _dateOnly(DateTime.now());
  final _odometerController = TextEditingController();
  final _litersController = TextEditingController();
  String _selectedFuelType = 'ГАЗ';
  final _odometerFormKey = GlobalKey<FormState>();
  final _fuelFormKey = GlobalKey<FormState>();
  int? _loadedCarId;
  bool _isSavingOdometer = false;
  bool _isSavingFuel = false;
  String? _odometerSaveError;
  String? _fuelSaveError;

  /// Date of the reading that conflicted with the last save attempt; offered
  /// as a shortcut so a typo in that reading is fixed in one step.
  String? _conflictDate;

  /// The previous working day when it has no odometer reading.
  DateTime? _missingDay;
  DateTime? _dismissedMissingDay;

  /// Highlights the odometer field while the missing reading is entered.
  bool _odometerMissingForPast = false;
  bool _showAllNotes = false;

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static String _key(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refreshForCar();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final today = _dateOnly(DateTime.now());
    if (today == _today) return;
    final wasToday = _dateOnly(_selectedDate) == _today;
    _today = today;
    // The app stayed open overnight: a morning reading must not be saved on
    // yesterday's date, so "today" moves along unless the user picked a date.
    if (wasToday) {
      setState(() {
        _selectedDate = DateTime.now();
        _odometerMissingForPast = false;
      });
    }
    _refreshForCar();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = Provider.of<AppProvider>(context);
    final carId = provider.selectedCar?.id;
    if (carId != _loadedCarId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _refreshForCar();
      });
    } else {
      // Readings changed (saved, edited, restored): re-check the gap. A
      // build follows anyway, so no setState here.
      _updateMissingDay(provider, rebuild: false);
    }
  }

  void _refreshForCar() {
    final provider = Provider.of<AppProvider>(context, listen: false);
    _updateMissingDay(provider);
    _loadCurrentOdometer();
  }

  bool _isWorkingDay(AppProvider provider, DateTime day) =>
      day.weekday != DateTime.sunday &&
      !provider.workSchedule.isNonWorkingSaturday(day);

  /// Finds the previous working day without a reading. It is offered only
  /// when the car already had readings before that day and a refuel was
  /// recorded on it: a working day spent at home has no reading, and its
  /// mileage simply carries over from the previous reading.
  void _updateMissingDay(AppProvider provider, {bool rebuild = true}) {
    DateTime? missing;
    if (provider.selectedCar != null) {
      var day = addCalendarDays(_today, -1);
      for (var i = 0; i < 7 && !_isWorkingDay(provider, day); i++) {
        day = addCalendarDays(day, -1);
      }
      final dayKey = _key(day);
      final logs = provider.odometerLogs;
      final hasReading = logs.any((log) => log.dateString == dayKey);
      final hasEarlier = logs.any((log) => log.dateString.compareTo(dayKey) < 0);
      final hasRefuel =
          provider.fuelLogs.any((log) => log.dateString == dayKey);
      if (!hasReading && hasEarlier && hasRefuel) {
        missing = day;
      }
    }
    if (missing != _missingDay) {
      if (rebuild && mounted) {
        setState(() => _missingDay = missing);
      } else {
        _missingDay = missing;
      }
    }
  }

  Future<void> _loadCurrentOdometer() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final carId = provider.selectedCar?.id;
    if (carId == null) {
      _loadedCarId = null;
      return;
    }
    final dateString = _key(_selectedDate);
    OdometerLog? log;
    for (final candidate in provider.odometerLogs) {
      if (candidate.dateString == dateString) log = candidate;
    }
    _loadedCarId = carId;
    setState(() {
      if (log != null) {
        _odometerController.text = log.odometer.toString();
      } else {
        _odometerController.clear();
      }
    });
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
      _odometerMissingForPast = false;
      _odometerSaveError = null;
      _conflictDate = null;
    });
    _loadCurrentOdometer();
  }

  /// The last reading before the selected date and the first one after it.
  (OdometerLog?, OdometerLog?) _neighbours(AppProvider provider) {
    final key = _key(_selectedDate);
    OdometerLog? previous;
    OdometerLog? next;
    for (final log in provider.odometerLogs) {
      final date = log.dateString;
      if (date.compareTo(key) < 0) {
        if (previous == null || date.compareTo(previous.dateString) > 0) {
          previous = log;
        }
      } else if (date.compareTo(key) > 0) {
        if (next == null || date.compareTo(next.dateString) < 0) next = log;
      }
    }
    return (previous, next);
  }

  /// Asks for confirmation before saving mileage on a Saturday that is a day
  /// off under the working-week schedule (inside a five-day period).
  Future<bool> _confirmNonWorkingSaturday() async {
    final schedule =
        Provider.of<AppProvider>(context, listen: false).workSchedule;
    if (!schedule.isNonWorkingSaturday(_selectedDate)) {
      return true;
    }

    if (!mounted) return false;
    final loc = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(loc.saturdayNotWorkingConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(loc.add),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  /// Asks before saving an unusually large jump since the previous reading.
  Future<bool> _confirmLargeJump(int odometer) async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final (previous, _) = _neighbours(provider);
    final previousDate =
        previous == null ? null : DateTime.tryParse(previous.dateString);
    if (previous == null || previousDate == null) return true;
    final delta = odometer - previous.odometer;
    final days = calendarDaysBetween(previousDate, _selectedDate);
    if (days < 1 || delta <= largeDailyJumpKm * days) return true;

    final loc = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(loc.largeJumpConfirm(
          NumberFormat.decimalPattern(languageCode).format(delta),
          days,
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(loc.save),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _saveOdometer() async {
    if (!(_odometerFormKey.currentState?.validate() ?? false)) return;

    final provider = Provider.of<AppProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final loc = AppLocalizations.of(context)!;
    final odometer = int.parse(_odometerController.text.trim());

    if (!await _confirmNonWorkingSaturday()) return;
    if (!mounted) return;
    if (!await _confirmLargeJump(odometer)) return;
    if (!mounted) return;

    setState(() {
      _isSavingOdometer = true;
      _odometerSaveError = null;
      _conflictDate = null;
    });
    final dateString = _key(_selectedDate);
    final wasMissingForPast = _odometerMissingForPast;
    try {
      await provider.saveOdometerLog(dateString, odometer);
      if (!mounted) return;
      setState(() {
        _isSavingOdometer = false;
        if (wasMissingForPast) {
          _odometerMissingForPast = false;
          _selectedDate = DateTime.now();
        }
      });
      // The gap for the previous day is closed: switch back to today.
      if (wasMissingForPast) await _loadCurrentOdometer();
      messenger.showSnackBar(SnackBar(content: Text(loc.saveOdometerSuccess)));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSavingOdometer = false;
        _odometerSaveError = describeError(error, loc);
        _conflictDate =
            error is DataValidationException ? error.readingDate : null;
      });
    }
  }

  Future<void> _saveFuel() async {
    if (!(_fuelFormKey.currentState?.validate() ?? false)) return;
    final loc = AppLocalizations.of(context)!;
    final provider = Provider.of<AppProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final focusScope = FocusScope.of(context);
    final fuelFormState = _fuelFormKey.currentState;

    setState(() {
      _isSavingFuel = true;
      _fuelSaveError = null;
    });
    try {
      await provider.addFuelLog(
        _key(_selectedDate),
        DateFormat('HH:mm').format(DateTime.now()),
        _selectedFuelType,
        double.parse(normalizeDecimalInput(_litersController.text.trim())),
      );
      if (!mounted) return;
      focusScope.unfocus();
      fuelFormState?.reset();
      _litersController.clear();
      setState(() => _isSavingFuel = false);
      messenger.showSnackBar(SnackBar(content: Text(loc.refuelingAdded)));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSavingFuel = false;
        _fuelSaveError = describeError(error, loc);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final loc = AppLocalizations.of(context)!;
    final languageCode = localeProvider.locale?.languageCode ?? 'uk';
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final missingDay = _missingDay;
        return Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (missingDay != null && missingDay != _dismissedMissingDay)
                    _buildMissingBanner(missingDay, loc, languageCode),
                  _buildReminderBanner(provider, loc),
                  _buildDateCard(loc, languageCode, localeProvider),
                  const SizedBox(height: 12),
                  _buildOdometerCard(provider, loc, languageCode),
                  const SizedBox(height: 12),
                  _buildFuelCard(provider, loc),
                  _buildNotes(provider, loc),
                ],
              ),
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                onPressed: () => _showNoteDialog(context),
                tooltip: loc.addNote,
                elevation: 8,
                child: const Icon(Icons.edit_note),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMissingBanner(
    DateTime day,
    AppLocalizations loc,
    String languageCode,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      color: colorScheme.errorContainer.withValues(alpha: 0.5),
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
        child: Row(
          children: [
            Icon(Icons.speed, color: colorScheme.error),
            const SizedBox(width: 10),
            Expanded(
              child: Text(loc.missingReadingBanner(
                  DateFormat('EEE, d MMMM', languageCode).format(day))),
            ),
            TextButton(
              onPressed: () {
                _selectDate(day);
                setState(() => _odometerMissingForPast = true);
              },
              child: Text(loc.add),
            ),
            IconButton(
              tooltip: loc.cancel,
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => _dismissedMissingDay = day),
            ),
          ],
        ),
      ),
    );
  }

  /// The most urgent overdue or soon-due reminder of the car. Mileage
  /// reminders cannot be notified by date, so this is where they show up.
  Widget _buildReminderBanner(AppProvider provider, AppLocalizations loc) {
    final currentKm = currentMileage(provider.odometerLogs);
    final today = DateTime.now();
    final due = [
      for (final reminder in sortRemindersByUrgency(
        provider.reminders,
        currentKm: currentKm,
        today: today,
      ))
        (
          reminder: reminder,
          status: reminderStatus(reminder, currentKm: currentKm, today: today),
        ),
    ].where((entry) => entry.status.isOverdue || entry.status.isUpcoming);
    if (due.isEmpty) return const SizedBox.shrink();

    final first = due.first;
    final overdue = first.status.isOverdue;
    final more = due.length - 1;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Card(
      elevation: 0,
      color: overdue
          ? colorScheme.errorContainer.withValues(alpha: 0.5)
          : colorScheme.tertiaryContainer.withValues(alpha: 0.6),
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const RemindersScreen()),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
          child: Row(
            children: [
              Icon(
                overdue
                    ? Icons.warning_amber_rounded
                    : Icons.notifications_active_outlined,
                color: overdue
                    ? colorScheme.error
                    : colorScheme.onTertiaryContainer,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${reminderTitle(first.reminder, loc)}: '
                  '${reminderTimeLeft(first.status, loc) ?? ''}',
                ),
              ),
              if (more > 0)
                Text(loc.remindersDueMore(more),
                    style: theme.textTheme.bodySmall),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateCard(
    AppLocalizations loc,
    String languageCode,
    LocaleProvider localeProvider,
  ) {
    final today = _dateOnly(DateTime.now());
    final yesterday = addCalendarDays(today, -1);
    final selected = _dateOnly(_selectedDate);
    final label = DateFormat('EEE, d MMMM', languageCode).format(selected);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            ChoiceChip(
              label: Text(loc.todayLabel),
              selected: selected == today,
              onSelected: (_) => _selectDate(DateTime.now()),
            ),
            const SizedBox(width: 6),
            ChoiceChip(
              label: Text(loc.yesterdayLabel),
              selected: selected == yesterday,
              onSelected: (_) => _selectDate(yesterday),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    locale: localeProvider.locale,
                  );
                  if (picked != null && _dateOnly(picked) != selected) {
                    _selectDate(picked);
                  }
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          label,
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.calendar_today, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOdometerCard(
    AppProvider provider,
    AppLocalizations loc,
    String languageCode,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final numbers = NumberFormat.decimalPattern(languageCode);
    final (previous, next) = _neighbours(provider);
    String dayLabel(OdometerLog log) {
      final date = DateTime.tryParse(log.dateString);
      return date == null
          ? log.dateString
          : DateFormat('EEE, d MMM', languageCode).format(date);
    }

    final conflictDate =
        _conflictDate == null ? null : DateTime.tryParse(_conflictDate!);
    final highlight = _odometerMissingForPast
        ? OutlineInputBorder(
            borderSide: BorderSide(color: colorScheme.error, width: 2),
          )
        : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Form(
          key: _odometerFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _odometerController,
                      keyboardType: TextInputType.number,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (value) => validateWholeNumber(
                        value,
                        requiredMessage: loc.fieldRequired,
                        invalidMessage: loc.invalidWholeNumber,
                        nonNegativeMessage: loc.numberMustBeNonNegative,
                      ),
                      decoration: InputDecoration(
                        labelText: loc.odometer,
                        suffixText: loc.km,
                        enabledBorder: highlight,
                        focusedBorder: highlight,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _isSavingOdometer ? null : _saveOdometer,
                    icon: _isSavingOdometer
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle, color: AppColors.success),
                    iconSize: 36,
                    tooltip: loc.save,
                  ),
                ],
              ),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _odometerController,
                builder: (context, value, child) {
                  final typed = int.tryParse(value.text.trim());
                  final lines = <Widget>[];
                  if (previous != null) {
                    final delta = typed == null ? null : typed - previous.odometer;
                    lines.add(Text(
                      [
                        loc.previousReading(
                            numbers.format(previous.odometer), dayLabel(previous)),
                        if (delta != null && delta >= 0)
                          '+${numbers.format(delta)} ${loc.km}',
                      ].join('  ·  '),
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ));
                    if (delta != null && delta < 0) {
                      lines.add(Text(
                        loc.readingBelowPrevious,
                        style: TextStyle(fontSize: 13, color: colorScheme.error),
                      ));
                    }
                  }
                  if (next != null && typed != null && typed > next.odometer) {
                    lines.add(Text(
                      loc.readingAboveNext(
                          numbers.format(next.odometer), dayLabel(next)),
                      style: TextStyle(fontSize: 13, color: colorScheme.error),
                    ));
                  }
                  if (lines.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6, bottom: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: lines,
                    ),
                  );
                },
              ),
              InlineFormError(message: _odometerSaveError),
              if (conflictDate != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => _selectDate(conflictDate),
                    icon: const Icon(Icons.edit_calendar, size: 18),
                    label: Text(loc.goToDate(
                        DateFormat('EEE, d MMM', languageCode)
                            .format(conflictDate))),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFuelCard(AppProvider provider, AppLocalizations loc) {
    final fuelTypes = provider.selectedCar?.fuelTypes ?? const ['ГАЗ', '95'];
    if (!fuelTypes.contains(_selectedFuelType) && fuelTypes.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedFuelType = fuelTypes.first);
      });
    }
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Form(
          key: _fuelFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8.0,
                runSpacing: 4.0,
                children: [
                  for (final type in fuelTypes)
                    _FuelTypeButton(
                      type: type,
                      selected: _selectedFuelType == type,
                      color: fuelTypeColor(type, colorScheme),
                      onPressed: () => setState(() => _selectedFuelType = type),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _litersController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      autovalidateMode: AutovalidateMode.disabled,
                      validator: (value) => validateNonNegativeDecimal(
                        value,
                        requiredMessage: loc.fieldRequired,
                        invalidMessage: loc.invalidNumber,
                        nonNegativeMessage: loc.numberMustBeNonNegative,
                        positiveMessage: loc.numberMustBePositive,
                      ),
                      onChanged: (value) {
                        if (value.contains(',')) {
                          final normalized = normalizeDecimalInput(value);
                          _litersController.value =
                              _litersController.value.copyWith(
                            text: normalized,
                            selection: TextSelection.collapsed(
                              offset: normalized.length,
                            ),
                          );
                        }
                      },
                      decoration: InputDecoration(
                        labelText: loc.fuel,
                        suffixText: loc.litersShort,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _isSavingFuel ? null : _saveFuel,
                    icon: _isSavingFuel
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(Icons.add_circle, color: colorScheme.primary),
                    iconSize: 36,
                    tooltip: loc.addRefueling,
                  ),
                ],
              ),
              InlineFormError(message: _fuelSaveError),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotes(AppProvider provider, AppLocalizations loc) {
    final notes = provider.notes;
    if (notes.isEmpty) return const SizedBox.shrink();
    final visible =
        _showAllNotes ? notes : notes.take(_collapsedNotes).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        const Divider(thickness: 1),
        const SizedBox(height: 12),
        Text(
          loc.notes,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                letterSpacing: 0.4,
              ),
        ),
        const SizedBox(height: 8),
        ...visible.map((note) => _buildNoteCard(context, note)),
        if (notes.length > _collapsedNotes)
          TextButton(
            onPressed: () => setState(() => _showAllNotes = !_showAllNotes),
            child: Text(
              _showAllNotes ? loc.showFewerNotes : loc.showAllNotes(notes.length),
            ),
          ),
      ],
    );
  }

  Widget _buildNoteCard(BuildContext context, Note note) {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final languageCode = localeProvider.locale?.languageCode ?? 'uk';

    return InkWell(
      onTap: () => _showNoteDialog(context, note),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (note.dateTime != null)
                Text(
                  DateFormat.yMMMd(languageCode).format(note.dateTime!),
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 14,
                  ),
                ),
              SizedBox(height: note.dateTime != null ? 4 : 0),
              Text(
                note.description,
                style: const TextStyle(fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNoteDialog(BuildContext context, [Note? noteToEdit]) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    if (provider.selectedCar == null) return;

    showDialog(
      context: context,
      builder: (context) => _NoteDialog(
        carId: provider.selectedCar!.id,
        noteToEdit: noteToEdit,
        onSave: (note) async {
          if (noteToEdit != null) {
            note.id = noteToEdit.id;
            await provider.updateNote(note);
          } else {
            await provider.addNote(note);
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _odometerController.dispose();
    _litersController.dispose();
    super.dispose();
  }
}

class _NoteDialog extends StatefulWidget {
  final int carId;
  final Future<void> Function(Note) onSave;
  final Note? noteToEdit;

  const _NoteDialog({
    required this.carId,
    required this.onSave,
    this.noteToEdit,
  });

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  DateTime? _dateTime;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isSaving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    if (widget.noteToEdit != null) {
      _dateTime = widget.noteToEdit!.dateTime;
      _descriptionController.text = widget.noteToEdit!.description;
    }
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final loc = AppLocalizations.of(context)!;
    final languageCode = localeProvider.locale?.languageCode ?? 'uk';

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      title: Text(
        widget.noteToEdit != null ? loc.editNote : loc.addNote,
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    _dateTime != null
                        ? DateFormat.yMMMd(languageCode).format(_dateTime!)
                        : loc.chooseDate,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_dateTime != null)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _dateTime = null;
                            });
                          },
                        ),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final noteDateSelectedText = loc.noteDateSelected;
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: _dateTime ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                      locale: localeProvider.locale,
                    );
                    if (!mounted) return;
                    if (pickedDate != null) {
                      setState(() {
                        _dateTime = pickedDate;
                      });
                      messenger.showSnackBar(
                        SnackBar(content: Text(noteDateSelectedText)),
                      );
                    }
                  },
                ),
                TextFormField(
                  controller: _descriptionController,
                  minLines: 3,
                  maxLines: 10,
                  textCapitalization: TextCapitalization.sentences,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (value) => validateRequiredText(
                    value,
                    message: loc.fieldRequired,
                  ),
                  decoration: InputDecoration(
                    labelText: loc.noteDescription,
                    alignLabelWithHint: true,
                  ),
                ),
                InlineFormError(message: _saveError),
              ],
            ),
          ),
        ),
      ),
      actions: [
        if (widget.noteToEdit != null)
          TextButton(
            onPressed: () async {
              final provider = Provider.of<AppProvider>(context, listen: false);
              final navigator = Navigator.of(context);
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(loc.deleteNote),
                  content: Text(loc.deleteNoteConfirmation),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(loc.cancel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(loc.delete,
                          style: const TextStyle(color: AppColors.error)),
                    ),
                  ],
                ),
              );

              if (!mounted) return;
              if (confirmed == true) {
                try {
                  await provider.deleteNote(widget.noteToEdit!);
                  if (!mounted) return;
                  navigator.pop();
                } catch (error) {
                  if (!mounted) return;
                  setState(() => _saveError = describeError(error, loc));
                }
              }
            },
            child:
                Text(loc.deleteNote, style: const TextStyle(color: AppColors.error)),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(loc.cancel),
        ),
        ElevatedButton(
          onPressed: _isSaving
              ? null
              : () async {
                  if (!(_formKey.currentState?.validate() ?? false)) {
                    return;
                  }

                  setState(() {
                    _isSaving = true;
                    _saveError = null;
                  });
                  final note = Note()
                    ..carId = widget.carId
                    ..dateTime = _dateTime
                    ..description = _descriptionController.text.trim();

                  final navigator = Navigator.of(context);
                  try {
                    await widget.onSave(note);
                    if (mounted) navigator.pop();
                  } catch (error) {
                    if (!mounted) return;
                    setState(() {
                      _isSaving = false;
                      _saveError = describeError(error, loc);
                    });
                  }
                },
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(loc.save),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }
}

/// Fuel type button: outlined in the fuel colour when selected.
class _FuelTypeButton extends StatelessWidget {
  final String type;
  final bool selected;
  final Color color;
  final VoidCallback onPressed;

  const _FuelTypeButton({
    required this.type,
    required this.selected,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        side: BorderSide(
          width: selected ? 2.0 : 1.0,
          color: selected ? color : AppColors.muted,
        ),
        foregroundColor: selected ? color : null,
      ),
      onPressed: onPressed,
      child: Text(
        type,
        style: TextStyle(
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/settings_provider.dart';
import '../l10n/app_localizations.dart';
import '../db/database_service.dart';
import '../models/note.dart';
import '../utils/form_validators.dart';
import '../widgets/inline_form_error.dart';

// #region debug-point F6:reporter
void _dbgEntry(String h, String loc, String msg,
    [Map<String, Object?> data = const {}]) {
  http
      .post(
        Uri.parse('http://192.168.31.107:7777/event'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sessionId': 'startup-freeze-google-auth',
          'runId': 'pre-fix',
          'hypothesisId': h,
          'location': loc,
          'msg': '[DEBUG] $msg',
          'data': data,
        }),
      )
      .catchError((_) => http.Response('', 0));
}
// #endregion

class DataEntryScreen extends StatefulWidget {
  const DataEntryScreen({super.key});

  @override
  State<DataEntryScreen> createState() => _DataEntryScreenState();
}

class _DataEntryScreenState extends State<DataEntryScreen> {
  DateTime _selectedDate = DateTime.now();
  final _odometerController = TextEditingController();
  final _litersController = TextEditingController();
  String _selectedFuelType = 'ГАЗ';
  final DatabaseService _db = DatabaseService();
  final _odometerFormKey = GlobalKey<FormState>();
  final _fuelFormKey = GlobalKey<FormState>();
  int? _loadedCarId;
  bool _isSavingOdometer = false;
  bool _isSavingFuel = false;
  String? _odometerSaveError;
  String? _fuelSaveError;
  // Set when yesterday had a refuel but no odometer reading. Highlights the
  // odometer field until the missing past reading is saved.
  bool _odometerMissingForPast = false;
  // #region debug-point F:counters
  int _depsCount = 0;
  int _checkCount = 0;
  int _loadCount = 0;
  // #endregion

  @override
  void initState() {
    super.initState();
    // #region debug-point F:lifecycle
    _dbgEntry('F', 'data_entry_screen.dart:initState', 'initState');
    // #endregion
    _checkMissedOdometerForYesterday();
  }

  @override
  void didUpdateWidget(covariant DataEntryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadCurrentOdometer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final carId = Provider.of<AppProvider>(context).selectedCar?.id;
    // #region debug-point F:lifecycle
    _depsCount++;
    _dbgEntry('F', 'data_entry_screen.dart:didChangeDependencies',
        'deps #$_depsCount carId=$carId loadedCarId=$_loadedCarId');
    // #endregion
    if (carId != _loadedCarId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _checkMissedOdometerForYesterday();
      });
    }
  }

  /// If yesterday has a refueling entry but no odometer reading, pre-select
  /// yesterday and flag the odometer field so the user can fill the gap.
  Future<void> _checkMissedOdometerForYesterday() async {
    // #region debug-point F:check
    final checkNo = ++_checkCount;
    _dbgEntry('F', 'data_entry_screen.dart:_checkMissedOdometerForYesterday',
        'check #$checkNo begin');
    // #endregion
    final provider = Provider.of<AppProvider>(context, listen: false);
    final carId = provider.selectedCar?.id;
    if (carId == null) {
      _loadedCarId = null;
      // #region debug-point F:check
      _dbgEntry('F', 'data_entry_screen.dart:_checkMissedOdometerForYesterday',
          'check #$checkNo end (no car)');
      // #endregion
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final yesterdayString = DateFormat('yyyy-MM-dd').format(yesterday);

    final odometerLog = await _db.getOdometerLog(carId, yesterdayString);
    if (!mounted) return;

    var shouldFlag = false;
    if (odometerLog == null) {
      final fuelLogs =
          await _db.getFuelLogsInRange(carId, yesterdayString, yesterdayString);
      if (!mounted) return;
      shouldFlag = fuelLogs.isNotEmpty;
    }

    // #region debug-point F:check
    _dbgEntry('F', 'data_entry_screen.dart:_checkMissedOdometerForYesterday',
        'check #$checkNo end shouldFlag=$shouldFlag');
    // #endregion

    if (shouldFlag && !_odometerMissingForPast) {
      setState(() {
        _selectedDate = yesterday;
        _odometerMissingForPast = true;
      });
    } else if (!shouldFlag && _odometerMissingForPast) {
      setState(() {
        _odometerMissingForPast = false;
      });
    }

    await _loadCurrentOdometer();
  }

  Future<void> _loadCurrentOdometer() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final carId = provider.selectedCar?.id;
    if (carId == null) {
      _loadedCarId = null;
      return;
    }
    // #region debug-point F:loadodo
    final loadNo = ++_loadCount;
    _dbgEntry('F', 'data_entry_screen.dart:_loadCurrentOdometer',
        'loadOdo #$loadNo begin carId=$carId');
    // #endregion
    final dateString = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final log = await _db.getOdometerLog(carId, dateString);
    if (!mounted ||
        Provider.of<AppProvider>(context, listen: false).selectedCar?.id !=
            carId) {
      // #region debug-point F:loadodo
      _dbgEntry('F', 'data_entry_screen.dart:_loadCurrentOdometer',
          'loadOdo #$loadNo aborted (unmounted or car changed)');
      // #endregion
      return;
    }
    _loadedCarId = carId;
    // #region debug-point F:loadodo
    _dbgEntry('F', 'data_entry_screen.dart:_loadCurrentOdometer',
        'loadOdo #$loadNo end found=${log != null}');
    // #endregion
    setState(() {
      if (log != null) {
        _odometerController.text = log.odometer.toString();
      } else {
        _odometerController.clear();
      }
    });
  }

  /// In 5-day mode, asks for confirmation before saving mileage on Saturday.
  Future<bool> _confirmNonWorkingSaturday() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    if (settings.workWeekDays != SettingsProvider.fiveDayWeek ||
        _selectedDate.weekday != DateTime.saturday) {
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

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final loc = AppLocalizations.of(context)!;
    final languageCode = localeProvider.locale?.languageCode ?? 'uk';
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        return Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Date selection.
                  Card(
                    child: InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                          locale: localeProvider.locale,
                        );
                        if (picked != null && picked != _selectedDate) {
                          setState(() {
                            _selectedDate = picked;
                            _odometerMissingForPast = false;
                          });
                          _loadCurrentOdometer();
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        child: Center(
                          child: Text(
                            DateFormat.yMMMd(languageCode)
                                .format(_selectedDate),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Odometer.
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
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
                                    autovalidateMode:
                                        AutovalidateMode.onUserInteraction,
                                    validator: (value) => validateWholeNumber(
                                      value,
                                      requiredMessage: loc.fieldRequired,
                                      invalidMessage: loc.invalidWholeNumber,
                                      nonNegativeMessage:
                                          loc.numberMustBeNonNegative,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: loc.odometer,
                                      suffixText: loc.km,
                                      enabledBorder: _odometerMissingForPast
                                          ? const OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Colors.red, width: 2),
                                            )
                                          : null,
                                      focusedBorder: _odometerMissingForPast
                                          ? const OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Colors.red, width: 2),
                                            )
                                          : null,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: _isSavingOdometer
                                      ? null
                                      : () async {
                                          if (!(_odometerFormKey.currentState
                                                  ?.validate() ??
                                              false)) {
                                            return;
                                          }

                                          final provider =
                                              Provider.of<AppProvider>(context,
                                                  listen: false);
                                          final messenger =
                                              ScaffoldMessenger.of(context);
                                          final successMessage =
                                              loc.saveOdometerSuccess;

                                          if (!await _confirmNonWorkingSaturday()) {
                                            return;
                                          }
                                          if (!mounted) return;

                                          setState(() {
                                            _isSavingOdometer = true;
                                            _odometerSaveError = null;
                                          });
                                          final dateString =
                                              DateFormat('yyyy-MM-dd')
                                                  .format(_selectedDate);
                                          final wasMissingForPast =
                                              _odometerMissingForPast;
                                          try {
                                            await provider.saveOdometerLog(
                                              dateString,
                                              int.parse(_odometerController.text
                                                  .trim()),
                                            );
                                            if (!mounted) return;
                                            setState(() {
                                              _isSavingOdometer = false;
                                              if (wasMissingForPast) {
                                                _odometerMissingForPast = false;
                                                _selectedDate = DateTime.now();
                                              }
                                            });
                                            if (wasMissingForPast) {
                                              // The gap for the previous day is
                                              // closed: switch back to today.
                                              await _loadCurrentOdometer();
                                            }
                                            messenger.showSnackBar(
                                              SnackBar(
                                                content: Text(successMessage),
                                              ),
                                            );
                                          } catch (e) {
                                            if (!mounted) return;
                                            setState(() {
                                              _isSavingOdometer = false;
                                              _odometerSaveError =
                                                  loc.saveError(e.toString());
                                            });
                                          }
                                        },
                                  icon: _isSavingOdometer
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        )
                                      : const Icon(Icons.check_circle,
                                          color: Colors.green),
                                  iconSize: 36,
                                  tooltip: loc.save,
                                ),
                              ],
                            ),
                            InlineFormError(message: _odometerSaveError),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Fuel.
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: Form(
                        key: _fuelFormKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Fuel type.
                            Consumer<AppProvider>(
                              builder: (context, provider, child) {
                                final fuelTypes =
                                    provider.selectedCar?.fuelTypes ??
                                        ['ГАЗ', '95'];
                                if (!fuelTypes.contains(_selectedFuelType) &&
                                    fuelTypes.isNotEmpty) {
                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                    if (mounted) {
                                      setState(() =>
                                          _selectedFuelType = fuelTypes.first);
                                    }
                                  });
                                }
                                return Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: 8.0,
                                  runSpacing: 4.0,
                                  children: fuelTypes.map((type) {
                                    final isSelected =
                                        _selectedFuelType == type;
                                    Color color = Colors.blue;
                                    if (type.toUpperCase() == 'ГАЗ') {
                                      color = Colors.green;
                                    }
                                    if (type == '95') {
                                      color = Colors.orange;
                                    }
                                    if (type.toUpperCase() == 'ДИЗЕЛЬ') {
                                      color = Colors.brown;
                                    }
                                    if (type.toUpperCase() == 'ЕЛЕКТРИКА') {
                                      color = Colors.teal;
                                    }

                                    return OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 10),
                                        side: BorderSide(
                                          width: isSelected ? 2.0 : 1.0,
                                          color:
                                              isSelected ? color : Colors.grey,
                                        ),
                                        foregroundColor:
                                            isSelected ? color : null,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _selectedFuelType = type;
                                        });
                                      },
                                      child: Text(
                                        type,
                                        style: TextStyle(
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal),
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            // Liters and add action.
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _litersController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    autovalidateMode: AutovalidateMode.disabled,
                                    validator: (value) =>
                                        validateNonNegativeDecimal(
                                      value,
                                      requiredMessage: loc.fieldRequired,
                                      invalidMessage: loc.invalidNumber,
                                      nonNegativeMessage:
                                          loc.numberMustBeNonNegative,
                                    ),
                                    onChanged: (value) {
                                      if (value.contains(',')) {
                                        final normalized =
                                            normalizeDecimalInput(value);
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
                                      labelText: loc.liters,
                                      suffixText: loc.litersShort,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: _isSavingFuel
                                      ? null
                                      : () async {
                                          if (!(_fuelFormKey.currentState
                                                  ?.validate() ??
                                              false)) {
                                            return;
                                          }

                                          setState(() {
                                            _isSavingFuel = true;
                                            _fuelSaveError = null;
                                          });
                                          final provider =
                                              Provider.of<AppProvider>(context,
                                                  listen: false);
                                          final messenger =
                                              ScaffoldMessenger.of(context);
                                          final successMessage =
                                              loc.refuelingAdded;
                                          final dateString =
                                              DateFormat('yyyy-MM-dd')
                                                  .format(_selectedDate);
                                          final timeString = DateFormat('HH:mm')
                                              .format(DateTime.now());
                                          final focusScope =
                                              FocusScope.of(context);
                                          final fuelFormState =
                                              _fuelFormKey.currentState;
                                          try {
                                            await provider.addFuelLog(
                                              dateString,
                                              timeString,
                                              _selectedFuelType,
                                              double.parse(
                                                normalizeDecimalInput(
                                                    _litersController.text
                                                        .trim()),
                                              ),
                                            );
                                            if (!mounted) return;
                                            focusScope.unfocus();
                                            fuelFormState?.reset();
                                            _litersController.clear();
                                            setState(() {
                                              _isSavingFuel = false;
                                            });
                                            messenger.showSnackBar(
                                              SnackBar(
                                                  content:
                                                      Text(successMessage)),
                                            );
                                          } catch (e) {
                                            if (!mounted) return;
                                            setState(() {
                                              _isSavingFuel = false;
                                              _fuelSaveError =
                                                  loc.saveError(e.toString());
                                            });
                                          }
                                        },
                                  icon: _isSavingFuel
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        )
                                      : const Icon(Icons.add_circle,
                                          color: Colors.blue),
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
                  ),
                  // Notes
                  Consumer<AppProvider>(
                    builder: (context, provider, child) {
                      final notes = provider.notes;
                      if (notes.isEmpty) return const SizedBox.shrink();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 16),
                          const Divider(thickness: 1),
                          const SizedBox(height: 12),
                          Text(
                            loc.notes,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color: Colors.grey.shade700,
                                  letterSpacing: 0.4,
                                ),
                          ),
                          const SizedBox(height: 8),
                          ...notes.map((note) => _buildNoteCard(context, note)),
                        ],
                      );
                    },
                  ),
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
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                child: const Icon(Icons.edit_note),
              ),
            ),
          ],
        );
      },
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
                    color: Colors.grey,
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
                          style: const TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );

              if (!mounted) return;
              if (confirmed == true) {
                await provider.deleteNote(widget.noteToEdit!);
                if (!mounted) return;
                navigator.pop();
              }
            },
            child:
                Text(loc.deleteNote, style: const TextStyle(color: Colors.red)),
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
                      _saveError = loc.saveError(error.toString());
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

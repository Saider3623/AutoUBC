import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_localizations.dart';
import '../db/database_service.dart';
import '../models/note.dart';

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
  int? _loadedCarId;

  @override
  void initState() {
    super.initState();
    _loadCurrentOdometer();
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
    if (carId != _loadedCarId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadCurrentOdometer();
      });
    }
  }

  Future<void> _loadCurrentOdometer() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final carId = provider.selectedCar?.id;
    if (carId == null) {
      _loadedCarId = null;
      return;
    }
    final dateString = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final log = await _db.getOdometerLog(carId, dateString);
    if (!mounted ||
        Provider.of<AppProvider>(context, listen: false).selectedCar?.id !=
            carId) {
      return;
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
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _odometerController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: loc.odometer,
                                border: const OutlineInputBorder(),
                                suffixText: loc.km,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () async {
                              if (_odometerController.text.isEmpty) return;
                              final odometer =
                                  int.tryParse(_odometerController.text);
                              if (odometer == null) return;
                              final provider = Provider.of<AppProvider>(context,
                                  listen: false);
                              final scaffoldMessenger =
                                  ScaffoldMessenger.of(context);
                              final dateString = DateFormat('yyyy-MM-dd')
                                  .format(_selectedDate);
                              try {
                                await provider.saveOdometerLog(
                                    dateString, odometer);
                                if (mounted) {
                                  scaffoldMessenger.showSnackBar(
                                    SnackBar(
                                        content: Text(loc.saveOdometerSuccess)),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  scaffoldMessenger.showSnackBar(
                                    SnackBar(
                                        content:
                                            Text(loc.saveError(e.toString()))),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.check_circle,
                                color: Colors.green),
                            iconSize: 36,
                            tooltip: loc.save,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Fuel.
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: Column(
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
                                spacing: 8.0,
                                runSpacing: 4.0,
                                children: fuelTypes.map((type) {
                                  final isSelected = _selectedFuelType == type;
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
                                        color: isSelected ? color : Colors.grey,
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
                                child: TextField(
                                  controller: _litersController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  onChanged: (value) {
                                    if (value.contains(',')) {
                                      _litersController.text =
                                          value.replaceAll(',', '.');
                                      _litersController.selection =
                                          TextSelection.fromPosition(
                                        TextPosition(
                                            offset:
                                                _litersController.text.length),
                                      );
                                    }
                                  },
                                  decoration: InputDecoration(
                                    labelText: loc.liters,
                                    border: const OutlineInputBorder(),
                                    suffixText: loc.litersShort,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () async {
                                  if (_litersController.text.isEmpty) return;
                                  final liters = double.tryParse(
                                      _litersController.text
                                          .replaceAll(',', '.'));
                                  if (liters == null) return;
                                  final provider = Provider.of<AppProvider>(
                                      context,
                                      listen: false);
                                  final scaffoldMessenger =
                                      ScaffoldMessenger.of(context);
                                  final dateString = DateFormat('yyyy-MM-dd')
                                      .format(_selectedDate);
                                  final timeString = DateFormat('HH:mm')
                                      .format(DateTime.now());
                                  try {
                                    await provider.addFuelLog(dateString,
                                        timeString, _selectedFuelType, liters);
                                    _litersController.clear();
                                    if (mounted) {
                                      scaffoldMessenger.showSnackBar(
                                        SnackBar(
                                            content: Text(loc.refuelingAdded)),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      scaffoldMessenger.showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                loc.saveError(e.toString()))),
                                      );
                                    }
                                  }
                                },
                                icon: const Icon(Icons.add_circle,
                                    color: Colors.blue),
                                iconSize: 36,
                                tooltip: loc.addRefueling,
                              ),
                            ],
                          ),
                        ],
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
                          ...notes
                              .map((note) => _buildNoteCard(context, note)),
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
        onSave: (note) {
          if (noteToEdit != null) {
            note.id = noteToEdit.id;
            provider.updateNote(note);
          } else {
            provider.addNote(note);
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
  final Function(Note) onSave;
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
  final TextEditingController _descriptionController = TextEditingController();

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
              TextField(
                controller: _descriptionController,
                minLines: 3,
                maxLines: 10,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: loc.noteDescription,
                  alignLabelWithHint: true,
                ),
              ),
            ],
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
          onPressed: () {
            if (_descriptionController.text.isEmpty) return;

            final note = Note()
              ..carId = widget.carId
              ..dateTime = _dateTime
              ..description = _descriptionController.text;

            widget.onSave(note);
            Navigator.pop(context);
          },
          child: Text(loc.save),
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

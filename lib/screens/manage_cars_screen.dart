import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/car.dart';
import '../providers/app_provider.dart';
import '../utils/error_messages.dart';
import '../widgets/work_schedule_card.dart';
import 'backups_screen.dart';
import '../theme/app_theme.dart';

/// Settings: the selected car (name, plate, driver, fuel types, deletion) and
/// app-wide options (working week, backups).
class ManageCarsScreen extends StatefulWidget {
  final bool autoOpenAddCar;

  const ManageCarsScreen({super.key, this.autoOpenAddCar = false});

  @override
  State<ManageCarsScreen> createState() => _ManageCarsScreenState();
}

class _ManageCarsScreenState extends State<ManageCarsScreen> {
  final _nameController = TextEditingController();
  final _plateController = TextEditingController();
  final _driverController = TextEditingController();
  final _newFuelController = TextEditingController();
  List<String> _localFuelTypes = [];

  /// Original fuel type name → its new name, applied to existing refuels.
  final Map<String, String> _renames = {};
  int? _loadedCarId;
  Car? _loadedCar;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentCarData();
    if (widget.autoOpenAddCar) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        if (appProvider.cars.isEmpty) {
          _showAddCarDialog(appProvider, AppLocalizations.of(context)!);
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = Provider.of<AppProvider>(context, listen: false);
    if (provider.selectedCar?.id != _loadedCarId) _loadCurrentCarData();
  }

  void _loadCurrentCarData() {
    final car = Provider.of<AppProvider>(context, listen: false).selectedCar;
    _loadedCarId = car?.id;
    _loadedCar = car;
    _renames.clear();
    _nameController.text = car?.name ?? '';
    _plateController.text = car?.plateNumber ?? '';
    _driverController.text = car?.driverName ?? '';
    _localFuelTypes = List.of(car?.fuelTypes ?? const ['ГАЗ', '95']);
  }

  bool get _isDirty {
    final car = _loadedCar;
    if (car == null) return false;
    final savedTypes = car.fuelTypes ?? const ['ГАЗ', '95'];
    return _nameController.text.trim() != car.name ||
        _plateController.text.trim() != (car.plateNumber ?? '') ||
        _driverController.text.trim() != (car.driverName ?? '') ||
        _localFuelTypes.length != savedTypes.length ||
        !_localFuelTypes.every(savedTypes.contains);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _plateController.dispose();
    _driverController.dispose();
    _newFuelController.dispose();
    super.dispose();
  }

  Future<bool> _confirmDiscard(AppLocalizations loc) async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(loc.discardChangesQuestion),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(loc.discardChanges),
          ),
        ],
      ),
    );
    return discard == true;
  }

  Future<void> _save(AppLocalizations loc) async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final selected = appProvider.selectedCar;
    if (selected == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    if (_nameController.text.trim().isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(loc.errorCarNameEmpty)));
      return;
    }
    if (_localFuelTypes.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(loc.atLeastOneFuelType)));
      return;
    }
    // Save a copy: the car held by the provider changes only when the
    // database write succeeds.
    final car = Car()
      ..id = selected.id
      ..name = _nameController.text.trim()
      ..plateNumber = _plateController.text.trim()
      ..driverName = _driverController.text.trim()
      ..fuelTypes = List.of(_localFuelTypes)
      ..selectedFuelTypesForConsumption =
          selected.selectedFuelTypesForConsumption;
    setState(() => _isSaving = true);
    try {
      await appProvider.updateCarSettings(car, Map.of(_renames));
      if (!mounted) return;
      _loadCurrentCarData();
      navigator.pop();
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(describeError(error, loc))));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final appProvider = Provider.of<AppProvider>(context);
    final selectedCar = appProvider.selectedCar;

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        if (await _confirmDiscard(loc) && mounted) {
          setState(_loadCurrentCarData);
          navigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(loc.carSettings),
          actions: [
            if (selectedCar != null)
              IconButton(
                icon: const Icon(Icons.check),
                onPressed: _isSaving ? null : () => _save(loc),
                tooltip: loc.saveTooltip,
              ),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _SectionTitle(loc.settingsCarSection),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      key: ValueKey(selectedCar?.id),
                      isExpanded: true,
                      initialValue: selectedCar?.id,
                      decoration: InputDecoration(
                        labelText: loc.selectCar,
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        for (final car in appProvider.cars)
                          DropdownMenuItem<int>(
                            value: car.id,
                            child: Text(car.name),
                          ),
                      ],
                      onChanged: (value) async {
                        if (value == null || value == selectedCar?.id) return;
                        if (_isDirty && !await _confirmDiscard(loc)) {
                          // Rebuild so the dropdown shows the kept car again.
                          if (mounted) setState(() {});
                          return;
                        }
                        final car =
                            appProvider.cars.firstWhere((c) => c.id == value);
                        await appProvider.selectCar(car);
                        if (mounted) setState(_loadCurrentCarData);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _showAddCarDialog(appProvider, loc),
                    icon: const Icon(Icons.add_circle, color: AppColors.success),
                    iconSize: 36,
                    tooltip: loc.addCar,
                  ),
                ],
              ),
              if (selectedCar != null) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: loc.carName,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _plateController,
                  textCapitalization: TextCapitalization.characters,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: loc.plateNumber,
                    helperText: loc.printedInReport,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _driverController,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: loc.driverName,
                    helperText: loc.printedInReport,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  loc.fuelTypesForCar(selectedCar.name),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(loc.fuelTypesHint,
                    style: const TextStyle(color: AppColors.muted)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newFuelController,
                        decoration: InputDecoration(
                          labelText: loc.newFuelTypeHint,
                          border: const OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _addFuelType(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: AppColors.primary),
                      iconSize: 36,
                      onPressed: _addFuelType,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                for (final fuelType in _localFuelTypes)
                  Card(
                    child: ListTile(
                      title: Text(fuelType),
                      onTap: () => _renameFuelType(fuelType, loc),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: loc.renameFuelType,
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _renameFuelType(fuelType, loc),
                          ),
                          IconButton(
                            tooltip: loc.delete,
                            icon: const Icon(Icons.delete, color: AppColors.error),
                            onPressed: () {
                              setState(() => _localFuelTypes.remove(fuelType));
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                    onPressed: () => _showDeleteCarDialog(appProvider, loc),
                    icon: const Icon(Icons.delete_outline),
                    label: Text(loc.deleteCar),
                  ),
                ),
              ],
              const SizedBox(height: 28),
              _SectionTitle(loc.settingsAppSection),
              const SizedBox(height: 8),
              const WorkScheduleCard(),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.backup_outlined),
                  title: Text(loc.backupsTitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const BackupsScreen()),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addFuelType() {
    final newFuel = _newFuelController.text.trim();
    if (newFuel.isEmpty) return;
    if (!_localFuelTypes.contains(newFuel)) {
      setState(() => _localFuelTypes.add(newFuel));
    }
    _newFuelController.clear();
  }

  Future<void> _renameFuelType(String current, AppLocalizations loc) async {
    final controller = TextEditingController(text: current);
    final messenger = ScaffoldMessenger.of(context);
    final renamed = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.renameFuelType),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(controller: controller, autofocus: true),
            const SizedBox(height: 8),
            Text(loc.renameFuelTypeHint,
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(loc.save),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || renamed == null || renamed.isEmpty || renamed == current) {
      return;
    }
    if (_localFuelTypes.contains(renamed)) {
      messenger.showSnackBar(
          SnackBar(content: Text(loc.fuelTypeExists(renamed))));
      return;
    }
    setState(() {
      final index = _localFuelTypes.indexOf(current);
      _localFuelTypes[index] = renamed;
      // Follow a chain of renames back to the name stored in the refuels.
      final original = _renames.entries
          .firstWhere((entry) => entry.value == current,
              orElse: () => MapEntry(current, current))
          .key;
      _renames[original] = renamed;
    });
  }

  Future<void> _showAddCarDialog(
      AppProvider appProvider, AppLocalizations loc) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.addCar),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: loc.enterCarName),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(loc.add),
          ),
        ],
      ),
    );
    controller.dispose();

    if (name == null || name.isEmpty || !mounted) return;
    try {
      await appProvider.addCar(name);
      if (!mounted) return;
      setState(_loadCurrentCarData);
      scaffoldMessenger.showSnackBar(SnackBar(content: Text(loc.carAdded)));
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(describeError(e, loc))),
      );
    }
  }

  /// Deleting a car removes its whole history, so the dialog lists what goes
  /// and asks for the car name to be typed.
  Future<void> _showDeleteCarDialog(
      AppProvider appProvider, AppLocalizations loc) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final car = appProvider.selectedCar!;
    final counts = await appProvider.countCarRecords(car.id);
    if (!mounted) return;
    final controller = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final matches = controller.text.trim() == car.name;
          return AlertDialog(
            title: Text(loc.deleteCar),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(loc.deleteCarWillRemove(car.name)),
                  const SizedBox(height: 8),
                  Text('• ${loc.cloudRowOdometer}: ${counts.odometer}'),
                  Text('• ${loc.cloudRowFuel}: ${counts.fuel}'),
                  Text('• ${loc.reminders}: ${counts.reminders}'),
                  Text('• ${loc.serviceBook}: ${counts.service}'),
                  Text('• ${loc.notes}: ${counts.notes}'),
                  const SizedBox(height: 12),
                  Text(loc.deleteCarTypeName),
                  const SizedBox(height: 6),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    onChanged: (_) => setDialogState(() {}),
                    decoration: InputDecoration(hintText: car.name),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(loc.cancel),
              ),
              TextButton(
                onPressed: matches ? () => Navigator.pop(context, true) : null,
                child: Text(
                  loc.delete,
                  style: TextStyle(color: matches ? AppColors.error : null),
                ),
              ),
            ],
          );
        },
      ),
    );
    controller.dispose();

    if (confirmed != true || !mounted) return;
    try {
      await appProvider.deleteCar(car);
      if (mounted) setState(_loadCurrentCarData);
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(describeError(e, loc))),
      );
    }
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.primary,
          ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/service_log.dart';
import '../providers/app_provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_localizations.dart';
import '../utils/error_messages.dart';
import '../utils/form_validators.dart';
import '../utils/validation.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/inline_form_error.dart';
import '../theme/app_theme.dart';

class ServiceBookScreen extends StatefulWidget {
  const ServiceBookScreen({super.key});

  @override
  State<ServiceBookScreen> createState() => _ServiceBookScreenState();
}

class _ServiceBookScreenState extends State<ServiceBookScreen> {
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final loc = AppLocalizations.of(context)!;
    final languageCode = localeProvider.locale?.languageCode ?? 'uk';

    return Scaffold(
      appBar: AppBar(
        leading: _isSearching
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _isSearching = false;
                    _searchQuery = '';
                    _searchController.clear();
                  });
                },
              )
            : null,
        title: _isSearching
            ? Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: loc.search,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon:
                                const Icon(Icons.clear, color: Colors.black54),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                                _searchController.clear();
                              });
                            },
                          )
                        : null,
                  ),
                  style: const TextStyle(color: Colors.black87),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              )
            : Text(loc.serviceBook),
        actions: [
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddServiceDialog(context),
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          if (provider.selectedCar == null) {
            return AppEmptyState(
              icon: Icons.directions_car_outlined,
              title: loc.selectACar,
            );
          }

          final logs = _searchQuery.isEmpty
              ? provider.serviceLogs
              : provider.serviceLogs
                  .where((log) => log.description
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase()))
                  .toList();

          if (logs.isEmpty) {
            return AppEmptyState(
              icon: Icons.build_outlined,
              title: loc.noServiceLogs,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              return InkWell(
                onTap: () => _showAddServiceDialog(context, log),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat.yMMMd(languageCode).format(log.date),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  '${log.odometer} ${loc.km}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: AppColors.muted,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  tooltip: loc.delete,
                                  icon: const Icon(Icons.delete_outline,
                                      color: AppColors.error, size: 20),
                                  onPressed: () => _confirmDelete(context, log),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Divider(height: 8),
                        Text(
                          log.description,
                          style: const TextStyle(fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddServiceDialog(BuildContext context, [ServiceLog? logToEdit]) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    if (provider.selectedCar == null) return;

    showDialog(
      context: context,
      builder: (context) => ServiceLogDialog(
        carId: provider.selectedCar!.id,
        logToEdit: logToEdit,
        onSave: (log) async {
          if (logToEdit != null) {
            await provider.updateServiceLog(log);
          } else {
            await provider.addServiceLog(log);
          }
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, ServiceLog log) async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.confirmDelete),
        content: Text(loc.deleteServiceLogConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(loc.delete, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final messenger = ScaffoldMessenger.of(context);
      try {
        await Provider.of<AppProvider>(context, listen: false)
            .deleteServiceLog(log);
      } catch (error) {
        messenger.showSnackBar(
          SnackBar(content: Text(describeError(error, loc))),
        );
      }
    }
  }
}

/// Adds or edits a service book entry. [initialDescription] prefills a new
/// entry, for example after a maintenance reminder was completed.
class ServiceLogDialog extends StatefulWidget {
  final int carId;
  final Future<void> Function(ServiceLog) onSave;
  final ServiceLog? logToEdit;
  final String? initialDescription;

  const ServiceLogDialog({
    super.key,
    required this.carId,
    required this.onSave,
    this.logToEdit,
    this.initialDescription,
  });

  @override
  State<ServiceLogDialog> createState() => _ServiceLogDialogState();
}

class _ServiceLogDialogState extends State<ServiceLogDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  String? _saveError;
  DateTime _date = DateTime.now();
  final TextEditingController _odometerController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.logToEdit != null) {
      _date = widget.logToEdit!.date;
      _odometerController.text = widget.logToEdit!.odometer.toString();
      _descController.text = widget.logToEdit!.description;
    } else {
      final provider = Provider.of<AppProvider>(context, listen: false);
      int maxKm = 0;
      if (provider.odometerLogs.isNotEmpty) {
        maxKm = provider.odometerLogs
            .map((e) => e.odometer)
            .reduce((a, b) => a > b ? a : b);
      }
      if (provider.serviceLogs.isNotEmpty) {
        int sMax = provider.serviceLogs
            .map((e) => e.odometer)
            .reduce((a, b) => a > b ? a : b);
        if (sMax > maxKm) maxKm = sMax;
      }
      if (provider.reminders.isNotEmpty) {
        int rMax = provider.reminders
            .map((e) => e.startKm ?? 0)
            .reduce((a, b) => a > b ? a : b);
        if (rMax > maxKm) maxKm = rMax;
      }
      _odometerController.text = maxKm > 0 ? maxKm.toString() : '';
      final initial = widget.initialDescription;
      _descController.text = initial == null ? '- ' : '- $initial\n- ';
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
          widget.logToEdit != null ? loc.editServiceLog : loc.addServiceLog),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
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
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.date,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat.yMMMd(languageCode).format(_date),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                      locale: localeProvider.locale,
                    );
                    if (picked != null) {
                      setState(() {
                        _date = picked;
                      });
                    }
                  },
                ),
                TextFormField(
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
                    labelText: loc.mileageKm,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descController,
                  minLines: 2,
                  maxLines: 6,
                  textCapitalization: TextCapitalization.sentences,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  // A description made only of list markers ("- ") is empty.
                  validator: (value) => validateRequiredText(
                    meaningfulText(value ?? ''),
                    message: loc.fieldRequired,
                  ),
                  decoration: InputDecoration(
                    labelText: loc.whatWasDone,
                    helperText: loc.whatWasDoneHint,
                    alignLabelWithHint: true,
                  ),
                  onChanged: (value) {
                    // Start every new line with a dash after Enter.
                    if (value.endsWith('\n')) {
                      _descController.text = '$value- ';
                      _descController.selection = TextSelection.fromPosition(
                        TextPosition(offset: _descController.text.length),
                      );
                    }
                  },
                ),
                InlineFormError(message: _saveError),
              ],
            ),
          ),
        ),
      ),
      actions: [
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

                  // Build a new object: the edited entry stays untouched in
                  // the provider until the save succeeds.
                  final log = ServiceLog()
                    ..carId = widget.carId
                    ..date = _date
                    ..odometer = int.parse(_odometerController.text.trim())
                    ..description = _descController.text.trim();
                  final editedId = widget.logToEdit?.id;
                  if (editedId != null) log.id = editedId;

                  setState(() {
                    _isSaving = true;
                    _saveError = null;
                  });
                  final navigator = Navigator.of(context);
                  try {
                    await widget.onSave(log);
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
    _odometerController.dispose();
    _descController.dispose();
    super.dispose();
  }
}

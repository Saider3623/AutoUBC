import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/service_log.dart';
import '../providers/app_provider.dart';
import '../providers/locale_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
            return Center(child: Text(loc.selectACar));
          }

          final logs = _searchQuery.isEmpty
              ? provider.serviceLogs
              : provider.serviceLogs
                  .where((log) => log.description
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase()))
                  .toList();

          if (logs.isEmpty) {
            return Center(
              child: Text(loc.noServiceLogs),
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
                  margin: const EdgeInsets.only(bottom: 8),
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
                                  style: const TextStyle(
                                      color: Colors.grey,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red, size: 20),
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
      builder: (context) => _ServiceLogDialog(
        carId: provider.selectedCar!.id,
        logToEdit: logToEdit,
        onSave: (log) {
          provider.addServiceLog(log);
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
            child: Text(loc.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await Provider.of<AppProvider>(context, listen: false)
          .deleteServiceLog(log);
    }
  }
}

class _ServiceLogDialog extends StatefulWidget {
  final int carId;
  final Function(ServiceLog) onSave;
  final ServiceLog? logToEdit;

  const _ServiceLogDialog({
    required this.carId,
    required this.onSave,
    this.logToEdit,
  });

  @override
  State<_ServiceLogDialog> createState() => _ServiceLogDialogState();
}

class _ServiceLogDialogState extends State<_ServiceLogDialog> {
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
      _descController.text = '- ';
    }
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final loc = AppLocalizations.of(context)!;
    final languageCode = localeProvider.locale?.languageCode ?? 'uk';

    return AlertDialog(
      title: Text(
          widget.logToEdit != null ? loc.editServiceLog : loc.addServiceLog),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(DateFormat.yMMMd(languageCode).format(_date)),
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
            TextField(
              controller: _odometerController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: loc.mileageKm,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              minLines: 2,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: loc.whatWasDone,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) {
                // Якщо користувач натиснув Enter, автоматично додаємо тире
                if (value.endsWith('\n')) {
                  _descController.text = '$value- ';
                  _descController.selection = TextSelection.fromPosition(
                    TextPosition(offset: _descController.text.length),
                  );
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(loc.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            if (_odometerController.text.isEmpty ||
                _descController.text.isEmpty) return;
            final odometer = int.tryParse(_odometerController.text);
            if (odometer == null) return;

            final log = widget.logToEdit ?? ServiceLog();
            log.carId = widget.carId;
            log.date = _date;
            log.odometer = odometer;
            log.description = _descController.text;

            widget.onSave(log);
            Navigator.pop(context);
          },
          child: Text(loc.save),
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

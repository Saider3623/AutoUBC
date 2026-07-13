import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/locale_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/odometer_log.dart';
import '../models/fuel_log.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DateTime _selectedMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final languageCode = localeProvider.locale?.languageCode ?? 'uk';
    
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        if (provider.selectedCar == null) {
          return Center(child: Text(loc.selectCarGeneric));
        }

        // Об'єднуємо та сортуємо всі записи за датою
        final allLogs = <dynamic>[];
        for (final log in provider.odometerLogs) {
          allLogs.add(log);
        }
        for (final log in provider.fuelLogs) {
          allLogs.add(log);
        }
        allLogs.sort((a, b) {
          final dateA = a is OdometerLog ? a.dateString : (a as FuelLog).dateString;
          final dateB = b is OdometerLog ? b.dateString : (b as FuelLog).dateString;
          return dateB.compareTo(dateA);
        });

        // Фільтруємо за вибраним місяцем
        final filteredLogs = allLogs.where((log) {
          final dateString = log is OdometerLog ? log.dateString : (log as FuelLog).dateString;
          final logDate = DateTime.parse(dateString);
          return logDate.year == _selectedMonth.year && logDate.month == _selectedMonth.month;
        }).toList();

        // Групуємо за датою
        final groupedLogs = <String, List<dynamic>>{};
        for (final log in filteredLogs) {
          final date = log is OdometerLog ? log.dateString : (log as FuelLog).dateString;
          if (!groupedLogs.containsKey(date)) {
            groupedLogs[date] = [];
          }
          groupedLogs[date]!.add(log);
        }

        return Column(
          children: [
            // Вибір місяця
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      setState(() {
                        _selectedMonth = DateTime(
                            _selectedMonth.year, _selectedMonth.month - 1);
                      });
                    },
                  ),
                  Text(
                    DateFormat.yMMMM(languageCode).format(_selectedMonth),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () {
                      setState(() {
                        _selectedMonth = DateTime(
                            _selectedMonth.year, _selectedMonth.month + 1);
                      });
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: groupedLogs.isEmpty
                  ? Center(child: Text(loc.noRecords))
                  : ListView.builder(
                      itemCount: groupedLogs.keys.length,
                      itemBuilder: (context, index) {
                        final date = groupedLogs.keys.elementAt(index);
                        final logs = groupedLogs[date]!;
                        final dateTime = DateTime.parse(date);
                        final formattedDate = DateFormat.yMMMd(languageCode).format(dateTime);

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  formattedDate,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                ...logs.map((log) {
                                  if (log is OdometerLog) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.speed, size: 16, color: Colors.grey),
                                          const SizedBox(width: 6),
                                          Text('${loc.odometerLabel}: ${log.odometer} ${loc.kilometers}'),
                                          const Spacer(),
                                          InkWell(
                                            onTap: () => _confirmDeleteOdometer(log),
                                            borderRadius: BorderRadius.circular(16),
                                            child: const Padding(
                                              padding: EdgeInsets.all(4),
                                              child: Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  } else if (log is FuelLog) {
                                    final color = log.fuelType == '95' ? Colors.orange : Colors.green;
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2),
                                      child: Row(
                                        children: [
                                          Icon(Icons.local_gas_station, size: 16, color: color),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${log.fuelType}: ${log.liters} ${loc.litersShort}',
                                            style: TextStyle(color: color),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            log.timeString,
                                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                                          ),
                                          const Spacer(),
                                          InkWell(
                                            onTap: () => _confirmDeleteFuel(log),
                                            borderRadius: BorderRadius.circular(16),
                                            child: const Padding(
                                              padding: EdgeInsets.all(4),
                                              child: Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                }),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDeleteOdometer(OdometerLog log) async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.confirmDelete),
        content: Text(loc.deleteOdometerLogConfirmation),
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

    if (confirmed == true && mounted) {
      await Provider.of<AppProvider>(context, listen: false).deleteOdometerLog(log);
    }
  }

  Future<void> _confirmDeleteFuel(FuelLog log) async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.confirmDelete),
        content: Text(loc.deleteFuelLogConfirmation),
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

    if (confirmed == true && mounted) {
      await Provider.of<AppProvider>(context, listen: false).deleteFuelLog(log);
    }
  }
}

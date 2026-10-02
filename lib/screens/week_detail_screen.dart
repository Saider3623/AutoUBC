import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_localizations.dart';
import '../models/odometer_log.dart';
import '../models/fuel_log.dart';
import '../widgets/app_empty_state.dart';

class WeekDetailScreen extends StatefulWidget {
  final DateTime weekStart;
  final DateTime weekEnd;

  const WeekDetailScreen({
    super.key,
    required this.weekStart,
    required this.weekEnd,
  });

  @override
  State<WeekDetailScreen> createState() => _WeekDetailScreenState();
}

class _WeekDetailScreenState extends State<WeekDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final languageCode = localeProvider.locale?.languageCode ?? 'uk';

    final titleRange =
        '${DateFormat.d(languageCode).format(widget.weekStart)} - ${DateFormat.d(languageCode).format(widget.weekEnd)} ${DateFormat.MMMM(languageCode).format(widget.weekStart)}';

    return Scaffold(
      appBar: AppBar(
        title: Text('Деталізація: $titleRange'),
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          if (provider.selectedCar == null) {
            return AppEmptyState(
              icon: Icons.directions_car_outlined,
              title: loc.selectCarGeneric,
            );
          }

          final allLogs = <dynamic>[];
          for (final log in provider.odometerLogs) {
            allLogs.add(log);
          }
          for (final log in provider.fuelLogs) {
            allLogs.add(log);
          }
          allLogs.sort((a, b) {
            final dateA =
                a is OdometerLog ? a.dateString : (a as FuelLog).dateString;
            final dateB =
                b is OdometerLog ? b.dateString : (b as FuelLog).dateString;
            return dateB.compareTo(dateA);
          });

          final filteredLogs = allLogs.where((log) {
            final dateString =
                log is OdometerLog ? log.dateString : (log as FuelLog).dateString;
            final logDate = DateTime.parse(dateString);
            final startDate = DateTime(
                widget.weekStart.year, widget.weekStart.month, widget.weekStart.day);
            final endDate = DateTime(
                widget.weekEnd.year, widget.weekEnd.month, widget.weekEnd.day, 23, 59, 59);
            return !logDate.isBefore(startDate) && !logDate.isAfter(endDate);
          }).toList();

          final groupedLogs = <String, List<dynamic>>{};
          for (final log in filteredLogs) {
            final date =
                log is OdometerLog ? log.dateString : (log as FuelLog).dateString;
            if (!groupedLogs.containsKey(date)) {
              groupedLogs[date] = [];
            }
            groupedLogs[date]!.add(log);
          }

          return groupedLogs.isEmpty
              ? Center(
                  child: AppEmptyState(
                    icon: Icons.history,
                    title: loc.noRecords,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: groupedLogs.keys.length,
                  itemBuilder: (context, index) {
                    final date = groupedLogs.keys.elementAt(index);
                    final logs = groupedLogs[date]!;
                    final dateTime = DateTime.parse(date);
                    final formattedDate =
                        DateFormat.yMMMd(languageCode).format(dateTime);

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formattedDate,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            ...logs.map((log) {
                              if (log is OdometerLog) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 4),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.speed,
                                          size: 18, color: Colors.grey),
                                      const SizedBox(width: 8),
                                      Text(
                                          '${loc.odometerLabel}: ${log.odometer} ${loc.kilometers}'),
                                      const Spacer(),
                                      IconButton(
                                        tooltip: loc.delete,
                                        icon: const Icon(Icons.delete_outline,
                                            size: 22, color: Colors.red),
                                        onPressed: () =>
                                            _confirmDeleteOdometer(log),
                                      ),
                                    ],
                                  ),
                                );
                              } else if (log is FuelLog) {
                                final color = log.fuelType == '95'
                                    ? Colors.orange
                                    : Colors.green;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 4),
                                  child: Row(
                                    children: [
                                      Icon(Icons.local_gas_station,
                                          size: 18, color: color),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${log.fuelType}: ${log.liters} ${loc.litersShort}',
                                        style: TextStyle(color: color),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        log.timeString,
                                        style: const TextStyle(
                                            fontSize: 12, color: Colors.grey),
                                      ),
                                      const Spacer(),
                                      IconButton(
                                        tooltip: loc.delete,
                                        icon: const Icon(Icons.delete_outline,
                                            size: 22, color: Colors.red),
                                        onPressed: () =>
                                            _confirmDeleteFuel(log),
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
                );
        },
      ),
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
      await Provider.of<AppProvider>(context, listen: false)
          .deleteOdometerLog(log);
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

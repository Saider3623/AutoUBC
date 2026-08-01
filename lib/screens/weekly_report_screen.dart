import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/app_provider.dart';
import '../providers/locale_provider.dart';
import '../db/database_service.dart';

class WeeklyReportScreen extends StatefulWidget {
  const WeeklyReportScreen({super.key});

  @override
  State<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends State<WeeklyReportScreen> {
  DateTime _selectedMonth = DateTime.now();
  final DatabaseService _db = DatabaseService();

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

        // Get all weeks in the selected month
        final weeks = _getWeeksInMonth(_selectedMonth);
        final today = DateTime.now();

        return Column(
          children: [
            // Month selector
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
              child: ListView.builder(
                itemCount: weeks.length,
                itemBuilder: (context, index) {
                  final week = weeks[index];
                  final isFutureWeek = week['start']!.isAfter(today);

                  if (isFutureWeek) {
                    // Отображаем будущие недели в сером и полупрозрачном виде
                    return Opacity(
                      opacity: 0.5,
                      child: Card(
                        elevation: 0,
                        color: Colors.grey[100],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${DateFormat.d(languageCode).format(week['start']!)} - ${DateFormat.d(languageCode).format(week['end']!)} ${DateFormat.MMMM(languageCode).format(week['start']!)}',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey),
                              ),
                              const SizedBox(height: 10),
                              const Divider(
                                  height: 1,
                                  thickness: 0.5,
                                  color: Colors.grey),
                              const SizedBox(height: 10),
                              Text(
                                loc.noRefuels,
                                style: const TextStyle(
                                    fontSize: 13, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  // Для прошедших и текущих недель показываем обычную карточку
                  return FutureBuilder<WeeklyReportData>(
                    future: _calculateWeeklyReport(
                      provider.selectedCar!.id,
                      week['start']!,
                      week['end']!,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: ListTile(
                            title: Text(loc.loading),
                          ),
                        );
                      }

                      final data = snapshot.data!;
                      return Card(
                        elevation: 1.5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${DateFormat.d(languageCode).format(week['start']!)} - ${DateFormat.d(languageCode).format(week['end']!)} ${DateFormat.MMMM(languageCode).format(week['start']!)}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      loc.weeklyReportDistance(data.distance),
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              const Divider(height: 1, thickness: 0.5),
                              const SizedBox(height: 10),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          loc.odometerSection,
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${loc.startLabel}: ${data.odometerStart != null ? "${data.odometerStart} ${loc.kilometers}" : "-"}',
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                        Text(
                                          '${loc.endLabel}: ${data.odometerEnd != null ? "${data.odometerEnd} ${loc.kilometers}" : "-"}',
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          loc.fuelSection,
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 4),
                                        if (data.liters95 == 0 &&
                                            data.litersGas == 0)
                                          Text(
                                            loc.noRefuels,
                                            style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey),
                                          ),
                                        if (data.liters95 > 0) ...[
                                          Row(
                                            children: [
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: const BoxDecoration(
                                                  color: Colors.orange,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  '95: ${((data.liters95 * 100).round() / 100)} ${loc.litersShort}',
                                                  style: const TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.orange,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                        if (data.litersGas > 0) ...[
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: const BoxDecoration(
                                                  color: Colors.green,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  'ГАЗ: ${((data.litersGas * 100).round() / 100)} ${loc.litersShort}',
                                                  style: const TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.green,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  List<Map<String, DateTime>> _getWeeksInMonth(DateTime month) {
    final weeks = <Map<String, DateTime>>[];
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);

    DateTime currentStart = firstDayOfMonth;
    while (currentStart.isBefore(lastDayOfMonth) ||
        currentStart.isAtSameMomentAs(lastDayOfMonth)) {
      final daysToSunday = 7 - currentStart.weekday;
      DateTime currentEnd = currentStart.add(Duration(days: daysToSunday));

      if (currentEnd.isAfter(lastDayOfMonth)) {
        currentEnd = lastDayOfMonth;
      }

      weeks.add({'start': currentStart, 'end': currentEnd});
      currentStart = currentEnd.add(const Duration(days: 1));
    }

    return weeks;
  }

  Future<WeeklyReportData> _calculateWeeklyReport(
    int carId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final startString = DateFormat('yyyy-MM-dd').format(startDate);
    final endString = DateFormat('yyyy-MM-dd').format(endDate);

    final odometerLogs =
        await _db.getOdometerLogsInRange(carId, startString, endString);
    final fuelLogs =
        await _db.getFuelLogsInRange(carId, startString, endString);

    // Получаем последнюю запись до начала недели
    final previousWeekLog =
        await _db.getLastOdometerLogBeforeDate(carId, startString);

    int? odometerStart;
    int? odometerEnd;
    int distance = 0;

    if (odometerLogs.isNotEmpty) {
      odometerLogs.sort((a, b) => a.dateString.compareTo(b.dateString));
      // Если есть запись из предыдущей недели - берем её, иначе первую запись текущей недели
      odometerStart = previousWeekLog?.odometer ?? odometerLogs.first.odometer;
      odometerEnd = odometerLogs.last.odometer;
      distance = odometerEnd - odometerStart;
      if (distance < 0) distance = 0;
    } else if (previousWeekLog != null) {
      // Если нет записей за текущую неделю, но есть из предыдущей - используем её для начала
      odometerStart = previousWeekLog.odometer;
      odometerEnd = previousWeekLog.odometer;
      distance = 0;
    }

    double liters95 = 0;
    double litersGas = 0;
    for (final log in fuelLogs) {
      if (log.fuelType == '95') {
        liters95 += log.liters;
      } else {
        litersGas += log.liters;
      }
    }

    double? consumption95;
    double? consumptionGas;
    if (distance > 0) {
      if (liters95 > 0) {
        consumption95 = (liters95 / distance) * 100;
      }
      if (litersGas > 0) {
        consumptionGas = (litersGas / distance) * 100;
      }
    }

    return WeeklyReportData(
      distance: distance,
      liters95: liters95,
      litersGas: litersGas,
      consumption95: consumption95,
      consumptionGas: consumptionGas,
      odometerStart: odometerStart,
      odometerEnd: odometerEnd,
    );
  }
}

class WeeklyReportData {
  final int distance;
  final double liters95;
  final double litersGas;
  final double? consumption95;
  final double? consumptionGas;
  final int? odometerStart;
  final int? odometerEnd;

  WeeklyReportData({
    required this.distance,
    required this.liters95,
    required this.litersGas,
    this.consumption95,
    this.consumptionGas,
    this.odometerStart,
    this.odometerEnd,
  });
}

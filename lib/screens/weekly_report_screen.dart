import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_provider.dart';
import '../providers/locale_provider.dart';
import '../db/database_service.dart';
import '../utils/report_status.dart';
import '../utils/weekly_report_utils.dart';

class WeeklyReportScreen extends StatefulWidget {
  const WeeklyReportScreen({super.key});

  @override
  State<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends State<WeeklyReportScreen> {
  static const _noMileageBackground = Color(0xFFFFFBF2);
  static const _noMileageForeground = Color(0xFF8D6E63);
  static const _secondaryTextColor = Color(0xFF607D8B);
  static const _dividerColor = Color(0xFFD8DEE5);

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

        final today = DateTime.now();
        final weeks = prioritizeCurrentReportWeek(
          _getWeeksInMonth(_selectedMonth),
          today,
        );

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
                  final isCurrentWeek = isDateInReportWeek(week, today);
                  final isFutureWeek = week['start']!.isAfter(today);

                  if (isFutureWeek) {
                    return _buildFutureWeekCard(
                      week,
                      languageCode: languageCode,
                      noRefuelsLabel: loc.noRefuels,
                    );
                  }

                  // Show a regular card for past and current weeks.
                  return FutureBuilder<WeeklyReportData>(
                    future: _calculateWeeklyReport(
                      provider.selectedCar!.id,
                      week['start']!,
                      week['end']!,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _buildLoadingWeekCard(
                          loc.loading,
                          isCurrentWeek: isCurrentWeek,
                          colorScheme: Theme.of(context).colorScheme,
                        );
                      }

                      final data = snapshot.data!;
                      final status = classifyWeeklyReportStatus(data.distance);
                      final isNoMileage = status.isNoMileage;
                      return _buildWeeklyReportCard(
                        context,
                        week,
                        data,
                        languageCode: languageCode,
                        loc: loc,
                        isNoMileage: isNoMileage,
                        isCurrentWeek: isCurrentWeek,
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

  Widget _buildLoadingWeekCard(
    String loadingLabel, {
    required bool isCurrentWeek,
    required ColorScheme colorScheme,
  }) {
    return Card(
      elevation: isCurrentWeek ? 4 : 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: isCurrentWeek
            ? BorderSide(color: colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(title: Text(loadingLabel)),
    );
  }

  Widget _buildWeeklyReportCard(
    BuildContext context,
    Map<String, DateTime> week,
    WeeklyReportData data, {
    required String languageCode,
    required AppLocalizations loc,
    required bool isNoMileage,
    required bool isCurrentWeek,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final weekTitle =
        '${DateFormat.d(languageCode).format(week['start']!)} - ${DateFormat.d(languageCode).format(week['end']!)} ${DateFormat.MMMM(languageCode).format(week['start']!)}';

    return Card(
      elevation: isCurrentWeek ? 4 : (isNoMileage ? 0 : 1.5),
      color: isNoMileage ? _noMileageBackground : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: isCurrentWeek
            ? BorderSide(color: colorScheme.primary, width: 2)
            : isNoMileage
                ? BorderSide(
                    color: _noMileageForeground.withValues(alpha: 0.08))
                : BorderSide.none,
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWeekHeader(
              weekTitle,
              isNoMileage
                  ? loc.weeklyReportNoMileage
                  : loc.weeklyReportDistance(data.distance),
              isNoMileage: isNoMileage,
              colorScheme: colorScheme,
              statusLabel: isNoMileage
                  ? loc.weeklyReportNoActivity
                  : loc.weeklyReportDistance(data.distance),
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, thickness: 1, color: _dividerColor),
            const SizedBox(height: 16),
            if (isNoMileage)
              _buildNoMileagePanel(loc)
            else
              _buildReportGrid(data, loc, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildFutureWeekCard(
    Map<String, DateTime> week, {
    required String languageCode,
    required String noRefuelsLabel,
  }) {
    final weekTitle =
        '${DateFormat.d(languageCode).format(week['start']!)} - ${DateFormat.d(languageCode).format(week['end']!)} ${DateFormat.MMMM(languageCode).format(week['start']!)}';
    const futureTextColor = Color(0xFF667685);
    const futureBorderColor = Color(0xFFDCE3EA);

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: futureBorderColor),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              weekTitle,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: futureTextColor,
              ),
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, thickness: 1, color: _dividerColor),
            const SizedBox(height: 14),
            Text(
              noRefuelsLabel,
              style: const TextStyle(
                fontSize: 13,
                color: futureTextColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekHeader(
    String title,
    String badgeText, {
    required bool isNoMileage,
    required ColorScheme colorScheme,
    required String statusLabel,
  }) {
    final badgeBackground = isNoMileage
        ? _noMileageForeground.withValues(alpha: 0.12)
        : const Color(0xFFEAF4FF);
    final badgeForeground =
        isNoMileage ? _noMileageForeground : colorScheme.primary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              height: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Semantics(
          label: statusLabel,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 176),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: badgeBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              badgeText,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: badgeForeground,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                height: 1.1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoMileagePanel(AppLocalizations loc) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: _noMileageForeground.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.route_outlined,
            size: 19,
            color: _noMileageForeground,
            semanticLabel: loc.weeklyReportNoMileage,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              loc.weeklyReportNoActivity,
              style: const TextStyle(
                fontSize: 13,
                height: 1.35,
                color: _noMileageForeground,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportGrid(
    WeeklyReportData data,
    AppLocalizations loc,
    ColorScheme colorScheme,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildOdometerColumn(data, loc),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: _buildFuelColumn(data, loc, colorScheme),
        ),
      ],
    );
  }

  Widget _buildOdometerColumn(WeeklyReportData data, AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(loc.odometerSection),
        const SizedBox(height: 10),
        _buildMetricRow(
          loc.startLabel,
          data.odometerStart != null
              ? '${data.odometerStart} ${loc.kilometers}'
              : '-',
        ),
        const SizedBox(height: 8),
        _buildMetricRow(
          loc.endLabel,
          data.odometerEnd != null
              ? '${data.odometerEnd} ${loc.kilometers}'
              : '-',
        ),
      ],
    );
  }

  Widget _buildFuelColumn(
    WeeklyReportData data,
    AppLocalizations loc,
    ColorScheme colorScheme,
  ) {
    final hasFuel = data.liters95 > 0 || data.litersGas > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(loc.fuelSection),
        const SizedBox(height: 10),
        if (!hasFuel)
          Text(
            loc.noRefuels,
            style: const TextStyle(
              fontSize: 13,
              height: 1.35,
              color: _secondaryTextColor,
            ),
          )
        else ...[
          if (data.liters95 > 0)
            _buildFuelAmountRow(
              '95',
              data.liters95,
              Colors.orange,
              loc.litersShort,
            ),
          if (data.litersGas > 0) ...[
            if (data.liters95 > 0) const SizedBox(height: 8),
            _buildFuelAmountRow(
              'ГАЗ',
              data.litersGas,
              Colors.green,
              loc.litersShort,
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        height: 1.2,
        letterSpacing: 0.2,
        color: _secondaryTextColor,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        SizedBox(
          width: 66,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontSize: 13,
              height: 1.25,
              color: Color(0xFF42464D),
            ),
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              height: 1.25,
              color: Color(0xFF202124),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFuelAmountRow(
    String fuelType,
    double liters,
    Color color,
    String unit,
  ) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            fuelType,
            style: TextStyle(
              fontSize: 13,
              height: 1.25,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          '${_formatLiters(liters)} $unit',
          textAlign: TextAlign.end,
          style: TextStyle(
            fontSize: 13,
            height: 1.25,
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  String _formatLiters(double liters) {
    if (liters % 1 == 0) return liters.toInt().toString();
    return liters.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
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

    // Get the latest odometer entry before the week.
    final previousWeekLog =
        await _db.getLastOdometerLogBeforeDate(carId, startString);

    int? odometerStart;
    int? odometerEnd;
    int distance = 0;

    if (odometerLogs.isNotEmpty) {
      odometerLogs.sort((a, b) => a.dateString.compareTo(b.dateString));
      // Use the previous reading when available; otherwise use the first reading in the current week.
      odometerStart = previousWeekLog?.odometer ?? odometerLogs.first.odometer;
      odometerEnd = odometerLogs.last.odometer;
      distance = odometerEnd - odometerStart;
      if (distance < 0) distance = 0;
    } else if (previousWeekLog != null) {
      // If the current week has no entries, reuse the previous reading as the start.
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

    return WeeklyReportData(
      distance: distance,
      liters95: liters95,
      litersGas: litersGas,
      odometerStart: odometerStart,
      odometerEnd: odometerEnd,
    );
  }
}

class WeeklyReportData {
  final int distance;
  final double liters95;
  final double litersGas;
  final int? odometerStart;
  final int? odometerEnd;

  WeeklyReportData({
    required this.distance,
    required this.liters95,
    required this.litersGas,
    this.odometerStart,
    this.odometerEnd,
  });
}

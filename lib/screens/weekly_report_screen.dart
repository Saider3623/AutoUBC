import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/settings_provider.dart';
import '../db/database_service.dart';
import '../utils/report_status.dart';
import '../utils/weekly_report_utils.dart';
import '../utils/fuel_summary.dart';
import '../widgets/app_empty_state.dart';
import 'week_detail_screen.dart';

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

  Future<void> _onWeekTap(Map<String, DateTime> week) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WeekDetailScreen(
          weekStart: week['start']!,
          weekEnd: week['end']!,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  bool _weekHasLogsCached(AppProvider provider, Map<String, DateTime> week) {
    final start = week['start']!;
    final end = week['end']!;
    final startDate = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day, 23, 59, 59);

    bool inRange(String dateString) {
      final d = DateTime.parse(dateString);
      return !d.isBefore(startDate) && !d.isAfter(endDate);
    }

    for (final log in provider.odometerLogs) {
      if (inRange(log.dateString)) return true;
    }
    for (final log in provider.fuelLogs) {
      if (inRange(log.dateString)) return true;
    }
    return false;
  }

  Widget _wrapClickable(
    Widget card,
    Map<String, DateTime> week, {
    required BorderRadius borderRadius,
    bool enabled = true,
  }) {
    if (!enabled) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: () => _onWeekTap(week),
        child: card,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final languageCode = localeProvider.locale?.languageCode ?? 'uk';
    final workWeekDays = Provider.of<SettingsProvider>(context).workWeekDays;

    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        if (provider.selectedCar == null) {
          return AppEmptyState(
            icon: Icons.directions_car_outlined,
            title: loc.selectCarGeneric,
          );
        }

        final today = DateTime.now();
        final weeks = prioritizeCurrentReportWeek(
          buildReportWeeks(_selectedMonth, workWeekDays),
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
                    return _wrapClickable(
                      _buildFutureWeekCard(
                        week,
                        languageCode: languageCode,
                        noRefuelsLabel: loc.upcoming,
                      ),
                      week,
                      borderRadius: BorderRadius.circular(20),
                      enabled: false,
                    );
                  }

                  final hasAnyLogs = _weekHasLogsCached(provider, week);
                  if (!hasAnyLogs) {
                    final empty = WeeklyReportData(
                      distance: 0,
                      fuelSummaries: const [],
                      odometerStart: null,
                      odometerEnd: null,
                    );
                    return _wrapClickable(
                      _buildWeeklyReportCard(
                        context,
                        week,
                        empty,
                        languageCode: languageCode,
                        loc: loc,
                        isNoMileage: true,
                        hasEntries: false,
                        isCurrentWeek: isCurrentWeek,
                      ),
                      week,
                      borderRadius: BorderRadius.circular(20),
                      enabled: false,
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
                      if (snapshot.hasError) {
                        return _wrapClickable(
                          _buildErrorWeekCard(
                            loc.reportLoadError,
                            loc.retry,
                            isCurrentWeek: isCurrentWeek,
                            colorScheme: Theme.of(context).colorScheme,
                            onRetry: () => setState(() {}),
                          ),
                          week,
                          borderRadius: BorderRadius.circular(16),
                          enabled: false,
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _wrapClickable(
                          _buildLoadingWeekCard(
                            isCurrentWeek: isCurrentWeek,
                            colorScheme: Theme.of(context).colorScheme,
                          ),
                          week,
                          borderRadius: BorderRadius.circular(16),
                          enabled: false,
                        );
                      }

                      final data = snapshot.data!;
                      final status = classifyWeeklyReportStatus(data.distance);
                      final isNoMileage = status.isNoMileage;
                      return _wrapClickable(
                        _buildWeeklyReportCard(
                          context,
                          week,
                          data,
                          languageCode: languageCode,
                          loc: loc,
                          isNoMileage: isNoMileage,
                          hasEntries: data.hasEntries,
                          isCurrentWeek: isCurrentWeek,
                        ),
                        week,
                        borderRadius: BorderRadius.circular(20),
                        // Any week with entries opens the detail screen, so a
                        // wrong refuel can be removed even without mileage.
                        enabled: data.hasEntries,
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

  Widget _buildLoadingWeekCard({
    required bool isCurrentWeek,
    required ColorScheme colorScheme,
  }) {
    final placeholderColor = colorScheme.outlineVariant.withValues(alpha: 0.45);

    return Card(
      elevation: isCurrentWeek ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isCurrentWeek
            ? BorderSide(color: colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPlaceholderBar(140, 15, placeholderColor),
                      const SizedBox(height: 8),
                      _buildPlaceholderBar(92, 12, placeholderColor),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _buildPlaceholderBar(104, 30, placeholderColor),
              ],
            ),
            const SizedBox(height: 16),
            Divider(height: 1, color: placeholderColor),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: _buildPlaceholderBar(
                        double.infinity, 12, placeholderColor)),
                const SizedBox(width: 18),
                Expanded(
                    child: _buildPlaceholderBar(
                        double.infinity, 12, placeholderColor)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWeekCard(
    String message,
    String retryLabel, {
    required bool isCurrentWeek,
    required ColorScheme colorScheme,
    required VoidCallback onRetry,
  }) {
    return Card(
      elevation: isCurrentWeek ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isCurrentWeek
            ? BorderSide(color: colorScheme.primary, width: 2)
            : BorderSide(color: colorScheme.outlineVariant),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Row(
          children: [
            Icon(Icons.cloud_off_outlined, color: colorScheme.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            TextButton(onPressed: onRetry, child: Text(retryLabel)),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderBar(
    double width,
    double height,
    Color color,
  ) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }

  Widget _buildWeeklyReportCard(
    BuildContext context,
    Map<String, DateTime> week,
    WeeklyReportData data, {
    required String languageCode,
    required AppLocalizations loc,
    required bool isNoMileage,
    required bool hasEntries,
    required bool isCurrentWeek,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final weekTitle =
        '${DateFormat.d(languageCode).format(week['start']!)} - ${DateFormat.d(languageCode).format(week['end']!)} ${DateFormat.MMMM(languageCode).format(week['start']!)}';
    // The "nothing recorded" look is reserved for weeks without any entries;
    // a week with refuels but zero mileage still shows its data.
    final isEmptyWeek = !hasEntries;

    return Card(
      elevation: isCurrentWeek ? 4 : (isEmptyWeek ? 0 : 1.5),
      color: isEmptyWeek ? _noMileageBackground : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: isCurrentWeek
            ? BorderSide(color: colorScheme.primary, width: 2)
            : isEmptyWeek
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
            if (isEmptyWeek)
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
    final hasFuel = data.fuelSummaries.isNotEmpty;

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
        else
          ...data.fuelSummaries.asMap().entries.map((entry) {
            final summary = entry.value;
            return Padding(
              padding: EdgeInsets.only(top: entry.key == 0 ? 0 : 8),
              child: _buildFuelAmountRow(
                summary.fuelType,
                summary.totalLiters,
                _fuelTypeColor(summary.fuelType, colorScheme),
                loc.litersShort,
              ),
            );
          }),
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

  Color _fuelTypeColor(String fuelType, ColorScheme colorScheme) {
    final normalized = fuelType.trim().toUpperCase();
    if (normalized == '95') return Colors.orange;
    if (normalized == 'ГАЗ') return Colors.green;
    return colorScheme.primary;
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
      // No odometer reading inside the week yet: the previous reading is the
      // start, and the end stays empty so the missing reading is visible.
      odometerStart = previousWeekLog.odometer;
      odometerEnd = null;
      distance = 0;
    }

    return WeeklyReportData(
      distance: distance,
      fuelSummaries: summarizeFuelLogsByType(fuelLogs),
      odometerStart: odometerStart,
      odometerEnd: odometerEnd,
      hasEntries: odometerLogs.isNotEmpty || fuelLogs.isNotEmpty,
    );
  }
}

class WeeklyReportData {
  final int distance;
  final List<FuelTypeSummary> fuelSummaries;
  final int? odometerStart;
  final int? odometerEnd;

  /// Whether the week contains at least one odometer or fuel entry.
  final bool hasEntries;

  WeeklyReportData({
    required this.distance,
    required this.fuelSummaries,
    this.odometerStart,
    this.odometerEnd,
    this.hasEntries = false,
  });
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../domain/week_summary.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_provider.dart';
import '../providers/locale_provider.dart';
import '../theme/app_theme.dart';
import '../theme/fuel_colors.dart';
import '../utils/weekly_report_utils.dart';
import '../widgets/app_empty_state.dart';
import 'week_detail_screen.dart';

/// "40", "40.5" or "40.25": no trailing zeros.
String formatLiters(double liters) {
  if (liters % 1 == 0) return liters.toInt().toString();
  return liters.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
}

class WeeklyReportScreen extends StatefulWidget {
  const WeeklyReportScreen({super.key});

  @override
  State<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends State<WeeklyReportScreen>
    with WidgetsBindingObserver {
  static const _noMileageBackground = Color(0xFFFFFBF2);
  // Darker than before so 13 px text keeps a 4.5:1 contrast on the card.
  static const _noMileageForeground = Color(0xFF7A5C52);
  static const _secondaryTextColor = Color(0xFF546E7A);
  static const _dividerColor = Color(0xFFD8DEE5);

  DateTime _selectedMonth = DateTime.now();
  DateTime _lastSeen = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final now = DateTime.now();
    bool sameMonth(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month;
    // Follow the calendar when the app was left open on the current month.
    if (sameMonth(_selectedMonth, _lastSeen) && !sameMonth(now, _lastSeen)) {
      _selectedMonth = now;
    }
    _lastSeen = now;
    // Rebuild anyway: the current week and future-week cards depend on today.
    setState(() {});
  }

  Future<void> _onWeekTap(ReportWeek week) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WeekDetailScreen(
          weekStart: week.start,
          weekEnd: week.end,
        ),
      ),
    );
  }

  Widget _wrapClickable(
    Widget card,
    ReportWeek week, {
    required bool enabled,
  }) {
    if (!enabled) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
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

    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        if (provider.selectedCar == null) {
          return AppEmptyState(
            icon: Icons.directions_car_outlined,
            title: loc.selectCarGeneric,
          );
        }

        final today = DateTime.now();
        final schedule = provider.workSchedule;
        final monthWeeks = buildReportWeeks(_selectedMonth, schedule);
        // Every week is computed from the records already in memory; there
        // is no database query per card any more.
        final summaries = {
          for (final week in monthWeeks)
            week: summarizeWeek(
              week,
              odometerLogs: provider.odometerLogs,
              fuelLogs: provider.fuelLogs,
            ),
        };
        final month = summarizeMonth(
          [for (final week in monthWeeks) summaries[week]!],
        );
        final weeks = prioritizeCurrentReportWeek(
          monthWeeks
              .where((week) => summaries[week]!.shouldShowInReport(schedule)),
          today,
        );
        final monthStarted = !monthWeeks.first.start.isAfter(today);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                  Expanded(
                    child: Text(
                      DateFormat.yMMMM(languageCode).format(_selectedMonth),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
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
              child: ListView(
                padding: const EdgeInsets.only(bottom: 8),
                children: [
                  if (monthStarted)
                    _buildMonthSummary(month, loc, languageCode),
                  for (final week in weeks)
                    _buildWeek(
                      week,
                      summaries[week]!,
                      today: today,
                      loc: loc,
                      languageCode: languageCode,
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWeek(
    ReportWeek week,
    WeekSummary summary, {
    required DateTime today,
    required AppLocalizations loc,
    required String languageCode,
  }) {
    if (week.start.isAfter(today)) {
      return _buildFutureWeekCard(
        week,
        languageCode: languageCode,
        label: loc.upcoming,
      );
    }
    return _wrapClickable(
      _buildWeeklyReportCard(
        summary,
        languageCode: languageCode,
        loc: loc,
        isCurrentWeek: week.contains(today),
      ),
      week,
      // Any week with entries opens the details, so a wrong refuel can be
      // removed even without mileage.
      enabled: summary.hasEntries,
    );
  }

  Widget _buildMonthSummary(
    MonthSummary month,
    AppLocalizations loc,
    String languageCode,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final numbers = NumberFormat.decimalPattern(languageCode);
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      elevation: 0,
      color: colorScheme.primary.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionLabel(loc.monthSummaryTitle),
            const SizedBox(height: 8),
            Text(
              loc.monthTotalDistance(numbers.format(month.distance)),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            if (month.fuelSummaries.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                runSpacing: 4,
                children: [
                  for (final fuel in month.fuelSummaries)
                    Text(
                      '${fuel.fuelType}: ${formatLiters(fuel.totalLiters)} '
                      '${loc.litersShort}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: fuelTypeColor(fuel.fuelType, colorScheme),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyReportCard(
    WeekSummary summary, {
    required String languageCode,
    required AppLocalizations loc,
    required bool isCurrentWeek,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final weekTitle = formatReportWeekTitle(summary.week, languageCode);
    final numbers = NumberFormat.decimalPattern(languageCode);
    // The "nothing recorded" look is reserved for weeks without any entries;
    // a week with refuels but zero mileage still shows its data.
    final isEmptyWeek = !summary.hasEntries;
    final hasMileage = summary.hasMileage;
    final distanceLabel =
        loc.weeklyReportDistanceText(numbers.format(summary.distance));

    return Card(
      elevation: isCurrentWeek ? 4 : (isEmptyWeek ? 0 : 1.5),
      color: isEmptyWeek ? _noMileageBackground : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: isCurrentWeek
            ? BorderSide(color: colorScheme.primary, width: 2)
            : const BorderSide(color: AppColors.line, width: 1.2),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWeekHeader(
              weekTitle,
              hasMileage ? distanceLabel : loc.weeklyReportNoMileage,
              isNoMileage: !hasMileage,
              colorScheme: colorScheme,
              statusLabel:
                  hasMileage ? distanceLabel : loc.weeklyReportNoActivity,
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, thickness: 1, color: _dividerColor),
            const SizedBox(height: 16),
            if (isEmptyWeek)
              _buildNoMileagePanel(loc)
            else
              _buildReportSections(summary, loc, colorScheme, languageCode),
          ],
        ),
      ),
    );
  }

  Widget _buildFutureWeekCard(
    ReportWeek week, {
    required String languageCode,
    required String label,
  }) {
    final weekTitle = formatReportWeekTitle(week, languageCode);
    const futureTextColor = Color(0xFF5B6874);

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.line, width: 1.2),
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
              label,
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
      crossAxisAlignment: CrossAxisAlignment.center,
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

  Widget _buildReportSections(
    WeekSummary summary,
    AppLocalizations loc,
    ColorScheme colorScheme,
    String languageCode,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildOdometerColumn(summary, loc, languageCode)),
        const SizedBox(width: 20),
        Expanded(child: _buildFuelColumn(summary, loc, colorScheme)),
      ],
    );
  }

  Widget _buildOdometerColumn(
    WeekSummary summary,
    AppLocalizations loc,
    String languageCode,
  ) {
    final numbers = NumberFormat.decimalPattern(languageCode);
    String km(int? value) =>
        value == null ? '-' : '${numbers.format(value)} ${loc.kilometers}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(loc.odometerSection),
        const SizedBox(height: 10),
        _buildMetricRow(loc.startLabel, km(summary.odometerStart)),
        const SizedBox(height: 8),
        _buildMetricRow(loc.endLabel, km(summary.odometerEnd)),
      ],
    );
  }

  Widget _buildFuelColumn(
    WeekSummary summary,
    AppLocalizations loc,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(loc.fuelSection),
        const SizedBox(height: 10),
        if (summary.fuelSummaries.isEmpty)
          Text(
            loc.noRefuels,
            style: const TextStyle(
              fontSize: 13,
              height: 1.35,
              color: _secondaryTextColor,
            ),
          )
        else
          for (final (index, fuel) in summary.fuelSummaries.indexed)
            Padding(
              padding: EdgeInsets.only(top: index == 0 ? 0 : 8),
              child: _buildFuelAmountRow(
                fuel.fuelType,
                fuel.totalLiters,
                fuelTypeColor(fuel.fuelType, colorScheme),
                loc.litersShort,
              ),
            ),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            '$label:',
            style: const TextStyle(
              fontSize: 13,
              height: 1.25,
              color: Color(0xFF42464D),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 13,
                height: 1.25,
                color: Color(0xFF202124),
                fontWeight: FontWeight.w600,
              ),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 2,
            children: [
              Text(
                fuelType,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.25,
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '${formatLiters(liters)} $unit',
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.25,
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

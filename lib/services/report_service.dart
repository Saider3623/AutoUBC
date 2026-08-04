import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/car.dart';
import '../models/odometer_log.dart';
import '../models/fuel_log.dart';
import '../db/database_service.dart';
import '../utils/report_status.dart';

/// Builds the localized PDF filename for a selected report month.
String buildReportFileName(
  String carName,
  DateTime reportMonth,
  String languageCode,
) {
  final sanitizedCarName = _sanitizeFileNamePart(carName);
  final monthName = _capitalizeFirstLetter(
    DateFormat.MMMM(languageCode).format(reportMonth),
  );
  final sanitizedMonthName = _sanitizeFileNamePart(monthName);
  return '${sanitizedCarName}_$sanitizedMonthName.pdf';
}

String _sanitizeFileNamePart(String value) {
  return value.trim().replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
}

String _capitalizeFirstLetter(String value) {
  if (value.isEmpty) return value;
  final firstRune = value.runes.first;
  final firstLetter = String.fromCharCode(firstRune);
  return '${firstLetter.toUpperCase()}${value.substring(firstLetter.length)}';
}

/// Aggregated fuel data for one fuel type within a report week.
class FuelTypeSummary {
  final String fuelType;
  final int refuelCount;
  final double totalLiters;

  const FuelTypeSummary({
    required this.fuelType,
    required this.refuelCount,
    required this.totalLiters,
  });
}

/// Groups refueling logs by their stored fuel type.
List<FuelTypeSummary> summarizeFuelLogsByType(Iterable<FuelLog> logs) {
  final grouped = <String, ({int refuelCount, double totalLiters})>{};

  for (final log in logs) {
    final fuelType = log.fuelType.trim();
    if (fuelType.isEmpty) continue;

    final current = grouped[fuelType];
    grouped[fuelType] = (
      refuelCount: (current?.refuelCount ?? 0) + 1,
      totalLiters: (current?.totalLiters ?? 0) + log.liters,
    );
  }

  final summaries = grouped.entries
      .map(
        (entry) => FuelTypeSummary(
          fuelType: entry.key,
          refuelCount: entry.value.refuelCount,
          totalLiters: entry.value.totalLiters,
        ),
      )
      .toList();
  summaries.sort((a, b) => a.fuelType.compareTo(b.fuelType));
  return summaries;
}

/// Дані по одному тижню для звіту
class _WeekData {
  final DateTime weekStart;
  final DateTime weekEnd;
  final int?
      odometerStart; // показання на початок тижня (перша запис в тижні або ближня до нього)
  final int? odometerEnd; // показання на кінець тижня
  final int mileage; // пробіг за тиждень
  final List<FuelTypeSummary> fuelSummaries;

  _WeekData({
    required this.weekStart,
    required this.weekEnd,
    required this.odometerStart,
    required this.odometerEnd,
    required this.mileage,
    required this.fuelSummaries,
  });
}

class _PdfTranslations {
  final String reportTitle;
  final String weekLabel;
  final String odometerStart;
  final String odometerEnd;
  final String mileage;
  final String refuelCount;
  final String noMileage;
  final String pcs;
  final String km;
  final String l;
  final String shareText;

  _PdfTranslations({
    required this.reportTitle,
    required this.weekLabel,
    required this.odometerStart,
    required this.odometerEnd,
    required this.mileage,
    required this.refuelCount,
    required this.noMileage,
    required this.pcs,
    required this.km,
    required this.l,
    required this.shareText,
  });

  factory _PdfTranslations.of(String languageCode) {
    switch (languageCode) {
      case 'ru':
        return _PdfTranslations(
          reportTitle: 'Отчет по автомобилю {carName}',
          weekLabel: 'Неделя:  {dateRange}',
          odometerStart: 'Начало недели',
          odometerEnd: 'Конец недели',
          mileage: 'Пробег за неделю',
          refuelCount: 'Заправки',
          noMileage: 'Без пробега',
          pcs: 'шт.',
          km: 'км',
          l: 'л',
          shareText: 'Отчет AutoUBC',
        );
      case 'en':
        return _PdfTranslations(
          reportTitle: 'Report for car {carName}',
          weekLabel: 'Week:  {dateRange}',
          odometerStart: 'Week start',
          odometerEnd: 'Week end',
          mileage: 'Weekly mileage',
          refuelCount: 'Refuels',
          noMileage: 'No mileage',
          pcs: 'pcs',
          km: 'km',
          l: 'L',
          shareText: 'AutoUBC Report',
        );
      case 'uk':
      default:
        return _PdfTranslations(
          reportTitle: 'Звіт по автомобілю {carName}',
          weekLabel: 'Тиждень:  {dateRange}',
          odometerStart: 'Початок тижня',
          odometerEnd: 'Кінець тижня',
          mileage: 'Пробіг за тиждень',
          refuelCount: 'Заправки',
          noMileage: 'Без пробігу',
          pcs: 'шт.',
          km: 'км',
          l: 'л',
          shareText: 'Звіт AutoUBC',
        );
    }
  }
}

class ReportService {
  final DatabaseService _db = DatabaseService();

  /// Генерує тижневий PDF-звіт за обраний місяць
  Future<File> generatePdfReport(
    Car car,
    DateTime startDate,
    DateTime endDate,
    String languageCode,
  ) async {
    final t = _PdfTranslations.of(languageCode);
    final pdf = pw.Document();

    final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final ttf = pw.Font.ttf(fontData);
    // Bold variant: same font with pw.FontWeight.bold
    final ttfBold = ttf;

    final startStr = DateFormat('yyyy-MM-dd').format(startDate);
    final endStr = DateFormat('yyyy-MM-dd').format(endDate);

    final odometerLogs =
        await _db.getOdometerLogsInRange(car.id, startStr, endStr);
    odometerLogs.sort((a, b) => a.dateString.compareTo(b.dateString));

    final fuelLogs = await _db.getFuelLogsInRange(car.id, startStr, endStr);
    fuelLogs.sort((a, b) => a.dateString.compareTo(b.dateString));

    final weeks = await _buildWeeks(
        car.id, startDate, endDate, odometerLogs, fuelLogs, languageCode, t);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => [
          // ── Заголовок ──────────────────────────────────────────────────
          pw.Inseparable(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  t.reportTitle.replaceFirst('{carName}', car.name),
                  style: pw.TextStyle(font: ttfBold, fontSize: 22),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  DateFormat.yMMMM(languageCode).format(startDate),
                  style: pw.TextStyle(
                      font: ttf, fontSize: 14, color: PdfColors.grey700),
                ),
                pw.Divider(thickness: 1.5, color: PdfColors.blueGrey800),
                pw.SizedBox(height: 16),
              ],
            ),
          ),

          // ── Тижні: кожен блок не розривається ──────────────────────────
          ...weeks.map((week) => pw.Inseparable(
                child: _buildWeekSection(week, ttf, ttfBold, languageCode, t),
              )),
        ],
      ),
    );

    final tempDir = await getTemporaryDirectory();
    final fileName = buildReportFileName(car.name, startDate, languageCode);
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  /// Розбити діапазон дат на тижні (Пн–Нд), обмежені межами місяця
  Future<List<_WeekData>> _buildWeeks(
    int carId,
    DateTime monthStart,
    DateTime monthEnd,
    List<OdometerLog> odometerLogs,
    List<FuelLog> fuelLogs,
    String languageCode,
    _PdfTranslations t,
  ) async {
    final weeks = <_WeekData>[];

    DateTime current = monthStart;

    while (!current.isAfter(monthEnd)) {
      final daysUntilSunday = 7 - current.weekday; // weekday: 1=Пн..7=Нд
      DateTime weekEnd = current.add(Duration(days: daysUntilSunday));
      if (weekEnd.isAfter(monthEnd)) weekEnd = monthEnd;

      // Одометр: всі записи в межах тижня
      final weekOdoLogs = odometerLogs.where((log) {
        final d = DateTime.parse(log.dateString);
        return !d.isBefore(current) && !d.isAfter(weekEnd);
      }).toList();
      weekOdoLogs.sort((a, b) => a.dateString.compareTo(b.dateString));

      // Заправки в межах тижня
      final weekFuelLogs = fuelLogs.where((log) {
        final d = DateTime.parse(log.dateString);
        return !d.isBefore(current) && !d.isAfter(weekEnd);
      }).toList();

      // Get the latest odometer entry before the current week.
      final startString = DateFormat('yyyy-MM-dd').format(current);
      final previousWeekLog =
          await _db.getLastOdometerLogBeforeDate(carId, startString);

      int? odoStart;
      int? odoEnd;
      int mileage = 0;

      if (weekOdoLogs.isNotEmpty) {
        // Use the previous week's reading when available; otherwise use the first reading in the current week.
        odoStart = previousWeekLog?.odometer ?? weekOdoLogs.first.odometer;
        odoEnd = weekOdoLogs.last.odometer;
        mileage = odoEnd - odoStart;
        if (mileage < 0) mileage = 0;
      } else if (previousWeekLog != null) {
        // If the current week has no entries, reuse the previous reading.
        odoStart = previousWeekLog.odometer;
        odoEnd = previousWeekLog.odometer;
        mileage = 0;
      }

      final fuelSummaries = summarizeFuelLogsByType(weekFuelLogs);

      weeks.add(_WeekData(
        weekStart: current,
        weekEnd: weekEnd,
        odometerStart: odoStart,
        odometerEnd: odoEnd,
        mileage: mileage,
        fuelSummaries: fuelSummaries,
      ));

      current = weekEnd.add(const Duration(days: 1));
    }

    return weeks;
  }

  /// Будує блок PDF для одного тижня
  pw.Widget _buildWeekSection(
    _WeekData week,
    pw.Font ttf,
    pw.Font ttfBold,
    String languageCode,
    _PdfTranslations t,
  ) {
    final dateRange =
        '${DateFormat('d MMM', languageCode).format(week.weekStart)} – ${DateFormat('d MMM yyyy', languageCode).format(week.weekEnd)}';
    final isNoMileage = classifyWeeklyReportStatus(week.mileage).isNoMileage;

    final odoStartStr =
        week.odometerStart != null ? '${week.odometerStart} ${t.km}' : '—';
    final odoEndStr =
        week.odometerEnd != null ? '${week.odometerEnd} ${t.km}' : '—';
    final mileageStr =
        week.odometerStart != null ? '${week.mileage} ${t.km}' : '—';
    final totalRefuelCount = week.fuelSummaries.fold<int>(
      0,
      (sum, summary) => sum + summary.refuelCount,
    );

    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Заголовок тижня
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
          child: pw.Text(
            t.weekLabel.replaceFirst('{dateRange}', dateRange),
            style: pw.TextStyle(
                font: ttfBold, fontSize: 13, color: PdfColors.white),
          ),
        ),

        if (isNoMileage)
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: pw.BoxDecoration(
              color: PdfColors.blueGrey50,
              border: pw.Border.all(color: PdfColors.blueGrey200, width: 0.5),
            ),
            child: pw.Text(
              t.noMileage,
              style: pw.TextStyle(
                font: ttf,
                fontSize: 11,
                color: PdfColors.blueGrey700,
              ),
            ),
          )
        else
          // Одна таблиця: одометр, кількість чеків і літри за типами пального.
          pw.Table(
            border:
                pw.TableBorder.all(color: PdfColors.blueGrey200, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(2.5),
              1: const pw.FlexColumnWidth(2),
            },
            children: [
              _tableRow(
                t.odometerStart,
                odoStartStr,
                ttf,
                ttfBold,
                header: true,
              ),
              _tableRow(t.odometerEnd, odoEndStr, ttf, ttfBold),
              _tableRow(t.mileage, mileageStr, ttf, ttfBold),
              _tableRow(
                t.refuelCount,
                '$totalRefuelCount ${t.pcs}',
                ttf,
                ttfBold,
              ),
              ...week.fuelSummaries.map(
                (summary) => _tableRow(
                  summary.fuelType,
                  _formatLiters(summary.totalLiters, t),
                  ttf,
                  ttfBold,
                ),
              ),
            ],
          ),

        pw.SizedBox(height: 20),
      ],
    );
  }

  String _formatLiters(double liters, _PdfTranslations t) {
    final value =
        liters % 1 == 0 ? liters.toInt().toString() : liters.toStringAsFixed(2);
    return '$value ${t.l}';
  }

  pw.TableRow _tableRow(
    String label,
    String value,
    pw.Font ttf,
    pw.Font ttfBold, {
    bool header = false,
  }) {
    final bg = header ? PdfColors.blueGrey50 : PdfColors.white;
    return pw.TableRow(
      decoration: pw.BoxDecoration(color: bg),
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: pw.Text(label, style: pw.TextStyle(font: ttf, fontSize: 11)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child:
              pw.Text(value, style: pw.TextStyle(font: ttfBold, fontSize: 11)),
        ),
      ],
    );
  }

  Future<void> shareReport(File file, {String languageCode = 'uk'}) async {
    final t = _PdfTranslations.of(languageCode);
    final fileName = file.path.split(Platform.pathSeparator).last;
    await Share.shareXFiles(
      [XFile(file.path, name: fileName)],
      text: t.shareText,
    );
  }
}

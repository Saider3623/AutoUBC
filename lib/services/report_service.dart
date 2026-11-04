import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../db/database_service.dart';
import '../domain/week_summary.dart';
import '../models/car.dart';
import '../utils/weekly_report_utils.dart';
import '../utils/work_schedule.dart';

export '../utils/fuel_summary.dart';

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

class _PdfTranslations {
  final String reportTitle;
  final String odometerStart;
  final String odometerEnd;
  final String mileage;
  final String noMileage;
  final String monthTotal;
  final String monthMileage;
  final String daysWithoutReading;
  final String gapNote;
  final String generated;
  final String page;
  final String plate;
  final String driver;
  final String km;
  final String l;
  final String shareText;

  const _PdfTranslations({
    required this.reportTitle,
    required this.odometerStart,
    required this.odometerEnd,
    required this.mileage,
    required this.noMileage,
    required this.monthTotal,
    required this.monthMileage,
    required this.daysWithoutReading,
    required this.gapNote,
    required this.generated,
    required this.page,
    required this.plate,
    required this.driver,
    required this.km,
    required this.l,
    required this.shareText,
  });

  factory _PdfTranslations.of(String languageCode) {
    switch (languageCode) {
      case 'en':
        return const _PdfTranslations(
          reportTitle: 'Report for car {carName}',
          odometerStart: 'Week start',
          odometerEnd: 'Week end',
          mileage: 'Weekly mileage',
          noMileage: 'No mileage',
          monthTotal: 'Month total',
          monthMileage: 'Mileage this month',
          daysWithoutReading: 'Working days without a reading',
          gapNote: 'The mileage includes days without readings since {date}',
          generated: 'Generated {date}',
          page: 'Page {page} of {pages}',
          plate: 'Plate',
          driver: 'Driver',
          km: 'km',
          l: 'L',
          shareText: 'AutoUBC Report',
        );
      case 'uk':
      default:
        return const _PdfTranslations(
          reportTitle: 'Звіт по автомобілю {carName}',
          odometerStart: 'Початок тижня',
          odometerEnd: 'Кінець тижня',
          mileage: 'Пробіг за тиждень',
          noMileage: 'Без пробігу',
          monthTotal: 'Підсумок місяця',
          monthMileage: 'Пробіг за місяць',
          daysWithoutReading: 'Робочих днів без показань',
          gapNote: 'Пробіг включає дні без показань від {date}',
          generated: 'Сформовано {date}',
          page: 'Сторінка {page} з {pages}',
          plate: 'Держномер',
          driver: 'Водій',
          km: 'км',
          l: 'л',
          shareText: 'Звіт AutoUBC',
        );
    }
  }
}

class ReportService {
  final DatabaseService _db = DatabaseService();

  /// Builds the weekly PDF report of the month that contains [startDate].
  ///
  /// Weeks are computed with the same [summarizeWeek] function as the weekly
  /// report screen, so both always show the same numbers.
  Future<File> generatePdfReport(
    Car car,
    DateTime startDate,
    DateTime endDate,
    String languageCode, {
    WorkSchedule schedule = const WorkSchedule(),
  }) async {
    final bytes = await buildPdfReport(
      car,
      startDate,
      endDate,
      languageCode,
      schedule: schedule,
    );
    final tempDir = await getTemporaryDirectory();
    final fileName = buildReportFileName(car.name, startDate, languageCode);
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file;
  }

  /// The PDF of [generatePdfReport] in memory, for the preview screen.
  Future<Uint8List> buildPdfReport(
    Car car,
    DateTime startDate,
    DateTime endDate,
    String languageCode, {
    WorkSchedule schedule = const WorkSchedule(),
  }) async {
    final t = _PdfTranslations.of(languageCode);
    final pdf = pw.Document();

    final regular =
        pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
    final bold =
        pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Bold.ttf'));
    final theme = pw.ThemeData.withFont(base: regular, bold: bold);

    final odometerLogs = await _db.getOdometerLogsForCar(car.id);
    final fuelLogs = await _db.getFuelLogsForCar(car.id);
    final weeks = [
      for (final week in buildReportWeeks(startDate, schedule))
        summarizeWeek(week, odometerLogs: odometerLogs, fuelLogs: fuelLogs),
    ];
    final now = DateTime.now();
    final month = summarizeMonth(
      weeks,
      odometerLogs: odometerLogs,
      today: now,
      isWorkingDay: (day) =>
          day.weekday != DateTime.sunday && !schedule.isNonWorkingSaturday(day),
    );
    final numbers = NumberFormat.decimalPattern(languageCode);

    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 8),
          child: pw.Text(
            t.page
                .replaceFirst('{page}', '${context.pageNumber}')
                .replaceFirst('{pages}', '${context.pagesCount}'),
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ),
        build: (pw.Context context) => [
          pw.Inseparable(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  t.reportTitle.replaceFirst('{carName}', car.name),
                  style: const pw.TextStyle(
                      fontSize: 22, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 6),
                if (car.plateNumber != null || car.driverName != null)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    child: pw.Text(
                      [
                        if (car.plateNumber != null)
                          '${t.plate}: ${car.plateNumber}',
                        if (car.driverName != null)
                          '${t.driver}: ${car.driverName}',
                      ].join('   ·   '),
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ),
                pw.Text(
                  DateFormat.yMMMM(languageCode).format(startDate),
                  style: const pw.TextStyle(
                      fontSize: 14, color: PdfColors.grey700),
                ),
                pw.Text(
                  t.generated.replaceFirst(
                    '{date}',
                    DateFormat('dd.MM.yy', languageCode).format(now),
                  ),
                  style:
                      const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                ),
                pw.Divider(thickness: 1.5, color: PdfColors.blueGrey800),
                pw.SizedBox(height: 8),
              ],
            ),
          ),
          pw.Inseparable(child: _buildMonthSection(month, numbers, t)),
          ...weeks
              .where((week) =>
                  week.hasEntries ||
                  week.week.start.weekday <=
                      schedule.workWeekDaysForWeekOf(week.week.start))
              .map((week) => pw.Inseparable(
                    child: _buildWeekSection(week, numbers, languageCode, t),
                  )),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildMonthSection(
    MonthSummary month,
    NumberFormat numbers,
    _PdfTranslations t,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(t.monthTotal,
            style: const pw.TextStyle(
                fontSize: 13, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.blueGrey200, width: 0.5),
          columnWidths: const {
            0: pw.FlexColumnWidth(2.5),
            1: pw.FlexColumnWidth(2),
          },
          children: [
            _tableRow(
                t.monthMileage, '${numbers.format(month.distance)} ${t.km}'),
            ...month.fuelSummaries.map(
              (fuel) => _tableRow(
                '${fuel.fuelType} (${fuel.refuelCount})',
                _formatLiters(fuel.totalLiters, t),
              ),
            ),
            if (month.daysWithoutReading > 0)
              _tableRow(t.daysWithoutReading, '${month.daysWithoutReading}'),
          ],
        ),
        pw.SizedBox(height: 20),
      ],
    );
  }

  pw.Widget _buildWeekSection(
    WeekSummary week,
    NumberFormat numbers,
    String languageCode,
    _PdfTranslations t,
  ) {
    final dateRange =
        '${DateFormat('EEE dd.MM.yy', languageCode).format(week.week.start)} - '
        '${DateFormat('EEE dd.MM.yy', languageCode).format(week.week.end)}';
    String km(int? value) =>
        value == null ? '—' : '${numbers.format(value)} ${t.km}';

    final gapDate = week.includesGap && week.odometerStartDate != null
        ? DateTime.tryParse(week.odometerStartDate!)
        : null;

    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
          child: pw.Text(
            dateRange,
            style: const pw.TextStyle(
              fontSize: 13,
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        if (!week.hasEntries)
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.blueGrey200, width: 0.5),
            ),
            child: pw.Text(
              t.noMileage,
              style: const pw.TextStyle(
                fontSize: 11,
                color: PdfColors.blueGrey700,
              ),
            ),
          )
        else
          // One table: odometer and litres by fuel type; the number of
          // receipts is shown in brackets next to each fuel type.
          pw.Table(
            border:
                pw.TableBorder.all(color: PdfColors.blueGrey200, width: 0.5),
            columnWidths: const {
              0: pw.FlexColumnWidth(2.5),
              1: pw.FlexColumnWidth(2),
            },
            children: [
              _tableRow(t.odometerStart, km(week.odometerStart)),
              _tableRow(t.odometerEnd, km(week.odometerEnd)),
              _tableRow(
                t.mileage,
                week.odometerStart == null ? '—' : km(week.distance),
              ),
              ...week.fuelSummaries.map(
                (summary) => _tableRow(
                  '${summary.fuelType} (${summary.refuelCount})',
                  _formatLiters(summary.totalLiters, t),
                ),
              ),
            ],
          ),
        if (gapDate != null)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 4),
            child: pw.Text(
              t.gapNote.replaceFirst('{date}',
                  DateFormat('dd.MM.yy', languageCode).format(gapDate)),
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
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

  pw.TableRow _tableRow(String label, String value) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.white),
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: pw.Text(label, style: const pw.TextStyle(fontSize: 11)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: pw.Text(value,
              style: const pw.TextStyle(
                  fontSize: 11, fontWeight: pw.FontWeight.bold)),
        ),
      ],
    );
  }

  Future<void> shareReport(File file, {String languageCode = 'uk'}) async {
    final t = _PdfTranslations.of(languageCode);
    final fileName = file.path.split(Platform.pathSeparator).last;
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, name: fileName)],
        fileNameOverrides: [fileName],
        text: t.shareText,
      ),
    );
  }
}

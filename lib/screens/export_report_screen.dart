import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/locale_provider.dart';
import '../services/report_service.dart';
import '../utils/error_messages.dart';
import 'report_preview_screen.dart';

class ExportReportScreen extends StatefulWidget {
  const ExportReportScreen({super.key});

  @override
  State<ExportReportScreen> createState() => _ExportReportScreenState();
}

class _ExportReportScreenState extends State<ExportReportScreen> {
  DateTime _selectedMonth = DateTime.now();
  final ReportService _reportService = ReportService();
  bool _isLoading = false;

  /// Opens the PDF preview; sharing from there makes the same file as the
  /// export button.
  void _preview() {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final car = appProvider.selectedCar;
    if (car == null) return;
    final languageCode = localeProvider.locale?.languageCode ?? 'uk';
    final startDate = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final endDate = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    final document = _reportService.buildPdfReport(
      car,
      startDate,
      endDate,
      languageCode,
      schedule: appProvider.workSchedule,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportPreviewScreen(
          title: DateFormat.yMMMM(languageCode).format(startDate),
          fileName: buildReportFileName(car.name, startDate, languageCode),
          document: document,
          onShare: _exportToPdf,
        ),
      ),
    );
  }

  Future<void> _exportToPdf() async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    if (appProvider.selectedCar == null) return;

    final startDate = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final endDate = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);

    setState(() => _isLoading = true);
    try {
      final languageCode = localeProvider.locale?.languageCode ?? 'uk';
      final file = await _reportService.generatePdfReport(
        appProvider.selectedCar!,
        startDate,
        endDate,
        languageCode,
        schedule: appProvider.workSchedule,
      );
      await _reportService.shareReport(file, languageCode: languageCode);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  AppLocalizations.of(context)!.exportError(
                      describeError(e, AppLocalizations.of(context)!)))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final localeProvider = Provider.of<LocaleProvider>(context);
    final languageCode = localeProvider.locale?.languageCode ?? 'uk';
    return Scaffold(
      appBar: AppBar(title: Text(loc.exportReports)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Text(loc.selectMonthForReport,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: () {
                            setState(() {
                              _selectedMonth = DateTime(_selectedMonth.year,
                                  _selectedMonth.month - 1);
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
                              _selectedMonth = DateTime(_selectedMonth.year,
                                  _selectedMonth.month + 1);
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              Center(
                  child:
                      Text(loc.loading, style: const TextStyle(fontSize: 16)))
            else ...[
              ElevatedButton.icon(
                onPressed: _exportToPdf,
                icon: const Icon(Icons.picture_as_pdf),
                label: Text(loc.exportToPDF),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _preview,
                icon: const Icon(Icons.visibility_outlined),
                label: Text(loc.previewReport),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

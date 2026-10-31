import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../l10n/app_localizations.dart';
import '../utils/error_messages.dart';

/// Shows the generated PDF before it is shared, so a wrong month or a missing
/// reading is noticed before the report leaves the phone.
class ReportPreviewScreen extends StatelessWidget {
  final String title;
  final String fileName;
  final Future<Uint8List> document;
  final Future<void> Function() onShare;

  const ReportPreviewScreen({
    super.key,
    required this.title,
    required this.fileName,
    required this.document,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: loc.shareReport,
            onPressed: onShare,
          ),
        ],
      ),
      body: PdfPreview(
        build: (_) => document,
        pdfFileName: fileName,
        // The report has a fixed A4 layout; the only action is sharing.
        useActions: false,
        allowPrinting: false,
        allowSharing: false,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        loadingWidget: const Center(child: CircularProgressIndicator()),
        onError: (context, error) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              loc.exportError(describeError(error, loc)),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

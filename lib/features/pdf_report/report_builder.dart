import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/config/constants.dart';
import '../../core/storage/local_db.dart';
import '../../shared/l10n/app_localizations.dart';

/// Builds a doctor-visit summary PDF. Optimised for share/print so
/// the user can hand it to a clinician — explicit "reference only,
/// not medical advice" footer required by product policy.
class ReportBuilder {
  Future<pw.Document> build({
    required List<Drug> drugs,
    required Map<String, List<DoseLog>> logsByDrug,
    required AppLocalizations l10n,
  }) async {
    final regularFontData = await rootBundle.load(
      'assets/fonts/Roboto-Regular.ttf',
    );
    final boldFontData = await rootBundle.load(
      'assets/fonts/Roboto-Medium.ttf',
    );
    final cjkFontData = await rootBundle.load(
      'assets/fonts/DroidSansFallbackFull.ttf',
    );
    final regularFont = pw.Font.ttf(regularFontData);
    final boldFont = pw.Font.ttf(boldFontData);
    final cjkFont = pw.Font.ttf(cjkFontData);
    final theme = pw.ThemeData.withFont(
      base: regularFont,
      bold: boldFont,
      fontFallback: [cjkFont],
    );
    final doc = pw.Document(theme: theme);
    final now = DateTime.now();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) => [
          pw.Header(
            level: 0,
            text: l10n.reportHeader,
          ),
          pw.Paragraph(
            text: '${l10n.reportGenerated} ${now.toIso8601String()}',
          ),
          pw.SizedBox(height: 8),
          pw.Header(level: 1, text: l10n.reportMedications),
          if (drugs.isEmpty)
            pw.Paragraph(text: l10n.reportNoMedications)
          else
            pw.TableHelper.fromTextArray(
              headers: l10n.reportMedicationHeaders,
              data: [
                for (final d in drugs)
                  [
                    d.brandName,
                    d.genericName ?? '',
                    '${d.doseMg.toStringAsFixed(0)} mg',
                    '${d.intervalHours.toStringAsFixed(0)} h',
                  ],
              ],
            ),
          pw.SizedBox(height: 16),
          pw.Header(level: 1, text: l10n.reportDoseLog),
          for (final d in drugs) ...[
            pw.Paragraph(text: d.brandName),
            pw.TableHelper.fromTextArray(
              headers: l10n.reportDoseLogHeaders,
              data: [
                for (final l in (logsByDrug[d.id] ?? const <DoseLog>[]).where(
                  (e) =>
                      e.takenAt.isAfter(now.subtract(const Duration(days: 30))),
                ))
                  [
                    l.takenAt.toIso8601String(),
                    l.doseMg.toStringAsFixed(0),
                    l.note ?? '',
                  ],
              ],
            ),
            pw.SizedBox(height: 8),
          ],
          pw.Footer(
            title: pw.Text(
              AppConstants.disclaimerEn,
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey),
            ),
          ),
        ],
      ),
    );
    return doc;
  }
}

import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../data/database.dart';
import '../domain/esc.dart';

class ExportUtils {
  static Future<String> buildCsv(List<Reading> data) async {
    final dateFmt = DateFormat('yyyy-MM-dd HH:mm');
    final buf = StringBuffer();
    buf.writeln('date,systolic,diastolic,category,notes');
    for (final r in data) {
      final cat = EscClassification.classify(systolic: r.systolic, diastolic: r.diastolic);
      buf.writeln('${dateFmt.format(r.takenAt)},${r.systolic},${r.diastolic},${EscClassification.label(cat)},"${r.notes.replaceAll('"', '""')}"');
    }
    return buf.toString();
  }

  static Future<Uint8List> buildPdf(List<Reading> data, {PdfPageFormat? format}) async {
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');
    final doc = pw.Document();

    final table = pw.Table.fromTextArray(
      headers: ['Date', 'PAS', 'PAD', 'Catégorie', 'Notes'],
      data: [
        for (final r in data)
          [
            dateFmt.format(r.takenAt),
            r.systolic.toString(),
            r.diastolic.toString(),
            EscClassification.label(EscClassification.classify(systolic: r.systolic, diastolic: r.diastolic)),
            r.notes,
          ]
      ],
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      cellAlignment: pw.Alignment.centerLeft,
      columnWidths: {
        0: const pw.FixedColumnWidth(110),
        1: const pw.FixedColumnWidth(40),
        2: const pw.FixedColumnWidth(40),
        3: const pw.FixedColumnWidth(90),
      },
      border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey400),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
    );

    final pageFormat = format ?? PdfPageFormat.a4;

    doc.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        build: (ctx) => [
          pw.Header(level: 0, child: pw.Text('CardioTrack - Journal de tension artérielle')),
          table,
          pw.SizedBox(height: 16),
          pw.Text('ESC 2024 - catégories utilisées: Normal, Normal élevé, Hypertension.', style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );

    // Ajoute une version mobile étroite
    doc.addPage(
      pw.MultiPage(
        pageFormat: const PdfPageFormat(360, 640, marginAll: 12),
        build: (ctx) => [
          pw.Header(level: 0, child: pw.Text('CardioTrack - Journal (mobile)')),
          table,
        ],
      ),
    );

    return doc.save();
  }

  static Future<void> sharePdfAndCsv(List<Reading> data) async {
    final pdfBytes = await buildPdf(data);
    final csvText = await buildCsv(data);

    await Printing.sharePdf(bytes: pdfBytes, filename: 'CardioTrack_journal.pdf');
    // Pour le CSV, on ouvre l’aperçu d’impression/partage en utilisant un PDF wrapper simple si le partage direct n’est pas supporté.
    final csvDoc = pw.Document();
    csvDoc.addPage(pw.Page(build: (ctx) => pw.Text(csvText)));
    await Printing.sharePdf(bytes: await csvDoc.save(), filename: 'CardioTrack_journal.csv.txt');
  }
}
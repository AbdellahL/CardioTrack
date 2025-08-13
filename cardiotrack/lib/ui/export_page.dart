import 'dart:io' as io show File, Platform;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../data/database.dart';
import '../export/export_utils.dart';

class ExportPage extends StatelessWidget {
  const ExportPage({super.key});

  Future<void> _export(BuildContext context) async {
    final db = AppDatabase();
    final data = await db.allReadings();
    if (data.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aucune donnée à exporter.')));
      return;
    }

    final pdfBytes = await ExportUtils.buildPdf(data);
    final csvText = await ExportUtils.buildCsv(data);

    if (kIsWeb) {
      // Web: utilise Printing pour partager le PDF et affiche un message pour CSV
      await ExportUtils.sharePdfAndCsv(data);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF partagé. Téléchargez le CSV depuis la page ou utilisez copier/coller.')));
      return;
    }

    final dir = await getTemporaryDirectory();
    final pdfPath = '${dir.path}/CardioTrack_journal.pdf';
    final csvPath = '${dir.path}/CardioTrack_journal.csv';
    await io.File(pdfPath).writeAsBytes(pdfBytes, flush: true);
    await io.File(csvPath).writeAsString(csvText, flush: true);

    await Share.shareXFiles([XFile(pdfPath), XFile(csvPath)], subject: 'CardioTrack - Journal tension (PDF + CSV)');
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Exportez votre journal en PDF (A4 + mobile) et CSV, prêt à être envoyé par e-mail.'),
          ),
          FilledButton.icon(
            onPressed: () => _export(context),
            icon: const Icon(Icons.ios_share),
            label: const Text('Exporter / Partager'),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:yeyo/models/export_history.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';

class ExportHistoryPage extends StatefulWidget {
  const ExportHistoryPage({super.key});

  @override
  State<ExportHistoryPage> createState() => _ExportHistoryPageState();
}

class _ExportHistoryPageState extends State<ExportHistoryPage> {
  late final Box<ExportHistory> _historyBox;

  @override
  void initState() {
    super.initState();
    _historyBox = Hive.box('export_history');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Ekspor'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ValueListenableBuilder(
        valueListenable: _historyBox.listenable(),
        builder: (context, Box<ExportHistory> box, _) {
          if (box.values.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off_outlined, size: 80, color: Colors.white30),
                  SizedBox(height: 16),
                  Text(
                    'Belum ada riwayat ekspor.',
                    style: TextStyle(color: Colors.white54, fontSize: 18),
                  ),
                ],
              ),
            );
          }
          // Sort by date descending
          final sortedItems = box.values.toList()..sort((a, b) => b.exportDate.compareTo(a.exportDate));

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: sortedItems.length,
            itemBuilder: (context, index) {
              final history = sortedItems[index];
              return Card(
                color: const Color(0xFF2E2E48),
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  leading: const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 40),
                  title: Text(history.pdfFileName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    '${history.courseName} - Minggu ${history.weekNumber}\nDiekspor pada: ${DateFormat('d MMM yyyy, HH:mm').format(history.exportDate)}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: const Icon(Icons.open_in_new, color: Colors.white54),
                  onTap: () {
                    OpenFile.open(history.pdfFilePath).catchError((e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Tidak bisa membuka file: $e'), backgroundColor: Colors.red),
                      );
                    });
                  },
                ),
              );
            },
          );
        },
      ),
      backgroundColor: const Color(0xFF1A1A2E),
    );
  }
} 
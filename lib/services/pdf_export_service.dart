import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:yeyo/models/note.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class PdfExportService {
  Future<Uint8List> createPdf(
    List<Note> notes, {
    required bool includeText,
    required bool includeImages,
    required bool compressImages,
  }) async {
    final pdf = pw.Document();
    final sortedNotes = List<Note>.from(notes)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    for (final note in sortedNotes) {
      if (note.type == 'text' && includeText) {
        pdf.addPage(
          pw.Page(
            build: (pw.Context context) {
              return pw.Paragraph(text: note.content);
            },
          ),
        );
      } else if (note.type == 'image' && includeImages) {
        final file = File(note.content);
        if (file.existsSync()) {
          Uint8List imageData;
          if (compressImages) {
            imageData = await FlutterImageCompress.compressWithFile(
                  file.absolute.path,
                  quality: 50, // Compress to 50% quality
                ) ??
                await file.readAsBytes();
          } else {
            imageData = await file.readAsBytes();
          }

          final image = pw.MemoryImage(imageData);
          pdf.addPage(
            pw.Page(
              build: (pw.Context context) {
                return pw.Center(
                  child: pw.Image(image),
                );
              },
            ),
          );
        }
      }
    }
    return pdf.save();
  }
} 
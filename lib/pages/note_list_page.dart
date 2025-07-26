import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yeyo/models/app_settings.dart';
import 'package:yeyo/models/note.dart';
import 'package:yeyo/models/week.dart';
import 'package:yeyo/models/course.dart';
import 'package:yeyo/models/export_history.dart';
import 'package:yeyo/pages/note_edit_page.dart';
import 'package:yeyo/services/pdf_export_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';


class NoteListPage extends StatefulWidget {
  final Week week;
  final dynamic weekKey;
  final Course course;

  const NoteListPage({
    super.key, 
    required this.week, 
    required this.weekKey, 
    required this.course,
  });

  @override
  State<NoteListPage> createState() => _NoteListPageState();
}

class _NoteListPageState extends State<NoteListPage> {
  late final Box<Note> _noteBox;
  late final Box<Week> _weekBox;
  late final Box<AppSettings> _settingsBox;
  late final Box<ExportHistory> _historyBox;
  final ImagePicker _picker = ImagePicker();
  final PdfExportService _pdfExportService = PdfExportService();

  @override
  void initState() {
    super.initState();
    _noteBox = Hive.box('notes');
    _weekBox = Hive.box('weeks');
    _settingsBox = Hive.box('settings');
    _historyBox = Hive.box('export_history');
  }

  Future<void> _addNote(Note newNote) async {
    final noteKey = await _noteBox.add(newNote);
    final week = _weekBox.get(widget.weekKey);
    if (week != null) {
      week.noteKeys.add(noteKey);
      week.save();
    }
  }

  Future<void> _navigateToAddTextNotePage() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const NoteEditPage()),
    );

    if (result != null && result.isNotEmpty) {
      final newNote = Note()
        ..type = 'text'
        ..content = result
        ..createdAt = DateTime.now();
      await _addNote(newNote);
      setState(() {}); // Refresh UI
    }
  }

  Future<void> _navigateToEditTextNotePage(Note note, dynamic noteKey) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditPage(note: note),
      ),
    );

    if (result != null && result.isNotEmpty) {
      final existingNote = _noteBox.get(noteKey) as Note;
      existingNote.content = result;
      await _noteBox.put(noteKey, existingNote);
      setState(() {}); // Refresh UI
    }
  }

  Future<void> _showAddTextNoteDialog() async {
    final textController = TextEditingController();
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Tambah Catatan Teks'),
          content: TextField(
            controller: textController,
            autofocus: true,
            maxLines: 5,
            decoration: const InputDecoration(hintText: "Tulis catatan Anda di sini..."),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Simpan'),
              onPressed: () {
                if (textController.text.isNotEmpty) {
                  final newNote = Note()
                    ..type = 'text'
                    ..content = textController.text
                    ..createdAt = DateTime.now();
                  _addNote(newNote);
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final newNote = Note()
        ..type = 'image'
        ..content = image.path
        ..createdAt = DateTime.now();
      _addNote(newNote);
    }
  }
  
  void _deleteNote(dynamic noteKey) {
    final week = _weekBox.get(widget.weekKey);
    if (week != null) {
      week.noteKeys.remove(noteKey);
      week.save();
    }
    _noteBox.delete(noteKey);
  }

  Future<void> _exportToPdf() async {
    final week = _weekBox.get(widget.weekKey);
    if (week == null || week.noteKeys.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada catatan untuk diekspor.')),
      );
      return;
    }

    final notes = week.noteKeys.map((key) => _noteBox.get(key)!).where((note) => note != null).toList();
    
    // Dialog state
    bool includeText = true;
    bool includeImages = true;
    bool compressImages = true;
    
    final settings = _settingsBox.get(0, defaultValue: AppSettings());
    final defaultFilename = 
      '${settings?.fullName ?? 'Nama'}_${settings?.npm ?? 'NPM'}_${settings?.className ?? 'Kelas'}.pdf'
      .replaceAll(' ', '_');
    final filenameController = TextEditingController(text: defaultFilename);

    final bool? doExport = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Opsi Ekspor PDF'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: filenameController,
                    decoration: const InputDecoration(labelText: 'Nama File'),
                  ),
                  const SizedBox(height: 16),
                  const Text('Sertakan Konten:', style: TextStyle(fontWeight: FontWeight.bold)),
                  CheckboxListTile(
                    title: const Text('Catatan Teks'),
                    value: includeText,
                    onChanged: (val) => setDialogState(() => includeText = val!),
                  ),
                  CheckboxListTile(
                    title: const Text('Catatan Gambar'),
                    value: includeImages,
                    onChanged: (val) => setDialogState(() => includeImages = val!),
                  ),
                  const SizedBox(height: 8),
                  const Text('Opsi Tambahan:', style: TextStyle(fontWeight: FontWeight.bold)),
                  SwitchListTile(
                    title: const Text('Kompres Gambar'),
                    value: compressImages,
                    onChanged: (val) => setDialogState(() => compressImages = val),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
              TextButton(
                onPressed: () {
                  if (!includeText && !includeImages) {
                    // Show error
                  } else {
                     Navigator.pop(context, true);
                  }
                },
                child: const Text('Lanjut'),
              ),
            ],
          );
        },
      ),
    );

    if (doExport ?? false) {
       try {
        // Step 1: Let user pick a directory
        String? outputDir = await FilePicker.platform.getDirectoryPath(
          dialogTitle: 'Pilih folder untuk menyimpan PDF',
        );

        if (outputDir == null) return; // User canceled picker

        // Step 2: Create the subdirectory structure
        final courseDirName = widget.course.name.replaceAll(RegExp(r'[^\w\s]+'), '').replaceAll(' ', '_');
        final weekDirName = 'Minggu_${widget.week.weekNumber}';
        final finalDir = Directory('$outputDir/$courseDirName/$weekDirName');
        await finalDir.create(recursive: true);

        // Step 3: Generate PDF
        final pdfData = await _pdfExportService.createPdf(
          notes,
          includeText: includeText,
          includeImages: includeImages,
          compressImages: compressImages,
        );

        // Step 4: Save the file
        final file = File('${finalDir.path}/${filenameController.text}');
        await file.writeAsBytes(pdfData);

        // Step 5: Save to history
        final history = ExportHistory()
          ..pdfFileName = filenameController.text
          ..pdfFilePath = file.path
          ..courseName = widget.course.name
          ..weekNumber = widget.week.weekNumber
          ..exportDate = DateTime.now();
        _historyBox.add(history);


        // Step 6: Show confirmation and offer to open the file
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
            content: Text('PDF berhasil disimpan di ${file.path}'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Buka',
              onPressed: () => OpenFile.open(file.path),
            ),
          ),
        );

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showAddNoteOptions() {
    // This is now handled by SpeedDial
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Minggu ${widget.week.weekNumber}'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportToPdf,
            tooltip: 'Export ke PDF',
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: _weekBox.listenable(keys: [widget.weekKey]),
        builder: (context, Box<Week> box, _) {
          final week = box.get(widget.weekKey);
          if (week == null || week.noteKeys.isEmpty) {
            return const Center(
              child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.notes_outlined, size: 80, color: Colors.white30),
                   SizedBox(height: 16),
                  Text(
                    'Belum ada catatan.',
                    style: TextStyle(color: Colors.white54, fontSize: 18),
                  ),
                   Text(
                    'Tekan tombol + untuk menambah',
                    style: TextStyle(color: Colors.white38, fontSize: 14),
                  ),
                ],
              ),
            );
          }
          
          final sortedNotes = List<dynamic>.from(week.noteKeys)
            ..sort((a, b) {
              final noteA = _noteBox.get(a) as Note;
              final noteB = _noteBox.get(b) as Note;
              return noteA.createdAt.compareTo(noteB.createdAt);
            });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedNotes.length,
            itemBuilder: (context, index) {
              final noteKey = sortedNotes[index];
              final note = _noteBox.get(noteKey);
              if (note == null) return const SizedBox.shrink();
              return _buildNoteCard(note, noteKey);
            },
          );
        },
      ),
      floatingActionButton: _buildSpeedDial(),
      backgroundColor: const Color(0xFF1A1A2E),
    );
  }

  Widget _buildNoteCard(Note note, dynamic noteKey) {
    Widget contentWidget;
    if (note.type == 'text') {
      contentWidget = InkWell(
        onTap: () => _navigateToEditTextNotePage(note, noteKey),
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(note.content,
                    style: const TextStyle(color: Colors.white, fontSize: 16)),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline,
                    color: Colors.red.shade300, size: 20),
                onPressed: () => _deleteNote(noteKey),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      );
    } else {
      contentWidget = Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Text('Catatan Gambar',
                  style: TextStyle(
                      color: Colors.white70, fontStyle: FontStyle.italic)),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline,
                  color: Colors.red.shade300, size: 20),
              onPressed: () => _deleteNote(noteKey),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      );
    }

    return Card(
      color: const Color(0xFF2E2E48),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (note.type == 'image')
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: Image.file(
                File(note.content),
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
          contentWidget,
        ],
      ),
    );
  }

  SpeedDial _buildSpeedDial() {
    return SpeedDial(
      icon: Icons.add,
      activeIcon: Icons.close,
      backgroundColor: Colors.deepPurpleAccent,
      foregroundColor: Colors.white,
      buttonSize: const Size(56.0, 56.0),
      childrenButtonSize: const Size(60.0, 60.0),
      curve: Curves.bounceIn,
      children: [
        SpeedDialChild(
          child: const Icon(Icons.text_fields),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          label: 'Catatan Teks',
          onTap: _navigateToAddTextNotePage,
        ),
        SpeedDialChild(
          child: const Icon(Icons.image_outlined),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          label: 'Catatan Gambar',
          onTap: _pickImage,
        ),
      ],
    );
  }
} 
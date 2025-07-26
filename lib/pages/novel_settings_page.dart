import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:hive/hive.dart';
import 'package:yeyo/models/novel.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

// Helper function to run in a separate isolate and return bytes
Future<Uint8List?> _createZipData(String stagingPath) async {
  final archive = Archive();
  final stagingDir = Directory(stagingPath);

  if (!await stagingDir.exists()) {
    return null;
  }

  await for (final fileEntity in stagingDir.list(recursive: true)) {
    if (fileEntity is File) {
      final file = fileEntity;
      final filePath = file.path;
      final relativePath = p.relative(filePath, from: stagingPath);
      final fileBytes = await file.readAsBytes();
      archive.addFile(ArchiveFile(relativePath, fileBytes.length, fileBytes));
    }
  }

  final zipEncoder = ZipEncoder();
  final zipData = zipEncoder.encode(archive);

  if (zipData == null) {
    return null;
  }

  return Uint8List.fromList(zipData);
}

class NovelSettingsPage extends StatefulWidget {
  const NovelSettingsPage({super.key});

  @override
  State<NovelSettingsPage> createState() => _NovelSettingsPageState();
}

class _NovelSettingsPageState extends State<NovelSettingsPage> {
  bool _isProcessing = false;

  Future<void> _exportData() async {
    setState(() {
      _isProcessing = true;
    });

    Directory? stagingDir;

    try {
      final novelBox = Hive.box<Novel>('novels');
      if (novelBox.values.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak ada data untuk diekspor.')),
        );
        return;
      }

      final tempDir = await getTemporaryDirectory();
      stagingDir = Directory(p.join(tempDir.path, 'novel_export'));
      if (await stagingDir.exists()) {
        await stagingDir.delete(recursive: true);
      }
      final imagesDir = Directory(p.join(stagingDir.path, 'images'));
      await imagesDir.create(recursive: true);

      List<Map<String, dynamic>> metadata = [];

      for (var novel in novelBox.values) {
        String newImagePath = '';
        if (novel.imageUrl.isNotEmpty) {
          try {
            final imageName = p.basename(novel.imageUrl);
            final newImageFile = File(p.join(imagesDir.path, imageName));

            if (novel.imageUrl.startsWith('http')) {
              final response = await http.get(Uri.parse(novel.imageUrl));
              await newImageFile.writeAsBytes(response.bodyBytes);
            } else {
              final localImageFile = File(novel.imageUrl);
              if (await localImageFile.exists()) {
                await localImageFile.copy(newImageFile.path);
              }
            }
            newImagePath = p.join('images', imageName);
          } catch (e) {
            // Handle image processing error, maybe skip this image
          }
        }
        final novelJson = novel.toJson();
        novelJson['imageUrl'] = newImagePath;
        metadata.add(novelJson);
      }

      final metadataFile = File(p.join(stagingDir.path, 'metadata.json'));
      await metadataFile.writeAsString(jsonEncode(metadata));

      // Create zip data in a separate isolate
      final Uint8List? fileBytes = await compute(_createZipData, stagingDir.path);

      if (!mounted) return;

      if (fileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Ekspor gagal: Gagal membuat file ZIP.')),
        );
        return;
      }

      final fileName =
          'novel_backup_${DateTime.now().toIso8601String()}.zip';

      final params = SaveFileDialogParams(
        data: fileBytes,
        fileName: fileName,
      );
      final String? filePath = await FlutterFileDialog.saveFile(params: params);

      if (filePath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data berhasil diekspor ke: $filePath')),
      );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ekspor dibatalkan oleh pengguna.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ekspor gagal: $e')),
      );
    } finally {
      if (stagingDir != null && await stagingDir.exists()) {
        await stagingDir.delete(recursive: true);
      }
      if (mounted) {
      setState(() {
        _isProcessing = false;
      });
      }
    }
  }

  Future<void> _importData() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (result == null || result.files.single.path == null) return;

      final appDocsDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(p.join(appDocsDir.path, 'novel_images'));
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final tempDir = await getTemporaryDirectory();
      final unzipDir = Directory(p.join(tempDir.path, 'novel_import'));
      if (await unzipDir.exists()) await unzipDir.delete(recursive: true);
      await unzipDir.create();

      final inputStream = InputFileStream(result.files.single.path!);
      final archive = ZipDecoder().decodeBytes(inputStream.toUint8List());

      for (final file in archive) {
        final filename = p.join(unzipDir.path, file.name);
        if (file.isFile) {
          final outFile = File(filename);
          await outFile.create(recursive: true);
          await outFile.writeAsBytes(file.content as List<int>);
        }
      }

      final metadataFile = File(p.join(unzipDir.path, 'metadata.json'));
      if (!await metadataFile.exists()) {
        throw Exception('File metadata.json tidak ditemukan di dalam ZIP.');
      }

      final jsonString = await metadataFile.readAsString();
      final List<dynamic> metadata = jsonDecode(jsonString);

      final novelBox = Hive.box<Novel>('novels');
      await novelBox.clear();

      for (var novelJson in metadata) {
        String newImageUrl = '';
        final imageUrlFromJson = novelJson['imageUrl'];

        if (imageUrlFromJson != null && imageUrlFromJson.isNotEmpty) {
          // Check if the path is a URL (old format) or a relative path (new format)
          if (imageUrlFromJson.startsWith('http')) {
            // Old format: Download the image from the web
            try {
              final imageName = p.basename(Uri.parse(imageUrlFromJson).path);
              final newPermImageFile = File(p.join(imagesDir.path, imageName));
              final response = await http.get(Uri.parse(imageUrlFromJson));
              await newPermImageFile.writeAsBytes(response.bodyBytes);
              newImageUrl = newPermImageFile.path;
            } catch (e) {
              // Log error but continue
              debugPrint('Failed to download image during import: $imageUrlFromJson. Error: $e');
            }
          } else {
            // New format: Copy the image from the unzipped folder
            try {
              final importedImagePath = p.join(unzipDir.path, imageUrlFromJson);
              if (await File(importedImagePath).exists()) {
                final imageName = p.basename(importedImagePath);
                final newPermImagePath = p.join(imagesDir.path, imageName);
                await File(importedImagePath).copy(newPermImagePath);
                newImageUrl = newPermImagePath;
              }
            } catch (e) {
              // Log error but continue
              debugPrint('Failed to copy image during import: $imageUrlFromJson. Error: $e');
            }
          }
        }
        
        novelJson['imageUrl'] = newImageUrl;
        final novel = Novel.fromJson(novelJson);
        await novelBox.add(novel);
      }
      
      await unzipDir.delete(recursive: true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data berhasil diimpor!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impor gagal: $e')),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Novel'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isProcessing
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.file_upload),
                    label: const Text('Export Data (.zip)'),
                    onPressed: _exportData,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.file_download),
                    label: const Text('Import Data (.zip)'),
                    onPressed: _importData,
                  ),
                ],
              ),
      ),
    );
  }
} 
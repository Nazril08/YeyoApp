import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:yeyo/utils/image_downloader.dart';

class ReminiPage extends StatefulWidget {
  const ReminiPage({super.key});

  @override
  State<ReminiPage> createState() => _ReminiPageState();
}

class _ReminiPageState extends State<ReminiPage> {
  File? _image;
  String? _reminiImageUrl;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _reminiImageUrl = null;
      });
    }
  }

  Future<void> _reminiImage() async {
    if (_image == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Upload to catbox.moe to get a public URL
      final catboxRequest = http.MultipartRequest(
        'POST',
        Uri.parse('https://catbox.moe/user/api.php'),
      );
      catboxRequest.fields['reqtype'] = 'fileupload';
      catboxRequest.fields['userhash'] = ''; // Anonymous upload
      catboxRequest.files.add(await http.MultipartFile.fromPath('fileToUpload', _image!.path));
      final catboxStreamedResponse = await catboxRequest.send();
      final catboxResponse = await http.Response.fromStream(catboxStreamedResponse);

      if (catboxResponse.statusCode != 200) {
        throw Exception('Failed to upload to catbox.moe: ${catboxResponse.body}');
      }
      final imageUrl = catboxResponse.body;

      // 2. Call the Remini API
      final encodedUrl = Uri.encodeComponent(imageUrl);
      final reminiApiUrl = 'https://zenz.biz.id/tools/remini?url=$encodedUrl';
      
      final reminiResponse = await http.get(Uri.parse(reminiApiUrl));

      if (reminiResponse.statusCode != 200) {
        throw Exception('Remini process failed: ${reminiResponse.body}');
      }

      final data = json.decode(reminiResponse.body);

      if (data['status'] != true || data['result']?['result_url'] == null) {
        throw Exception('Remini process failed: ${json.encode(data)}');
      }

      setState(() {
        _reminiImageUrl = data['result']['result_url'];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Remini Upscaler'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo_library),
              label: const Text('Select Image'),
            ),
            const SizedBox(height: 16),
            if (_image != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(_image!),
                ),
              ),
            
            if (_image != null)
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _reminiImage,
                icon: const Icon(Icons.auto_fix_high),
                label: const Text('Upscale with Remini'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32.0),
                child: Center(child: CircularProgressIndicator()),
              ),
            
            if (_reminiImageUrl != null)
              Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: Column(
                  children: [
                    const Text('Upscaled Image:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Stack(
                      alignment: Alignment.topRight,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(_reminiImageUrl!),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: FloatingActionButton(
                            mini: true,
                            onPressed: () => ImageDownloader.downloadImage(context, _reminiImageUrl!),
                            child: const Icon(Icons.download),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
} 
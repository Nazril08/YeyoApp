import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:yeyo/utils/image_downloader.dart';

class MosynePage extends StatefulWidget {
  const MosynePage({super.key});

  @override
  State<MosynePage> createState() => _MosynePageState();
}

class _MosynePageState extends State<MosynePage> {
  File? _image;
  String? _processedImageUrl;
  bool _isLoading = false;
  String _statusMessage = '';

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _processedImageUrl = null;
      });
    }
  }

  Future<String> _uploadToUguu(File image) async {
    setState(() {
      _statusMessage = 'Uploading image...';
    });
    final request = http.MultipartRequest('POST', Uri.parse('https://uguu.se/upload.php'));
    request.files.add(await http.MultipartFile.fromPath('files[]', image.path));
    
    final response = await request.send();
    
    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      final decodedData = json.decode(responseData);
      final url = decodedData['files']?[0]?['url'];
      if (url != null) {
        return url;
      }
    }
    throw Exception('Failed to upload to Uguu.se');
  }

  Future<void> _processImage(String type) async {
    if (_image == null) return;

    setState(() {
      _isLoading = true;
      _processedImageUrl = null;
    });

    try {
      final imageUrl = await _uploadToUguu(_image!);

      setState(() {
        _statusMessage = 'Initializing process...';
      });

      final headers = {
        'accept': 'application/json, text/plain, */*',
        'content-type': 'application/json',
        'origin': 'https://mosyne.ai',
        'referer': 'https://mosyne.ai/ai/${type == 'upscale' ? 'upscaling' : 'remove-bg'}',
        'user-agent': 'Mozilla/5.0 (X11; Linux x86_64)',
      };
      
      const userId = 'user_test';
      
      final initResponse = await http.post(
        Uri.parse('https://mosyne.ai/api/$type'),
        headers: headers,
        body: json.encode({'image': imageUrl, 'user_id': userId}),
      );
      
      final initData = json.decode(initResponse.body);
      final String? id = initData['id'];

      if (id == null) {
        throw Exception('Failed to get process ID.');
      }

      // Polling for status
      for (int i = 0; i < 30; i++) {
        setState(() {
          _statusMessage = 'Processing... (Attempt ${i + 1}/30)';
        });
        
        await Future.delayed(const Duration(seconds: 2));
        
        final statusResponse = await http.post(
          Uri.parse('https://mosyne.ai/api/status'),
          headers: headers,
          body: json.encode({'id': id, 'type': type, 'user_id': userId}),
        );
        
        final statusData = json.decode(statusResponse.body);

        if (statusData['status'] == 'COMPLETED' && statusData['image'] != null) {
          dynamic imageData = statusData['image'];
          String? finalImageUrl;
          if (imageData is List && imageData.isNotEmpty) {
            finalImageUrl = imageData.first as String?;
          } else if (imageData is String) {
            finalImageUrl = imageData;
          }

          if (finalImageUrl != null) {
            setState(() {
              _processedImageUrl = finalImageUrl;
              _statusMessage = 'Completed!';
            });
            return;
          }
        }

        if (statusData['status'] == 'FAILED') {
          throw Exception('Processing failed.');
        }
      }
      
      throw Exception('Processing timed out.');

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
        _statusMessage = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mosyne AI Tools'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _pickImage,
              icon: const Icon(Icons.photo_library),
              label: const Text('Select Image'),
            ),
            const SizedBox(height: 16),
            if (_image != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(_image!),
                ),
              ),
            
            if (_image != null)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : () => _processImage('remove_background'),
                      icon: const Icon(Icons.layers_clear),
                      label: const Text('Remove BG'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : () => _processImage('upscale'),
                      icon: const Icon(Icons.zoom_in_map),
                      label: const Text('Upscale'),
                    ),
                  ),
                ],
              ),
            
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32.0),
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(_statusMessage, style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            
            if (_processedImageUrl != null)
              Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: Column(
                  children: [
                    const Text('Processed Image:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Stack(
                      alignment: Alignment.topRight,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(_processedImageUrl!),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: FloatingActionButton(
                            mini: true,
                            onPressed: () => ImageDownloader.downloadImage(context, _processedImageUrl!),
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
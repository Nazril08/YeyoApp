import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:yeyo/utils/image_downloader.dart';

class UpscalerPage extends StatefulWidget {
  const UpscalerPage({super.key});

  @override
  State<UpscalerPage> createState() => _UpscalerPageState();
}

class _UpscalerPageState extends State<UpscalerPage> {
  File? _image;
  String? _upscaledImageUrl;
  bool _isUpscaling = false;
  String _resolution = '1080p';

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _upscaledImageUrl = null;
      });
    }
  }

  Future<void> _upscaleImage() async {
    if (_image == null) return;

    setState(() {
      _isUpscaling = true;
    });

    try {
      // 1. Upload to catbox.moe
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

      // 2. Call the upscale API
      final upscaleRequest = http.MultipartRequest(
        'POST',
        Uri.parse('https://upscale.cloudkuimages.guru/hd.php'),
      );
      upscaleRequest.headers.addAll({
        'origin': 'https://upscale.cloudkuimages.guru',
        'referer': 'https://upscale.cloudkuimages.guru/',
      });
      upscaleRequest.fields['resolution'] = _resolution;
      upscaleRequest.fields['enhance'] = 'false';

      // We need to re-download the image from the new URL to send it to the upscaler
      final imageResponse = await http.get(Uri.parse(imageUrl));
      upscaleRequest.files.add(http.MultipartFile.fromBytes(
        'image',
        imageResponse.bodyBytes,
        filename: 'image.jpg', // Filename is required
      ));

      final upscaleStreamedResponse = await upscaleRequest.send();
      final upscaleResponse = await http.Response.fromStream(upscaleStreamedResponse);

      if (upscaleResponse.statusCode != 200) {
        throw Exception('Upscale failed: ${upscaleResponse.body}');
      }

      final data = json.decode(upscaleResponse.body);

      if (data['status'] != 'success') {
        throw Exception('Upscale failed: ${json.encode(data)}');
      }

      setState(() {
        _upscaledImageUrl = data['data']['url'];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() {
        _isUpscaling = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Upscaler'),
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
            const Text('Options', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            DropdownButtonFormField<String>(
              value: _resolution,
              decoration: const InputDecoration(labelText: 'Resolution'),
              items: ['480p', '720p', '1080p', '2k', '4k', '8k', '12k']
                  .map((label) => DropdownMenuItem(
                        value: label,
                        child: Text(label),
                      ))
                  .toList(),
              onChanged: _image == null
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() {
                          _resolution = value;
                        });
                      }
                    },
            ),
            if (_image != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isUpscaling ? null : _upscaleImage,
                icon: const Icon(Icons.arrow_upward),
                label: const Text('Upscale Image'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
            if (_isUpscaling)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32.0),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (_upscaledImageUrl != null)
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
                          child: Image.network(_upscaledImageUrl!),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: FloatingActionButton(
                            mini: true,
                            onPressed: () => ImageDownloader.downloadImage(context, _upscaledImageUrl!),
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
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';

class ImageDownloader {
  static Future<void> downloadImage(BuildContext context, String imageUrl) async {
    try {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Downloading image...')),
        );
      }

      // 1. Check for permission
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        final granted = await Gal.requestAccess();
        if (!granted) {
          throw Exception('Storage permission denied.');
        }
      }

      // 2. Download the image to a temporary file
      final tempDir = await getTemporaryDirectory();
      final path = '${tempDir.path}/yeyo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await Dio().download(imageUrl, path);

      // 3. Save the image from the temporary file to the gallery
      await Gal.putImage(path, album: 'Yeyo');

      // 4. Clean up the temporary file
      await File(path).delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image saved to "Yeyo" album!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 
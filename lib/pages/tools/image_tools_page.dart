import 'package:flutter/material.dart';
import 'package:yeyo/pages/tools/remini_page.dart';
import 'package:yeyo/pages/tools/upscaler_page.dart';
import 'package:yeyo/pages/tools/mosyne_page.dart';

class ImageToolsPage extends StatelessWidget {
  const ImageToolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Tools'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildToolCard(
              context,
              title: 'Upscaler',
              description: 'Increase image resolution.',
              icon: Icons.high_quality,
              color: Colors.deepPurple,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UpscalerPage()),
                );
              },
            ),
            _buildToolCard(
              context,
              title: 'Remini Upscaler',
              description: 'Enhance images using Remini.',
              icon: Icons.auto_awesome,
              color: Colors.blueAccent,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ReminiPage()),
                );
              },
            ),
            _buildToolCard(
              context,
              title: 'Mosyne AI',
              description: 'Upscale or remove background.',
              icon: Icons.auto_fix_normal,
              color: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MosynePage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 5,
        shadowColor: Colors.black.withOpacity(0.15),
        color: color,
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            Positioned(
              bottom: -15,
              right: -15,
              child: Icon(
                icon,
                size: 90,
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
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
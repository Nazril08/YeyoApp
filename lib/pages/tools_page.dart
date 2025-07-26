import 'package:flutter/material.dart';
import 'package:yeyo/pages/tools/image_tools_page.dart';

class ToolsPage extends StatelessWidget {
  const ToolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tools'),
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
              title: 'Images',
              icon: Icons.image,
              color: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ImageToolsPage()),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 
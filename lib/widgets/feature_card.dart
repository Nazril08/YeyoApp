import 'package:flutter/material.dart';

class FeatureCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const FeatureCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48.0, color: Theme.of(context).primaryColor),
            const SizedBox(height: 16.0),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final String status;
  final String normalRange;
  final Color color;
  final IconData icon;
  final String? unit;

  const DashboardCard({
    super.key,
    required this.title,
    required this.value,
    required this.status,
    required this.normalRange,
    required this.color,
    required this.icon,
    this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                      if (unit != null) ...[
                        const SizedBox(width: 4),
                        Text(unit!, style: const TextStyle(fontSize: 20)),
                      ],
                    ],
                  ),
                  Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
                  Text('Normal range: $normalRange', style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
            CircleAvatar(
              radius: 28,
              backgroundColor: color.withOpacity(0.1),
              child: Text(
                value,
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 
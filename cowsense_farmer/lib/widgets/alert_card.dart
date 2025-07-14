import 'package:flutter/material.dart';
import '../models/alert.dart';

class AlertCard extends StatelessWidget {
  final Alert alert;
  const AlertCard({super.key, required this.alert});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: alert.isCritical ? const Color(0xFFCB2213) : Colors.orange[50],
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error,
                color: alert.isCritical
                    ? Theme.of(context).colorScheme.primary
                    : Colors.orange,
                size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(alert.message,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: alert.isCritical
                              ? Theme.of(context).colorScheme.primary
                              : Colors.orange)),
                  const SizedBox(height: 4),
                  Text(alert.value,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                      '${alert.time.hour.toString().padLeft(2, '0')}:${alert.time.minute.toString().padLeft(2, '0')}:${alert.time.second.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

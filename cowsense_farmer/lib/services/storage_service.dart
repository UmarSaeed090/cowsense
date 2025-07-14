import 'package:hive_flutter/hive_flutter.dart';
import '../models/alert.dart';

class StorageService {
  static const String _alertsBoxName = 'alerts';
  late Box _alertsBox; // Using untyped box

  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;

  StorageService._internal();
  Future<void> initialize() async {
    await Hive.initFlutter();

    // Register the Alert adapter
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(AlertAdapter());
    }

    // Clean up the box first if needed
    if (await Hive.boxExists(_alertsBoxName)) {
      await Hive.deleteBoxFromDisk(_alertsBoxName);
      print('Deleted existing alerts box to avoid migration issues');
    }

    _alertsBox = await Hive.openBox(_alertsBoxName);
  }

  Future<void> storeAlert(String tagNumber, Alert alert) async {
    try {
      print('Storing alert for tag: $tagNumber');

      // Convert alert to JSON for reliable storage
      Map<String, dynamic> alertJson = alert.toJson();

      // Retrieve existing alerts as JSON maps
      List<dynamic> existingAlerts = _alertsBox.get(tagNumber) ?? [];
      print('Retrieved ${existingAlerts.length} existing alerts');

      // Insert the new alert at the beginning
      List<Map<String, dynamic>> alertsList = [];

      // Add the new alert first
      alertsList.add(alertJson);

      // Add existing alerts
      for (var item in existingAlerts) {
        if (item is Map) {
          try {
            alertsList.add(Map<String, dynamic>.from(item));
          } catch (e) {
            print('Error adding existing alert: $e');
          }
        }
      }

      // Store the list back in Hive
      await _alertsBox.put(tagNumber, alertsList);
      print(
          'Successfully stored alert for tag: $tagNumber (total: ${alertsList.length})');
    } catch (e) {
      print('Error storing alert in Hive: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }

  Future<Map<String, List<Alert>>> getAlerts() async {
    try {
      Map<String, List<Alert>> alertsMap = {};
      print('Getting all alerts from Hive');

      // Process each key (tag number) in the box
      for (var key in _alertsBox.keys) {
        if (key is String) {
          print('Processing tag: $key');

          // Get the raw data
          dynamic rawData = _alertsBox.get(key);

          if (rawData is List) {
            print('Found list for $key with ${rawData.length} items');
            List<Alert> alerts = [];

            // Process each item in the list
            for (var item in rawData) {
              if (item is Map) {
                try {
                  // Create an Alert from the map safely
                  final type = item['type']?.toString() ?? 'unknown';
                  final message = item['message']?.toString() ?? 'unknown';
                  final value = item['value']?.toString() ?? 'unknown';

                  // Handle different time formats
                  DateTime time;
                  if (item['time'] is DateTime) {
                    time = item['time'];
                  } else if (item['time'] is String) {
                    time = DateTime.tryParse(item['time']) ?? DateTime.now();
                  } else {
                    time = DateTime.now();
                  }

                  // Extract remaining fields with defaults
                  final isCritical = item['isCritical'] == true;
                  final read = item['read'] == true;
                  final tagNumber = item['tagNumber']?.toString() ?? key;

                  Alert alert = Alert(
                    type: type,
                    message: message,
                    value: value,
                    time: time,
                    isCritical: isCritical,
                    read: read,
                    tagNumber: tagNumber,
                  );

                  alerts.add(alert);
                } catch (e) {
                  print('Error parsing alert item: $e');
                }
              } else if (item is Alert) {
                // Already an Alert object
                alerts.add(item);
              }
            }

            alertsMap[key] = alerts;
            print('Added ${alerts.length} alerts for tag: $key');
          } else {
            alertsMap[key] = [];
          }
        }
      }

      print('Retrieved alerts for ${alertsMap.length} animals');
      return alertsMap;
    } catch (e) {
      print('Error getting alerts from Hive: $e');
      print('Stack trace: ${StackTrace.current}');
      return {};
    }
  }

  Future<void> clearAlerts() async {
    await _alertsBox.clear();
  }

  Future<void> dispose() async {
    await _alertsBox.close();
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:cowsense/providers/sensor_provider.dart';
import 'package:cowsense/services/sensor_service.dart';
import 'package:cowsense/services/notification_service.dart';
import 'package:cowsense/models/alert.dart';

// Simple mock classes without using mockito package
class MockSensorService implements SensorService {
  @override
  bool get isInitialized => true;

  @override
  static String get baseUrl => 'http://localhost:3000';

  @override
  void dispose() {}

  @override
  Future<List<dynamic>> getHistoricalData(DateTime date) async => [];

  @override
  void subscribeToCows(List<String> cowIds) {}

  @override
  void subscribeToRealTimeData(Function(dynamic) onData) {}
}

class MockNotificationService implements NotificationService {
  @override
  String? get activeChatRoomId => null;

  @override
  set activeChatRoomId(String? roomId) {}

  @override
  set sensorProvider(provider) {}

  @override
  Stream<dynamic> get onNotificationClick => Stream.empty();

  @override
  Future<void> initialize() async {}

  @override
  void listenForChatMessages(String currentUserId) {}

  @override
  Future<void> subscribeToTopic(String topic) async {}

  @override
  Future<void> unsubscribeFromTopic(String topic) async {}

  @override
  void dispose() {}
}

void main() {
  group('SensorProvider Subscription Tests', () {
    late SensorProvider sensorProvider;
    late MockSensorService mockSensorService;
    late MockNotificationService mockNotificationService;

    setUp(() {
      mockSensorService = MockSensorService();
      mockNotificationService = MockNotificationService();
      sensorProvider =
          SensorProvider(mockSensorService, mockNotificationService);
    });

    test('should only add alerts for subscribed tag numbers', () {
      // Arrange
      const subscribedTag = 'cow_001';
      const unsubscribedTag = 'device_001';

      // Set up subscriptions
      sensorProvider.updateSubscriptions([subscribedTag]);

      // Create test alerts
      final subscribedAlert = Alert(
        type: 'test',
        message: 'Test alert for subscribed cow',
        value: 'High temperature',
        time: DateTime.now(),
        isCritical: true,
        read: false,
        tagNumber: subscribedTag,
      );

      final unsubscribedAlert = Alert(
        type: 'test',
        message: 'Test alert for unsubscribed device',
        value: 'High temperature',
        time: DateTime.now(),
        isCritical: true,
        read: false,
        tagNumber: unsubscribedTag,
      );

      // Act
      sensorProvider.addAlert(subscribedAlert);
      sensorProvider.addAlert(unsubscribedAlert);

      // Assert
      final subscribedAlerts = sensorProvider.getAlertsForAnimal(subscribedTag);
      final unsubscribedAlerts =
          sensorProvider.getAlertsForAnimal(unsubscribedTag);

      expect(subscribedAlerts.length, 1);
      expect(unsubscribedAlerts.length, 0);
      expect(subscribedAlerts.first.message, 'Test alert for subscribed cow');
    });

    test('should check subscription status correctly', () {
      // Arrange
      const subscribedTag = 'cow_001';
      const unsubscribedTag = 'device_001';

      // Set up subscriptions
      sensorProvider.updateSubscriptions([subscribedTag]);

      // Act & Assert
      expect(sensorProvider.isSubscribedToTag(subscribedTag), true);
      expect(sensorProvider.isSubscribedToTag(unsubscribedTag), false);
    });

    test('should only add notification alerts for subscribed tag numbers', () {
      // Arrange
      const subscribedTag = 'cow_001';
      const unsubscribedTag = 'device_001';

      // Set up subscriptions
      sensorProvider.updateSubscriptions([subscribedTag]);

      // Act
      sensorProvider.addAlertFromNotification(
          'Alert', 'High temperature', subscribedTag);
      sensorProvider.addAlertFromNotification(
          'Alert', 'High temperature', unsubscribedTag);

      // Assert
      final subscribedAlerts = sensorProvider.getAlertsForAnimal(subscribedTag);
      final unsubscribedAlerts =
          sensorProvider.getAlertsForAnimal(unsubscribedTag);

      expect(subscribedAlerts.length, 1);
      expect(unsubscribedAlerts.length, 0);
    });
  });
}

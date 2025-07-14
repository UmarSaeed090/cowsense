import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:rxdart/rxdart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/chat_message_model.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/sensor_provider.dart';
import '../providers/auth_provider.dart' as app;
import 'package:firebase_core/firebase_core.dart';
import '../models/alert.dart';
import 'storage_service.dart';

class NotificationPayload {
  final String chatRoomId;
  final String senderId;

  NotificationPayload({required this.chatRoomId, required this.senderId});

  factory NotificationPayload.fromJson(Map<String, dynamic> json) {
    return NotificationPayload(
      chatRoomId: json['chatRoomId'] ?? '',
      senderId: json['senderId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'chatRoomId': chatRoomId,
        'senderId': senderId,
      };

  @override
  String toString() {
    return '{"chatRoomId": "$chatRoomId", "senderId": "$senderId"}';
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static bool _isBackgroundHandlerRegistered = false;
  factory NotificationService() => _instance;

  NotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final BehaviorSubject<NotificationPayload?> _selectedNotificationSubject =
      BehaviorSubject<NotificationPayload?>();

  // Track active chat room to prevent notifications when user is in that chat
  String? _activeChatRoomId;
  SensorProvider? _sensorProvider;

  final StorageService _storageService = StorageService();

  // Setter for active chat room
  set activeChatRoomId(String? roomId) {
    debugPrint('Setting active chat room: $roomId');
    _activeChatRoomId = roomId;
  }

  // Setter for sensor provider
  set sensorProvider(SensorProvider provider) {
    _sensorProvider = provider;
  }

  Stream<NotificationPayload?> get onNotificationClick =>
      _selectedNotificationSubject.stream;

  Future<void> initialize() async {
    // Ensure Flutter bindings are initialized
    WidgetsFlutterBinding.ensureInitialized();

    // Check if user is authenticated
    if (FirebaseAuth.instance.currentUser == null) {
      debugPrint('User not authenticated - notifications disabled');
      return;
    }

    // Initialize AwesomeNotifications
    final isAwesomeInitialized = await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'sensor_alerts',
          channelName: 'Sensor Alerts',
          channelDescription: 'Notifications for sensor alerts',
          defaultColor: Colors.green,
          ledColor: Colors.green,
          importance: NotificationImportance.High,
          channelShowBadge: true,
          enableVibration: true,
          playSound: true,
        ),
        NotificationChannel(
          channelKey: 'chat_messages',
          channelName: 'Chat Messages',
          channelDescription: 'Notifications for new chat messages',
          defaultColor: Colors.blue,
          ledColor: Colors.blue,
          importance: NotificationImportance.High,
          channelShowBadge: true,
          enableVibration: true,
          playSound: true,
        ),
      ],
    );
    debugPrint('AwesomeNotifications initialized: $isAwesomeInitialized');

    // Check if notifications are allowed
    final isAllowed = await AwesomeNotifications().isNotificationAllowed();
    debugPrint('Notifications allowed: $isAllowed');
    if (!isAllowed) {
      // Request permission if not granted
      final isNowAllowed =
          await AwesomeNotifications().requestPermissionToSendNotifications();
      debugPrint('Notification permission request result: $isNowAllowed');
    }

    // Set up notification action handlers
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: onActionReceivedMethod,
    );

    // Request FCM permission
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('FCM authorization status: ${settings.authorizationStatus}');

    // Get FCM token
    String? token = await _messaging.getToken();
    if (token != null) {
      debugPrint('FCM Token obtained: ${token.substring(0, 10)}...');
      await _saveTokenToDatabase(token);
    } else {
      debugPrint('Failed to get FCM token');
    }

    // Listen to token refresh
    _messaging.onTokenRefresh.listen((token) {
      debugPrint('FCM Token refreshed: ${token.substring(0, 10)}...');
      _saveTokenToDatabase(token);
    });

    // Handle incoming messages when app is in foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Register background handler only once
    if (!_isBackgroundHandlerRegistered) {
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);
      _isBackgroundHandlerRegistered = true;
    }
  }

  Future<void> _saveTokenToDatabase(String token) async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
      });
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Received foreground message: ${message.data}');

    // Check if user is authenticated
    if (FirebaseAuth.instance.currentUser == null) {
      debugPrint('User not authenticated - ignoring notification');
      return;
    }

    // Show local notification when app is in foreground
    RemoteNotification? notification = message.notification;
    if (notification != null) {
      // Use the correct channel for sensor alerts
      final channelKey = message.data['type'] == 'sensor_alert'
          ? 'sensor_alerts'
          : 'chat_messages';

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: notification.hashCode,
          channelKey: channelKey,
          title: notification.title ?? '',
          body: notification.body ?? '',
          payload: Map<String, String>.from(message.data
              .map((key, value) => MapEntry(key, value.toString()))),
          notificationLayout: NotificationLayout.Default,
          icon: 'resource://drawable/notification_icon',
        ),
      );

      // Handle sensor alerts
      if (message.data['type'] == 'sensor_alert') {
        final tagNumber = message.data['tagNumber'];
        if (tagNumber != null) {
          try {
            if (_sensorProvider != null) {
              debugPrint('Using sensor provider directly');
              _sensorProvider!.addAlertFromNotification(
                notification.title ?? 'Alert',
                notification.body ?? '',
                tagNumber,
              );
              debugPrint('Alert added to sensor provider');
            } else {
              debugPrint(
                  'Sensor provider not available, storing in SharedPreferences');
              await _storeAlertInSharedPreferences(
                notification.title ?? 'Alert',
                notification.body ?? '',
                tagNumber,
              );
            }
          } catch (e) {
            debugPrint('Error handling sensor alert: $e');
            await _storeAlertInSharedPreferences(
              notification.title ?? 'Alert',
              notification.body ?? '',
              tagNumber,
            );
          }
        }
      }
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    // Check if user is authenticated
    if (FirebaseAuth.instance.currentUser == null) {
      debugPrint('User not authenticated - ignoring notification tap');
      return;
    }

    // Handle notification tap when app is in background
    String? chatRoomId = message.data['chatRoomId'];
    if (chatRoomId != null) {
      // Navigate to chat room
      // You'll need to implement navigation logic here
    }

    // Handle sensor alerts
    if (message.data['type'] == 'sensor_alert') {
      final tagNumber = message.data['tagNumber'];
      if (tagNumber != null) {}
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    debugPrint('Subscribed to topic: $topic');
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    debugPrint('Unsubscribed from topic: $topic');
  }

  // Listen for new messages to show notifications
  void listenForChatMessages(String currentUserId) {
    // Check if user is authenticated
    if (FirebaseAuth.instance.currentUser == null) {
      debugPrint('User not authenticated - chat message listener disabled');
      return;
    }

    // Listen for new messages where user is the receiver
    _firestore
        .collectionGroup('messages')
        .where('receiverId', isEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snapshot) async {
      for (final change in snapshot.docChanges) {
        // Only process newly added messages
        if (change.type == DocumentChangeType.added) {
          final message = ChatMessage.fromMap(change.doc.data() ?? {});
          final senderId = message.senderId;
          final chatRoomId = change.doc.reference.parent.parent?.id ?? '';

          // Skip notification if user is currently in this chat
          if (_activeChatRoomId == chatRoomId) {
            debugPrint(
                'User is in chat room $chatRoomId - skipping notification');
            continue;
          }

          // Get sender name from Firestore
          final senderDoc =
              await _firestore.collection('users').doc(senderId).get();
          final senderName = senderDoc.data()?['name'] ?? 'User';

          // Create payload with both chatRoomId and senderId
          final payload = NotificationPayload(
            chatRoomId: chatRoomId,
            senderId: senderId,
          );

          // Show notification
          _showLocalNotification(
            id: message.id.hashCode,
            title: senderName,
            body: message.type == MessageType.text
                ? message.content
                : _getContentByMessageType(message.type),
            payload: payload.toString(),
          );
        }
      }
    });
  }

  String _getContentByMessageType(MessageType type) {
    switch (type) {
      case MessageType.image:
        return '📷 Image';
      case MessageType.call:
        return '📞 Call';
      default:
        return 'New message';
    }
  }

  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'chat_messages',
        title: title,
        body: body,
        payload: {'payload': payload},
        notificationLayout: NotificationLayout.Default,
        icon: 'resource://drawable/notification_icon',
      ),
    );
  }

  Future<void> _storeAlertInSharedPreferences(
      String title, String body, String tagNumber) async {
    try {
      // Check if sensor provider is available and user is subscribed
      if (_sensorProvider != null &&
          !_sensorProvider!.isSubscribedToTag(tagNumber)) {
        debugPrint('Ignoring alert for unsubscribed tag: $tagNumber');
        return;
      }

      // If sensor provider is not available, check Firebase directly
      if (_sensorProvider == null) {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          try {
            final userDoc =
                await _firestore.collection('users').doc(currentUser.uid).get();

            if (userDoc.exists) {
              final userData = userDoc.data();
              final cowIds = List<String>.from(userData?['cows'] ?? []);

              if (!cowIds.contains(tagNumber)) {
                debugPrint(
                    'Ignoring alert for unsubscribed tag: $tagNumber (Firebase check)');
                return;
              }
            }
          } catch (e) {
            debugPrint('Error checking subscription from Firebase: $e');
            // In case of error, don't store the alert to be safe
            return;
          }
        }
      }

      final alert = Alert(
        type: 'Notification',
        message: title,
        value: body,
        time: DateTime.now(),
        isCritical: true,
        read: false,
        tagNumber: tagNumber,
      );

      await _storageService.storeAlert(tagNumber, alert);
      debugPrint('Stored sensor alert for $tagNumber');
    } catch (e) {
      debugPrint('Error storing sensor alert: $e');
    }
  }

  void dispose() {
    _selectedNotificationSubject.close();
  }
}

// This needs to be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  if (FirebaseAuth.instance.currentUser == null) {
    debugPrint('User not authenticated - ignoring notification');
    return;
  }

  if (message.data['type'] == 'sensor_alert') {
    final tagNumber = message.data['tagNumber'];
    if (tagNumber != null) {
      try {
        // Check if user is subscribed to this tag number
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get();

          if (userDoc.exists) {
            final userData = userDoc.data();
            final cowIds = List<String>.from(userData?['cows'] ?? []);

            if (!cowIds.contains(tagNumber)) {
              debugPrint(
                  'Ignoring background alert for unsubscribed tag: $tagNumber');
              return;
            }
          }
        }

        final authProvider = app.AuthProvider();
        final context = authProvider.navigatorKey.currentContext;
        if (context != null) {
          Provider.of<SensorProvider>(context, listen: false)
              .addAlertFromNotification(
            message.notification?.title ?? 'Alert',
            message.notification?.body ?? '',
            tagNumber,
          );
        } else {
          final storageService = StorageService();
          final alert = Alert(
            type: 'Notification',
            message: message.notification?.title ?? 'Alert',
            value: message.notification?.body ?? '',
            time: DateTime.now(),
            isCritical: true,
            read: false,
            tagNumber: tagNumber,
          );

          await storageService.storeAlert(tagNumber, alert);
          debugPrint('Stored background sensor alert for $tagNumber');
        }
      } catch (e) {
        debugPrint('Error handling background sensor alert: $e');
      }
    }
  }
}

// This needs to be a top-level function
@pragma('vm:entry-point')
Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
  if (receivedAction.payload != null) {
    try {
      final payload = NotificationPayload.fromJson(
          jsonDecode(receivedAction.payload!['payload'] ?? '{}'));
      // You might want to handle this differently in background
      debugPrint(
          'Received notification action in background: ${payload.toString()}');
    } catch (e) {
      debugPrint('Error handling notification action in background: $e');
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';

class FCMService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // Function to send notifications using Firebase Cloud Functions
  Future<void> sendChatNotification({
    required String receiverId,
    required String senderId,
    required String senderName,
    required String messageContent,
    required String roomId,
  }) async {
    try {
      // Call Firebase Cloud Function
      final result =
          await _functions.httpsCallable('sendChatNotification').call({
        'receiverId': receiverId,
        'messageContent': messageContent,
        'roomId': roomId,
        // Note: senderId is automatically included in the context.auth
      });

      debugPrint('FCM notification sent with result: ${result.data}');
    } catch (e) {
      debugPrint('Error calling sendChatNotification function: $e');
    }
  }
}

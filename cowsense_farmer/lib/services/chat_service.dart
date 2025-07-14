import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import '../models/chat_message_model.dart';
import '../models/chat_room_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  // Create or get chat room
  Future<String> createOrGetChatRoom(String userId, String otherUserId,
      {String? serviceId}) async {
    // Sort user IDs to ensure consistent room ID
    final List<String> participants = [userId, otherUserId]..sort();

    // Check if a chat room already exists
    final querySnapshot = await _firestore
        .collection('chatRooms')
        .where('participants', isEqualTo: participants)
        .limit(1)
        .get();

    // Return existing chat room if it exists
    if (querySnapshot.docs.isNotEmpty) {
      final existingRoomId = querySnapshot.docs.first.id;

      // If room exists but was deleted by this user, restore it by removing from deletedBy
      final Map<String, dynamic> data = querySnapshot.docs.first.data();
      if (data.containsKey('deletedBy') &&
          (data['deletedBy'] as List<dynamic>).contains(userId)) {
        await _firestore.collection('chatRooms').doc(existingRoomId).update({
          'deletedBy': FieldValue.arrayRemove([userId])
        });
      }

      return existingRoomId;
    }

    // Create a new chat room
    final String roomId = _uuid.v4();
    final ChatRoom newChatRoom = ChatRoom(
      id: roomId,
      participants: participants,
      lastMessageTime: DateTime.now(),
      lastMessageContent: '',
      lastMessageSenderId: userId,
      isServiceRequest: serviceId != null,
      tagNumber: serviceId,
      unreadCount: {
        userId: 0,
        otherUserId: 0,
      },
      deletedBy: [], // Initialize with empty list of users who deleted the chat
    );

    await _firestore
        .collection('chatRooms')
        .doc(roomId)
        .set(newChatRoom.toMap());

    debugPrint('Chat room created with ID: $roomId');
    return roomId;
  }

  // Send a text message
  Future<void> sendTextMessage(
      String roomId, String senderId, String receiverId, String content) async {
    final message = ChatMessage(
      id: _uuid.v4(),
      senderId: senderId,
      receiverId: receiverId,
      content: content,
      type: MessageType.text,
      timestamp: DateTime.now(),
      isRead: false,
    );

    // Add message to the messages subcollection
    await _firestore
        .collection('chatRooms')
        .doc(roomId)
        .collection('messages')
        .doc(message.id)
        .set(message.toMap());

    // Update chat room with last message info
    await _updateChatRoomLastMessage(roomId, message, receiverId);

    // If any participant previously deleted this chat, restore it for them
    // since there's new activity
    final roomDoc = await _firestore.collection('chatRooms').doc(roomId).get();
    if (roomDoc.exists) {
      final roomData = roomDoc.data() as Map<String, dynamic>;
      if (roomData.containsKey('deletedBy') &&
          (roomData['deletedBy'] as List<dynamic>).isNotEmpty) {
        await _firestore.collection('chatRooms').doc(roomId).update({
          'deletedBy': [] // Reset deletedBy list when new messages arrive
        });
      }
    }
  }

  // Send an image message
  Future<void> sendImageMessage(
      String roomId, String senderId, String receiverId, File imageFile) async {
    try {
      // Create a unique filename
      final String fileName =
          '$roomId-${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';

      // Create a reference to the file path
      final Reference storageRef =
          _storage.ref().child('chat_images').child(fileName);

      // Upload the file
      await storageRef.putFile(imageFile);

      // Get the download URL
      final String downloadURL = await storageRef.getDownloadURL();

      // Create the message
      final message = ChatMessage(
        id: _uuid.v4(),
        senderId: senderId,
        receiverId: receiverId,
        content: 'Image',
        type: MessageType.image,
        timestamp: DateTime.now(),
        isRead: false,
        mediaUrl: downloadURL,
      );

      // Add message to the messages subcollection
      await _firestore
          .collection('chatRooms')
          .doc(roomId)
          .collection('messages')
          .doc(message.id)
          .set(message.toMap());

      // Update chat room with last message info
      await _updateChatRoomLastMessage(roomId, message, receiverId);

      // Reset deletedBy list when new messages arrive
      await _firestore
          .collection('chatRooms')
          .doc(roomId)
          .update({'deletedBy': []});
    } catch (e) {
      debugPrint('Error sending image message: $e');
      throw e;
    }
  }

  // Send a call message
  Future<void> sendCallMessage(String roomId, String senderId,
      String receiverId, bool isVideoCall) async {
    final message = ChatMessage(
      id: _uuid.v4(),
      senderId: senderId,
      receiverId: receiverId,
      content: isVideoCall ? 'Video Call' : 'Voice Call',
      type: MessageType.call,
      timestamp: DateTime.now(),
      isRead: false,
    );

    // Add message to the messages subcollection
    await _firestore
        .collection('chatRooms')
        .doc(roomId)
        .collection('messages')
        .doc(message.id)
        .set(message.toMap());

    // Update chat room with last message info
    await _updateChatRoomLastMessage(roomId, message, receiverId);

    // Reset deletedBy list when new messages arrive
    await _firestore
        .collection('chatRooms')
        .doc(roomId)
        .update({'deletedBy': []});
  }

  // Update chat room with last message info
  Future<void> _updateChatRoomLastMessage(
      String roomId, ChatMessage message, String receiverId) async {
    // Get current unread count
    final roomDoc = await _firestore.collection('chatRooms').doc(roomId).get();
    final roomData = roomDoc.data();

    Map<String, int> unreadCount = {};
    if (roomData != null && roomData['unreadCount'] != null) {
      (roomData['unreadCount'] as Map<String, dynamic>).forEach((key, value) {
        unreadCount[key] = value as int;
      });
    }

    // Increment unread count for receiver
    if (unreadCount.containsKey(receiverId)) {
      unreadCount[receiverId] = (unreadCount[receiverId] ?? 0) + 1;
    } else {
      unreadCount[receiverId] = 1;
    }

    // Update chat room
    await _firestore.collection('chatRooms').doc(roomId).update({
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageContent': message.content,
      'lastMessageSenderId': message.senderId,
      'unreadCount': unreadCount,
    });
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String roomId, String userId) async {
    // Mark all messages as read where the user is the receiver
    final messagesQuery = await _firestore
        .collection('chatRooms')
        .doc(roomId)
        .collection('messages')
        .where('receiverId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    // Update each message
    final batch = _firestore.batch();
    for (final doc in messagesQuery.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();

    // Reset unread count for this user
    final roomDoc = await _firestore.collection('chatRooms').doc(roomId).get();
    if (roomDoc.exists) {
      final roomData = roomDoc.data() as Map<String, dynamic>;
      final unreadCount = Map<String, int>.from(roomData['unreadCount'] ?? {});

      if (unreadCount.containsKey(userId)) {
        unreadCount[userId] = 0;
        await _firestore.collection('chatRooms').doc(roomId).update({
          'unreadCount': unreadCount,
        });
      }
    }
  }

  // Get stream of messages for a chat room
  Stream<List<ChatMessage>> getMessages(String roomId) {
    return _firestore
        .collection('chatRooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromMap(doc.data()))
            .toList());
  }

  // Get stream of chat rooms for a user (excluding deleted ones)
  Stream<List<ChatRoom>> getChatRooms(String userId) {
    return _firestore
        .collection('chatRooms')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatRoom.fromFirestore(doc))
          .where((chatRoom) => !(chatRoom.deletedBy.contains(userId)))
          .toList();
    });
  }

  // Updated method to get chat rooms properly
  Stream<List<ChatRoom>> getUserChatRooms(String userId) {
    return _firestore
        .collection('chatRooms')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
      final rooms =
          snapshot.docs.map((doc) => ChatRoom.fromFirestore(doc)).where((room) {
        // Filter out rooms where the user is in the deletedBy list
        return !(room.deletedBy.contains(userId));
      }).toList();
      return rooms;
    });
  }

  // Get total unread message count for a user (excluding deleted rooms)
  Stream<int> getTotalUnreadCount(String userId) {
    return _firestore
        .collection('chatRooms')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      int count = 0;
      for (final doc in snapshot.docs) {
        final roomData = doc.data();

        // Skip if this room is deleted by the user
        if (roomData['deletedBy'] != null &&
            (roomData['deletedBy'] as List<dynamic>).contains(userId)) {
          continue;
        }

        if (roomData['unreadCount'] != null &&
            roomData['unreadCount'][userId] != null) {
          count += (roomData['unreadCount'][userId] as int);
        }
      }
      debugPrint("*********count: $count");
      return count;
    });
  }

  // Delete a chat room for a specific user
  Future<void> deleteChatRoom(String roomId, String userId) async {
    try {
      final roomDoc =
          await _firestore.collection('chatRooms').doc(roomId).get();

      if (!roomDoc.exists) {
        throw Exception('Chat room not found');
      }

      final roomData = roomDoc.data() as Map<String, dynamic>;
      final List<String> participants =
          List<String>.from(roomData['participants'] ?? []);
      List<String> deletedBy = List<String>.from(roomData['deletedBy'] ?? []);

      // Add this user to deletedBy list if not already there
      if (!deletedBy.contains(userId)) {
        deletedBy.add(userId);
      }

      // If all participants have deleted the chat, actually delete it
      bool allDeleted = true;
      for (final participant in participants) {
        if (!deletedBy.contains(participant)) {
          allDeleted = false;
          break;
        }
      }

      if (allDeleted) {
        // Delete all messages in the chat room
        final messagesQuery = await _firestore
            .collection('chatRooms')
            .doc(roomId)
            .collection('messages')
            .get();

        final batch = _firestore.batch();
        for (final doc in messagesQuery.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();

        // Delete the chat room document
        await _firestore.collection('chatRooms').doc(roomId).delete();
      } else {
        // Just mark as deleted for this user
        await _firestore.collection('chatRooms').doc(roomId).update({
          'deletedBy': deletedBy,
        });
      }
    } catch (e) {
      debugPrint('Error deleting chat room: $e');
      throw e;
    }
  }

  // Delete a message
  Future<void> deleteMessage(String roomId, String messageId) async {
    await _firestore
        .collection('chatRooms')
        .doc(roomId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }
}

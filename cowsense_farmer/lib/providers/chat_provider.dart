import 'package:flutter/material.dart';
import '../models/chat_message_model.dart';
import '../models/chat_room_model.dart';
import '../services/chat_service.dart';

class ChatProvider with ChangeNotifier {
  final ChatService _chatService;
  List<ChatRoom> _chatRooms = [];
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _error;
  String? _currentRoomId;

  ChatProvider(this._chatService);

  // Initialize provider with user data
  Future<void> initialize(String userId) async {
    await loadChatRooms(userId);
  }

  // Getters
  List<ChatRoom> get chatRooms => _chatRooms;
  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentRoomId => _currentRoomId;

  // Methods
  void setCurrentRoomId(String? roomId) {
    _currentRoomId = roomId;
    notifyListeners();
  }

  Future<String> createRoom(String userId, String veterinarianId) async {
    final roomId =
        await _chatService.createOrGetChatRoom(userId, veterinarianId);
    notifyListeners();
    return roomId;
  }

  Future<void> loadChatRooms(String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _chatService.getChatRooms(userId).listen(
        (chatRooms) {
          _chatRooms = chatRooms;
          notifyListeners();
        },
        onError: (error) {
          _error = error.toString();
          notifyListeners();
        },
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMessages(String roomId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _chatService.getMessages(roomId).listen(
        (messages) {
          _messages = messages;
          notifyListeners();
        },
        onError: (error) {
          _error = error.toString();
          notifyListeners();
        },
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendTextMessage(
    String chatRoomId,
    String senderId,
    String receiverId,
    String content,
  ) async {
    try {
      await _chatService.sendTextMessage(
        chatRoomId,
        senderId,
        receiverId,
        content,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> markMessagesAsRead(String roomId, String userId) async {
    try {
      await _chatService.markMessagesAsRead(roomId, userId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteChatRoom(String roomId, String userId) async {
    try {
      await _chatService.deleteChatRoom(roomId, userId);
      _chatRooms.removeWhere((room) => room.id == roomId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

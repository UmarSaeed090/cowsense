import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType {
  text,
  image,
  video,
  audio,
  file,
  call,
}

class ChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final bool isRead;
  final String? mediaUrl;
  final int? duration;
  final String? fileName;
  final int? fileSize;
  final bool? isVideoCall;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.type,
    required this.timestamp,
    required this.isRead,
    this.mediaUrl,
    this.duration,
    this.fileName,
    this.fileSize,
    this.isVideoCall,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'type': type.toString().split('.').last,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'mediaUrl': mediaUrl,
      'duration': duration,
      'fileName': fileName,
      'fileSize': fileSize,
      'isVideoCall': isVideoCall,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      content: map['content'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => MessageType.text,
      ),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      isRead: map['isRead'] ?? false,
      mediaUrl: map['mediaUrl'],
      duration: map['duration'],
      fileName: map['fileName'],
      fileSize: map['fileSize'],
      isVideoCall: map['isVideoCall'],
    );
  }

  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    bool? isRead,
    String? mediaUrl,
    int? duration,
    String? fileName,
    int? fileSize,
    bool? isVideoCall,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      duration: duration ?? this.duration,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      isVideoCall: isVideoCall ?? this.isVideoCall,
    );
  }
}

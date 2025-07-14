import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoom {
  final String id;
  final List<String> participants;
  final DateTime lastMessageTime;
  final String lastMessageContent;
  final String lastMessageSenderId;
  final bool isServiceRequest;
  final String? tagNumber;
  final Map<String, int> unreadCount;
  final List<String> deletedBy;

  ChatRoom({
    required this.id,
    required this.participants,
    required this.lastMessageTime,
    required this.lastMessageContent,
    required this.lastMessageSenderId,
    required this.isServiceRequest,
    this.tagNumber,
    required this.unreadCount,
    required this.deletedBy,
  });

  // Create a ChatRoom from a Firestore document
  factory ChatRoom.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Convert Firestore Timestamp to DateTime
    DateTime lastMsgTime;
    if (data['lastMessageTime'] is Timestamp) {
      lastMsgTime = (data['lastMessageTime'] as Timestamp).toDate();
    } else {
      lastMsgTime = DateTime.now();
    }

    // Convert unreadCount map
    Map<String, int> unreadCountMap = {};
    if (data['unreadCount'] != null) {
      (data['unreadCount'] as Map<String, dynamic>).forEach((key, value) {
        unreadCountMap[key] = value as int;
      });
    }

    // Extract deletedBy list
    List<String> deletedByList = [];
    if (data['deletedBy'] != null) {
      deletedByList = List<String>.from(data['deletedBy']);
    }

    return ChatRoom(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      lastMessageTime: lastMsgTime,
      lastMessageContent: data['lastMessageContent'] ?? '',
      lastMessageSenderId: data['lastMessageSenderId'] ?? '',
      isServiceRequest: data['isServiceRequest'] ?? false,
      tagNumber: data['tagNumber'],
      unreadCount: unreadCountMap,
      deletedBy: deletedByList,
    );
  }

  // Convert the ChatRoom to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'participants': participants,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'lastMessageContent': lastMessageContent,
      'lastMessageSenderId': lastMessageSenderId,
      'isServiceRequest': isServiceRequest,
      'tagNumber': tagNumber,
      'unreadCount': unreadCount,
      'deletedBy': deletedBy,
    };
  }

  factory ChatRoom.fromMap(Map<String, dynamic> map) {
    return ChatRoom(
      id: map['id'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      lastMessageTime: (map['lastMessageTime'] as Timestamp).toDate(),
      lastMessageContent: map['lastMessageContent'] ?? '',
      lastMessageSenderId: map['lastMessageSenderId'] ?? '',
      isServiceRequest: map['isServiceRequest'] ?? false,
      tagNumber: map['tagNumber'],
      unreadCount: Map<String, int>.from(map['unreadCount'] ?? {}),
      deletedBy: List<String>.from(map['deletedBy'] ?? []),
    );
  }
}

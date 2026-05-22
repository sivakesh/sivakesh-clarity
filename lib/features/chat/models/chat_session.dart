import 'package:cloud_firestore/cloud_firestore.dart';

class ChatSession {
  final String id;
  final String userId;
  final Timestamp createdAt;
  final String lastMessage;
  final String? activeMood;
  final String? source;

  const ChatSession({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.lastMessage,
    this.activeMood,
    this.source,
  });

  factory ChatSession.fromDoc(String id, Map<String, dynamic> data) {
    return ChatSession(
      id: id,
      userId: (data['userId'] as String?) ?? '',
      createdAt: (data['createdAt'] as Timestamp?) ?? Timestamp.now(),
      lastMessage: (data['lastMessage'] as String?) ?? '',
      activeMood: data['activeMood'] as String?,
      source: data['source'] as String?,
    );
  }
}

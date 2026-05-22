import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String userId;
  final String role;
  final String text;
  final Timestamp createdAt;
  final String? moodContext;
  final String? source;
  final String? assessmentSuggestion;

  const ChatMessage({
    required this.id,
    required this.userId,
    required this.role,
    required this.text,
    required this.createdAt,
    this.moodContext,
    this.source,
    this.assessmentSuggestion,
  });

  Map<String, dynamic> toJson() => {
    'role': role,
    'text': text,
    'createdAt': createdAt,
    'moodContext': moodContext,
    'source': source,
    'assessmentSuggestion': assessmentSuggestion,
  };

  factory ChatMessage.fromDoc(String id, String userId, Map<String, dynamic> data) {
    return ChatMessage(
      id: id,
      userId: userId,
      role: (data['role'] as String?) ?? 'assistant',
      text: (data['text'] as String?) ?? '',
      createdAt: (data['createdAt'] as Timestamp?) ?? Timestamp.now(),
      moodContext: data['moodContext'] as String?,
      source: data['source'] as String?,
      assessmentSuggestion: data['assessmentSuggestion'] as String?,
    );
  }
}

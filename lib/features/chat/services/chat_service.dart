import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat_message.dart';
import '../models/chat_session.dart';

class ChatService {
  final FirebaseFirestore _firestore;

  ChatService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<ChatSession> getOrCreateLatestSession({
    required String userId,
    String? mood,
    String? source,
  }) async {
    final query = await _firestore
        .collection('chatSessions')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return ChatSession.fromDoc(query.docs.first.id, query.docs.first.data());
    }

    final doc = _firestore.collection('chatSessions').doc();
    final now = Timestamp.now();
    await doc.set({
      'userId': userId,
      'createdAt': now,
      'lastMessage': '',
      'activeMood': mood,
      'source': source,
    });

    return ChatSession(
      id: doc.id,
      userId: userId,
      createdAt: now,
      lastMessage: '',
      activeMood: mood,
      source: source,
    );
  }

  Stream<List<ChatMessage>> messagesStream({required String sessionId, required String userId}) {
    return _firestore
        .collection('chatSessions')
        .doc(sessionId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((d) => ChatMessage.fromDoc(d.id, userId, d.data()))
              .toList(),
        );
  }

  Future<void> addMessage({
    required String sessionId,
    required String userId,
    required ChatMessage message,
  }) async {
    final msgRef = _firestore
        .collection('chatSessions')
        .doc(sessionId)
        .collection('messages')
        .doc();

    await msgRef.set({
      ...message.toJson(),
      'createdAt': Timestamp.now(),
    });

    await _firestore.collection('chatSessions').doc(sessionId).set({
      'lastMessage': message.text,
      'activeMood': message.moodContext,
      'source': message.source,
    }, SetOptions(merge: true));

    await _appendInsights(userId: userId, text: message.text);
  }

  Future<void> _appendInsights({required String userId, required String text}) async {
    final lower = text.toLowerCase();
    final tags = <String>[];
    if (lower.contains('sleep')) tags.add('sleep');
    if (lower.contains('stress')) tags.add('stress');
    if (lower.contains('work')) tags.add('work');
    if (lower.contains('study')) tags.add('study');
    if (lower.contains('anx')) tags.add('anxiety');
    if (lower.contains('motivation')) tags.add('motivation');
    if (tags.isEmpty) return;

    final doc = _firestore
        .collection('users')
        .doc(userId)
        .collection('insights')
        .doc('signals');

    await doc.set({
      'tags': FieldValue.arrayUnion(tags),
      'lastUpdatedAt': Timestamp.now(),
    }, SetOptions(merge: true));
  }
}

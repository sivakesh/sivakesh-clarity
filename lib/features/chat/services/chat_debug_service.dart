import 'package:cloud_firestore/cloud_firestore.dart';

class ChatDebugService {
  final FirebaseFirestore _firestore;

  ChatDebugService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<String> setupSampleChat({required String userId}) async {
    final sessionRef = _firestore.collection('chatSessions').doc();
    await sessionRef.set({
      'userId': userId,
      'createdAt': Timestamp.now(),
      'lastMessage': 'Welcome to Clarity',
      'activeMood': 'Okay',
      'source': 'debug_setup',
    });

    final messageRef = sessionRef.collection('messages').doc();
    await messageRef.set({
      'role': 'assistant',
      'text': 'Welcome to Clarity',
      'createdAt': Timestamp.now(),
      'moodContext': 'Okay',
      'source': 'debug_setup',
    });

    return sessionRef.id;
  }
}

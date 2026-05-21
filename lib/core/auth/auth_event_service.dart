import 'package:cloud_firestore/cloud_firestore.dart';

import '../config/app_environment.dart';
import '../../models/auth_event_model.dart';

class AuthEventService {
  final FirebaseFirestore _firestore;

  AuthEventService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> track(AuthEventModel event) async {
    final doc = _firestore.collection('auth_events').doc();
    await doc.set({
      'id': doc.id,
      'userId': event.userId,
      'phone': event.phone,
      'event': event.event,
      'metadata': event.metadata,
      'environment': event.environment,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> trackByName({
    required String event,
    String? userId,
    String? phone,
    Map<String, dynamic>? metadata,
  }) {
    return track(
      AuthEventModel(
        event: event,
        environment: AppConfig.isDev ? 'dev' : 'prod',
        userId: userId,
        phone: phone,
        metadata: metadata,
      ),
    );
  }
}

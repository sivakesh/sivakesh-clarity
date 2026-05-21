import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../config/app_environment.dart';
import '../../models/user_model.dart';

class AuthSessionService {
  final FirebaseFirestore _firestore;

  AuthSessionService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  String get _platform {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      default:
        return 'web';
    }
  }

  String get _environment => AppConfig.isDev ? 'dev' : 'prod';

  Future<void> closeActiveSessions(String userId) async {
    final query = await _firestore
        .collection('user_sessions')
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .get();

    for (final doc in query.docs) {
      await doc.reference.update({
        'isActive': false,
        'logoutTime': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<String> openSession(UserModel user) async {
    await closeActiveSessions(user.id);

    final doc = _firestore.collection('user_sessions').doc();
    await doc.set({
      'id': doc.id,
      'userId': user.id,
      'phone': user.phone,
      'authUid': user.authUid,
      'loginTime': FieldValue.serverTimestamp(),
      'logoutTime': null,
      'isActive': true,
      'platform': _platform,
      'environment': _environment,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> closeSessionById(String sessionId) async {
    final doc = _firestore.collection('user_sessions').doc(sessionId);
    await doc.update({
      'isActive': false,
      'logoutTime': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

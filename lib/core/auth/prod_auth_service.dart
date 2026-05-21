import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/user_model.dart';
import 'auth_event_service.dart';
import 'auth_service.dart';
import 'auth_session_service.dart';

class ProdAuthService implements AuthService {
  static const int _minLocalDigits = 10;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final AuthSessionService _sessionService;
  final AuthEventService _eventService;

  String? _verificationId;
  int? _resendToken;
  String? _pendingPhone;
  String? _activeSessionId;

  ProdAuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    AuthSessionService? sessionService,
    AuthEventService? eventService,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _sessionService = sessionService ?? AuthSessionService(firestore: firestore),
       _eventService = eventService ?? AuthEventService(firestore: firestore) {
    _auth.setPersistence(Persistence.LOCAL);
  }

  @override
  Future<UserModel?> login(String phoneNumber) async {
    final normalizedPhone = _normalizePhone(phoneNumber);
    if (!_isValidPhone(normalizedPhone)) {
      await _eventService.trackByName(event: 'login_failed', phone: normalizedPhone.isEmpty ? null : normalizedPhone);
      throw Exception('Enter a valid phone number');
    }

    _pendingPhone = normalizedPhone;
    await _eventService.trackByName(event: 'otp_sent', phone: normalizedPhone);

    final completer = Completer<UserModel?>();

    await _auth.verifyPhoneNumber(
      phoneNumber: normalizedPhone,
      forceResendingToken: _resendToken,
      verificationCompleted: (PhoneAuthCredential credential) async {
        final credentialResult = await _auth.signInWithCredential(credential);
        final user = await _syncFirestoreUser(credentialResult.user, emitVerifiedEvent: true);
        if (!completer.isCompleted) completer.complete(user);
      },
      verificationFailed: (FirebaseAuthException error) async {
        await _eventService.trackByName(
          event: 'login_failed',
          phone: normalizedPhone,
          metadata: {'code': error.code, 'message': error.message},
        );
        if (!completer.isCompleted) completer.completeError(error);
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        _resendToken = resendToken;
        if (!completer.isCompleted) completer.complete(null);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );

    return completer.future;
  }

  @override
  Future<UserModel?> verifyOtp(String code) async {
    if (_verificationId == null) {
      throw Exception('OTP session not initialized. Please request OTP again.');
    }

    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: code.trim(),
    );

    final result = await _auth.signInWithCredential(credential);
    return _syncFirestoreUser(result.user, emitVerifiedEvent: true);
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final restored = await _syncFirestoreUser(user);
    await _eventService.trackByName(
      event: 'session_restored',
      userId: restored.id,
      phone: restored.phone,
    );
    return restored;
  }

  @override
  Future<void> logout() async {
    final current = _auth.currentUser;
    String? userId;
    String? phone;

    if (current != null) {
      final synced = await _syncFirestoreUser(current);
      userId = synced.id;
      phone = synced.phone;
      await _sessionService.closeActiveSessions(synced.id);
    }

    if (_activeSessionId != null) {
      await _sessionService.closeSessionById(_activeSessionId!);
      _activeSessionId = null;
    }

    await _eventService.trackByName(event: 'logout', userId: userId, phone: phone);

    _verificationId = null;
    _resendToken = null;
    _pendingPhone = null;
    await _auth.signOut();
  }

  Future<UserModel> _syncFirestoreUser(
    User? firebaseUser, {
    bool emitVerifiedEvent = false,
  }) async {
    if (firebaseUser == null) throw Exception('Unable to authenticate user');

    final normalizedPhone = _normalizePhone(firebaseUser.phoneNumber ?? _pendingPhone ?? '');
    if (!_isValidPhone(normalizedPhone)) {
      throw Exception('Authenticated user does not have a valid phone number');
    }

    final users = _firestore.collection('users');
    final query = await users.where('phone', isEqualTo: normalizedPhone).limit(1).get();

    DocumentReference<Map<String, dynamic>> userDoc;
    if (query.docs.isNotEmpty) {
      userDoc = query.docs.first.reference;
      await userDoc.update({
        'phone': normalizedPhone,
        'authUid': firebaseUser.uid,
        'lastLogin': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      userDoc = users.doc();
      await userDoc.set({
        'id': userDoc.id,
        'phone': normalizedPhone,
        'name': '',
        'authUid': firebaseUser.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });
    }

    final latest = await userDoc.get();
    final data = latest.data() ?? <String, dynamic>{};
    final appUser = _toUser(userDoc.id, data);

    _activeSessionId = await _sessionService.openSession(appUser);
    if (emitVerifiedEvent) {
      await _eventService.trackByName(event: 'otp_verified', userId: appUser.id, phone: appUser.phone);
      await _eventService.trackByName(event: 'login_success', userId: appUser.id, phone: appUser.phone);
    }

    return appUser;
  }

  UserModel _toUser(String id, Map<String, dynamic> data) {
    return UserModel(
      id: id,
      phone: (data['phone'] as String?) ?? '',
      name: (data['name'] as String?) ?? '',
      authUid: (data['authUid'] as String?) ?? '',
    );
  }

  String _normalizePhone(String phoneNumber) {
    final raw = phoneNumber.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (raw.isEmpty) return '';

    var withPlus = raw;
    if (withPlus.startsWith('00')) withPlus = '+${withPlus.substring(2)}';
    if (!withPlus.startsWith('+')) withPlus = '+$withPlus';

    final digits = withPlus.replaceAll(RegExp(r'[^0-9]'), '');
    final trimmedDigits = digits.replaceFirst(RegExp(r'^0+'), '');
    if (trimmedDigits.length < _minLocalDigits) return '';
    return '+$trimmedDigits';
  }

  bool _isValidPhone(String normalizedPhone) {
    final digits = normalizedPhone.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length >= _minLocalDigits;
  }
}

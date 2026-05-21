import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/user_model.dart';
import 'auth_event_service.dart';
import 'auth_service.dart';
import 'auth_session_service.dart';

class DevAuthService implements AuthService {
  static const int _minLocalDigits = 10;
  static const String _devUserKey = 'dev_logged_in_user';
  static const String _devSessionKey = 'dev_active_session_id';

  final FirebaseFirestore _firestore;
  final AuthSessionService _sessionService;
  final AuthEventService _eventService;

  DevAuthService({
    FirebaseFirestore? firestore,
    AuthSessionService? sessionService,
    AuthEventService? eventService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _sessionService = sessionService ?? AuthSessionService(firestore: firestore),
       _eventService = eventService ?? AuthEventService(firestore: firestore);

  @override
  Future<UserModel?> login(String phoneNumber) async {
    final normalizedPhone = _normalizePhone(phoneNumber);
    if (!_isValidPhone(normalizedPhone)) {
      await _eventService.trackByName(
        event: 'login_failed',
        phone: normalizedPhone.isEmpty ? null : normalizedPhone,
      );
      throw Exception('Enter a valid phone number');
    }

    final users = _firestore.collection('users');
    final query = await users.where('phone', isEqualTo: normalizedPhone).limit(1).get();

    UserModel user;
    if (query.docs.isNotEmpty) {
      final doc = query.docs.first.reference;
      await doc.update({
        'lastLogin': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      final refreshed = await doc.get();
      user = _toUser(refreshed.id, refreshed.data() ?? <String, dynamic>{});
    } else {
      final doc = users.doc();
      await doc.set({
        'id': doc.id,
        'phone': normalizedPhone,
        'name': '',
        'authUid': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });
      user = UserModel(id: doc.id, phone: normalizedPhone, name: '', authUid: null);
    }

    final sessionId = await _sessionService.openSession(user);
    await _persistLocalDevSession(user: user, sessionId: sessionId);
    await _eventService.trackByName(event: 'login_success', userId: user.id, phone: user.phone);
    return user;
  }

  @override
  Future<UserModel?> verifyOtp(String code) async {
    throw UnsupportedError('OTP is not required in dev mode');
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_devUserKey);
    if (raw == null || raw.isEmpty) return null;

    final data = jsonDecode(raw) as Map<String, dynamic>;
    final user = UserModel.fromJson(data);
    if (user.id.isEmpty || user.phone.isEmpty) {
      await _clearLocalDevSession();
      return null;
    }

    await _eventService.trackByName(event: 'session_restored', userId: user.id, phone: user.phone);
    return user;
  }

  @override
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_devUserKey);
    final sessionId = prefs.getString(_devSessionKey);

    String? userId;
    String? phone;
    if (raw != null && raw.isNotEmpty) {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      userId = data['id'] as String?;
      phone = data['phone'] as String?;
    }

    if (sessionId != null && sessionId.isNotEmpty) {
      await _sessionService.closeSessionById(sessionId);
    } else if (userId != null && userId.isNotEmpty) {
      await _sessionService.closeActiveSessions(userId);
    }

    await _eventService.trackByName(event: 'logout', userId: userId, phone: phone);
    await _clearLocalDevSession();
  }

  Future<void> _persistLocalDevSession({required UserModel user, required String sessionId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_devUserKey, jsonEncode(user.toJson()));
    await prefs.setString(_devSessionKey, sessionId);
  }

  Future<void> _clearLocalDevSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_devUserKey);
    await prefs.remove(_devSessionKey);
  }

  UserModel _toUser(String id, Map<String, dynamic> data) {
    return UserModel(
      id: id,
      phone: (data['phone'] as String?) ?? '',
      name: (data['name'] as String?) ?? '',
      authUid: data['authUid'] as String?,
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

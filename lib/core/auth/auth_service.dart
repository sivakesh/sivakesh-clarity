import '../../models/user_model.dart';

abstract class AuthService {
  Future<UserModel?> login(String phoneNumber);
  Future<UserModel?> verifyOtp(String code);
  Future<UserModel?> getCurrentUser();
  Future<void> logout();
}

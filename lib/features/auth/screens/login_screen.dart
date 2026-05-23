import 'package:flutter/material.dart';

import '../../../core/auth/auth_factory.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/config/app_environment.dart';
import '../../core/role_based_home.dart';
import '../widgets/phone_input.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final AuthService _authService;

  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _authService = AuthFactory.create();
  }

  Future<void> _handleLogin(String phoneNumber) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = await _authService.login(phoneNumber);
      if (!mounted) {
        return;
      }

      if (AppConfig.isDev || user != null) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => RoleBasedHome(user: user!)),
          (route) => false,
        );
      } else {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OtpScreen(authService: _authService),
          ),
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090A0C),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A1C20), Color(0xFF141518)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0x26FFFFFF), width: 1),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x55000000),
                      blurRadius: 36,
                      offset: Offset(0, 16),
                    ),
                    BoxShadow(
                      color: Color(0x18000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF3A3C42), Color(0xFF2A2C31)],
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x33000000),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Text(
                              'SR',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFF2F2F3),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Sivakesh Raman',
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Welcome',
                      style: TextStyle(
                        fontSize: 34,
                        height: 1.1,
                        letterSpacing: -0.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      AppConfig.isDev
                          ? 'Enter phone number to continue (Dev mode)'
                          : 'Enter phone number to continue',
                      style: const TextStyle(
                        color: Color(0xFF9B9EA4),
                        fontSize: 15,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 24),
                    PhoneInput(onSendOtp: _handleLogin, isLoading: _isLoading),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: const TextStyle(
                          color: Color(0xFFE58B92),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

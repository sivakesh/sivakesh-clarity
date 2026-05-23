import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'core/auth/auth_factory.dart';
import 'core/config/app_environment.dart';
import 'firebase_options.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/core/role_based_home.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  print('Current ENV: ${AppConfig.environment}');

  runApp(const AppStartGate());
}

class AppStartGate extends StatelessWidget {
  const AppStartGate({super.key});

  @override
  Widget build(BuildContext context) {
    return const CounselingApp();
  }
}

class CounselingApp extends StatelessWidget {
  const CounselingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Clarity',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0B0B),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFF2F2F2),
          secondary: Color(0xFF9D9D9D),
          surface: Color(0xFF1A1A1A),
        ),
        cardColor: const Color(0xFF1A1A1A),
        useMaterial3: true,
        fontFamily: 'SF Pro Display',
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthFactory.create();

    return FutureBuilder(
      future: authService.getCurrentUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return RoleBasedHome(user: snapshot.data!);
        }

        return const LoginScreen();
      },
    );
  }
}

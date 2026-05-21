import 'package:flutter/material.dart';

import '../../common/widgets/app_header.dart';
import '../../common/widgets/page_shell.dart';
import '../widgets/action_buttons.dart';
import '../widgets/home_header.dart';
import '../widgets/mood_check_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const AppHeader(),
          Expanded(
            child: SingleChildScrollView(
              child: PageShell(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: const [
                    HomeHeader(),
                    SizedBox(height: 28),
                    ActionButtons(),
                    SizedBox(height: 28),
                    MoodCheckCard(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

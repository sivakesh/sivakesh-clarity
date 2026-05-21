import 'package:flutter/material.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          'Clarity begins here',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 10),
        Text(
          'A calm space to reflect, breathe, and take your next step with confidence.',
          style: TextStyle(
            fontSize: 15,
            height: 1.45,
            color: Color(0xFFB3B3B3),
          ),
        ),
      ],
    );
  }
}

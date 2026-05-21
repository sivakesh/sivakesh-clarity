import 'package:flutter/material.dart';

class ChatEmptyState extends StatelessWidget {
  const ChatEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              color: Color(0xFFB9B9B9),
              size: 40,
            ),
            SizedBox(height: 12),
            Text(
              'Your conversations will appear here',
              style: TextStyle(color: Color(0xFFD0D0D0), fontSize: 16),
            ),
            SizedBox(height: 6),
            Text(
              'Start with a gentle message when you are ready.',
              style: TextStyle(color: Color(0xFF8E8E8E)),
            ),
          ],
        ),
      ),
    );
  }
}

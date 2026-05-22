import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final String role;
  final String text;

  const ChatBubble({super.key, required this.role, required this.text});

  @override
  Widget build(BuildContext context) {
    final isUser = role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        constraints: const BoxConstraints(maxWidth: 520),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isUser
                ? const [Color(0xFFE6E8EE), Color(0xFFDDE0E8)]
                : const [Color(0xFF21242C), Color(0xFF191B21)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUser ? const Color(0xFFE7EAF1) : const Color(0x2EFFFFFF),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? const Color(0xFF18191C) : const Color(0xFFE6E9EF),
            height: 1.35,
          ),
        ),
      ),
    );
  }
}

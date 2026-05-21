import 'package:flutter/material.dart';

class MoodCheckCard extends StatelessWidget {
  const MoodCheckCard({super.key});

  @override
  Widget build(BuildContext context) {
    const moods = ['Calm', 'Okay', 'Stressed', 'Low'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF262626)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How are you feeling today?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: moods
                .map(
                  (mood) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF222222),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      mood,
                      style: const TextStyle(color: Color(0xFFD5D5D5)),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

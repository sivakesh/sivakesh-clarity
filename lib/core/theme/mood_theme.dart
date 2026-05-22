import 'package:flutter/material.dart';

class MoodTheme {
  static const Map<String, Color> moodColors = {
    'Calm': Color(0xFF4ADE80),
    'Okay': Color(0xFF60A5FA),
    'Stressed': Color(0xFFF59E0B),
    'Low': Color(0xFFF87171),
  };

  static Color getColor(String mood) {
    return moodColors[mood] ?? const Color(0xFF9CA3AF);
  }

  static const Map<String, int> moodScores = {
    'Calm': 4,
    'Okay': 3,
    'Stressed': 2,
    'Low': 1,
  };

  static int getScore(String mood) {
    return moodScores[mood] ?? 0;
  }

  static String scoreToMood(double score) {
    if (score >= 3.5) return 'Calm';
    if (score >= 2.5) return 'Okay';
    if (score >= 1.5) return 'Stressed';
    return 'Low';
  }
}

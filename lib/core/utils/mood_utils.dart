import 'package:flutter/material.dart';

class MoodUtils {
  static Color getColorFromMood(String mood) {
    switch (mood) {
      case 'Calm':
        return const Color(0xFF4ADE80);
      case 'Okay':
        return const Color(0xFF60A5FA);
      case 'Stressed':
        return const Color(0xFFFBBF24);
      case 'Low':
        return const Color(0xFFF87171);
      default:
        return const Color(0xFF2C2C2C);
    }
  }

  static Color getColorFromScore(int score) {
    switch (score) {
      case 4:
        return getColorFromMood('Calm');
      case 3:
        return getColorFromMood('Okay');
      case 2:
        return getColorFromMood('Stressed');
      case 1:
        return getColorFromMood('Low');
      default:
        return const Color(0xFF2C2C2C);
    }
  }
}

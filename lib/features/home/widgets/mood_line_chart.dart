import 'package:flutter/material.dart';
import '../../../core/utils/mood_utils.dart';

class MoodBarChart extends StatelessWidget {
  final List<int> scores;

  const MoodBarChart({super.key, required this.scores});

  @override
  Widget build(BuildContext context) {
    final safeScores = scores.isEmpty ? List.filled(7, 0) : scores;

    return SizedBox(
      height: 140,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(safeScores.length, (index) {
          final score = safeScores[index];
          final heightFactor = score == 0 ? 0.1 : score / 4;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 100 * heightFactor,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          MoodUtils.getColorFromScore(score),
                          MoodUtils.getColorFromScore(
                            score,
                          ).withValues(alpha: 0.65),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _dayLabel(index),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF7A7A7A),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  String _dayLabel(int index) {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return labels[index % 7];
  }
}

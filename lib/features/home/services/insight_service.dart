import '../../../core/theme/mood_theme.dart';

class InsightService {
  String? generateInsight({
    required List<Map<String, dynamic>> todayCheckins,
    required List<Map<String, dynamic>> historyCheckins,
    required int streak,
  }) {
    final todayMoods = todayCheckins
        .map((e) => _resolveMood(e))
        .where((m) => m.isNotEmpty)
        .toList();
    final historyMoods = historyCheckins
        .map((e) => _resolveMood(e))
        .where((m) => m.isNotEmpty)
        .toList();

    final stressedToday = todayMoods.where((m) => m == 'Stressed').length;
    if (stressedToday >= 3) {
      return 'Frequent stress check-ins detected today.';
    }

    if (historyMoods.length >= 2) {
      final latestMood = historyMoods.isNotEmpty ? historyMoods.first : null;
      final olderMood = historyMoods.isNotEmpty ? historyMoods.last : null;
      if (latestMood != null &&
          olderMood != null &&
          MoodTheme.getScore(latestMood) > MoodTheme.getScore(olderMood)) {
        return 'You seem calmer compared to earlier this week.';
      }
    }

    if (streak >= 5) {
      return 'Your consistency is improving.';
    }

    final avg = _averageScore(historyCheckins);
    if (avg >= 3.2) return 'Your mood has remained fairly stable this week.';
    if (avg >= 2.4) return "You've shown recovery after stressful moments.";
    return 'Small daily check-ins can help build momentum.';
  }

  String _resolveMood(Map<String, dynamic> data) {
    final mood = data['mood'] as String?;
    if (mood != null && mood.isNotEmpty) return mood;
    final score = ((data['score'] ?? 0) as num).toDouble();
    return MoodTheme.scoreToMood(score);
  }

  double _averageScore(List<Map<String, dynamic>> docs) {
    if (docs.isEmpty) return 0;
    var total = 0.0;
    var count = 0;
    for (final d in docs.take(7)) {
      final score = d['score'];
      if (score is num) {
        total += score.toDouble();
        count++;
      }
    }
    return count == 0 ? 0 : total / count;
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/mood_theme.dart';
import '../../../core/utils/mood_utils.dart';
import '../services/daily_checkin_service.dart';
import '../services/insight_service.dart';
import 'mood_line_chart.dart';

class MoodCheckCard extends StatefulWidget {
  final String? userId;
  final VoidCallback onReflectMore;
  final VoidCallback onTakeAssessment;
  final ValueChanged<String?> onMoodSelected;

  const MoodCheckCard({
    super.key,
    required this.userId,
    required this.onReflectMore,
    required this.onTakeAssessment,
    required this.onMoodSelected,
  });

  @override
  State<MoodCheckCard> createState() => _MoodCheckCardState();
}

class _MoodCheckCardState extends State<MoodCheckCard> {
  static const List<String> _moods = ['Calm', 'Okay', 'Stressed', 'Low'];
  static const int _pageSize = 3;
  static const int _historyPageSize = 3;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DailyCheckinService _checkinService = DailyCheckinService();
  final InsightService _insightService = InsightService();
  String? _selectedMood;
  bool _isSaving = false;
  int _startIndex = 0;
  int _historyStartIndex = 0;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _todayMomentStream;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _historyStream;

  @override
  void initState() {
    super.initState();
    _bindStreams();
  }

  @override
  void didUpdateWidget(covariant MoodCheckCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _startIndex = 0;
      _historyStartIndex = 0;
      _bindStreams();
    }
  }

  void _bindStreams() {
    final userId = widget.userId;
    _todayMomentStream = (userId == null || userId.isEmpty)
        ? null
        : _checkinService.todayMomentCheckins(userId);
    _historyStream = (userId == null || userId.isEmpty)
        ? null
        : _firestore
              .collection('dailyCheckins')
              .where('userId', isEqualTo: userId)
              .orderBy('dateKey', descending: true)
              .limit(30)
              .snapshots();
  }

  Future<void> _handleMoodTap(String mood) async {
    FocusScope.of(context).unfocus();
    final userId = widget.userId;
    if (userId == null || userId.isEmpty || _isSaving) return;

    setState(() {
      _selectedMood = mood;
      _isSaving = true;
    });

    try {
      await _checkinService.saveCheckin(userId: userId, mood: mood);
      widget.onMoodSelected(mood);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = widget.userId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          key: const ValueKey('mood_card_context'),
          stream: _todayMomentStream,
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? [];
            final moodFromStream = docs.isEmpty ? null : _averageMoodFromDocs(docs);
            final effectiveMood = _selectedMood ?? moodFromStream;
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              key: const ValueKey('insight_context'),
              stream: _historyStream,
              builder: (context, historySnapshot) {
                final todayData = docs.map((d) => d.data()).toList();
                final historyDocs = historySnapshot.data?.docs ?? [];
                final historyData = historyDocs.map((d) => d.data()).toList();
                final streak = _calculateStreak(historyDocs);
                final insight = _insightService.generateInsight(
                  todayCheckins: todayData,
                  historyCheckins: historyData,
                  streak: streak,
                );

                return Column(
                  children: [
                    if (insight != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF1D2026), Color(0xFF17191E)],
                          ),
                          border: Border.all(color: const Color(0x2EFFFFFF)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.insights,
                                  color: MoodUtils.getColorFromMood('Okay'),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    insight,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                // OutlinedButton(
                                //   onPressed: widget.onReflectMore,
                                //   style: OutlinedButton.styleFrom(
                                //     side: const BorderSide(
                                //       color: Color(0x39FFFFFF),
                                //     ),
                                //     foregroundColor: const Color(0xFFE2E6EF),
                                //     padding: const EdgeInsets.symmetric(
                                //       horizontal: 14,
                                //       vertical: 10,
                                //     ),
                                //     shape: RoundedRectangleBorder(
                                //       borderRadius: BorderRadius.circular(12),
                                //     ),
                                //   ),
                                //   child: const Text('Talk it out'),
                                // ),
                                const SizedBox(width: 10),
                                FilledButton(
                                  onPressed: widget.onTakeAssessment,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFFE9EBEF),
                                    foregroundColor: const Color(0xFF17191D),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text('View assessment'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF1B1D22), Color(0xFF15161A)],
                        ),
                        border: Border.all(color: const Color(0x2EFFFFFF)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x2C000000),
                            blurRadius: 24,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'How are you feeling today?',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Take a moment to check in with yourself',
                            style: TextStyle(
                              color: Color(0xFFA6A9B0),
                              fontSize: 13,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: _moods.map((mood) {
                              final selected = _selectedMood == mood;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                curve: Curves.easeOutCubic,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  color: selected
                                      ? MoodUtils.getColorFromMood(
                                          mood,
                                        ).withValues(alpha: 0.22)
                                      : const Color(0xFF23252B),
                                  border: Border.all(
                                    color: selected
                                        ? MoodUtils.getColorFromMood(mood)
                                        : const Color(0x33FFFFFF),
                                  ),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(999),
                                  onTap: userId == null
                                      ? null
                                      : () => _handleMoodTap(mood),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    child: Text(
                                      mood,
                                      style: TextStyle(
                                        color: selected
                                            ? MoodUtils.getColorFromMood(mood)
                                            : const Color(0xFFE0E2E7),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          if (_isSaving) ...[
                            const SizedBox(height: 12),
                            const Text(
                              'Saving your check-in...',
                              style: TextStyle(
                                color: Color(0xFF9EA3AF),
                                fontSize: 12,
                              ),
                            ),
                          ],
                          if (effectiveMood != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              "You're feeling ${effectiveMood.toLowerCase()}.",
                              style: const TextStyle(
                                color: Color(0xFFE7EAF0),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _getMoodSupportText(effectiveMood),
                              style: const TextStyle(
                                color: Color(0xFF9CA2AE),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: widget.onReflectMore,
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                        color: Color(0x39FFFFFF),
                                      ),
                                      foregroundColor: const Color(0xFFE2E6EF),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 10,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text('Talk it out'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: FilledButton(
                                    onPressed: widget.onTakeAssessment,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFFE9EBEF),
                                      foregroundColor: const Color(0xFF17191D),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 10,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text('Take assessment'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
        const SizedBox(height: 16),
        if (userId != null) ...[
          
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            key: const ValueKey('today_state'),
            stream: _todayMomentStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                debugPrint(
                  'todayMomentCheckins stream error (today state card): ${snapshot.error}',
                );
                final mood = _selectedMood;
                final title = mood == null
                    ? 'Start your check-in'
                    : "Today you're feeling: $mood";
                return _buildTodayStateCard(
                  title: title,
                  subtitle: _todaySubtitle(mood),
                  mood: mood,
                );
              }
              final docs = snapshot.data?.docs ?? [];
              final mood = docs.isEmpty ? null : _averageMoodFromDocs(docs);
              final title = mood == null
                  ? 'Start your check-in'
                  : "Today you're feeling: $mood";
              return _buildTodayStateCard(
                title: title,
                subtitle: _todaySubtitle(mood),
                mood: mood,
              );
            },
          ),
        ],
        const SizedBox(height: 22),
        Row(
          children: [
            const Expanded(
              child: Text(
                "Today's Check-ins",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            _buildPagerButton(
              icon: Icons.chevron_left_rounded,
              enabled: _startIndex > 0,
              onTap: () {
                FocusScope.of(context).unfocus();
                setState(() {
                  _startIndex = (_startIndex - _pageSize).clamp(0, 9999);
                });
              },
            ),
            const SizedBox(width: 8),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              key: const ValueKey('today_checkins_pager'),
              stream: _todayMomentStream,
              builder: (context, snapshot) {
                final total = (snapshot.data?.docs.length ?? 0);
                final canNext = _startIndex + _pageSize < total;
                return _buildPagerButton(
                  icon: Icons.chevron_right_rounded,
                  enabled: canNext,
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    setState(() {
                      _startIndex += _pageSize;
                    });
                  },
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (userId == null)
          const Text(
            'No recent check-ins yet.',
            style: TextStyle(color: Color(0xFF9EA3AF)),
          )
        else
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            key: const ValueKey('today_checkins'),
            stream: _todayMomentStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                debugPrint(
                  'todayMomentCheckins stream error (today list): ${snapshot.error}',
                );
                return Text(
                  'Check-ins unavailable right now.',
                  style: const TextStyle(color: Color(0xFFCC8E8E)),
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }

              final docs = snapshot.data?.docs ?? [];
              if (_startIndex >= docs.length && docs.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  setState(() {
                    _startIndex = ((docs.length - 1) ~/ _pageSize) * _pageSize;
                  });
                });
              }
              if (docs.isEmpty) {
                return const Text(
                  'No recent check-ins yet.',
                  style: TextStyle(color: Color(0xFF9EA3AF)),
                );
              }

              final paged = docs.skip(_startIndex).take(_pageSize).toList();
              return Column(
                children: paged.map((doc) {
                  final data = doc.data();
                  final mood = _resolveMood(data);
                  final createdAt = data['createdAt'];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B1D22),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0x24FFFFFF)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: MoodUtils.getColorFromMood(mood),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            mood,
                            style: const TextStyle(
                              color: Color(0xFFE6E7EA),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          _formatTime(createdAt),
                          style: const TextStyle(
                            color: Color(0xFF9EA3AF),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        const SizedBox(height: 18),
        const Text(
          "Today's Summary",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        if (userId == null)
          const Text(
            'No summary available yet.',
            style: TextStyle(color: Color(0xFF9EA3AF)),
          )
        else
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            key: const ValueKey('today_summary'),
            stream: _todayMomentStream,
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }
              if (docs.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B1D22),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0x24FFFFFF)),
                  ),
                  child: const Text(
                    'No summary available yet.',
                    style: TextStyle(color: Color(0xFF9EA3AF)),
                  ),
                );
              }
              final mood = _averageMoodFromDocs(docs);
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1B1D22), Color(0xFF16181D)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0x2EFFFFFF)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: MoodUtils.getColorFromMood(mood),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        mood,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        const SizedBox(height: 18),
        const Text(
          'Weekly Trend',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          key: const ValueKey('weekly_trend'),
          stream: _historyStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: CircularProgressIndicator(strokeWidth: 2),
              );
            }
            final docs = snapshot.data?.docs ?? [];
            final last7 = docs.take(7).toList().reversed.toList();
            final filtered = last7
                .where((d) => d.data()['score'] != null || d.data()['mood'] != null)
                .toList();
            debugPrint('Weekly raw docs: $last7');
            if (filtered.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: const Color(0xFF1B1D22),
                  border: Border.all(color: const Color(0x24FFFFFF)),
                ),
                child: const Text(
                  'Not enough data for weekly trend yet.',
                  style: TextStyle(color: Color(0xFF9EA3AF)),
                ),
              );
            }
            final scores = filtered
                .map((d) => (d.data()['score'] ?? 0) as num)
                .map((n) => n.toDouble())
                .where((s) => s > 0)
                .toList();
            debugPrint('Weekly scores: $scores');
            if (scores.isEmpty) {
              return const Center(
                child: Text(
                  'No data yet',
                  style: TextStyle(color: Color(0xFF9CA3AF)),
                ),
              );
            }
            final averageScore = scores.reduce((a, b) => a + b) / scores.length;
            final weeklyScores = scores.map((s) => s.round().clamp(1, 4)).toList();
            final weeklyScoresSafe = weeklyScores.isEmpty
                ? List.filled(7, 0)
                : weeklyScores;
            final averageMood = MoodTheme.scoreToMood(averageScore);
            final streak = _calculateStreak(docs);
            final weeklyInsight = _insightService.generateInsight(
              todayCheckins: const [],
              historyCheckins: docs.map((e) => e.data()).toList(),
              streak: streak,
            );

            return AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1C1F25), Color(0xFF15181D)],
                ),
                border: Border.all(color: const Color(0x2EFFFFFF)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x28000000),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your emotional rhythm over the past 7 days',
                    style: TextStyle(color: Color(0xFFA8AFBC), fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: MoodBarChart(scores: weeklyScoresSafe),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Average mood: $averageMood',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    streak > 0 ? '🔥 $streak day streak' : 'Start your streak today',
                    style: const TextStyle(color: Color(0xFFECEFF5)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    weeklyInsight ?? 'Your mood has remained fairly stable this week.',
                    style: const TextStyle(color: Color(0xFFA8AFBC), fontSize: 12),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Check-in History',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            _buildPagerButton(
              icon: Icons.chevron_left_rounded,
              enabled: _historyStartIndex > 0,
              onTap: () {
                setState(() {
                  _historyStartIndex = (_historyStartIndex - _historyPageSize)
                      .clamp(0, 9999);
                });
              },
            ),
            const SizedBox(width: 8),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              key: const ValueKey('history_checkins_pager'),
              stream: _historyStream,
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? [];
                final canNext =
                    _historyStartIndex + _historyPageSize < docs.length;
                return _buildPagerButton(
                  icon: Icons.chevron_right_rounded,
                  enabled: canNext,
                  onTap: () {
                    setState(() {
                      _historyStartIndex += _historyPageSize;
                    });
                  },
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (userId == null)
          const Text(
            'No history available yet.',
            style: TextStyle(color: Color(0xFF9EA3AF)),
          )
        else
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            key: const ValueKey('history_checkins'),
            stream: _historyStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }
              if (snapshot.hasError) {
                debugPrint('dailyCheckins history stream error: ${snapshot.error}');
                return const Text(
                  'History unavailable right now.',
                  style: TextStyle(color: Color(0xFFCC8E8E)),
                );
              }

              final docs = snapshot.data?.docs ?? [];
              if (_historyStartIndex >= docs.length && docs.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  setState(() {
                    _historyStartIndex =
                        ((docs.length - 1) ~/ _historyPageSize) *
                            _historyPageSize;
                  });
                });
              }

              if (docs.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B1D22),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0x24FFFFFF)),
                  ),
                  child: const Text(
                    'No history available yet.',
                    style: TextStyle(color: Color(0xFF9EA3AF)),
                  ),
                );
              }

              final paged = docs
                  .skip(_historyStartIndex)
                  .take(_historyPageSize)
                  .toList();
              return Column(
                children: paged.map((doc) {
                  final data = doc.data();
                  final dateKey = (data['dateKey'] as String?) ?? '--';
                  final mood = _resolveMood(data);
                  final dateLabel = _formatDateKey(dateKey);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B1D22),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0x24FFFFFF)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: MoodUtils.getColorFromMood(mood),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            mood,
                            style: const TextStyle(
                              color: Color(0xFFE6E7EA),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          dateLabel,
                          style: const TextStyle(
                            color: Color(0xFF9EA3AF),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
      ],
    );
  }

  String _formatTime(dynamic createdAt) {
    if (createdAt is! Timestamp) return '--';
    final date = createdAt.toDate();
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _formatDateKey(String dateKey) {
    final now = DateTime.now();
    final today = _dateKey(now);
    final yesterday = _dateKey(now.subtract(const Duration(days: 1)));

    if (dateKey == today) return 'Today';
    if (dateKey == yesterday) return 'Yesterday';
    return dateKey;
  }

  String _dateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _resolveMood(Map<String, dynamic> data) {
    final moodValue = data['mood'];
    if (moodValue is String && moodValue.isNotEmpty) return moodValue;
    final score = ((data['score'] ?? 0) as num).toDouble();
    return MoodTheme.scoreToMood(score);
  }

  int _calculateStreak(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    var streak = 0;
    for (final doc in docs) {
      final dateKey = doc.data()['dateKey'] as String?;
      if (dateKey == null || dateKey.isEmpty) break;
      final mood = _resolveMood(doc.data());
      if (MoodTheme.getScore(mood) >= 3) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  Widget _buildTodayStateCard({
    required String title,
    required String subtitle,
    required String? mood,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1D2026), Color(0xFF17191E)],
        ),
        border: Border.all(color: const Color(0x45C7D3F2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22446195),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: MoodUtils.getColorFromMood(mood ?? ''),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFFA7ACB5),
              fontSize: 13,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: widget.onReflectMore,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0x39FFFFFF)),
              foregroundColor: const Color(0xFFE2E6EF),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Reflect more'),
          ),
        ],
      ),
    );
  }

  String _todaySubtitle(String? mood) {
    switch (mood) {
      case 'Calm':
        return "You're in a good space. Keep it steady.";
      case 'Okay':
        return "You're doing alright. Small steps matter.";
      case 'Stressed':
        return "Take a pause. You don't have to rush.";
      case 'Low':
        return "It's okay to slow down. Be kind to yourself.";
      default:
        return 'Track your mood to get better insights';
    }
  }

  String _getMoodSupportText(String mood) {
    switch (mood) {
      case 'Calm':
        return "That's great. Let's build on this.";
      case 'Okay':
        return "You're doing fine. Want to reflect a bit deeper?";
      case 'Stressed':
        return "Take a pause. You don't have to rush.";
      case 'Low':
        return "It's okay to slow down. Be kind to yourself.";
      default:
        return '';
    }
  }

  String _averageMoodFromDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    var total = 0.0;
    var count = 0;

    for (final doc in docs) {
      final scoreValue = doc.data()['score'];
      if (scoreValue is num) {
        total += scoreValue.toDouble();
        count += 1;
      }
    }

    if (count == 0) return 'Low';

    final avg = total / count;
    if (avg >= 3.5) return 'Calm';
    if (avg >= 2.5) return 'Okay';
    if (avg >= 1.5) return 'Stressed';
    return 'Low';
  }

  Widget _buildPagerButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: enabled ? 1 : 0.45,
      child: InkWell(
        onTap: enabled
            ? () {
                FocusScope.of(context).unfocus();
                onTap();
              }
            : null,
        borderRadius: BorderRadius.circular(999),
        hoverColor: const Color(0x1FFFFFFF),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0x33FFFFFF)),
            color: const Color(0xFF1D1F25),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFFD9DDE6)),
        ),
      ),
    );
  }
}

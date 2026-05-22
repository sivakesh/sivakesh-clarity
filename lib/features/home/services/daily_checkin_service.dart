import 'package:cloud_firestore/cloud_firestore.dart';

class DailyCheckinService {
  final FirebaseFirestore _firestore;

  DailyCheckinService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const Map<String, int> moodScores = {
    'Calm': 4,
    'Okay': 3,
    'Stressed': 2,
    'Low': 1,
  };

  Future<void> saveCheckin({required String userId, required String mood}) async {
    final score = moodScores[mood];
    if (score == null) throw Exception('Invalid mood');

    final now = DateTime.now();
    final dateKey = _dateKey(now);

    final dailyRef = _firestore.collection('dailyCheckins');
    final today = await dailyRef
        .where('userId', isEqualTo: userId)
        .where('dateKey', isEqualTo: dateKey)
        .limit(1)
        .get();

    // 1) Always append a moment check-in (unlimited per day).
    await _firestore.collection('momentCheckins').add({
      'userId': userId,
      'mood': mood,
      'score': score,
      'createdAt': Timestamp.now(),
    });

    // 2) Keep one daily summary by upserting for current day.
    if (today.docs.isNotEmpty) {
      await today.docs.first.reference.update({
        'mood': mood,
        'score': score,
        'dateKey': dateKey,
        'createdAt': Timestamp.now(),
      });
      return;
    }

    await dailyRef.add({
      'userId': userId,
      'dateKey': dateKey,
      'mood': mood,
      'score': score,
      'createdAt': Timestamp.now(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> todayMomentCheckins(
    String userId,
  ) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    // Firestore composite index required for this query:
    // 1) userId ASC
    // 2) createdAt DESC
    // If missing, Firestore will return an error with a create-index link.
    return _firestore
        .collection('momentCheckins')
        .where('userId', isEqualTo: userId)
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> todayDailySummary(String userId) {
    final dateKey = _dateKey(DateTime.now());
    return _firestore
        .collection('dailyCheckins')
        .where('userId', isEqualTo: userId)
        .where('dateKey', isEqualTo: dateKey)
        .limit(1)
        .snapshots();
  }

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

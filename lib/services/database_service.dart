import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_models.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // ==================== USER OPERATIONS ====================

  Future<void> createUserDocument(User user, {String? learningGoal, int? dailyGoalMinutes}) async {
    final userDoc = _db.collection('users').doc(user.uid);
    final docSnapshot = await userDoc.get();
    
    if (!docSnapshot.exists) {
      final newUser = UserModel(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? 'Learner',
        photoUrl: user.photoURL,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        gems: 50, // Starting bonus
        coins: 100, // Starting bonus
        learningGoal: learningGoal,
        dailyGoalMinutes: dailyGoalMinutes ?? 10,
      );
      await userDoc.set(newUser.toFirestore());
    } else {
      await userDoc.update({
        'lastLoginAt': Timestamp.now(),
      });
    }
  }

  Future<UserModel?> getCurrentUser() async {
    if (currentUserId == null) return null;
    final doc = await _db.collection('users').doc(currentUserId).get();
    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }
    return null;
  }

  Stream<UserModel?> userStream() {
    if (currentUserId == null) return Stream.value(null);
    return _db.collection('users').doc(currentUserId).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    });
  }

  Future<void> updateUserStats({
    int? gemsToAdd,
    int? coinsToAdd,
    int? xpToAdd,
    int? lessonsCompleted,
    int? signsLearned,
    int? practiceMinutes,
  }) async {
    if (currentUserId == null) return;
    
    final updates = <String, dynamic>{};
    
    if (gemsToAdd != null) {
      updates['gems'] = FieldValue.increment(gemsToAdd);
    }
    if (coinsToAdd != null) {
      updates['coins'] = FieldValue.increment(coinsToAdd);
    }
    if (xpToAdd != null) {
      updates['xp'] = FieldValue.increment(xpToAdd);
    }
    if (lessonsCompleted != null) {
      updates['totalLessonsCompleted'] = FieldValue.increment(lessonsCompleted);
    }
    if (signsLearned != null) {
      updates['totalSignsLearned'] = FieldValue.increment(signsLearned);
    }
    if (practiceMinutes != null) {
      updates['totalPracticeMinutes'] = FieldValue.increment(practiceMinutes);
    }
    
    if (updates.isNotEmpty) {
      await _db.collection('users').doc(currentUserId).update(updates);
    }
  }

  Future<void> updateStreak() async {
    if (currentUserId == null) return;
    
    final userDoc = await _db.collection('users').doc(currentUserId).get();
    if (!userDoc.exists) return;
    
    final userData = userDoc.data()!;
    final lastStreakDate = (userData['lastStreakDate'] as Timestamp?)?.toDate();
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    
    if (lastStreakDate == null) {
      // First time - start streak
      await _db.collection('users').doc(currentUserId).update({
        'streakDays': 1,
        'lastStreakDate': Timestamp.fromDate(todayDate),
      });
    } else {
      final lastDate = DateTime(lastStreakDate.year, lastStreakDate.month, lastStreakDate.day);
      final difference = todayDate.difference(lastDate).inDays;
      
      if (difference == 0) {
        // Already practiced today
        return;
      } else if (difference == 1) {
        // Consecutive day - increment streak
        await _db.collection('users').doc(currentUserId).update({
          'streakDays': FieldValue.increment(1),
          'lastStreakDate': Timestamp.fromDate(todayDate),
        });
      } else {
        // Streak broken - reset
        await _db.collection('users').doc(currentUserId).update({
          'streakDays': 1,
          'lastStreakDate': Timestamp.fromDate(todayDate),
        });
      }
    }
  }

  // ==================== CATEGORY OPERATIONS ====================

  Stream<List<CategoryModel>> categoriesStream() {
    return _db
        .collection('categories')
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => CategoryModel.fromFirestore(doc)).toList());
  }

  Future<List<CategoryModel>> getCategories() async {
    final snapshot = await _db.collection('categories').orderBy('order').get();
    return snapshot.docs.map((doc) => CategoryModel.fromFirestore(doc)).toList();
  }

  // ==================== LESSON OPERATIONS ====================

  Stream<List<LessonModel>> lessonsStream(String categoryId) {
    return _db
        .collection('categories')
        .doc(categoryId)
        .collection('lessons')
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => LessonModel.fromFirestore(doc)).toList());
  }

  Future<List<LessonModel>> getLessons(String categoryId) async {
    final snapshot = await _db
        .collection('categories')
        .doc(categoryId)
        .collection('lessons')
        .orderBy('order')
        .get();
    return snapshot.docs.map((doc) => LessonModel.fromFirestore(doc)).toList();
  }

  Future<LessonModel?> getLesson(String categoryId, String lessonId) async {
    final doc = await _db
        .collection('categories')
        .doc(categoryId)
        .collection('lessons')
        .doc(lessonId)
        .get();
    if (doc.exists) {
      return LessonModel.fromFirestore(doc);
    }
    return null;
  }

  // ==================== SIGN OPERATIONS ====================

  Stream<List<SignModel>> signsStream(String categoryId, String lessonId) {
    return _db
        .collection('categories')
        .doc(categoryId)
        .collection('lessons')
        .doc(lessonId)
        .collection('signs')
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => SignModel.fromFirestore(doc)).toList());
  }

  Future<List<SignModel>> getSigns(String categoryId, String lessonId) async {
    final snapshot = await _db
        .collection('categories')
        .doc(categoryId)
        .collection('lessons')
        .doc(lessonId)
        .collection('signs')
        .orderBy('order')
        .get();
    return snapshot.docs.map((doc) => SignModel.fromFirestore(doc)).toList();
  }

  // ==================== PROGRESS OPERATIONS ====================

  Stream<List<LessonProgress>> progressStream() {
    if (currentUserId == null) return Stream.value([]);
    return _db
        .collection('users')
        .doc(currentUserId)
        .collection('progress')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => LessonProgress.fromFirestore(doc)).toList());
  }

  Future<LessonProgress?> getLessonProgress(String lessonId) async {
    if (currentUserId == null) return null;
    final doc = await _db
        .collection('users')
        .doc(currentUserId)
        .collection('progress')
        .doc(lessonId)
        .get();
    if (doc.exists) {
      return LessonProgress.fromFirestore(doc);
    }
    return null;
  }

  Future<void> startLesson(String lessonId, String categoryId) async {
    if (currentUserId == null) return;
    
    final progressDoc = _db
        .collection('users')
        .doc(currentUserId)
        .collection('progress')
        .doc(lessonId);
    
    final existing = await progressDoc.get();
    if (!existing.exists) {
      final progress = LessonProgress(
        lessonId: lessonId,
        categoryId: categoryId,
        status: 'in_progress',
        startedAt: DateTime.now(),
        attemptsCount: 1,
      );
      await progressDoc.set(progress.toFirestore());
    } else {
      await progressDoc.update({
        'status': 'in_progress',
        'attemptsCount': FieldValue.increment(1),
      });
    }
  }

  Future<void> completeSign(String lessonId, String signId) async {
    if (currentUserId == null) return;
    
    await _db
        .collection('users')
        .doc(currentUserId)
        .collection('progress')
        .doc(lessonId)
        .update({
      'signsCompleted': FieldValue.arrayUnion([signId]),
    });
  }

  Future<void> completeLesson({
    required String lessonId,
    required String categoryId,
    required double accuracy,
    required int timeSpentSeconds,
    required int gemsEarned,
    required int coinsEarned,
    required int xpEarned,
    required int signsCount,
  }) async {
    if (currentUserId == null) return;
    
    // Update progress
    await _db
        .collection('users')
        .doc(currentUserId)
        .collection('progress')
        .doc(lessonId)
        .update({
      'status': 'completed',
      'completedAt': Timestamp.now(),
      'accuracy': accuracy,
      'timeSpentSeconds': timeSpentSeconds,
      'gemsEarned': gemsEarned,
      'coinsEarned': coinsEarned,
    });
    
    // Update user stats
    await updateUserStats(
      gemsToAdd: gemsEarned,
      coinsToAdd: coinsEarned,
      xpToAdd: xpEarned,
      lessonsCompleted: 1,
      signsLearned: signsCount,
      practiceMinutes: (timeSpentSeconds / 60).ceil(),
    );

    // Track lesson-only time for the daily goal widget.
    await _updateTodayLessonPracticeMinutes(timeSpentSeconds);
    
    // Update streak
    await updateStreak();
  }

  Future<void> _updateTodayLessonPracticeMinutes(int timeSpentSeconds) async {
    if (currentUserId == null) return;

    final minutesToAdd = (timeSpentSeconds / 60).ceil();
    if (minutesToAdd <= 0) return;

    final userRef = _db.collection('users').doc(currentUserId);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(userRef);
      if (!snap.exists) return;

      final data = snap.data() ?? <String, dynamic>{};
      final previousDate = (data['todayLessonPracticeDate'] as Timestamp?)?.toDate();
      final existingMinutes = (data['todayLessonPracticeMinutes'] ?? 0) as int;

      final sameDay = previousDate != null && _isSameCalendarDay(previousDate, today);
      final updatedMinutes = sameDay ? existingMinutes + minutesToAdd : minutesToAdd;

      tx.update(userRef, {
        'todayLessonPracticeMinutes': updatedMinutes,
        'todayLessonPracticeDate': Timestamp.fromDate(today),
      });
    });
  }

  bool _isSameCalendarDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // ==================== DAILY INSIGHT OPERATIONS ====================

  Future<DailyInsight?> getTodayInsight() async {
    final today = DateTime.now();
    final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    final snapshot = await _db
        .collection('daily_insights')
        .where('date', isEqualTo: dateStr)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();
    
    if (snapshot.docs.isNotEmpty) {
      return DailyInsight.fromFirestore(snapshot.docs.first);
    }
    
    // Fallback to most recent insight
    final fallbackSnapshot = await _db
        .collection('daily_insights')
        .where('isActive', isEqualTo: true)
        .orderBy('date', descending: true)
        .limit(1)
        .get();
    
    if (fallbackSnapshot.docs.isNotEmpty) {
      return DailyInsight.fromFirestore(fallbackSnapshot.docs.first);
    }
    
    return null;
  }
}


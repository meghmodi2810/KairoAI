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
    
    // Update streak
    await updateStreak();
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

  // ==================== SEED DATA (For initial setup) ====================

  Future<void> seedInitialData() async {
    // Check if data already exists
    final categoriesSnapshot = await _db.collection('categories').limit(1).get();
    if (categoriesSnapshot.docs.isNotEmpty) {
      print('Data already seeded');
      return;
    }

    // Seed categories
    final categories = [
      CategoryModel(
        id: 'greetings',
        name: 'Greetings',
        description: 'Learn common greeting signs',
        iconEmoji: '👋',
        color: '#4A90D9',
        order: 1,
        totalLessons: 2,
        totalSigns: 8,
      ),
      CategoryModel(
        id: 'numbers',
        name: 'Numbers',
        description: 'Learn to count in ISL',
        iconEmoji: '🔢',
        color: '#E67E22',
        order: 2,
        totalLessons: 2,
        totalSigns: 10,
      ),
      CategoryModel(
        id: 'alphabets',
        name: 'Alphabets',
        description: 'Learn A-Z in ISL',
        iconEmoji: '🔤',
        color: '#9B59B6',
        order: 3,
        totalLessons: 3,
        totalSigns: 26,
        isLocked: true,
        requiredLevel: 2,
      ),
      CategoryModel(
        id: 'family',
        name: 'Family',
        description: 'Family-related signs',
        iconEmoji: '👨‍👩‍👧‍👦',
        color: '#27AE60',
        order: 4,
        totalLessons: 2,
        totalSigns: 8,
        isLocked: true,
        requiredLevel: 2,
      ),
    ];

    for (final category in categories) {
      await _db.collection('categories').doc(category.id).set(category.toFirestore());
    }

    // Seed lessons for greetings
    final greetingsLessons = [
      LessonModel(
        id: 'greetings_unit1',
        categoryId: 'greetings',
        unitNumber: 1,
        title: 'Greetings',
        subtitle: 'Basic greetings',
        description: 'Learn to say hello and goodbye',
        order: 1,
        totalSigns: 4,
        estimatedMinutes: 5,
        gemsReward: 5,
        coinsReward: 50,
        xpReward: 25,
        focusPoints: [
          'Learn basic greeting signs in ISL',
          'Understand hand positioning',
          'Practice smooth movements',
        ],
      ),
      LessonModel(
        id: 'greetings_unit2',
        categoryId: 'greetings',
        unitNumber: 2,
        title: 'Polite Words',
        subtitle: 'Thank you & Please',
        description: 'Learn polite expressions',
        order: 2,
        totalSigns: 4,
        estimatedMinutes: 5,
        gemsReward: 5,
        coinsReward: 50,
        xpReward: 25,
        requiredLessonId: 'greetings_unit1',
        focusPoints: [
          'Learn polite expressions',
          'Master "Thank You" sign',
          'Practice "Please" and "Sorry"',
        ],
      ),
    ];

    for (final lesson in greetingsLessons) {
      await _db
          .collection('categories')
          .doc('greetings')
          .collection('lessons')
          .doc(lesson.id)
          .set(lesson.toFirestore());
    }

    // Seed signs for greetings_unit1
    final greetingSigns = [
      SignModel(
        id: 'hello',
        lessonId: 'greetings_unit1',
        word: 'Hello',
        wordInHindi: 'नमस्ते',
        order: 1,
        description: 'Open palm wave',
        instructions: [
          'Raise your dominant hand',
          'Keep palm facing outward',
          'Wave gently side to side',
        ],
        tips: 'Keep fingers together and relaxed',
        difficulty: 'easy',
      ),
      SignModel(
        id: 'goodbye',
        lessonId: 'greetings_unit1',
        word: 'Goodbye',
        wordInHindi: 'अलविदा',
        order: 2,
        description: 'Wave goodbye motion',
        instructions: [
          'Raise your hand to shoulder level',
          'Open and close fingers repeatedly',
          'Like a waving motion',
        ],
        tips: 'Make it a gentle, friendly wave',
        difficulty: 'easy',
      ),
      SignModel(
        id: 'good_morning',
        lessonId: 'greetings_unit1',
        word: 'Good Morning',
        wordInHindi: 'सुप्रभात',
        order: 3,
        description: 'Morning greeting sign',
        instructions: [
          'Touch your chin with flat hand',
          'Move hand outward and up',
          'Like the sun rising',
        ],
        tips: 'Smooth upward motion',
        difficulty: 'medium',
      ),
      SignModel(
        id: 'good_night',
        lessonId: 'greetings_unit1',
        word: 'Good Night',
        wordInHindi: 'शुभ रात्रि',
        order: 4,
        description: 'Night greeting sign',
        instructions: [
          'Place both hands together',
          'Tilt head slightly',
          'Like sleeping gesture',
        ],
        tips: 'Gentle, peaceful movement',
        difficulty: 'medium',
      ),
    ];

    for (final sign in greetingSigns) {
      await _db
          .collection('categories')
          .doc('greetings')
          .collection('lessons')
          .doc('greetings_unit1')
          .collection('signs')
          .doc(sign.id)
          .set(sign.toFirestore());
    }

    // Seed a daily insight
    final today = DateTime.now();
    final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    await _db.collection('daily_insights').doc('insight_$dateStr').set({
      'date': dateStr,
      'title': 'Day Insight',
      'message': 'Listen every Day Insight about your education',
      'tip': 'Practice makes perfect! Try to practice for at least 10 minutes daily.',
      'funFact': 'Did you know? ISL has regional variations across India!',
      'motivationalQuote': 'Every sign you learn brings you closer to connection.',
      'isActive': true,
      'createdAt': Timestamp.now(),
    });

    print('Initial data seeded successfully!');
  }
}

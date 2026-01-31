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

  /// Force re-seed all lesson data (deletes existing and creates new)
  Future<void> forceReseedData() async {
    print('Force re-seeding data...');
    
    // Delete existing categories and their subcollections
    final categoriesSnapshot = await _db.collection('categories').get();
    for (final doc in categoriesSnapshot.docs) {
      // Delete lessons subcollection
      final lessonsSnapshot = await doc.reference.collection('lessons').get();
      for (final lessonDoc in lessonsSnapshot.docs) {
        // Delete signs subcollection
        final signsSnapshot = await lessonDoc.reference.collection('signs').get();
        for (final signDoc in signsSnapshot.docs) {
          await signDoc.reference.delete();
        }
        await lessonDoc.reference.delete();
      }
      await doc.reference.delete();
    }
    
    print('Old data deleted, seeding new data...');
    
    // Now seed fresh data
    await _seedFreshData();
  }

  Future<void> seedInitialData() async {
    // Check if data already exists
    final categoriesSnapshot = await _db.collection('categories').limit(1).get();
    if (categoriesSnapshot.docs.isNotEmpty) {
      print('Data already seeded');
      return;
    }

    await _seedFreshData();
  }

  Future<void> _seedFreshData() async {
    // Seed categories with child-friendly descriptions
    final categories = [
      CategoryModel(
        id: 'greetings',
        name: 'Greetings',
        description: 'Say hello and make new friends! 👋',
        iconEmoji: '👋',
        color: '#4A90D9',
        order: 1,
        totalLessons: 2,
        totalSigns: 8,
      ),
      CategoryModel(
        id: 'numbers',
        name: 'Numbers',
        description: 'Count from 1 to 10 with your hands! 🔢',
        iconEmoji: '🔢',
        color: '#E67E22',
        order: 2,
        totalLessons: 2,
        totalSigns: 10,
      ),
      CategoryModel(
        id: 'alphabets',
        name: 'Alphabets',
        description: 'Learn the ABC in sign language! 🔤',
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
        description: 'Sign about your family members! 👨‍👩‍👧‍👦',
        iconEmoji: '👨‍👩‍👧‍👦',
        color: '#27AE60',
        order: 4,
        totalLessons: 2,
        totalSigns: 8,
        isLocked: true,
        requiredLevel: 2,
      ),
      CategoryModel(
        id: 'colors',
        name: 'Colors',
        description: 'Express all the colors of the rainbow! 🌈',
        iconEmoji: '🌈',
        color: '#E91E63',
        order: 5,
        totalLessons: 2,
        totalSigns: 8,
        isLocked: true,
        requiredLevel: 3,
      ),
      CategoryModel(
        id: 'animals',
        name: 'Animals',
        description: 'Sign your favorite animals! 🐾',
        iconEmoji: '🐾',
        color: '#795548',
        order: 6,
        totalLessons: 2,
        totalSigns: 10,
        isLocked: true,
        requiredLevel: 3,
      ),
    ];

    for (final category in categories) {
      await _db.collection('categories').doc(category.id).set(category.toFirestore());
    }

    // ==================== GREETINGS CATEGORY ====================
    final greetingsLessons = [
      LessonModel(
        id: 'greetings_unit1',
        categoryId: 'greetings',
        unitNumber: 1,
        title: 'Hello & Goodbye',
        subtitle: 'Basic greetings',
        description: 'Start your sign language journey by learning how to say hello and goodbye! These are the first signs everyone learns, and you will use them every day.',
        order: 1,
        totalSigns: 4,
        estimatedMinutes: 5,
        gemsReward: 5,
        coinsReward: 50,
        xpReward: 25,
        difficulty: 'easy',
        focusPoints: [
          'Wave hello like meeting a new friend',
          'Learn to say goodbye nicely',
          'Greet people in the morning and night',
          'Practice smooth and friendly movements',
        ],
      ),
      LessonModel(
        id: 'greetings_unit2',
        categoryId: 'greetings',
        unitNumber: 2,
        title: 'Polite Words',
        subtitle: 'Thank you & Please',
        description: 'Being polite is super important! Learn how to say thank you, please, and sorry in sign language. These magic words will make everyone happy!',
        order: 2,
        totalSigns: 4,
        estimatedMinutes: 5,
        gemsReward: 8,
        coinsReward: 75,
        xpReward: 35,
        difficulty: 'easy',
        requiredLessonId: 'greetings_unit1',
        focusPoints: [
          'Say "Thank You" to show gratitude',
          'Ask nicely with "Please"',
          'Apologize with "Sorry"',
          'Make everyone smile with polite signs!',
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

    // Signs for greetings_unit1 with detailed instructions
    final greetingsSigns1 = [
      SignModel(
        id: 'hello',
        lessonId: 'greetings_unit1',
        word: 'Hello',
        wordInHindi: 'नमस्ते',
        order: 1,
        description: 'A friendly wave to say hi! Use this when you meet someone.',
        instructions: [
          'Hold your hand up near your face with palm facing forward 🖐️',
          'Keep all your fingers together and pointing up',
          'Wave your hand gently from side to side - like saying hi to a friend!',
          'Smile while you sign - it makes it even friendlier! 😊',
        ],
        tips: 'Imagine you are waving at your best friend across the playground! Keep your fingers together and relaxed.',
        difficulty: 'easy',
      ),
      SignModel(
        id: 'goodbye',
        lessonId: 'greetings_unit1',
        word: 'Goodbye',
        wordInHindi: 'अलविदा',
        order: 2,
        description: 'A gentle wave to say see you later! Use this when leaving.',
        instructions: [
          'Raise your hand to about shoulder height 👋',
          'Open your palm facing the person you are waving to',
          'Bend your fingers down and up repeatedly - like your hand is saying bye-bye!',
          'Do this motion 2-3 times smoothly',
        ],
        tips: 'Think of it like your hand is opening and closing to blow kisses goodbye! Not too fast, nice and gentle.',
        difficulty: 'easy',
      ),
      SignModel(
        id: 'good_morning',
        lessonId: 'greetings_unit1',
        word: 'Good Morning',
        wordInHindi: 'सुप्रभात',
        order: 3,
        description: 'Greet people when the sun comes up! Perfect for starting the day.',
        instructions: [
          'Make a flat hand with your palm facing down ✋',
          'Start with your hand near your chin',
          'Move your hand forward and up - like the sun rising in the sky! ☀️',
          'Your palm should end up facing forward',
        ],
        tips: 'Picture the beautiful sunrise! Your hand is like the sun coming up over the horizon. Rise and shine!',
        difficulty: 'medium',
      ),
      SignModel(
        id: 'good_night',
        lessonId: 'greetings_unit1',
        word: 'Good Night',
        wordInHindi: 'शुभ रात्रि',
        order: 4,
        description: 'Say sweet dreams before bedtime! A peaceful sign for the evening.',
        instructions: [
          'Put your hands together like you are praying 🙏',
          'Bring them to the side of your face',
          'Tilt your head slightly like resting on a pillow 😴',
          'You can close your eyes a little to show sleeping',
        ],
        tips: 'Think about how cozy and peaceful it feels when you go to sleep. Your hands are like your soft pillow!',
        difficulty: 'medium',
      ),
    ];

    for (final sign in greetingsSigns1) {
      await _db
          .collection('categories')
          .doc('greetings')
          .collection('lessons')
          .doc('greetings_unit1')
          .collection('signs')
          .doc(sign.id)
          .set(sign.toFirestore());
    }

    // Signs for greetings_unit2 (Polite Words)
    final greetingsSigns2 = [
      SignModel(
        id: 'thank_you',
        lessonId: 'greetings_unit2',
        word: 'Thank You',
        wordInHindi: 'धन्यवाद',
        order: 1,
        description: 'Show gratitude when someone helps you or gives you something nice!',
        instructions: [
          'Start with a flat hand touching your chin 🤚',
          'Your fingertips should be pointing up toward your chin',
          'Move your hand forward and slightly down - like blowing a kiss of thanks!',
          'End with your palm facing up, as if offering thanks',
        ],
        tips: 'Think of it as sending a kiss of thanks to the person! The hand goes from your mouth toward them with gratitude.',
        difficulty: 'easy',
      ),
      SignModel(
        id: 'please',
        lessonId: 'greetings_unit2',
        word: 'Please',
        wordInHindi: 'कृपया',
        order: 2,
        description: 'The magic word that makes requests nicer! Always use this when asking.',
        instructions: [
          'Put your flat hand on your chest ✋',
          'Make a circular motion on your chest',
          'Move your hand clockwise (like stirring soup)',
          'Keep a gentle, polite expression on your face',
        ],
        tips: 'Circle your hand gently like rubbing your belly when you eat something yummy! It shows you are being polite and kind.',
        difficulty: 'easy',
      ),
      SignModel(
        id: 'sorry',
        lessonId: 'greetings_unit2',
        word: 'Sorry',
        wordInHindi: 'माफ़ कीजिए',
        order: 3,
        description: 'Apologize when you make a mistake. A kind way to say you feel bad!',
        instructions: [
          'Make a fist with your right hand ✊',
          'Place your fist on your chest near your heart',
          'Rub your fist in a circular motion on your chest',
          'Look sincere and a little sad to show you mean it',
        ],
        tips: 'This is like rubbing your heart because you feel sorry inside. Circle it gently - you are showing your feelings!',
        difficulty: 'easy',
      ),
      SignModel(
        id: 'excuse_me',
        lessonId: 'greetings_unit2',
        word: 'Excuse Me',
        wordInHindi: 'क्षमा कीजिए',
        order: 4,
        description: 'Get someone\'s attention politely or ask to pass by someone.',
        instructions: [
          'Extend one arm forward with palm facing to the side',
          'Keep fingers together and pointing forward',
          'Gently tap the air twice in front of you',
          'Combine with a polite facial expression',
        ],
        tips: 'Think of gently tapping someone on the shoulder to get their attention in a nice, polite way!',
        difficulty: 'medium',
      ),
    ];

    for (final sign in greetingsSigns2) {
      await _db
          .collection('categories')
          .doc('greetings')
          .collection('lessons')
          .doc('greetings_unit2')
          .collection('signs')
          .doc(sign.id)
          .set(sign.toFirestore());
    }

    // ==================== NUMBERS CATEGORY ====================
    final numbersLessons = [
      LessonModel(
        id: 'numbers_unit1',
        categoryId: 'numbers',
        unitNumber: 1,
        title: 'Numbers 1-5',
        subtitle: 'Count on one hand',
        description: 'Learn to count from 1 to 5 using just one hand! These are the building blocks for all number signs in ISL.',
        order: 1,
        totalSigns: 5,
        estimatedMinutes: 6,
        gemsReward: 6,
        coinsReward: 60,
        xpReward: 30,
        difficulty: 'easy',
        focusPoints: [
          'Count from ONE to FIVE',
          'Use your fingers clearly',
          'Practice showing numbers quickly',
          'Have fun counting things around you!',
        ],
      ),
      LessonModel(
        id: 'numbers_unit2',
        categoryId: 'numbers',
        unitNumber: 2,
        title: 'Numbers 6-10',
        subtitle: 'Count higher',
        description: 'Now let\'s count higher! Learn numbers 6 to 10 and you\'ll be able to count all your fingers!',
        order: 2,
        totalSigns: 5,
        estimatedMinutes: 6,
        gemsReward: 8,
        coinsReward: 80,
        xpReward: 40,
        difficulty: 'medium',
        requiredLessonId: 'numbers_unit1',
        focusPoints: [
          'Count from SIX to TEN',
          'Learn two-hand number signs',
          'Combine numbers you know',
          'Count to 10 super fast!',
        ],
      ),
    ];

    for (final lesson in numbersLessons) {
      await _db
          .collection('categories')
          .doc('numbers')
          .collection('lessons')
          .doc(lesson.id)
          .set(lesson.toFirestore());
    }

    // Signs for numbers_unit1 (1-5)
    final numbersSigns1 = [
      SignModel(
        id: 'one',
        lessonId: 'numbers_unit1',
        word: 'One',
        wordInHindi: 'एक',
        order: 1,
        description: 'The number 1! Just like pointing up with one finger.',
        instructions: [
          'Make a fist with your hand ✊',
          'Point your index finger (pointer finger) straight up ☝️',
          'Keep all other fingers closed in your fist',
          'Hold it steady so everyone can see!',
        ],
        tips: 'Think about pointing to show "just one" of something! Your pointer finger is your number one hero!',
        difficulty: 'easy',
      ),
      SignModel(
        id: 'two',
        lessonId: 'numbers_unit1',
        word: 'Two',
        wordInHindi: 'दो',
        order: 2,
        description: 'The number 2! Like making the peace sign or bunny ears.',
        instructions: [
          'Make a fist with your hand ✊',
          'Raise your index finger AND middle finger ✌️',
          'Keep them spread apart a little bit',
          'Other fingers stay closed in your fist',
        ],
        tips: 'It looks like bunny ears or a peace sign! Think of two things - like your two eyes or two ears!',
        difficulty: 'easy',
      ),
      SignModel(
        id: 'three',
        lessonId: 'numbers_unit1',
        word: 'Three',
        wordInHindi: 'तीन',
        order: 3,
        description: 'The number 3! Three fingers standing tall.',
        instructions: [
          'Make a fist with your hand ✊',
          'Raise your thumb, index finger, and middle finger',
          'Keep them spread out like a fan 🖐️',
          'Ring finger and pinky stay down',
        ],
        tips: 'Three fingers up! Think of three yummy scoops of ice cream 🍦🍦🍦',
        difficulty: 'easy',
      ),
      SignModel(
        id: 'four',
        lessonId: 'numbers_unit1',
        word: 'Four',
        wordInHindi: 'चार',
        order: 4,
        description: 'The number 4! Four fingers standing up together.',
        instructions: [
          'Hold your hand up with palm facing forward 🖐️',
          'Raise all four fingers (not your thumb!)',
          'Keep your thumb tucked against your palm',
          'Fingers should be together and straight',
        ],
        tips: 'Think of showing four fingers - like counting four cookies you want! Keep your thumb hidden.',
        difficulty: 'easy',
      ),
      SignModel(
        id: 'five',
        lessonId: 'numbers_unit1',
        word: 'Five',
        wordInHindi: 'पांच',
        order: 5,
        description: 'The number 5! All fingers up - high five!',
        instructions: [
          'Hold your hand up high 🖐️',
          'Spread ALL five fingers apart',
          'Palm should face forward',
          'Like giving someone a high five!',
        ],
        tips: 'High five! Show all five fingers spread out. Count them: thumb, pointer, middle, ring, pinky! 🖐️',
        difficulty: 'easy',
      ),
    ];

    for (final sign in numbersSigns1) {
      await _db
          .collection('categories')
          .doc('numbers')
          .collection('lessons')
          .doc('numbers_unit1')
          .collection('signs')
          .doc(sign.id)
          .set(sign.toFirestore());
    }

    // Signs for numbers_unit2 (6-10)
    final numbersSigns2 = [
      SignModel(
        id: 'six',
        lessonId: 'numbers_unit2',
        word: 'Six',
        wordInHindi: 'छह',
        order: 1,
        description: 'The number 6! Five plus one more.',
        instructions: [
          'Show five fingers on one hand 🖐️',
          'Touch your pinky to your thumb on the same hand',
          'Keep other three fingers up',
          'It makes a special shape!',
        ],
        tips: 'Think of it as 5 + 1 = 6! Your thumb and pinky touch while three fingers stay up.',
        difficulty: 'medium',
      ),
      SignModel(
        id: 'seven',
        lessonId: 'numbers_unit2',
        word: 'Seven',
        wordInHindi: 'सात',
        order: 2,
        description: 'The number 7! A lucky number.',
        instructions: [
          'Touch your ring finger to your thumb',
          'Keep your index, middle, and pinky fingers up',
          'The three up fingers and the two touching = 7!',
          'Hold it steady',
        ],
        tips: 'Lucky number 7! Three fingers standing tall while two fingers make a circle. Count them!',
        difficulty: 'medium',
      ),
      SignModel(
        id: 'eight',
        lessonId: 'numbers_unit2',
        word: 'Eight',
        wordInHindi: 'आठ',
        order: 3,
        description: 'The number 8! Like a snowman number.',
        instructions: [
          'Touch your middle finger to your thumb',
          'Keep your index finger, ring finger, and pinky up',
          'Middle finger and thumb make a circle',
          'Four fingers visible in total',
        ],
        tips: 'The number 8 looks like a snowman ⛄! Your thumb and middle finger make one ball.',
        difficulty: 'medium',
      ),
      SignModel(
        id: 'nine',
        lessonId: 'numbers_unit2',
        word: 'Nine',
        wordInHindi: 'नौ',
        order: 4,
        description: 'The number 9! Almost to ten.',
        instructions: [
          'Touch your index finger to your thumb',
          'Keep middle, ring, and pinky fingers up',
          'Index and thumb make a small circle',
          'Three fingers standing tall',
        ],
        tips: 'So close to 10! Your pointer finger touches your thumb, leaving three fingers up. 9 is almost there!',
        difficulty: 'medium',
      ),
      SignModel(
        id: 'ten',
        lessonId: 'numbers_unit2',
        word: 'Ten',
        wordInHindi: 'दस',
        order: 5,
        description: 'The number 10! All ten fingers!',
        instructions: [
          'Make a thumbs up with your hand 👍',
          'Shake your thumb slightly from side to side',
          'Keep your fist closed with thumb pointing up',
          'A gentle wiggle shows TEN!',
        ],
        tips: 'TEN is like a super thumbs up with a wiggle! You did it - you can count to 10! 🎉',
        difficulty: 'medium',
      ),
    ];

    for (final sign in numbersSigns2) {
      await _db
          .collection('categories')
          .doc('numbers')
          .collection('lessons')
          .doc('numbers_unit2')
          .collection('signs')
          .doc(sign.id)
          .set(sign.toFirestore());
    }

    // ==================== FAMILY CATEGORY ====================
    final familyLessons = [
      LessonModel(
        id: 'family_unit1',
        categoryId: 'family',
        unitNumber: 1,
        title: 'My Family',
        subtitle: 'Mom, Dad & More',
        description: 'Learn to sign about the people you love most! Start with mom, dad, and other important family members.',
        order: 1,
        totalSigns: 4,
        estimatedMinutes: 6,
        gemsReward: 7,
        coinsReward: 70,
        xpReward: 35,
        difficulty: 'easy',
        focusPoints: [
          'Sign for your loving mother',
          'Sign for your caring father',
          'Talk about brothers and sisters',
          'Share about your family!',
        ],
      ),
      LessonModel(
        id: 'family_unit2',
        categoryId: 'family',
        unitNumber: 2,
        title: 'Extended Family',
        subtitle: 'Grandparents & More',
        description: 'Learn signs for grandparents, aunts, uncles, and more! Your whole family tree in sign language!',
        order: 2,
        totalSigns: 4,
        estimatedMinutes: 6,
        gemsReward: 10,
        coinsReward: 90,
        xpReward: 45,
        difficulty: 'medium',
        requiredLessonId: 'family_unit1',
        focusPoints: [
          'Sign for grandma and grandpa',
          'Learn aunt and uncle signs',
          'Describe your whole family',
          'Family is everything! ❤️',
        ],
      ),
    ];

    for (final lesson in familyLessons) {
      await _db
          .collection('categories')
          .doc('family')
          .collection('lessons')
          .doc(lesson.id)
          .set(lesson.toFirestore());
    }

    // Signs for family_unit1
    final familySigns1 = [
      SignModel(
        id: 'mother',
        lessonId: 'family_unit1',
        word: 'Mother',
        wordInHindi: 'माँ',
        order: 1,
        description: 'The sign for your loving mom! 👩',
        instructions: [
          'Open your hand with palm facing left 🤚',
          'Touch your thumb to your chin',
          'Tap your chin gently two times',
          'Keep your fingers spread open and relaxed',
        ],
        tips: 'Think about your mom giving you a kiss on the chin! The thumb tapping your chin means mother.',
        difficulty: 'easy',
      ),
      SignModel(
        id: 'father',
        lessonId: 'family_unit1',
        word: 'Father',
        wordInHindi: 'पिताजी',
        order: 2,
        description: 'The sign for your caring dad! 👨',
        instructions: [
          'Open your hand with palm facing left 🤚',
          'Touch your thumb to your forehead',
          'Tap your forehead gently two times',
          'Keep your fingers spread open',
        ],
        tips: 'Father is like mother, but on your forehead instead of chin! Dad has his thinking cap on.',
        difficulty: 'easy',
      ),
      SignModel(
        id: 'brother',
        lessonId: 'family_unit1',
        word: 'Brother',
        wordInHindi: 'भाई',
        order: 3,
        description: 'The sign for your brother! 👦',
        instructions: [
          'Make the sign for "father" (thumb on forehead)',
          'Then bring both hands down',
          'Point both index fingers forward',
          'Bring them together side by side',
        ],
        tips: 'It\'s like saying "boy" + "same as me"! Your brother is a boy in your family.',
        difficulty: 'medium',
      ),
      SignModel(
        id: 'sister',
        lessonId: 'family_unit1',
        word: 'Sister',
        wordInHindi: 'बहन',
        order: 4,
        description: 'The sign for your sister! 👧',
        instructions: [
          'Make the sign for "mother" (thumb on chin)',
          'Then bring both hands down',
          'Point both index fingers forward',
          'Bring them together side by side',
        ],
        tips: 'It\'s like saying "girl" + "same as me"! Your sister is a girl in your family.',
        difficulty: 'medium',
      ),
    ];

    for (final sign in familySigns1) {
      await _db
          .collection('categories')
          .doc('family')
          .collection('lessons')
          .doc('family_unit1')
          .collection('signs')
          .doc(sign.id)
          .set(sign.toFirestore());
    }

    // Signs for family_unit2
    final familySigns2 = [
      SignModel(
        id: 'grandmother',
        lessonId: 'family_unit2',
        word: 'Grandmother',
        wordInHindi: 'दादी/नानी',
        order: 1,
        description: 'The sign for your grandma! 👵',
        instructions: [
          'Make the sign for "mother" (thumb on chin)',
          'Then move your hand forward in two small hops',
          'Like showing two generations',
          'Mother\'s mother = Grandmother!',
        ],
        tips: 'Grandma is mother + one generation older! Two little bounces forward from your chin.',
        difficulty: 'medium',
      ),
      SignModel(
        id: 'grandfather',
        lessonId: 'family_unit2',
        word: 'Grandfather',
        wordInHindi: 'दादा/नाना',
        order: 2,
        description: 'The sign for your grandpa! 👴',
        instructions: [
          'Make the sign for "father" (thumb on forehead)',
          'Then move your hand forward in two small hops',
          'Like showing two generations',
          'Father\'s father = Grandfather!',
        ],
        tips: 'Grandpa is father + one generation older! Two little bounces forward from your forehead.',
        difficulty: 'medium',
      ),
      SignModel(
        id: 'aunt',
        lessonId: 'family_unit2',
        word: 'Aunt',
        wordInHindi: 'मौसी/चाची',
        order: 3,
        description: 'The sign for your aunt! 👩',
        instructions: [
          'Make the letter "A" with your hand (fist with thumb up)',
          'Hold it near your chin (like mother)',
          'Move it in a small circle',
          'Aunt is related to mother\'s side!',
        ],
        tips: 'Aunt starts with "A" and is near the chin like mother. Circle it to show it\'s a different person!',
        difficulty: 'medium',
      ),
      SignModel(
        id: 'uncle',
        lessonId: 'family_unit2',
        word: 'Uncle',
        wordInHindi: 'मामा/चाचा',
        order: 4,
        description: 'The sign for your uncle! 👨',
        instructions: [
          'Make the letter "U" with your hand (two fingers up)',
          'Hold it near your forehead (like father)',
          'Move it in a small circle',
          'Uncle is related to father\'s side!',
        ],
        tips: 'Uncle starts with "U" and is near the forehead like father. Circle it to show it\'s a different person!',
        difficulty: 'medium',
      ),
    ];

    for (final sign in familySigns2) {
      await _db
          .collection('categories')
          .doc('family')
          .collection('lessons')
          .doc('family_unit2')
          .collection('signs')
          .doc(sign.id)
          .set(sign.toFirestore());
    }

    // Seed a daily insight with child-friendly content
    final today = DateTime.now();
    final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    await _db.collection('daily_insights').doc('insight_$dateStr').set({
      'date': dateStr,
      'title': 'Fun Learning Tip! 🌟',
      'message': 'Welcome to KairoAI! Every day brings a new opportunity to learn and grow.',
      'tip': 'Practice your signs in front of a mirror! Seeing yourself helps you learn faster. Try practicing for just 10 minutes each day! 🪞',
      'funFact': 'Did you know? Sign language is different all around the world! Indian Sign Language (ISL) is used by over 5 million people in India! 🇮🇳',
      'motivationalQuote': 'Every sign you learn opens a door to new friendships! Keep practicing, you\'re doing amazing! 🌈',
      'isActive': true,
      'createdAt': Timestamp.now(),
    });

    print('Initial data seeded successfully with comprehensive child-friendly content!');
  }
}

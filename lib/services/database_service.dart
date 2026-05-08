import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_models.dart';
import '../models/experience_models.dart';
import '../models/lesson_character_models.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const List<int> _defaultXpThresholds = <int>[
    0,
    120,
    280,
    520,
    860,
    1300,
  ];

  String? get currentUserId => _auth.currentUser?.uid;

  /// Compute player level from XP.
  /// Formula: level = floor(0.5 + sqrt(0.25 + xp / 50)), min 1.
  static int computeLevel(int xp) {
    if (xp <= 0) return 1;
    final level = (0.5 + sqrt(0.25 + xp / 50.0)).floor();
    return level < 1 ? 1 : level;
  }

  // ==================== USER OPERATIONS ====================

  Future<void> createUserDocument(
    User user, {
    String? learningGoal,
    int? dailyGoalMinutes,
  }) async {
    // Admin accounts must not be mirrored into learner documents.
    final adminSnapshot = await _db.collection('admins').doc(user.uid).get();
    if (adminSnapshot.exists) {
      return;
    }

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
        currentLevel: 1,
        completedSignCharacters: const <String>[],
        postLoginExperienceV1: const ExperienceState.newLearner(),
      );
      await userDoc.set(newUser.toFirestore());
    } else {
      await userDoc.update({'lastLoginAt': Timestamp.now()});
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

  Stream<ExperienceState> experienceStateStream() {
    if (currentUserId == null) return Stream.value(const ExperienceState());
    return _db.collection('users').doc(currentUserId).snapshots().map((doc) {
      final data = doc.data();
      if (data == null || data['postLoginExperienceV1'] is! Map) {
        return const ExperienceState();
      }
      return ExperienceState.fromMap(
        Map<String, dynamic>.from(data['postLoginExperienceV1'] as Map),
      );
    });
  }

  Stream<List<String>> completedSignCharactersStream() {
    if (currentUserId == null) return Stream.value(const <String>[]);
    return _db.collection('users').doc(currentUserId).snapshots().map((doc) {
      final data = doc.data() ?? <String, dynamic>{};
      return normalizeSignCharacters(
        (data['completedSignCharacters'] as List<dynamic>? ?? const []).map(
          (value) => value.toString(),
        ),
      );
    });
  }

  Future<void> saveExperienceState(ExperienceState state) async {
    if (currentUserId == null) return;
    await _db.collection('users').doc(currentUserId).set({
      'postLoginExperienceV1': state.toFirestore(),
    }, SetOptions(merge: true));
  }

  Future<void> updateExperience({
    ExperienceStatus? tourStatus,
    String? tourStep,
    bool clearTourStep = false,
    bool? activationRequired,
    ExperienceStatus? activationStatus,
    String? activationCategoryId,
    String? activationLessonId,
    bool clearActivationLesson = false,
    ActivationStage? activationStage,
    bool? lessonTourCompleted,
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) async {
    if (currentUserId == null) return;
    final userDoc = await _db.collection('users').doc(currentUserId).get();
    final current = ExperienceState.fromMap(
      userDoc.data()?['postLoginExperienceV1'] is Map
          ? Map<String, dynamic>.from(
              userDoc.data()!['postLoginExperienceV1'] as Map,
            )
          : null,
    );

    await saveExperienceState(
      current.copyWith(
        tourStatus: tourStatus,
        tourStep: tourStep,
        clearTourStep: clearTourStep,
        activationRequired: activationRequired,
        activationStatus: activationStatus,
        activationCategoryId: activationCategoryId,
        activationLessonId: activationLessonId,
        clearActivationLesson: clearActivationLesson,
        activationStage: activationStage,
        lessonTourCompleted: lessonTourCompleted,
        updatedAt: DateTime.now(),
        completedAt: completedAt,
        clearCompletedAt: clearCompletedAt,
      ),
    );
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
      if (xpToAdd != null) {
        await _syncUserLevelFromXp();
      }
    }
  }

  Future<List<int>> _loadXpThresholds() async {
    try {
      final doc = await _db.collection('settings').doc('level_config').get();
      if (!doc.exists) {
        return _defaultXpThresholds;
      }

      final data = doc.data() ?? <String, dynamic>{};
      final rawList =
          (data['xpThresholds'] as List<dynamic>? ?? _defaultXpThresholds)
              .map((v) => (v as num).toInt())
              .toSet()
              .toList()
            ..sort();

      if (rawList.isEmpty || rawList.first != 0) {
        rawList.insert(0, 0);
      }

      return rawList;
    } catch (_) {
      return _defaultXpThresholds;
    }
  }

  int _deriveLevelFromXp(int xp, List<int> thresholds) {
    final safeXp = xp < 0 ? 0 : xp;
    var level = 1;
    for (var i = 0; i < thresholds.length; i++) {
      if (safeXp >= thresholds[i]) {
        level = i + 1;
      } else {
        break;
      }
    }
    return level;
  }

  Future<void> _syncUserLevelFromXp() async {
    if (currentUserId == null) return;

    final userDoc = await _db.collection('users').doc(currentUserId).get();
    if (!userDoc.exists) return;

    final data = userDoc.data() ?? <String, dynamic>{};
    final xp = (data['xp'] as num?)?.toInt() ?? 0;
    final thresholds = await _loadXpThresholds();
    final derivedLevel = _deriveLevelFromXp(xp, thresholds);
    final storedLevel = (data['currentLevel'] as num?)?.toInt() ?? 1;

    if (derivedLevel != storedLevel) {
      await userDoc.reference.update(<String, dynamic>{
        'currentLevel': derivedLevel,
      });
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
      final lastDate = DateTime(
        lastStreakDate.year,
        lastStreakDate.month,
        lastStreakDate.day,
      );
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
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CategoryModel.fromFirestore(doc))
              .toList(),
        );
  }

  Future<List<CategoryModel>> getCategories() async {
    final snapshot = await _db.collection('categories').orderBy('order').get();
    return snapshot.docs
        .map((doc) => CategoryModel.fromFirestore(doc))
        .toList();
  }

  // ==================== LESSON OPERATIONS ====================

  Stream<List<LessonModel>> lessonsStream(String categoryId) {
    return _db
        .collection('categories')
        .doc(categoryId)
        .collection('lessons')
        .orderBy('order')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => LessonModel.fromFirestore(doc))
              .toList(),
        );
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
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => SignModel.fromFirestore(doc)).toList(),
        );
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

  Future<List<String>> getGlobalSignLabels() async {
    final snapshot = await _db.collection('signs').get();
    final labels = <String>{};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final label = _normalizeSignLabel(data, fallbackId: doc.id);
      if (label.isNotEmpty) {
        labels.add(label);
      }
    }

    final ordered = labels.toList()..sort();
    return ordered;
  }

  Future<Map<String, String>> getGlobalSignImageUrls() async {
    final snapshot = await _db.collection('signs').get();
    final imageByLabel = <String, String>{};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final label = _normalizeSignLabel(data, fallbackId: doc.id);
      if (label.isEmpty) continue;

      final imageUrl = (data['imageUrl'] ?? data['pictureUrl'] ?? '')
          .toString()
          .trim();
      final assetPathImage = (data['assetPathImage'] ?? '').toString().trim();
      final gifUrl = (data['gifUrl'] ?? '').toString().trim();

      final resolvedRef = imageUrl.isNotEmpty
          ? imageUrl
          : assetPathImage.isNotEmpty
          ? assetPathImage
          : gifUrl;

      if (resolvedRef.isNotEmpty) {
        imageByLabel[label] = resolvedRef;
      }
    }

    return imageByLabel;
  }

  String _normalizeSignLabel(Map<String, dynamic> data, {String? fallbackId}) {
    final raw =
        (data['word'] ?? data['character'] ?? data['label'] ?? fallbackId ?? '')
            .toString()
            .trim();
    if (raw.isEmpty) return '';
    return raw.toUpperCase();
  }

  Future<List<String>> getLessonCharacters(
    String categoryId,
    String lessonId,
  ) async {
    final signs = await getSigns(categoryId, lessonId);
    return normalizeSignCharacters(signs.map((sign) => sign.word));
  }

  Future<Map<String, List<String>>> getLessonCharactersMap(
    String categoryId,
    Iterable<String> lessonIds,
  ) async {
    final result = <String, List<String>>{};
    for (final lessonId in lessonIds) {
      result[lessonId] = await getLessonCharacters(categoryId, lessonId);
    }
    return result;
  }

  Future<void> markLessonCharactersCompleted(
    Iterable<String> characters,
  ) async {
    if (currentUserId == null) return;
    final normalized = normalizeSignCharacters(characters);
    if (normalized.isEmpty) return;

    await _db.collection('users').doc(currentUserId).set({
      'completedSignCharacters': FieldValue.arrayUnion(normalized),
    }, SetOptions(merge: true));
  }

  Future<ActivationLessonRef?> resolveFirstActivationLesson() async {
    if (currentUserId == null) return null;

    final user = await getCurrentUser();
    final currentLevel = user?.currentLevel ?? 1;
    final categories = await getCategories();
    final progressIndex = await getLessonProgressIndex();

    for (final category in categories) {
      final categoryLocked =
          category.isLocked || currentLevel < category.requiredLevel;
      if (categoryLocked) continue;

      final lessons = await getLessons(category.id);
      for (final lesson in lessons) {
        if (lesson.isLocked) continue;

        if (lesson.requiredLessonId != null &&
            lesson.requiredLessonId!.trim().isNotEmpty) {
          final required = progressIndex[lesson.requiredLessonId!];
          if (required == null || required.status != 'completed') continue;
        }

        return ActivationLessonRef(
          categoryId: category.id,
          lessonId: lesson.id,
        );
      }
    }

    return null;
  }

  Future<LessonCharacterIndex> buildLessonCandidatesForCharacters(
    Set<String> characters,
  ) async {
    final missing = normalizeSignCharacters(characters).toSet();
    if (missing.isEmpty) return const LessonCharacterIndex([]);

    final categories = await getCategories();
    final candidates = <LessonCharacterCandidate>[];

    for (final category in categories) {
      final lessons = await getLessons(category.id);
      for (final lesson in lessons) {
        final lessonCharacters = (await getLessonCharacters(
          category.id,
          lesson.id,
        )).toSet();
        if (lessonCharacters.intersection(missing).isEmpty) continue;

        candidates.add(
          LessonCharacterCandidate(
            categoryId: category.id,
            categoryName: category.name,
            lessonId: lesson.id,
            lessonTitle: lesson.title,
            categoryOrder: category.order,
            lessonOrder: lesson.order,
            characters: lessonCharacters,
          ),
        );
      }
    }

    return LessonCharacterIndex(candidates);
  }

  // ==================== PROGRESS OPERATIONS ====================

  Stream<List<LessonProgress>> progressStream() {
    if (currentUserId == null) return Stream.value([]);
    return _db
        .collection('users')
        .doc(currentUserId)
        .collection('progress')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => LessonProgress.fromFirestore(doc))
              .toList(),
        );
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

  Future<Map<String, LessonProgress>> getLessonProgressIndex() async {
    if (currentUserId == null) return <String, LessonProgress>{};
    final snapshot = await _db
        .collection('users')
        .doc(currentUserId)
        .collection('progress')
        .get();
    final index = <String, LessonProgress>{};
    for (final doc in snapshot.docs) {
      index[doc.id] = LessonProgress.fromFirestore(doc);
    }
    return index;
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
        guidedCurrentIndex: 0,
      );
      await progressDoc.set(progress.toFirestore());
    } else {
      await progressDoc.update({
        'status': 'in_progress',
        'attemptsCount': FieldValue.increment(1),
      });
    }
  }

  Future<void> completeSign(
    String lessonId,
    String signId, {
    int? nextIndex,
  }) async {
    if (currentUserId == null) return;

    final updates = <String, dynamic>{
      'signsCompleted': FieldValue.arrayUnion([signId]),
      'signsSkipped': FieldValue.arrayRemove([signId]),
    };

    if (nextIndex != null) {
      updates['guidedCurrentIndex'] = nextIndex;
    }

    await _db
        .collection('users')
        .doc(currentUserId)
        .collection('progress')
        .doc(lessonId)
        .set(updates, SetOptions(merge: true));
  }

  Future<void> markSignSkipped({
    required String lessonId,
    required String signId,
    required int nextIndex,
  }) async {
    if (currentUserId == null) return;

    await _db
        .collection('users')
        .doc(currentUserId)
        .collection('progress')
        .doc(lessonId)
        .set({
          'signsSkipped': FieldValue.arrayUnion([signId]),
          'guidedCurrentIndex': nextIndex,
        }, SetOptions(merge: true));
  }

  Future<void> setGuidedCurrentIndex(String lessonId, int currentIndex) async {
    if (currentUserId == null) return;

    await _db
        .collection('users')
        .doc(currentUserId)
        .collection('progress')
        .doc(lessonId)
        .set({'guidedCurrentIndex': currentIndex}, SetOptions(merge: true));
  }

  Future<void> saveAssessmentCheckpoint({
    required String lessonId,
    required List<String> skippedAssessmentTypes,
    String? resumeAssessmentType,
    Map<String, dynamic>? assessmentResults,
    bool? guidedPracticeCompleted,
    bool? assessmentSummaryReady,
  }) async {
    if (currentUserId == null) return;

    final payload = <String, dynamic>{
      'assessmentsSkipped': skippedAssessmentTypes,
      'assessmentResumeFrom': resumeAssessmentType,
    };

    if (assessmentResults != null) {
      payload['assessmentResults'] = assessmentResults;
    }

    if (guidedPracticeCompleted != null) {
      payload['guidedPracticeCompleted'] = guidedPracticeCompleted;
    }

    if (assessmentSummaryReady != null) {
      payload['assessmentSummaryReady'] = assessmentSummaryReady;
    }

    await _db
        .collection('users')
        .doc(currentUserId)
        .collection('progress')
        .doc(lessonId)
        .set(payload, SetOptions(merge: true));
  }

  Future<void> restartLessonProgress({
    required String lessonId,
    required String categoryId,
  }) async {
    if (currentUserId == null) return;

    final progressRef = _db
        .collection('users')
        .doc(currentUserId)
        .collection('progress')
        .doc(lessonId);

    final snapshot = await progressRef.get();
    final data = snapshot.data();
    final attemptsCount = (data?['attemptsCount'] as num?)?.toInt() ?? 0;
    final wasCompleted = data?['status'] == 'completed';
    final preservedCompletedAt = data?['completedAt'];
    final now = Timestamp.now();

    await progressRef.set({
      'categoryId': categoryId,
      'status': wasCompleted ? 'completed' : 'in_progress',
      'startedAt': now,
      'lastAttemptAt': now,
      'completedAt': wasCompleted ? preservedCompletedAt : null,
      'attemptsCount': attemptsCount + 1,
      'accuracy': null,
      'timeSpentSeconds': 0,
      'gemsEarned': 0,
      'coinsEarned': 0,
      'xpEarned': 0,
      'signsCompleted': <String>[],
      'signsSkipped': <String>[],
      'guidedPracticeCompleted': false,
      'guidedCurrentIndex': 0,
      'assessmentsSkipped': <String>[],
      'assessmentResumeFrom': null,
      'assessmentSummaryReady': false,
      'assessmentResults': <String, dynamic>{},
    }, SetOptions(merge: true));
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
    List<String> completedCharacters = const <String>[],
    Map<String, dynamic>? assessmentResults,
  }) async {
    if (currentUserId == null) return;

    final userRef = _db.collection('users').doc(currentUserId);
    final progressRef = userRef.collection('progress').doc(lessonId);
    final now = Timestamp.now();
    final practiceMinutes = (timeSpentSeconds / 60).ceil();

    await _db.runTransaction((tx) async {
      final progressSnap = await tx.get(progressRef);
      final userSnap = await tx.get(userRef);
      final existingData = progressSnap.data();
      final wasAlreadyCompleted = existingData?['status'] == 'completed';
      final firstCompletedAt = existingData?['completedAt'] as Timestamp?;

      final safeXpEarned = xpEarned < 0 ? 0 : xpEarned;
      final safeGemsEarned = wasAlreadyCompleted
          ? 0
          : (gemsEarned < 0 ? 0 : gemsEarned);
      final safeCoinsEarned = wasAlreadyCompleted
          ? 0
          : (coinsEarned < 0 ? 0 : coinsEarned);
      final normalizedCharacters = normalizeSignCharacters(completedCharacters);

      tx.set(progressRef, {
        'categoryId': categoryId,
        'status': 'completed',
        'completedAt': firstCompletedAt ?? now,
        'lastAttemptAt': now,
        'accuracy': accuracy,
        'timeSpentSeconds': timeSpentSeconds,
        'gemsEarned': safeGemsEarned,
        'coinsEarned': safeCoinsEarned,
        'xpEarned': safeXpEarned,
        'signsSkipped': <String>[],
        'guidedPracticeCompleted': true,
        'guidedCurrentIndex': signsCount > 0 ? signsCount - 1 : 0,
        'assessmentsSkipped': <String>[],
        'assessmentResumeFrom': null,
        'assessmentSummaryReady': false,
        'assessmentResults':
            assessmentResults ??
            (existingData?['assessmentResults'] is Map
                ? Map<String, dynamic>.from(
                    existingData!['assessmentResults'] as Map,
                  )
                : <String, dynamic>{}),
      }, SetOptions(merge: true));

      final updates = <String, dynamic>{
        'xp': FieldValue.increment(safeXpEarned),
        'totalPracticeMinutes': FieldValue.increment(practiceMinutes),
      };

      if (normalizedCharacters.isNotEmpty) {
        updates['completedSignCharacters'] = FieldValue.arrayUnion(
          normalizedCharacters,
        );
      }

      if (!wasAlreadyCompleted) {
        updates['gems'] = FieldValue.increment(safeGemsEarned);
        updates['coins'] = FieldValue.increment(safeCoinsEarned);
        updates['totalLessonsCompleted'] = FieldValue.increment(1);
        updates['totalSignsLearned'] = FieldValue.increment(signsCount);
      }

      // Recalculate level from new XP total.
      final currentXp = (userSnap.data()?['xp'] as int?) ?? 0;
      final newLevel = computeLevel(currentXp + safeXpEarned);
      updates['currentLevel'] = newLevel;

      tx.update(userRef, updates);
    });

    // Track lesson-only time for the daily goal widget.
    await _updateTodayLessonPracticeMinutes(timeSpentSeconds);

    // Keep user level derived from XP thresholds.
    await _syncUserLevelFromXp();

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
      final previousDate = (data['todayLessonPracticeDate'] as Timestamp?)
          ?.toDate();
      final existingMinutes = (data['todayLessonPracticeMinutes'] ?? 0) as int;

      final sameDay =
          previousDate != null && _isSameCalendarDay(previousDate, today);
      final updatedMinutes = sameDay
          ? existingMinutes + minutesToAdd
          : minutesToAdd;

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
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

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

  // ==================== WORD PRACTICE OPERATIONS ====================

  Stream<List<WordGroupUnlockModel>> wordGroupUnlocksStream() {
    if (currentUserId == null) return Stream.value([]);
    return _db
        .collection('users')
        .doc(currentUserId)
        .collection('word_group_unlocks')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => WordGroupUnlockModel.fromFirestore(doc))
              .toList(),
        );
  }

  Stream<List<WordProgressModel>> wordProgressStream(String groupId) {
    if (currentUserId == null) return Stream.value([]);
    return _db
        .collection('users')
        .doc(currentUserId)
        .collection('word_progress')
        .where('groupId', isEqualTo: groupId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => WordProgressModel.fromFirestore(doc))
              .toList(),
        );
  }

  Future<bool> unlockWordGroup(String groupId, int cost) async {
    if (currentUserId == null) return false;

    final userRef = _db.collection('users').doc(currentUserId);
    final unlockRef = userRef.collection('word_group_unlocks').doc(groupId);

    try {
      await _db.runTransaction((tx) async {
        final userDoc = await tx.get(userRef);
        final userData = userDoc.data() ?? {};
        final currentGems = userData['gems'] as int? ?? 0;

        if (currentGems < cost) {
          throw Exception('Insufficient gems to unlock this pack.');
        }

        final unlockDoc = await tx.get(unlockRef);
        if (unlockDoc.exists) {
          // Already unlocked
          return;
        }

        tx.update(userRef, {'gems': FieldValue.increment(-cost)});

        final unlockModel = WordGroupUnlockModel(
          groupId: groupId,
          unlockedAt: DateTime.now(),
          gemCostPaid: cost,
        );

        tx.set(unlockRef, unlockModel.toFirestore());
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> updateWordProgress(WordProgressModel progress) async {
    if (currentUserId == null) return;
    await _db
        .collection('users')
        .doc(currentUserId)
        .collection('word_progress')
        .doc(progress.wordId)
        .set(progress.toFirestore(), SetOptions(merge: true));
  }

  Future<void> grantWordCompletionReward({
    required int xpEarned,
    required int coinsEarned,
    required int gemsEarned,
  }) async {
    if (currentUserId == null) return;

    final userRef = _db.collection('users').doc(currentUserId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(userRef);
      final currentXp = (snap.data()?['xp'] as int?) ?? 0;
      final newLevel = computeLevel(currentXp + xpEarned);

      final updates = <String, dynamic>{'currentLevel': newLevel};
      if (xpEarned > 0) updates['xp'] = FieldValue.increment(xpEarned);
      if (coinsEarned > 0) updates['coins'] = FieldValue.increment(coinsEarned);
      if (gemsEarned > 0) updates['gems'] = FieldValue.increment(gemsEarned);

      tx.update(userRef, updates);
    });
  }

  Future<void> saveWordPracticeLog(Map<String, dynamic> logData) async {
    if (currentUserId == null) return;

    // Convert to SignPracticeLogModel if it exists or just push raw data.
    // Given SignPracticeLogModel is in admin_models, we can just push raw data
    // structured identically.
    await _db.collection('sign_practice_logs').add({
      ...logData,
      'learnerId': currentUserId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}

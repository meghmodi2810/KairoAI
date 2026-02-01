import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  
  // Gamification
  final int gems;
  final int coins;
  final int streakDays;
  final DateTime? lastStreakDate;
  
  // Settings
  final String? learningGoal;
  final int dailyGoalMinutes;
  
  // Progress summary
  final int totalLessonsCompleted;
  final int totalSignsLearned;
  final int totalPracticeMinutes;
  final int currentLevel;
  final int xp;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.createdAt,
    required this.lastLoginAt,
    this.gems = 0,
    this.coins = 0,
    this.streakDays = 0,
    this.lastStreakDate,
    this.learningGoal,
    this.dailyGoalMinutes = 10,
    this.totalLessonsCompleted = 0,
    this.totalSignsLearned = 0,
    this.totalPracticeMinutes = 0,
    this.currentLevel = 1,
    this.xp = 0,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoUrl: data['photoUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      gems: data['gems'] ?? 0,
      coins: data['coins'] ?? 0,
      streakDays: data['streakDays'] ?? 0,
      lastStreakDate: (data['lastStreakDate'] as Timestamp?)?.toDate(),
      learningGoal: data['learningGoal'],
      dailyGoalMinutes: data['dailyGoalMinutes'] ?? 10,
      totalLessonsCompleted: data['totalLessonsCompleted'] ?? 0,
      totalSignsLearned: data['totalSignsLearned'] ?? 0,
      totalPracticeMinutes: data['totalPracticeMinutes'] ?? 0,
      currentLevel: data['currentLevel'] ?? 1,
      xp: data['xp'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': Timestamp.fromDate(lastLoginAt),
      'gems': gems,
      'coins': coins,
      'streakDays': streakDays,
      'lastStreakDate': lastStreakDate != null ? Timestamp.fromDate(lastStreakDate!) : null,
      'learningGoal': learningGoal,
      'dailyGoalMinutes': dailyGoalMinutes,
      'totalLessonsCompleted': totalLessonsCompleted,
      'totalSignsLearned': totalSignsLearned,
      'totalPracticeMinutes': totalPracticeMinutes,
      'currentLevel': currentLevel,
      'xp': xp,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    int? gems,
    int? coins,
    int? streakDays,
    DateTime? lastStreakDate,
    String? learningGoal,
    int? dailyGoalMinutes,
    int? totalLessonsCompleted,
    int? totalSignsLearned,
    int? totalPracticeMinutes,
    int? currentLevel,
    int? xp,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      gems: gems ?? this.gems,
      coins: coins ?? this.coins,
      streakDays: streakDays ?? this.streakDays,
      lastStreakDate: lastStreakDate ?? this.lastStreakDate,
      learningGoal: learningGoal ?? this.learningGoal,
      dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
      totalLessonsCompleted: totalLessonsCompleted ?? this.totalLessonsCompleted,
      totalSignsLearned: totalSignsLearned ?? this.totalSignsLearned,
      totalPracticeMinutes: totalPracticeMinutes ?? this.totalPracticeMinutes,
      currentLevel: currentLevel ?? this.currentLevel,
      xp: xp ?? this.xp,
    );
  }
}

class CategoryModel {
  final String id;
  final String name;
  final String description;
  final String? iconUrl;
  final String iconEmoji;
  final String color;
  final int order;
  final int totalLessons;
  final int totalSigns;
  final bool isLocked;
  final int requiredLevel;

  CategoryModel({
    required this.id,
    required this.name,
    required this.description,
    this.iconUrl,
    required this.iconEmoji,
    required this.color,
    required this.order,
    required this.totalLessons,
    required this.totalSigns,
    this.isLocked = false,
    this.requiredLevel = 1,
  });

  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CategoryModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      iconUrl: data['iconUrl'],
      iconEmoji: data['iconEmoji'] ?? '📚',
      color: data['color'] ?? '#4A90D9',
      order: data['order'] ?? 0,
      totalLessons: data['totalLessons'] ?? 0,
      totalSigns: data['totalSigns'] ?? 0,
      isLocked: data['isLocked'] ?? false,
      requiredLevel: data['requiredLevel'] ?? 1,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'iconUrl': iconUrl,
      'iconEmoji': iconEmoji,
      'color': color,
      'order': order,
      'totalLessons': totalLessons,
      'totalSigns': totalSigns,
      'isLocked': isLocked,
      'requiredLevel': requiredLevel,
    };
  }
}

class LessonModel {
  final String id;
  final String categoryId;
  final int unitNumber;
  final String title;
  final String subtitle;
  final String description;
  final String? thumbnailUrl;
  final int order;
  final int totalSigns;
  final int estimatedMinutes;
  final String difficulty;
  final int gemsReward;
  final int coinsReward;
  final int xpReward;
  final bool isLocked;
  final String? requiredLessonId;
  final List<String> focusPoints;

  LessonModel({
    required this.id,
    required this.categoryId,
    required this.unitNumber,
    required this.title,
    required this.subtitle,
    required this.description,
    this.thumbnailUrl,
    required this.order,
    required this.totalSigns,
    this.estimatedMinutes = 5,
    this.difficulty = 'beginner',
    this.gemsReward = 5,
    this.coinsReward = 50,
    this.xpReward = 25,
    this.isLocked = false,
    this.requiredLessonId,
    required this.focusPoints,
  });

  factory LessonModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LessonModel(
      id: doc.id,
      categoryId: data['categoryId'] ?? '',
      unitNumber: data['unitNumber'] ?? 1,
      title: data['title'] ?? '',
      subtitle: data['subtitle'] ?? '',
      description: data['description'] ?? '',
      thumbnailUrl: data['thumbnailUrl'],
      order: data['order'] ?? 0,
      totalSigns: data['totalSigns'] ?? 0,
      estimatedMinutes: data['estimatedMinutes'] ?? 5,
      difficulty: data['difficulty'] ?? 'beginner',
      gemsReward: data['gemsReward'] ?? 5,
      coinsReward: data['coinsReward'] ?? 50,
      xpReward: data['xpReward'] ?? 25,
      isLocked: data['isLocked'] ?? false,
      requiredLessonId: data['requiredLessonId'],
      focusPoints: List<String>.from(data['focusPoints'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'categoryId': categoryId,
      'unitNumber': unitNumber,
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'order': order,
      'totalSigns': totalSigns,
      'estimatedMinutes': estimatedMinutes,
      'difficulty': difficulty,
      'gemsReward': gemsReward,
      'coinsReward': coinsReward,
      'xpReward': xpReward,
      'isLocked': isLocked,
      'requiredLessonId': requiredLessonId,
      'focusPoints': focusPoints,
    };
  }
}

class SignModel {
  final String id;
  final String lessonId;
  final String word;
  final String? wordInHindi;
  final int order;
  final String? imageUrl;
  final String? gifUrl;
  final String? videoUrl;
  final String description;
  final List<String> instructions;
  final String? tips;
  final String difficulty;

  SignModel({
    required this.id,
    required this.lessonId,
    required this.word,
    this.wordInHindi,
    required this.order,
    this.imageUrl,
    this.gifUrl,
    this.videoUrl,
    required this.description,
    required this.instructions,
    this.tips,
    this.difficulty = 'easy',
  });

  factory SignModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SignModel(
      id: doc.id,
      lessonId: data['lessonId'] ?? '',
      word: data['word'] ?? '',
      wordInHindi: data['wordInHindi'],
      order: data['order'] ?? 0,
      imageUrl: data['imageUrl'],
      gifUrl: data['gifUrl'],
      videoUrl: data['videoUrl'],
      description: data['description'] ?? '',
      instructions: List<String>.from(data['instructions'] ?? []),
      tips: data['tips'],
      difficulty: data['difficulty'] ?? 'easy',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'lessonId': lessonId,
      'word': word,
      'wordInHindi': wordInHindi,
      'order': order,
      'imageUrl': imageUrl,
      'gifUrl': gifUrl,
      'videoUrl': videoUrl,
      'description': description,
      'instructions': instructions,
      'tips': tips,
      'difficulty': difficulty,
    };
  }
}

class LessonProgress {
  final String lessonId;
  final String categoryId;
  final String status; // "not_started", "in_progress", "completed"
  final DateTime? completedAt;
  final DateTime? startedAt;
  final double accuracy;
  final int timeSpentSeconds;
  final int attemptsCount;
  final List<String> signsCompleted;
  final int gemsEarned;
  final int coinsEarned;

  LessonProgress({
    required this.lessonId,
    required this.categoryId,
    this.status = 'not_started',
    this.completedAt,
    this.startedAt,
    this.accuracy = 0.0,
    this.timeSpentSeconds = 0,
    this.attemptsCount = 0,
    this.signsCompleted = const [],
    this.gemsEarned = 0,
    this.coinsEarned = 0,
  });

  factory LessonProgress.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LessonProgress(
      lessonId: doc.id,
      categoryId: data['categoryId'] ?? '',
      status: data['status'] ?? 'not_started',
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      startedAt: (data['startedAt'] as Timestamp?)?.toDate(),
      accuracy: (data['accuracy'] ?? 0.0).toDouble(),
      timeSpentSeconds: data['timeSpentSeconds'] ?? 0,
      attemptsCount: data['attemptsCount'] ?? 0,
      signsCompleted: List<String>.from(data['signsCompleted'] ?? []),
      gemsEarned: data['gemsEarned'] ?? 0,
      coinsEarned: data['coinsEarned'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'categoryId': categoryId,
      'status': status,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'accuracy': accuracy,
      'timeSpentSeconds': timeSpentSeconds,
      'attemptsCount': attemptsCount,
      'signsCompleted': signsCompleted,
      'gemsEarned': gemsEarned,
      'coinsEarned': coinsEarned,
    };
  }
}

class DailyInsight {
  final String id;
  final String date;
  final String title;
  final String message;
  final String? tip;
  final String? funFact;
  final String? motivationalQuote;
  final String? audioUrl;
  final String? imageUrl;
  final bool isActive;

  DailyInsight({
    required this.id,
    required this.date,
    required this.title,
    required this.message,
    this.tip,
    this.funFact,
    this.motivationalQuote,
    this.audioUrl,
    this.imageUrl,
    this.isActive = true,
  });

  factory DailyInsight.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DailyInsight(
      id: doc.id,
      date: data['date'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      tip: data['tip'],
      funFact: data['funFact'],
      motivationalQuote: data['motivationalQuote'],
      audioUrl: data['audioUrl'],
      imageUrl: data['imageUrl'],
      isActive: data['isActive'] ?? true,
    );
  }
}

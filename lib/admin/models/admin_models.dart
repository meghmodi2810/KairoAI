import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kairo_ai/models/app_models.dart';

/// Admin user model matching Firebase structure
class AdminModel {
  final String id;
  final String email;
  final String displayName;
  final bool isActive;
  final String role; // 'super_admin', 'admin', 'content_manager'
  final List<String> permissions;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;

  AdminModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.isActive = true,
    this.role = 'admin',
    this.permissions = const [],
    this.createdAt,
    this.lastLoginAt,
  });

  // Alias for backwards compatibility
  String get uid => id;

  factory AdminModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdminModel(
      id: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      isActive: data['isActive'] ?? true,
      role: data['role'] ?? 'admin',
      permissions: List<String>.from(data['permissions'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'isActive': isActive,
      'role': role,
      'permissions': permissions,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : FieldValue.serverTimestamp(),
    };
  }

  bool hasPermission(String permission) {
    return role == 'super_admin' || permissions.contains(permission);
  }

  AdminModel copyWith({
    String? id,
    String? email,
    String? displayName,
    bool? isActive,
    String? role,
    List<String>? permissions,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return AdminModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      isActive: isActive ?? this.isActive,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}

/// Lesson model for admin management with full CRUD fields
class AdminLessonModel {
  final String id;
  final String title;
  final String description;
  final String categoryId;
  final int unitNumber;
  final String type; // 'alphabet', 'numeric', 'both'
  final String difficulty; // 'Beginner', 'Intermediate', 'Advanced'
  final int estimatedMinutes;
  final int gemsReward;
  final int coinsReward;
  final int xpReward;
  final List<AdminSignItem> signs;
  final List<String> testTypes; // 'mcq', 'matching', 'recall'
  final int order;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  AdminLessonModel({
    required this.id,
    required this.title,
    this.description = '',
    required this.categoryId,
    this.unitNumber = 1,
    required this.type,
    this.difficulty = 'Beginner',
    this.estimatedMinutes = 5,
    this.gemsReward = 5,
    this.coinsReward = 50,
    this.xpReward = 25,
    required this.signs,
    required this.testTypes,
    this.order = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  /// Alias for backwards compatibility
  String get name => title;

  factory AdminLessonModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdminLessonModel(
      id: doc.id,
      title: data['title'] ?? data['name'] ?? '',
      description: data['description'] ?? '',
      categoryId: data['categoryId'] ?? '',
      unitNumber: data['unitNumber'] ?? 1,
      type: data['type'] ?? 'alphabet',
      difficulty: data['difficulty'] ?? 'Beginner',
      estimatedMinutes: data['estimatedMinutes'] ?? 5,
      gemsReward: data['gemsReward'] ?? 5,
      coinsReward: data['coinsReward'] ?? 50,
      xpReward: data['xpReward'] ?? 25,
      signs: (data['signs'] as List<dynamic>?)
              ?.map((s) => AdminSignItem.fromMap(s as Map<String, dynamic>))
              .toList() ??
          [],
      testTypes: List<String>.from(data['testTypes'] ?? ['mcq']),
      order: data['order'] ?? 0,
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'categoryId': categoryId,
      'unitNumber': unitNumber,
      'type': type,
      'difficulty': difficulty,
      'estimatedMinutes': estimatedMinutes,
      'gemsReward': gemsReward,
      'coinsReward': coinsReward,
      'xpReward': xpReward,
      'signs': signs.map((s) => s.toMap()).toList(),
      'testTypes': testTypes,
      'order': order,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
    };
  }
}

class AdminSignItem {
  final String character;
  final String? animationUrl;
  final String? pictureUrl;
  final int order;
  final String? description;

  AdminSignItem({
    required this.character,
    this.animationUrl,
    this.pictureUrl,
    this.order = 0,
    this.description,
  });

  factory AdminSignItem.fromMap(Map<String, dynamic> map) {
    return AdminSignItem(
      character: map['character'] ?? '',
      animationUrl: map['animationUrl'],
      pictureUrl: map['pictureUrl'],
      order: map['order'] ?? 0,
      description: map['description'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'character': character,
      'animationUrl': animationUrl,
      'pictureUrl': pictureUrl,
      'order': order,
      'description': description,
    };
  }
}

/// Admin Sign model for the global SIGNS collection
class AdminSignModel {
  final String id;
  final String word; // The letter or number e.g. "A", "1"
  final String description;
  final String? imageUrl;
  final String? gifUrl;
  final String? videoUrl;
  final String type; // 'alphabet', 'number'
  final int order;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  AdminSignModel({
    required this.id,
    required this.word,
    this.description = '',
    this.imageUrl,
    this.gifUrl,
    this.videoUrl,
    this.type = 'alphabet',
    this.order = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AdminSignModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdminSignModel(
      id: doc.id,
      word: data['word'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'],
      gifUrl: data['gifUrl'],
      videoUrl: data['videoUrl'],
      type: data['type'] ?? 'alphabet',
      order: data['order'] ?? 0,
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'word': word,
      'description': description,
      'imageUrl': imageUrl,
      'gifUrl': gifUrl,
      'videoUrl': videoUrl,
      'type': type,
      'order': order,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

/// MCQ Question model for automated test generation
class MCQQuestion {
  final AdminSignModel correctSign;
  final List<AdminSignModel> options; // correct + 3 wrong
  final String questionText;

  MCQQuestion({
    required this.correctSign,
    required this.options,
    required this.questionText,
  });

  Map<String, dynamic> toMap() {
    return {
      'correctSignId': correctSign.id,
      'correctWord': correctSign.word,
      'questionText': questionText,
      'options': options
          .map((s) => {
                'signId': s.id,
                'word': s.word,
                'imageUrl': s.imageUrl,
                'gifUrl': s.gifUrl,
              })
          .toList(),
    };
  }
}

/// Word Group model for admin management
class WordGroupModel {
  final String id;
  final String name;
  final String description;
  final int gemCost;
  final int order;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  WordGroupModel({
    required this.id,
    required this.name,
    required this.description,
    this.gemCost = 0,
    this.order = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WordGroupModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WordGroupModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      gemCost: data['gemCost'] ?? 0,
      order: data['order'] ?? 0,
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'gemCost': gemCost,
      'order': order,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

/// Word model within a word group
class WordModel {
  final String id;
  final String wordGroupId;
  final String text;
  final List<WordCharacter> characters;
  final int order;
  final DateTime createdAt;

  WordModel({
    required this.id,
    required this.wordGroupId,
    required this.text,
    required this.characters,
    this.order = 0,
    required this.createdAt,
  });

  factory WordModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WordModel(
      id: doc.id,
      wordGroupId: data['wordGroupId'] ?? '',
      text: data['text'] ?? '',
      characters: (data['characters'] as List<dynamic>?)
              ?.map((c) => WordCharacter.fromMap(c as Map<String, dynamic>))
              .toList() ??
          [],
      order: data['order'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'wordGroupId': wordGroupId,
      'text': text,
      'characters': characters.map((c) => c.toMap()).toList(),
      'order': order,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class WordCharacter {
  final String char;
  final String? signReference;

  WordCharacter({
    required this.char,
    this.signReference,
  });

  factory WordCharacter.fromMap(Map<String, dynamic> map) {
    return WordCharacter(
      char: map['char'] ?? '',
      signReference: map['signReference'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'char': char,
      'signReference': signReference,
    };
  }
}

/// Issue/Feedback model for admin management
class IssueModel {
  final String id;
  final String reportedBy; // userId or email
  final String title;
  final String description;
  final String type; // 'bug', 'feature', 'content', 'other'
  final String priority; // 'low', 'medium', 'high', 'critical'
  final String status; // 'open', 'in_progress', 'resolved', 'closed'
  final String? lessonId;
  final String? signId;
  final List<String> attachments;
  final Map<String, dynamic>? deviceInfo;
  final String? appVersion;
  final List<AdminNote> adminNotes;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  IssueModel({
    required this.id,
    required this.reportedBy,
    required this.title,
    required this.description,
    this.type = 'other',
    this.priority = 'medium',
    this.status = 'open',
    this.lessonId,
    this.signId,
    this.attachments = const [],
    this.deviceInfo,
    this.appVersion,
    this.adminNotes = const [],
    required this.createdAt,
    this.resolvedAt,
  });

  factory IssueModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return IssueModel(
      id: doc.id,
      reportedBy: data['reportedBy'] ?? data['learnerId'] ?? data['learnerEmail'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: data['type'] ?? data['category'] ?? 'other',
      priority: data['priority'] ?? 'medium',
      status: data['status'] ?? 'open',
      lessonId: data['lessonId'],
      signId: data['signId'],
      attachments: List<String>.from(data['attachments'] ?? []),
      deviceInfo: data['deviceInfo'] as Map<String, dynamic>?,
      appVersion: data['appVersion'],
      adminNotes: (data['adminNotes'] as List<dynamic>?)
              ?.map((n) => AdminNote.fromMap(n as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      resolvedAt: (data['resolvedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'reportedBy': reportedBy,
      'title': title,
      'description': description,
      'type': type,
      'priority': priority,
      'status': status,
      'lessonId': lessonId,
      'signId': signId,
      'attachments': attachments,
      'deviceInfo': deviceInfo,
      'appVersion': appVersion,
      'adminNotes': adminNotes.map((n) => n.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
    };
  }
}

class AdminNote {
  final String adminId;
  final String adminName;
  final String content;
  final DateTime createdAt;

  AdminNote({
    required this.adminId,
    required this.adminName,
    required this.content,
    required this.createdAt,
  });

  // Alias for content
  String get note => content;

  factory AdminNote.fromMap(Map<String, dynamic> map) {
    return AdminNote(
      adminId: map['adminId'] ?? '',
      adminName: map['adminName'] ?? '',
      content: map['content'] ?? map['note'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? 
                 (map['timestamp'] as Timestamp?)?.toDate() ?? 
                 DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'adminId': adminId,
      'adminName': adminName,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

/// Maintenance Mode model
class MaintenanceModeModel {
  final bool isEnabled;
  final String message;
  final DateTime? estimatedEndTime;
  final String? enabledBy;
  final DateTime? enabledAt;

  MaintenanceModeModel({
    this.isEnabled = false,
    this.message = 'The app is under maintenance. Please try again later.',
    this.estimatedEndTime,
    this.enabledBy,
    this.enabledAt,
  });

  factory MaintenanceModeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MaintenanceModeModel(
      isEnabled: data['isEnabled'] ?? false,
      message: data['message'] ?? 'The app is under maintenance. Please try again later.',
      estimatedEndTime: (data['estimatedEndTime'] as Timestamp?)?.toDate() ?? 
                        (data['scheduledEnd'] as Timestamp?)?.toDate(),
      enabledBy: data['enabledBy'],
      enabledAt: (data['enabledAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'isEnabled': isEnabled,
      'message': message,
      'estimatedEndTime': estimatedEndTime != null ? Timestamp.fromDate(estimatedEndTime!) : null,
      'enabledBy': enabledBy,
      'enabledAt': enabledAt != null ? Timestamp.fromDate(enabledAt!) : null,
    };
  }
}

/// Audit Log model
class AuditLogModel {
  final String id;
  final String adminId;
  final String adminEmail;
  final String adminName;
  final String action;
  final String entityType;
  final String? entityId;
  final String details;
  final Map<String, dynamic>? changes;
  final DateTime timestamp;

  AuditLogModel({
    required this.id,
    required this.adminId,
    required this.adminEmail,
    this.adminName = '',
    required this.action,
    required this.entityType,
    this.entityId,
    this.details = '',
    this.changes,
    required this.timestamp,
  });

  factory AuditLogModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final changes = data['changes'] as Map<String, dynamic>?;
    
    // Generate a readable details string from changes
    String details = data['details'] ?? '';
    if (details.isEmpty && changes != null) {
      details = changes.entries
          .take(3)
          .map((e) => '${e.key}: ${e.value}')
          .join(', ');
    }
    
    return AuditLogModel(
      id: doc.id,
      adminId: data['adminId'] ?? '',
      adminEmail: data['adminEmail'] ?? '',
      adminName: data['adminName'] ?? data['adminEmail']?.split('@').first ?? '',
      action: data['action'] ?? '',
      entityType: data['entityType'] ?? '',
      entityId: data['entityId'],
      details: details,
      changes: changes,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'adminId': adminId,
      'adminEmail': adminEmail,
      'adminName': adminName,
      'action': action,
      'entityType': entityType,
      'entityId': entityId,
      'details': details,
      'changes': changes,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}

/// Sign Practice Log for analytics
class SignPracticeLogModel {
  final String id;
  final String learnerId;
  final String lessonId;
  final String signId;
  final String signCharacter;
  final int timeTaken; // milliseconds
  final bool isCorrect;
  final double confidenceScore;
  final DateTime timestamp;
  final int attemptNumber;

  SignPracticeLogModel({
    required this.id,
    required this.learnerId,
    required this.lessonId,
    required this.signId,
    required this.signCharacter,
    required this.timeTaken,
    required this.isCorrect,
    this.confidenceScore = 0.0,
    required this.timestamp,
    this.attemptNumber = 1,
  });

  factory SignPracticeLogModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SignPracticeLogModel(
      id: doc.id,
      learnerId: data['learnerId'] ?? '',
      lessonId: data['lessonId'] ?? '',
      signId: data['signId'] ?? data['signCharacter'] ?? '',
      signCharacter: data['signCharacter'] ?? '',
      timeTaken: data['timeTaken'] ?? 0,
      isCorrect: data['isCorrect'] ?? false,
      confidenceScore: (data['confidenceScore'] ?? 0.0).toDouble(),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      attemptNumber: data['attemptNumber'] ?? 1,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'learnerId': learnerId,
      'lessonId': lessonId,
      'signId': signId,
      'signCharacter': signCharacter,
      'timeTaken': timeTaken,
      'isCorrect': isCorrect,
      'confidenceScore': confidenceScore,
      'timestamp': Timestamp.fromDate(timestamp),
      'attemptNumber': attemptNumber,
    };
  }
}

/// Result of a paginated learner query
class LearnerQueryResult {
  final List<UserModel> learners;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;

  LearnerQueryResult({
    required this.learners,
    this.lastDocument,
    required this.hasMore,
  });
}

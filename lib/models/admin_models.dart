import 'package:cloud_firestore/cloud_firestore.dart';

/// Admin user model with role-based access control
class AdminModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final AdminRole role;
  final List<String> permissions;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final bool isActive;
  final String? createdBy;

  AdminModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.role,
    this.permissions = const [],
    required this.createdAt,
    required this.lastLoginAt,
    this.isActive = true,
    this.createdBy,
  });

  factory AdminModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdminModel(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoUrl: data['photoUrl'],
      role: AdminRole.fromString(data['role'] ?? 'admin'),
      permissions: List<String>.from(data['permissions'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt:
          (data['lastLoginAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
      createdBy: data['createdBy'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'role': role.value,
      'permissions': permissions,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': Timestamp.fromDate(lastLoginAt),
      'isActive': isActive,
      'createdBy': createdBy,
    };
  }

  AdminModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    AdminRole? role,
    List<String>? permissions,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isActive,
    String? createdBy,
  }) {
    return AdminModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  bool hasPermission(String permission) {
    if (role == AdminRole.superAdmin) return true;
    return permissions.contains(permission);
  }
}

/// Admin roles enumeration
enum AdminRole {
  superAdmin('super_admin'),
  admin('admin'),
  moderator('moderator'),
  contentManager('content_manager');

  const AdminRole(this.value);
  final String value;

  static AdminRole fromString(String value) {
    return AdminRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => AdminRole.admin,
    );
  }

  String get displayName {
    switch (this) {
      case AdminRole.superAdmin:
        return 'Super Admin';
      case AdminRole.admin:
        return 'Admin';
      case AdminRole.moderator:
        return 'Moderator';
      case AdminRole.contentManager:
        return 'Content Manager';
    }
  }
}

/// Admin permissions constants
class AdminPermissions {
  static const String manageAdmins = 'manage_admins';
  static const String manageLessons = 'manage_lessons';
  static const String manageWordGroups = 'manage_word_groups';
  static const String manageLearners = 'manage_learners';
  static const String viewAnalytics = 'view_analytics';
  static const String manageIssues = 'manage_issues';
  static const String maintenanceMode = 'maintenance_mode';
  static const String viewAuditLogs = 'view_audit_logs';

  static List<String> all = [
    manageAdmins,
    manageLessons,
    manageWordGroups,
    manageLearners,
    viewAnalytics,
    manageIssues,
    maintenanceMode,
    viewAuditLogs,
  ];
}

/// Lesson model with admin fields for CRUD operations
class AdminLessonModel {
  final String id;
  final String categoryId;
  final String title;
  final String subtitle;
  final String description;
  final List<AdminSignModel> signs;
  final List<TestType> testTypes;
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
  final String? thumbnailUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final bool isPublished;

  AdminLessonModel({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.subtitle,
    required this.description,
    this.signs = const [],
    this.testTypes = const [TestType.matching, TestType.recall, TestType.mcq],
    required this.order,
    this.totalSigns = 0,
    this.estimatedMinutes = 5,
    this.difficulty = 'beginner',
    this.gemsReward = 5,
    this.coinsReward = 50,
    this.xpReward = 25,
    this.isLocked = false,
      this.requiredLessonId,
      this.focusPoints = const [],
    this.thumbnailUrl,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.isPublished = true,
  });

  static List<TestType> _normalizeTestTypes(List<dynamic>? rawTypes) {
    final raw =
        rawTypes
            ?.map((e) => e.toString().trim().toLowerCase())
            .toList(growable: false) ??
        const <String>[];

    if (raw.isEmpty) {
      return const <TestType>[TestType.matching, TestType.recall, TestType.mcq];
    }

    final normalized = <TestType>{};
    for (final type in raw) {
      normalized.add(TestType.fromString(type));
    }

    final ordered = <TestType>[];
    for (final type in const <TestType>[
      TestType.matching,
      TestType.recall,
      TestType.mcq,
    ]) {
      if (normalized.contains(type)) {
        ordered.add(type);
      }
    }

    return ordered;
  }

  factory AdminLessonModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdminLessonModel(
      id: doc.id,
      categoryId: _categoryIdFromLessonDoc(doc, data),
      title: data['title'] ?? '',
      subtitle: data['subtitle'] ?? '',
      description: data['description'] ?? '',
      testTypes: _normalizeTestTypes(data['testTypes'] as List<dynamic>?),
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
      thumbnailUrl: data['thumbnailUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'],
      isPublished: data['isPublished'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'categoryId': categoryId,
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'testTypes': testTypes.map((e) => e.value).toList(),
      'order': order,
      'totalSigns': signs.length,
      'estimatedMinutes': estimatedMinutes,
      'difficulty': difficulty,
      'gemsReward': gemsReward,
      'coinsReward': coinsReward,
      'xpReward': xpReward,
      'isLocked': isLocked,
      'requiredLessonId': requiredLessonId,
      'focusPoints': focusPoints,
      'thumbnailUrl': thumbnailUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
      'isPublished': isPublished,
    };
  }

  AdminLessonModel copyWith({
    String? id,
    String? categoryId,
    String? title,
    String? subtitle,
    String? description,
    List<AdminSignModel>? signs,
    List<TestType>? testTypes,
    int? order,
    int? totalSigns,
    int? estimatedMinutes,
    String? difficulty,
    int? gemsReward,
    int? coinsReward,
    int? xpReward,
    bool? isLocked,
    String? requiredLessonId,
    List<String>? focusPoints,
    String? thumbnailUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    bool? isPublished,
  }) {
    return AdminLessonModel(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      signs: signs ?? this.signs,
      testTypes: testTypes ?? this.testTypes,
      order: order ?? this.order,
      totalSigns: totalSigns ?? this.totalSigns,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      difficulty: difficulty ?? this.difficulty,
      gemsReward: gemsReward ?? this.gemsReward,
      coinsReward: coinsReward ?? this.coinsReward,
      xpReward: xpReward ?? this.xpReward,
      isLocked: isLocked ?? this.isLocked,
      requiredLessonId: requiredLessonId ?? this.requiredLessonId,
      focusPoints: focusPoints ?? this.focusPoints,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      isPublished: isPublished ?? this.isPublished,
    );
  }
}

String _categoryIdFromLessonDoc(
  DocumentSnapshot doc,
  Map<String, dynamic> data,
) {
  final parentCategoryId = doc.reference.parent.parent?.id;
  if (parentCategoryId != null && parentCategoryId.isNotEmpty) {
    return parentCategoryId;
  }
  return data['categoryId']?.toString() ?? '';
}

/// Test types enumeration
enum TestType {
  mcq('mcq'),
  matching('matching'),
  recall('recall');

  const TestType(this.value);
  final String value;

  static TestType fromString(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'match' || normalized == 'matching') {
      return TestType.matching;
    }

    return TestType.values.firstWhere(
      (type) => type.value == normalized,
      orElse: () => TestType.mcq,
    );
  }

  String get displayName {
    switch (this) {
      case TestType.mcq:
        return 'Multiple Choice (MCQ)';
      case TestType.matching:
        return 'Match';
      case TestType.recall:
        return 'Recall';
    }
  }
}

/// Sign model for admin management
class AdminSignModel {
  final String id;
  final String lessonId;
  final String character;
  final String? word;
  final String? wordInHindi;
  final int order;
  final String? imageUrl;
  final String? gifUrl;
  final String? videoUrl;
  final String description;
  final List<String> instructions;
  final String? tips;
  final String difficulty;
  final DateTime createdAt;
  final DateTime updatedAt;

  AdminSignModel({
    required this.id,
    required this.lessonId,
    required this.character,
    this.word,
    this.wordInHindi,
    required this.order,
    this.imageUrl,
    this.gifUrl,
    this.videoUrl,
    required this.description,
    this.instructions = const [],
    this.tips,
    this.difficulty = 'easy',
    required this.createdAt,
    required this.updatedAt,
  });

  factory AdminSignModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdminSignModel(
      id: doc.id,
      lessonId: data['lessonId'] ?? '',
      character: data['character'] ?? data['word'] ?? '',
      word: data['word'],
      wordInHindi: data['wordInHindi'],
      order: data['order'] ?? 0,
      imageUrl: data['imageUrl'],
      gifUrl: data['gifUrl'],
      videoUrl: data['videoUrl'],
      description: data['description'] ?? '',
      instructions: List<String>.from(data['instructions'] ?? []),
      tips: data['tips'],
      difficulty: data['difficulty'] ?? 'easy',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'lessonId': lessonId,
      'character': character,
      'word': word ?? character,
      'wordInHindi': wordInHindi,
      'order': order,
      'imageUrl': imageUrl,
      'gifUrl': gifUrl,
      'videoUrl': videoUrl,
      'description': description,
      'instructions': instructions,
      'tips': tips,
      'difficulty': difficulty,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

/// Word Group model for admin management
class WordGroupModel {
  final String id;
  final String name;
  final String description;
  final String iconEmoji;
  final String difficulty;
  final int unlockGemCost;
  final int completionGemReward;
  final int order;
  final int totalWords;
  final List<WordModel> words;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final bool isPublished;

  WordGroupModel({
    required this.id,
    required this.name,
    required this.description,
    this.iconEmoji = '📝',
    this.difficulty = 'beginner',
    required this.unlockGemCost,
    this.completionGemReward = 0,
    required this.order,
    this.totalWords = 0,
    this.words = const [],
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.isPublished = true,
  });

  factory WordGroupModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WordGroupModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      iconEmoji: data['iconEmoji'] ?? '📝',
      difficulty: data['difficulty'] ?? 'beginner',
      unlockGemCost: data['unlockGemCost'] ?? data['gemCost'] ?? 0,
      completionGemReward: data['completionGemReward'] ?? 0,
      order: data['order'] ?? 0,
      totalWords: data['totalWords'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'],
      isPublished: data['isPublished'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'iconEmoji': iconEmoji,
      'difficulty': difficulty,
      'unlockGemCost': unlockGemCost,
      'completionGemReward': completionGemReward,
      'order': order,
      'totalWords': totalWords,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
      'isPublished': isPublished,
    };
  }

  WordGroupModel copyWith({
    String? id,
    String? name,
    String? description,
    String? iconEmoji,
    String? difficulty,
    int? unlockGemCost,
    int? completionGemReward,
    int? order,
    int? totalWords,
    List<WordModel>? words,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    bool? isPublished,
  }) {
    return WordGroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconEmoji: iconEmoji ?? this.iconEmoji,
      difficulty: difficulty ?? this.difficulty,
      unlockGemCost: unlockGemCost ?? this.unlockGemCost,
      completionGemReward: completionGemReward ?? this.completionGemReward,
      order: order ?? this.order,
      totalWords: totalWords ?? this.totalWords,
      words: words ?? this.words,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      isPublished: isPublished ?? this.isPublished,
    );
  }
}

/// Word model within word groups
class WordModel {
  final String id;
  final String wordGroupId;
  final String text;
  final String normalizedText;
  final List<WordCharacter> characters;
  final int order;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;

  WordModel({
    required this.id,
    required this.wordGroupId,
    required this.text,
    required this.normalizedText,
    this.characters = const [],
    required this.order,
    this.isPublished = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WordModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WordModel(
      id: doc.id,
      wordGroupId: data['wordGroupId'] ?? '',
      text: data['text'] ?? '',
      normalizedText: data['normalizedText'] ?? (data['text'] ?? '').toString().toUpperCase(),
      characters:
          (data['characters'] as List<dynamic>?)
              ?.map((e) => WordCharacter.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      order: data['order'] ?? 0,
      isPublished: data['isPublished'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'wordGroupId': wordGroupId,
      'text': text,
      'normalizedText': normalizedText,
      'characters': characters.map((e) => e.toMap()).toList(),
      'order': order,
      'isPublished': isPublished,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

/// Word character with sign reference
class WordCharacter {
  final String char;
  final String? signReference;

  WordCharacter({required this.char, this.signReference});

  factory WordCharacter.fromMap(Map<String, dynamic> map) {
    return WordCharacter(
      char: map['char'] ?? '',
      signReference: map['signReference'],
    );
  }

  Map<String, dynamic> toMap() {
    return {'char': char, 'signReference': signReference};
  }
}

/// Issue/Feedback model for admin management
class IssueModel {
  final String id;
  final String learnerId;
  final String learnerEmail;
  final String learnerName;
  final String title;
  final String description;
  final IssueCategory category;
  final IssuePriority priority;
  final IssueStatus status;
  final List<String> attachments;
  final Map<String, dynamic>? deviceInfo;
  final String? appVersion;
  final List<AdminNote> adminNotes;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? resolvedBy;

  IssueModel({
    required this.id,
    required this.learnerId,
    required this.learnerEmail,
    required this.learnerName,
    required this.title,
    required this.description,
    required this.category,
    this.priority = IssuePriority.medium,
    this.status = IssueStatus.newIssue,
    this.attachments = const [],
    this.deviceInfo,
    this.appVersion,
    this.adminNotes = const [],
    required this.createdAt,
    this.resolvedAt,
    this.resolvedBy,
  });

  factory IssueModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return IssueModel(
      id: doc.id,
      learnerId: data['learnerId'] ?? '',
      learnerEmail: data['learnerEmail'] ?? '',
      learnerName: data['learnerName'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: IssueCategory.fromString(data['category'] ?? 'other'),
      priority: IssuePriority.fromString(data['priority'] ?? 'medium'),
      status: IssueStatus.fromString(data['status'] ?? 'new'),
      attachments: List<String>.from(data['attachments'] ?? []),
      deviceInfo: data['deviceInfo'] as Map<String, dynamic>?,
      appVersion: data['appVersion'],
      adminNotes:
          (data['adminNotes'] as List<dynamic>?)
              ?.map((e) => AdminNote.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      resolvedAt: (data['resolvedAt'] as Timestamp?)?.toDate(),
      resolvedBy: data['resolvedBy'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'learnerId': learnerId,
      'learnerEmail': learnerEmail,
      'learnerName': learnerName,
      'title': title,
      'description': description,
      'category': category.value,
      'priority': priority.value,
      'status': status.value,
      'attachments': attachments,
      'deviceInfo': deviceInfo,
      'appVersion': appVersion,
      'adminNotes': adminNotes.map((e) => e.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'resolvedBy': resolvedBy,
    };
  }

  IssueModel copyWith({
    String? id,
    String? learnerId,
    String? learnerEmail,
    String? learnerName,
    String? title,
    String? description,
    IssueCategory? category,
    IssuePriority? priority,
    IssueStatus? status,
    List<String>? attachments,
    Map<String, dynamic>? deviceInfo,
    String? appVersion,
    List<AdminNote>? adminNotes,
    DateTime? createdAt,
    DateTime? resolvedAt,
    String? resolvedBy,
  }) {
    return IssueModel(
      id: id ?? this.id,
      learnerId: learnerId ?? this.learnerId,
      learnerEmail: learnerEmail ?? this.learnerEmail,
      learnerName: learnerName ?? this.learnerName,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      attachments: attachments ?? this.attachments,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      appVersion: appVersion ?? this.appVersion,
      adminNotes: adminNotes ?? this.adminNotes,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolvedBy: resolvedBy ?? this.resolvedBy,
    );
  }
}

/// Admin note for issues
class AdminNote {
  final String adminId;
  final String adminName;
  final String note;
  final DateTime timestamp;

  AdminNote({
    required this.adminId,
    required this.adminName,
    required this.note,
    required this.timestamp,
  });

  factory AdminNote.fromMap(Map<String, dynamic> map) {
    return AdminNote(
      adminId: map['adminId'] ?? '',
      adminName: map['adminName'] ?? '',
      note: map['note'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'adminId': adminId,
      'adminName': adminName,
      'note': note,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}

/// Issue categories
enum IssueCategory {
  bug('bug'),
  featureRequest('feature'),
  contentIssue('content'),
  other('other');

  const IssueCategory(this.value);
  final String value;

  static IssueCategory fromString(String value) {
    return IssueCategory.values.firstWhere(
      (cat) => cat.value == value,
      orElse: () => IssueCategory.other,
    );
  }

  String get displayName {
    switch (this) {
      case IssueCategory.bug:
        return 'Bug Report';
      case IssueCategory.featureRequest:
        return 'Feature Request';
      case IssueCategory.contentIssue:
        return 'Content Issue';
      case IssueCategory.other:
        return 'Other';
    }
  }
}

/// Issue priorities
enum IssuePriority {
  low('low'),
  medium('medium'),
  high('high'),
  critical('critical');

  const IssuePriority(this.value);
  final String value;

  static IssuePriority fromString(String value) {
    return IssuePriority.values.firstWhere(
      (p) => p.value == value,
      orElse: () => IssuePriority.medium,
    );
  }

  String get displayName {
    switch (this) {
      case IssuePriority.low:
        return 'Low';
      case IssuePriority.medium:
        return 'Medium';
      case IssuePriority.high:
        return 'High';
      case IssuePriority.critical:
        return 'Critical';
    }
  }
}

/// Issue statuses
enum IssueStatus {
  newIssue('new'),
  inProgress('in-progress'),
  resolved('resolved'),
  closed('closed');

  const IssueStatus(this.value);
  final String value;

  static IssueStatus fromString(String value) {
    return IssueStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => IssueStatus.newIssue,
    );
  }

  String get displayName {
    switch (this) {
      case IssueStatus.newIssue:
        return 'New';
      case IssueStatus.inProgress:
        return 'In Progress';
      case IssueStatus.resolved:
        return 'Resolved';
      case IssueStatus.closed:
        return 'Closed';
    }
  }
}

/// Maintenance mode configuration
class MaintenanceModeModel {
  final bool isEnabled;
  final String message;
  final DateTime? scheduledStart;
  final DateTime? scheduledEnd;
  final String? enabledBy;
  final DateTime? enabledAt;

  MaintenanceModeModel({
    this.isEnabled = false,
    this.message =
        'The app is currently under maintenance. Please try again later.',
    this.scheduledStart,
    this.scheduledEnd,
    this.enabledBy,
    this.enabledAt,
  });

  factory MaintenanceModeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MaintenanceModeModel(
      isEnabled: data['isEnabled'] ?? false,
      message:
          data['message'] ??
          'The app is currently under maintenance. Please try again later.',
      scheduledStart: (data['scheduledStart'] as Timestamp?)?.toDate(),
      scheduledEnd: (data['scheduledEnd'] as Timestamp?)?.toDate(),
      enabledBy: data['enabledBy'],
      enabledAt: (data['enabledAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'isEnabled': isEnabled,
      'message': message,
      'scheduledStart': scheduledStart != null
          ? Timestamp.fromDate(scheduledStart!)
          : null,
      'scheduledEnd': scheduledEnd != null
          ? Timestamp.fromDate(scheduledEnd!)
          : null,
      'enabledBy': enabledBy,
      'enabledAt': enabledAt != null ? Timestamp.fromDate(enabledAt!) : null,
    };
  }

  MaintenanceModeModel copyWith({
    bool? isEnabled,
    String? message,
    DateTime? scheduledStart,
    DateTime? scheduledEnd,
    String? enabledBy,
    DateTime? enabledAt,
  }) {
    return MaintenanceModeModel(
      isEnabled: isEnabled ?? this.isEnabled,
      message: message ?? this.message,
      scheduledStart: scheduledStart ?? this.scheduledStart,
      scheduledEnd: scheduledEnd ?? this.scheduledEnd,
      enabledBy: enabledBy ?? this.enabledBy,
      enabledAt: enabledAt ?? this.enabledAt,
    );
  }
}

/// Audit log model
class AuditLogModel {
  final String id;
  final String adminId;
  final String adminName;
  final String action;
  final String entityType;
  final String? entityId;
  final Map<String, dynamic>? changes;
  final DateTime timestamp;

  AuditLogModel({
    required this.id,
    required this.adminId,
    required this.adminName,
    required this.action,
    required this.entityType,
    this.entityId,
    this.changes,
    required this.timestamp,
  });

  factory AuditLogModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AuditLogModel(
      id: doc.id,
      adminId: data['adminId'] ?? '',
      adminName: data['adminName'] ?? '',
      action: data['action'] ?? '',
      entityType: data['entityType'] ?? '',
      entityId: data['entityId'],
      changes: data['changes'] as Map<String, dynamic>?,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'adminId': adminId,
      'adminName': adminName,
      'action': action,
      'entityType': entityType,
      'entityId': entityId,
      'changes': changes,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}

/// Sign practice log model for analytics
class SignPracticeLogModel {
  final String id;
  final String learnerId;
  final String lessonId;
  final String signCharacter;
  final int timeTaken;
  final bool isCorrect;
  final DateTime timestamp;
  final int attemptNumber;

  SignPracticeLogModel({
    required this.id,
    required this.learnerId,
    required this.lessonId,
    required this.signCharacter,
    required this.timeTaken,
    required this.isCorrect,
    required this.timestamp,
    required this.attemptNumber,
  });

  factory SignPracticeLogModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SignPracticeLogModel(
      id: doc.id,
      learnerId: data['learnerId'] ?? '',
      lessonId: data['lessonId'] ?? '',
      signCharacter: data['signCharacter'] ?? '',
      timeTaken: data['timeTaken'] ?? 0,
      isCorrect: data['isCorrect'] ?? false,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      attemptNumber: data['attemptNumber'] ?? 1,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'learnerId': learnerId,
      'lessonId': lessonId,
      'signCharacter': signCharacter,
      'timeTaken': timeTaken,
      'isCorrect': isCorrect,
      'timestamp': Timestamp.fromDate(timestamp),
      'attemptNumber': attemptNumber,
    };
  }
}

/// Analytics summary model
class AnalyticsSummary {
  final int totalLearners;
  final int activeLearners;
  final int totalLessonsCompleted;
  final double averageAccuracy;
  final int averageResponseTime;
  final int newLearnersToday;
  final int newLearnersThisWeek;
  final int newLearnersThisMonth;
  final Map<String, int> lessonCompletionRates;
  final Map<String, double> signAccuracyRates;

  AnalyticsSummary({
    this.totalLearners = 0,
    this.activeLearners = 0,
    this.totalLessonsCompleted = 0,
    this.averageAccuracy = 0.0,
    this.averageResponseTime = 0,
    this.newLearnersToday = 0,
    this.newLearnersThisWeek = 0,
    this.newLearnersThisMonth = 0,
    this.lessonCompletionRates = const {},
    this.signAccuracyRates = const {},
  });
}

/// Learner model for admin view (extended user model)
class LearnerModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final int gems;
  final int coins;
  final int streakDays;
  final DateTime? lastStreakDate;
  final String? learningGoal;
  final int dailyGoalMinutes;
  final int totalLessonsCompleted;
  final int totalSignsLearned;
  final int totalPracticeMinutes;
  final int currentLevel;
  final int xp;
  final bool isActive;
  final DateTime? deactivatedAt;
  final String? deactivatedBy;

  LearnerModel({
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
    this.isActive = true,
    this.deactivatedAt,
    this.deactivatedBy,
  });

  factory LearnerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LearnerModel(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoUrl: data['photoUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt:
          (data['lastLoginAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
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
      isActive: data['isActive'] ?? true,
      deactivatedAt: (data['deactivatedAt'] as Timestamp?)?.toDate(),
      deactivatedBy: data['deactivatedBy'],
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
      'lastStreakDate': lastStreakDate != null
          ? Timestamp.fromDate(lastStreakDate!)
          : null,
      'learningGoal': learningGoal,
      'dailyGoalMinutes': dailyGoalMinutes,
      'totalLessonsCompleted': totalLessonsCompleted,
      'totalSignsLearned': totalSignsLearned,
      'totalPracticeMinutes': totalPracticeMinutes,
      'currentLevel': currentLevel,
      'xp': xp,
      'isActive': isActive,
      'deactivatedAt': deactivatedAt != null
          ? Timestamp.fromDate(deactivatedAt!)
          : null,
      'deactivatedBy': deactivatedBy,
    };
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/admin_models.dart';
import '../models/app_models.dart';

/// Admin Database Service for all admin-related operations
class AdminDatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentAdminId => _auth.currentUser?.uid;

  // ==================== ADMIN AUTHENTICATION ====================

  /// Check if current user is an admin
  Future<bool> isAdmin() async {
    if (currentAdminId == null) return false;
    final doc = await _db.collection('admins').doc(currentAdminId).get();
    if (!doc.exists) return false;
    final admin = AdminModel.fromFirestore(doc);
    return admin.isActive;
  }

  /// Get current admin user
  Future<AdminModel?> getCurrentAdmin() async {
    if (currentAdminId == null) return null;
    final doc = await _db.collection('admins').doc(currentAdminId).get();
    if (doc.exists) {
      return AdminModel.fromFirestore(doc);
    }
    return null;
  }

  /// Stream of current admin user
  Stream<AdminModel?> adminStream() {
    if (currentAdminId == null) return Stream.value(null);
    return _db.collection('admins').doc(currentAdminId).snapshots().map((doc) {
      if (doc.exists) {
        return AdminModel.fromFirestore(doc);
      }
      return null;
    });
  }

  /// Create admin document (for first-time setup or adding new admins)
  Future<void> createAdminDocument(User user, {AdminRole role = AdminRole.admin}) async {
    final adminDoc = _db.collection('admins').doc(user.uid);
    final docSnapshot = await adminDoc.get();

    if (!docSnapshot.exists) {
      final newAdmin = AdminModel(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? 'Admin',
        photoUrl: user.photoURL,
        role: role,
        permissions: AdminPermissions.all,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        createdBy: currentAdminId,
      );
      await adminDoc.set(newAdmin.toFirestore());
    } else {
      await adminDoc.update({
        'lastLoginAt': Timestamp.now(),
      });
    }
  }

  /// Update admin last login
  Future<void> updateAdminLastLogin() async {
    if (currentAdminId == null) return;
    await _db.collection('admins').doc(currentAdminId).update({
      'lastLoginAt': Timestamp.now(),
    });
  }

  // ==================== LESSON CRUD OPERATIONS ====================

  /// Get all lessons across all categories
  Future<List<AdminLessonModel>> getAllLessons() async {
    final List<AdminLessonModel> allLessons = [];
    final categoriesSnapshot = await _db.collection('categories').get();

    for (final categoryDoc in categoriesSnapshot.docs) {
      final lessonsSnapshot = await categoryDoc.reference
          .collection('lessons')
          .orderBy('order')
          .get();
      for (final lessonDoc in lessonsSnapshot.docs) {
        allLessons.add(AdminLessonModel.fromFirestore(lessonDoc));
      }
    }

    return allLessons;
  }

  /// Get lessons by category
  Future<List<AdminLessonModel>> getLessonsByCategory(String categoryId) async {
    final snapshot = await _db
        .collection('categories')
        .doc(categoryId)
        .collection('lessons')
        .orderBy('order')
        .get();
    return snapshot.docs.map((doc) => AdminLessonModel.fromFirestore(doc)).toList();
  }

  /// Stream of lessons by category
  Stream<List<AdminLessonModel>> lessonsStream(String categoryId) {
    return _db
        .collection('categories')
        .doc(categoryId)
        .collection('lessons')
        .orderBy('order')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => AdminLessonModel.fromFirestore(doc)).toList());
  }

  /// Get single lesson
  Future<AdminLessonModel?> getLesson(String categoryId, String lessonId) async {
    final doc = await _db
        .collection('categories')
        .doc(categoryId)
        .collection('lessons')
        .doc(lessonId)
        .get();
    if (doc.exists) {
      return AdminLessonModel.fromFirestore(doc);
    }
    return null;
  }

  /// Create a new lesson
  Future<String> createLesson(AdminLessonModel lesson) async {
    final lessonRef = _db
        .collection('categories')
        .doc(lesson.categoryId)
        .collection('lessons')
        .doc();

    final newLesson = lesson.copyWith(
      id: lessonRef.id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      createdBy: currentAdminId,
    );

    await lessonRef.set(newLesson.toFirestore());

    // Log the action
    await _logAction('create', 'lesson', lessonRef.id, {'title': lesson.title});

    // Update category total lessons count
    await _updateCategoryLessonCount(lesson.categoryId);

    return lessonRef.id;
  }

  /// Update an existing lesson
  Future<void> updateLesson(AdminLessonModel lesson) async {
    final lessonData = lesson.copyWith(updatedAt: DateTime.now()).toFirestore();
    
    await _db
        .collection('categories')
        .doc(lesson.categoryId)
        .collection('lessons')
        .doc(lesson.id)
        .update(lessonData);

    // Log the action
    await _logAction('update', 'lesson', lesson.id, {'title': lesson.title});
  }

  /// Delete a lesson
  Future<void> deleteLesson(String categoryId, String lessonId) async {
    // First delete all signs in the lesson
    final signsSnapshot = await _db
        .collection('categories')
        .doc(categoryId)
        .collection('lessons')
        .doc(lessonId)
        .collection('signs')
        .get();

    for (final signDoc in signsSnapshot.docs) {
      await signDoc.reference.delete();
    }

    // Delete the lesson
    await _db
        .collection('categories')
        .doc(categoryId)
        .collection('lessons')
        .doc(lessonId)
        .delete();

    // Log the action
    await _logAction('delete', 'lesson', lessonId, null);

    // Update category total lessons count
    await _updateCategoryLessonCount(categoryId);
  }

  /// Update category lesson count
  Future<void> _updateCategoryLessonCount(String categoryId) async {
    final lessonsSnapshot = await _db
        .collection('categories')
        .doc(categoryId)
        .collection('lessons')
        .get();

    await _db.collection('categories').doc(categoryId).update({
      'totalLessons': lessonsSnapshot.docs.length,
    });
  }

  // ==================== SIGN CRUD OPERATIONS ====================

  /// Get signs for a lesson
  Future<List<AdminSignModel>> getSigns(String categoryId, String lessonId) async {
    final snapshot = await _db
        .collection('categories')
        .doc(categoryId)
        .collection('lessons')
        .doc(lessonId)
        .collection('signs')
        .orderBy('order')
        .get();
    return snapshot.docs.map((doc) => AdminSignModel.fromFirestore(doc)).toList();
  }

  /// Stream of signs for a lesson
  Stream<List<AdminSignModel>> signsStream(String categoryId, String lessonId) {
    return _db
        .collection('categories')
        .doc(categoryId)
        .collection('lessons')
        .doc(lessonId)
        .collection('signs')
        .orderBy('order')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => AdminSignModel.fromFirestore(doc)).toList());
  }

  /// Create a new sign
  Future<String> createSign(String categoryId, String lessonId, AdminSignModel sign) async {
    final signRef = _db
        .collection('categories')
        .doc(categoryId)
        .collection('lessons')
        .doc(lessonId)
        .collection('signs')
        .doc();

    final signData = {
      ...sign.toFirestore(),
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    };

    await signRef.set(signData);

    // Update lesson total signs count
    await _updateLessonSignCount(categoryId, lessonId);

    return signRef.id;
  }

  /// Update a sign
  Future<void> updateSign(String categoryId, String lessonId, AdminSignModel sign) async {
    await _db
        .collection('categories')
        .doc(categoryId)
        .collection('lessons')
        .doc(lessonId)
        .collection('signs')
        .doc(sign.id)
        .update({
      ...sign.toFirestore(),
      'updatedAt': Timestamp.now(),
    });
  }

  /// Delete a sign
  Future<void> deleteSign(String categoryId, String lessonId, String signId) async {
    await _db
        .collection('categories')
        .doc(categoryId)
        .collection('lessons')
        .doc(lessonId)
        .collection('signs')
        .doc(signId)
        .delete();

    // Update lesson total signs count
    await _updateLessonSignCount(categoryId, lessonId);
  }

  /// Update lesson sign count
  Future<void> _updateLessonSignCount(String categoryId, String lessonId) async {
    final signsSnapshot = await _db
        .collection('categories')
        .doc(categoryId)
        .collection('lessons')
        .doc(lessonId)
        .collection('signs')
        .get();

    await _db
        .collection('categories')
        .doc(categoryId)
        .collection('lessons')
        .doc(lessonId)
        .update({
      'totalSigns': signsSnapshot.docs.length,
    });
  }

  // ==================== CATEGORY OPERATIONS ====================

  /// Get all categories
  Future<List<CategoryModel>> getCategories() async {
    final snapshot = await _db.collection('categories').orderBy('order').get();
    return snapshot.docs.map((doc) => CategoryModel.fromFirestore(doc)).toList();
  }

  /// Stream of categories
  Stream<List<CategoryModel>> categoriesStream() {
    return _db
        .collection('categories')
        .orderBy('order')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => CategoryModel.fromFirestore(doc)).toList());
  }

  /// Create a new category
  Future<String> createCategory(CategoryModel category) async {
    final categoryRef = _db.collection('categories').doc();
    
    final categoryData = {
      ...category.toFirestore(),
      'createdAt': Timestamp.now(),
    };
    
    await categoryRef.set(categoryData);
    await _logAction('create', 'category', categoryRef.id, {'name': category.name});
    
    return categoryRef.id;
  }

  /// Update a category
  Future<void> updateCategory(CategoryModel category) async {
    await _db.collection('categories').doc(category.id).update(category.toFirestore());
    await _logAction('update', 'category', category.id, {'name': category.name});
  }

  /// Delete a category
  Future<void> deleteCategory(String categoryId) async {
    // First delete all lessons and their signs
    final lessonsSnapshot = await _db
        .collection('categories')
        .doc(categoryId)
        .collection('lessons')
        .get();

    for (final lessonDoc in lessonsSnapshot.docs) {
      final signsSnapshot = await lessonDoc.reference.collection('signs').get();
      for (final signDoc in signsSnapshot.docs) {
        await signDoc.reference.delete();
      }
      await lessonDoc.reference.delete();
    }

    // Delete the category
    await _db.collection('categories').doc(categoryId).delete();
    await _logAction('delete', 'category', categoryId, null);
  }

  // ==================== WORD GROUP CRUD OPERATIONS ====================

  /// Get all word groups
  Future<List<WordGroupModel>> getWordGroups() async {
    final snapshot = await _db.collection('word_groups').orderBy('order').get();
    return snapshot.docs.map((doc) => WordGroupModel.fromFirestore(doc)).toList();
  }

  /// Stream of word groups
  Stream<List<WordGroupModel>> wordGroupsStream() {
    return _db
        .collection('word_groups')
        .orderBy('order')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => WordGroupModel.fromFirestore(doc)).toList());
  }

  /// Create a word group
  Future<String> createWordGroup(WordGroupModel wordGroup) async {
    final wordGroupRef = _db.collection('word_groups').doc();

    final newWordGroup = wordGroup.copyWith(
      id: wordGroupRef.id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      createdBy: currentAdminId,
    );

    await wordGroupRef.set(newWordGroup.toFirestore());
    await _logAction('create', 'word_group', wordGroupRef.id, {'name': wordGroup.name});

    return wordGroupRef.id;
  }

  /// Update a word group
  Future<void> updateWordGroup(WordGroupModel wordGroup) async {
    final wordGroupData = wordGroup.copyWith(updatedAt: DateTime.now()).toFirestore();
    
    await _db.collection('word_groups').doc(wordGroup.id).update(wordGroupData);
    await _logAction('update', 'word_group', wordGroup.id, {'name': wordGroup.name});
  }

  /// Delete a word group
  Future<void> deleteWordGroup(String wordGroupId) async {
    // Delete all words in the group
    final wordsSnapshot = await _db
        .collection('word_groups')
        .doc(wordGroupId)
        .collection('words')
        .get();

    for (final wordDoc in wordsSnapshot.docs) {
      await wordDoc.reference.delete();
    }

    // Delete the word group
    await _db.collection('word_groups').doc(wordGroupId).delete();
    await _logAction('delete', 'word_group', wordGroupId, null);
  }

  // ==================== WORD CRUD OPERATIONS ====================

  /// Get words in a word group
  Future<List<WordModel>> getWords(String wordGroupId) async {
    final snapshot = await _db
        .collection('word_groups')
        .doc(wordGroupId)
        .collection('words')
        .orderBy('order')
        .get();
    return snapshot.docs.map((doc) => WordModel.fromFirestore(doc)).toList();
  }

  /// Stream of words in a word group
  Stream<List<WordModel>> wordsStream(String wordGroupId) {
    return _db
        .collection('word_groups')
        .doc(wordGroupId)
        .collection('words')
        .orderBy('order')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => WordModel.fromFirestore(doc)).toList());
  }

  /// Create a word
  Future<String> createWord(String wordGroupId, WordModel word) async {
    final wordRef = _db
        .collection('word_groups')
        .doc(wordGroupId)
        .collection('words')
        .doc();

    final wordData = {
      ...word.toFirestore(),
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    };

    await wordRef.set(wordData);
    return wordRef.id;
  }

  /// Update a word
  Future<void> updateWord(String wordGroupId, WordModel word) async {
    await _db
        .collection('word_groups')
        .doc(wordGroupId)
        .collection('words')
        .doc(word.id)
        .update({
      ...word.toFirestore(),
      'updatedAt': Timestamp.now(),
    });
  }

  /// Delete a word
  Future<void> deleteWord(String wordGroupId, String wordId) async {
    await _db
        .collection('word_groups')
        .doc(wordGroupId)
        .collection('words')
        .doc(wordId)
        .delete();
  }

  // ==================== LEARNER MANAGEMENT ====================

  /// Get all learners with pagination
  Future<List<LearnerModel>> getLearners({
    int limit = 25,
    DocumentSnapshot? startAfter,
    String? orderBy,
    bool descending = false,
    bool? isActive,
  }) async {
    Query query = _db.collection('users');

    if (isActive != null) {
      query = query.where('isActive', isEqualTo: isActive);
    }

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    } else {
      query = query.orderBy('createdAt', descending: true);
    }

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    query = query.limit(limit);

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => LearnerModel.fromFirestore(doc)).toList();
  }

  /// Search learners
  Future<List<LearnerModel>> searchLearners(String query) async {
    // Search by email (exact match)
    final emailSnapshot = await _db
        .collection('users')
        .where('email', isEqualTo: query.toLowerCase())
        .get();

    // Search by display name (prefix match)
    final nameSnapshot = await _db
        .collection('users')
        .where('displayName', isGreaterThanOrEqualTo: query)
        .where('displayName', isLessThanOrEqualTo: '$query\uf8ff')
        .limit(20)
        .get();

    final Set<String> seenIds = {};
    final List<LearnerModel> results = [];

    for (final doc in [...emailSnapshot.docs, ...nameSnapshot.docs]) {
      if (!seenIds.contains(doc.id)) {
        seenIds.add(doc.id);
        results.add(LearnerModel.fromFirestore(doc));
      }
    }

    return results;
  }

  /// Get single learner
  Future<LearnerModel?> getLearner(String learnerId) async {
    final doc = await _db.collection('users').doc(learnerId).get();
    if (doc.exists) {
      return LearnerModel.fromFirestore(doc);
    }
    return null;
  }

  /// Stream of single learner
  Stream<LearnerModel?> learnerStream(String learnerId) {
    return _db.collection('users').doc(learnerId).snapshots().map((doc) {
      if (doc.exists) {
        return LearnerModel.fromFirestore(doc);
      }
      return null;
    });
  }

  /// Update learner profile
  Future<void> updateLearnerProfile(String learnerId, Map<String, dynamic> updates) async {
    await _db.collection('users').doc(learnerId).update(updates);
    await _logAction('update', 'learner', learnerId, updates);
  }

  /// Deactivate a learner account
  Future<void> deactivateLearner(String learnerId) async {
    await _db.collection('users').doc(learnerId).update({
      'isActive': false,
      'deactivatedAt': Timestamp.now(),
      'deactivatedBy': currentAdminId,
    });
    await _logAction('deactivate', 'learner', learnerId, null);
  }

  /// Reactivate a learner account
  Future<void> reactivateLearner(String learnerId) async {
    await _db.collection('users').doc(learnerId).update({
      'isActive': true,
      'deactivatedAt': FieldValue.delete(),
      'deactivatedBy': FieldValue.delete(),
    });
    await _logAction('reactivate', 'learner', learnerId, null);
  }

  /// Update learner active status
  Future<void> updateLearnerStatus(String learnerId, bool isActive) async {
    if (isActive) {
      await reactivateLearner(learnerId);
    } else {
      await deactivateLearner(learnerId);
    }
  }

  /// Adjust learner XP/Gems manually
  Future<void> adjustLearnerStats(
    String learnerId, {
    int? xpAdjustment,
    int? gemsAdjustment,
    int? coinsAdjustment,
  }) async {
    final updates = <String, dynamic>{};

    if (xpAdjustment != null) {
      updates['xp'] = FieldValue.increment(xpAdjustment);
    }
    if (gemsAdjustment != null) {
      updates['gems'] = FieldValue.increment(gemsAdjustment);
    }
    if (coinsAdjustment != null) {
      updates['coins'] = FieldValue.increment(coinsAdjustment);
    }

    if (updates.isNotEmpty) {
      await _db.collection('users').doc(learnerId).update(updates);
      await _logAction('adjust_stats', 'learner', learnerId, {
        'xpAdjustment': xpAdjustment,
        'gemsAdjustment': gemsAdjustment,
        'coinsAdjustment': coinsAdjustment,
      });
    }
  }

  /// Get learner progress
  Future<List<LessonProgress>> getLearnerProgress(String learnerId) async {
    final snapshot = await _db
        .collection('users')
        .doc(learnerId)
        .collection('progress')
        .get();
    return snapshot.docs.map((doc) => LessonProgress.fromFirestore(doc)).toList();
  }

  // ==================== ANALYTICS ====================

  /// Get total learner count
  Future<int> getTotalLearnerCount() async {
    final snapshot = await _db.collection('users').count().get();
    return snapshot.count ?? 0;
  }

  /// Get active learner count (last 7 days)
  Future<int> getActiveLearnerCount() async {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final snapshot = await _db
        .collection('users')
        .where('lastLoginAt', isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo))
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  /// Get new learners count by period
  Future<int> getNewLearnersCount(Duration period) async {
    final startDate = DateTime.now().subtract(period);
    final snapshot = await _db
        .collection('users')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  /// Get analytics summary
  Future<AnalyticsSummary> getAnalyticsSummary() async {
    final totalLearners = await getTotalLearnerCount();
    final activeLearners = await getActiveLearnerCount();
    final newLearnersToday = await getNewLearnersCount(const Duration(days: 1));
    final newLearnersThisWeek = await getNewLearnersCount(const Duration(days: 7));
    final newLearnersThisMonth = await getNewLearnersCount(const Duration(days: 30));

    // Get total lessons completed
    final usersSnapshot = await _db.collection('users').get();
    int totalLessonsCompleted = 0;
    for (final userDoc in usersSnapshot.docs) {
      final data = userDoc.data();
      totalLessonsCompleted += (data['totalLessonsCompleted'] as int?) ?? 0;
    }

    return AnalyticsSummary(
      totalLearners: totalLearners,
      activeLearners: activeLearners,
      totalLessonsCompleted: totalLessonsCompleted,
      newLearnersToday: newLearnersToday,
      newLearnersThisWeek: newLearnersThisWeek,
      newLearnersThisMonth: newLearnersThisMonth,
    );
  }

  /// Get sign practice analytics
  Future<List<SignPracticeLogModel>> getSignPracticeLogs({
    String? learnerId,
    String? lessonId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    Query query = _db.collection('sign_practice_logs');

    if (learnerId != null) {
      query = query.where('learnerId', isEqualTo: learnerId);
    }
    if (lessonId != null) {
      query = query.where('lessonId', isEqualTo: lessonId);
    }
    if (startDate != null) {
      query = query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }
    if (endDate != null) {
      query = query.where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }

    query = query.orderBy('timestamp', descending: true).limit(limit);

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => SignPracticeLogModel.fromFirestore(doc)).toList();
  }

  // ==================== ISSUES/FEEDBACK MANAGEMENT ====================

  /// Get all issues with filtering
  Future<List<IssueModel>> getIssues({
    IssueStatus? status,
    IssuePriority? priority,
    IssueCategory? category,
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) async {
    Query query = _db.collection('issues');

    if (status != null) {
      query = query.where('status', isEqualTo: status.value);
    }
    if (priority != null) {
      query = query.where('priority', isEqualTo: priority.value);
    }
    if (category != null) {
      query = query.where('category', isEqualTo: category.value);
    }

    query = query.orderBy('createdAt', descending: true);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    query = query.limit(limit);

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => IssueModel.fromFirestore(doc)).toList();
  }

  /// Stream of issues
  Stream<List<IssueModel>> issuesStream({IssueStatus? status}) {
    Query query = _db.collection('issues');

    if (status != null) {
      query = query.where('status', isEqualTo: status.value);
    }

    query = query.orderBy('createdAt', descending: true).limit(50);

    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => IssueModel.fromFirestore(doc)).toList());
  }

  /// Get single issue
  Future<IssueModel?> getIssue(String issueId) async {
    final doc = await _db.collection('issues').doc(issueId).get();
    if (doc.exists) {
      return IssueModel.fromFirestore(doc);
    }
    return null;
  }

  /// Stream of single issue
  Stream<IssueModel?> issueStream(String issueId) {
    return _db.collection('issues').doc(issueId).snapshots().map((doc) {
      if (doc.exists) {
        return IssueModel.fromFirestore(doc);
      }
      return null;
    });
  }

  /// Update issue status
  Future<void> updateIssueStatus(String issueId, IssueStatus status) async {
    final updates = <String, dynamic>{
      'status': status.value,
    };

    if (status == IssueStatus.resolved) {
      updates['resolvedAt'] = Timestamp.now();
      updates['resolvedBy'] = currentAdminId;
    }

    await _db.collection('issues').doc(issueId).update(updates);
    await _logAction('update_status', 'issue', issueId, {'status': status.value});
  }

  /// Update issue priority
  Future<void> updateIssuePriority(String issueId, IssuePriority priority) async {
    await _db.collection('issues').doc(issueId).update({
      'priority': priority.value,
    });
    await _logAction('update_priority', 'issue', issueId, {'priority': priority.value});
  }

  /// Add admin note to issue
  Future<void> addIssueNote(String issueId, String note) async {
    final admin = await getCurrentAdmin();
    if (admin == null) return;

    final adminNote = AdminNote(
      adminId: admin.uid,
      adminName: admin.displayName,
      note: note,
      timestamp: DateTime.now(),
    );

    await _db.collection('issues').doc(issueId).update({
      'adminNotes': FieldValue.arrayUnion([adminNote.toMap()]),
    });
  }

  /// Get issue counts by status
  Future<Map<IssueStatus, int>> getIssueCounts() async {
    final counts = <IssueStatus, int>{};
    
    for (final status in IssueStatus.values) {
      final snapshot = await _db
          .collection('issues')
          .where('status', isEqualTo: status.value)
          .count()
          .get();
      counts[status] = snapshot.count ?? 0;
    }
    
    return counts;
  }

  // ==================== MAINTENANCE MODE ====================

  /// Get maintenance mode status
  Future<MaintenanceModeModel> getMaintenanceMode() async {
    final doc = await _db.collection('system').doc('maintenance').get();
    if (doc.exists) {
      return MaintenanceModeModel.fromFirestore(doc);
    }
    return MaintenanceModeModel();
  }

  /// Stream of maintenance mode status
  Stream<MaintenanceModeModel> maintenanceModeStream() {
    return _db.collection('system').doc('maintenance').snapshots().map((doc) {
      if (doc.exists) {
        return MaintenanceModeModel.fromFirestore(doc);
      }
      return MaintenanceModeModel();
    });
  }

  /// Toggle maintenance mode
  Future<void> setMaintenanceMode(MaintenanceModeModel mode) async {
    final modeWithAdmin = mode.copyWith(
      enabledBy: currentAdminId,
      enabledAt: DateTime.now(),
    );

    await _db.collection('system').doc('maintenance').set(modeWithAdmin.toFirestore());
    await _logAction(
      mode.isEnabled ? 'enable_maintenance' : 'disable_maintenance',
      'system',
      'maintenance',
      {'message': mode.message},
    );
  }

  // ==================== AUDIT LOGGING ====================

  /// Log admin action
  Future<void> _logAction(
    String action,
    String entityType,
    String? entityId,
    Map<String, dynamic>? changes,
  ) async {
    final admin = await getCurrentAdmin();
    if (admin == null) return;

    final logRef = _db.collection('audit_logs').doc();
    final auditLog = AuditLogModel(
      id: logRef.id,
      adminId: admin.uid,
      adminName: admin.displayName,
      action: action,
      entityType: entityType,
      entityId: entityId,
      changes: changes,
      timestamp: DateTime.now(),
    );

    await logRef.set(auditLog.toFirestore());
  }

  /// Get audit logs
  Future<List<AuditLogModel>> getAuditLogs({
    String? adminId,
    String? entityType,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    Query query = _db.collection('audit_logs');

    if (adminId != null) {
      query = query.where('adminId', isEqualTo: adminId);
    }
    if (entityType != null) {
      query = query.where('entityType', isEqualTo: entityType);
    }
    if (startDate != null) {
      query = query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }
    if (endDate != null) {
      query = query.where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }

    query = query.orderBy('timestamp', descending: true).limit(limit);

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => AuditLogModel.fromFirestore(doc)).toList();
  }

  /// Stream of audit logs
  Stream<List<AuditLogModel>> auditLogsStream({int limit = 50}) {
    return _db
        .collection('audit_logs')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => AuditLogModel.fromFirestore(doc)).toList());
  }

  // ==================== ADMIN MANAGEMENT ====================

  /// Get all admins
  Future<List<AdminModel>> getAdmins() async {
    final snapshot = await _db.collection('admins').orderBy('createdAt').get();
    return snapshot.docs.map((doc) => AdminModel.fromFirestore(doc)).toList();
  }

  /// Create a new admin
  Future<void> createAdmin(AdminModel admin) async {
    await _db.collection('admins').doc(admin.uid).set(admin.toFirestore());
    await _logAction('create', 'admin', admin.uid, {'email': admin.email, 'role': admin.role.value});
  }

  /// Update admin
  Future<void> updateAdmin(AdminModel admin) async {
    await _db.collection('admins').doc(admin.uid).update(admin.toFirestore());
    await _logAction('update', 'admin', admin.uid, {'email': admin.email, 'role': admin.role.value});
  }

  /// Deactivate admin
  Future<void> deactivateAdmin(String adminId) async {
    await _db.collection('admins').doc(adminId).update({'isActive': false});
    await _logAction('deactivate', 'admin', adminId, null);
  }
}

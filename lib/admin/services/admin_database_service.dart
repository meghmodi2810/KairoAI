import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/admin_models.dart';
import '../../models/app_models.dart';

class AdminDatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ==================== LESSON OPERATIONS ====================

  /// Get all lessons (admin view)
  Stream<List<AdminLessonModel>> lessonsStream() {
    return _db
        .collection('admin_lessons')
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => AdminLessonModel.fromFirestore(doc)).toList());
  }

  /// Get lesson by ID
  Future<AdminLessonModel?> getLesson(String lessonId) async {
    final doc = await _db.collection('admin_lessons').doc(lessonId).get();
    if (doc.exists) {
      return AdminLessonModel.fromFirestore(doc);
    }
    return null;
  }

  /// Create new lesson
  Future<String?> createLesson(AdminLessonModel lesson) async {
    try {
      final docRef = await _db.collection('admin_lessons').add(lesson.toFirestore());
      await _logAuditAction(
        action: 'create',
        entityType: 'lesson',
        entityId: docRef.id,
        changes: {'name': lesson.name, 'type': lesson.type},
      );
      return docRef.id;
    } catch (e) {
      print('Error creating lesson: $e');
      return null;
    }
  }

  /// Update lesson
  Future<bool> updateLesson(String lessonId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _db.collection('admin_lessons').doc(lessonId).update(updates);
      await _logAuditAction(
        action: 'update',
        entityType: 'lesson',
        entityId: lessonId,
        changes: updates,
      );
      return true;
    } catch (e) {
      print('Error updating lesson: $e');
      return false;
    }
  }

  /// Delete lesson
  Future<bool> deleteLesson(String lessonId) async {
    try {
      await _db.collection('admin_lessons').doc(lessonId).delete();
      await _logAuditAction(
        action: 'delete',
        entityType: 'lesson',
        entityId: lessonId,
      );
      return true;
    } catch (e) {
      print('Error deleting lesson: $e');
      return false;
    }
  }

  // ==================== WORD GROUP OPERATIONS ====================

  /// Get all word groups
  Stream<List<WordGroupModel>> wordGroupsStream() {
    return _db
        .collection('word_groups')
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => WordGroupModel.fromFirestore(doc)).toList());
  }

  /// Get word group by ID
  Future<WordGroupModel?> getWordGroup(String groupId) async {
    final doc = await _db.collection('word_groups').doc(groupId).get();
    if (doc.exists) {
      return WordGroupModel.fromFirestore(doc);
    }
    return null;
  }

  /// Create word group
  Future<String?> createWordGroup(WordGroupModel group) async {
    try {
      final docRef = await _db.collection('word_groups').add(group.toFirestore());
      await _logAuditAction(
        action: 'create',
        entityType: 'word_group',
        entityId: docRef.id,
        changes: {'name': group.name, 'gemCost': group.gemCost},
      );
      return docRef.id;
    } catch (e) {
      print('Error creating word group: $e');
      return null;
    }
  }

  /// Update word group
  Future<bool> updateWordGroup(String groupId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _db.collection('word_groups').doc(groupId).update(updates);
      await _logAuditAction(
        action: 'update',
        entityType: 'word_group',
        entityId: groupId,
        changes: updates,
      );
      return true;
    } catch (e) {
      print('Error updating word group: $e');
      return false;
    }
  }

  /// Delete word group
  Future<bool> deleteWordGroup(String groupId) async {
    try {
      // Also delete all words in the group
      final wordsSnapshot = await _db
          .collection('word_groups')
          .doc(groupId)
          .collection('words')
          .get();
      
      for (final doc in wordsSnapshot.docs) {
        await doc.reference.delete();
      }
      
      await _db.collection('word_groups').doc(groupId).delete();
      await _logAuditAction(
        action: 'delete',
        entityType: 'word_group',
        entityId: groupId,
      );
      return true;
    } catch (e) {
      print('Error deleting word group: $e');
      return false;
    }
  }

  // ==================== WORD OPERATIONS ====================

  /// Get words in a group
  Stream<List<WordModel>> wordsStream(String groupId) {
    return _db
        .collection('word_groups')
        .doc(groupId)
        .collection('words')
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => WordModel.fromFirestore(doc)).toList());
  }

  /// Add word to group
  Future<String?> addWord(String groupId, WordModel word) async {
    try {
      final docRef = await _db
          .collection('word_groups')
          .doc(groupId)
          .collection('words')
          .add(word.toFirestore());
      await _logAuditAction(
        action: 'create',
        entityType: 'word',
        entityId: docRef.id,
        changes: {'text': word.text, 'groupId': groupId},
      );
      return docRef.id;
    } catch (e) {
      print('Error adding word: $e');
      return null;
    }
  }

  /// Update word
  Future<bool> updateWord(String groupId, String wordId, Map<String, dynamic> updates) async {
    try {
      await _db
          .collection('word_groups')
          .doc(groupId)
          .collection('words')
          .doc(wordId)
          .update(updates);
      await _logAuditAction(
        action: 'update',
        entityType: 'word',
        entityId: wordId,
        changes: updates,
      );
      return true;
    } catch (e) {
      print('Error updating word: $e');
      return false;
    }
  }

  /// Delete word
  Future<bool> deleteWord(String groupId, String wordId) async {
    try {
      await _db
          .collection('word_groups')
          .doc(groupId)
          .collection('words')
          .doc(wordId)
          .delete();
      await _logAuditAction(
        action: 'delete',
        entityType: 'word',
        entityId: wordId,
      );
      return true;
    } catch (e) {
      print('Error deleting word: $e');
      return false;
    }
  }

  // ==================== LEARNER OPERATIONS ====================

  /// Get all learners with pagination
  Future<LearnerQueryResult> getLearners({
    int limit = 25,
    DocumentSnapshot? lastDoc,
    String? searchQuery,
    bool? isActive,
    String? orderBy = 'createdAt',
    bool descending = true,
  }) async {
    try {
      Query query = _db.collection('users');
      
      // Apply ordering
      query = query.orderBy(orderBy ?? 'createdAt', descending: descending);
      
      // Apply pagination
      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }
      
      query = query.limit(limit);
      
      final snapshot = await query.get();
      final learners = snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
      
      return LearnerQueryResult(
        learners: learners,
        lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
        hasMore: snapshot.docs.length == limit,
      );
    } catch (e) {
      print('Error getting learners: $e');
      return LearnerQueryResult(learners: [], hasMore: false);
    }
  }

  /// Get learner by ID
  Future<UserModel?> getLearner(String learnerId) async {
    try {
      final doc = await _db.collection('users').doc(learnerId).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting learner: $e');
      return null;
    }
  }

  /// Update learner
  Future<bool> updateLearner(String learnerId, Map<String, dynamic> updates) async {
    try {
      await _db.collection('users').doc(learnerId).update(updates);
      await _logAuditAction(
        action: 'update',
        entityType: 'learner',
        entityId: learnerId,
        changes: updates,
      );
      return true;
    } catch (e) {
      print('Error updating learner: $e');
      return false;
    }
  }

  /// Reset learner progress
  Future<bool> resetLearnerProgress(String learnerId) async {
    try {
      // Delete all progress documents
      final progressSnapshot = await _db
          .collection('users')
          .doc(learnerId)
          .collection('progress')
          .get();
      
      for (final doc in progressSnapshot.docs) {
        await doc.reference.delete();
      }
      
      // Reset user stats
      await _db.collection('users').doc(learnerId).update({
        'xp': 0,
        'level': 1,
        'completedLessonIds': [],
        'streakDays': 0,
      });
      
      await _logAuditAction(
        action: 'reset_progress',
        entityType: 'learner',
        entityId: learnerId,
      );
      return true;
    } catch (e) {
      print('Error resetting learner progress: $e');
      return false;
    }
  }

  /// Delete learner account
  Future<bool> deleteLearner(String learnerId) async {
    try {
      // Delete progress subcollection
      final progressSnapshot = await _db
          .collection('users')
          .doc(learnerId)
          .collection('progress')
          .get();
      
      for (final doc in progressSnapshot.docs) {
        await doc.reference.delete();
      }
      
      // Delete user document
      await _db.collection('users').doc(learnerId).delete();
      
      await _logAuditAction(
        action: 'delete',
        entityType: 'learner',
        entityId: learnerId,
      );
      return true;
    } catch (e) {
      print('Error deleting learner: $e');
      return false;
    }
  }

  /// Get learners with simple pagination
  Future<List<UserModel>> getLearnersPaginated({
    int limit = 25,
    String? startAfterDocId,
  }) async {
    try {
      Query query = _db.collection('users').orderBy('createdAt', descending: true);
      
      if (startAfterDocId != null) {
        final startDoc = await _db.collection('users').doc(startAfterDocId).get();
        if (startDoc.exists) {
          query = query.startAfterDocument(startDoc);
        }
      }
      
      query = query.limit(limit);
      final snapshot = await query.get();
      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting learners paginated: $e');
      return [];
    }
  }

  /// Deactivate/Activate learner
  Future<bool> setLearnerStatus(String learnerId, bool isActive) async {
    try {
      await _db.collection('users').doc(learnerId).update({
        'isActive': isActive,
        'statusUpdatedAt': FieldValue.serverTimestamp(),
      });
      await _logAuditAction(
        action: isActive ? 'activate' : 'deactivate',
        entityType: 'learner',
        entityId: learnerId,
      );
      return true;
    } catch (e) {
      print('Error setting learner status: $e');
      return false;
    }
  }

  /// Get learner progress
  Future<List<LessonProgress>> getLearnerProgress(String learnerId) async {
    try {
      final snapshot = await _db
          .collection('users')
          .doc(learnerId)
          .collection('progress')
          .get();
      return snapshot.docs.map((doc) => LessonProgress.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting learner progress: $e');
      return [];
    }
  }

  // ==================== ISSUE/FEEDBACK OPERATIONS ====================

  /// Get all issues
  Stream<List<IssueModel>> issuesStream({String? status, String? priority}) {
    Query query = _db.collection('issues').orderBy('createdAt', descending: true);
    
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }
    if (priority != null) {
      query = query.where('priority', isEqualTo: priority);
    }
    
    return query.snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => IssueModel.fromFirestore(doc)).toList(),
    );
  }

  /// Get issue by ID
  Future<IssueModel?> getIssue(String issueId) async {
    try {
      final doc = await _db.collection('issues').doc(issueId).get();
      if (doc.exists) {
        return IssueModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting issue: $e');
      return null;
    }
  }

  /// Update issue status
  Future<bool> updateIssueStatus(String issueId, String status) async {
    try {
      final updates = <String, dynamic>{
        'status': status,
      };
      
      if (status == 'resolved' || status == 'closed') {
        updates['resolvedAt'] = FieldValue.serverTimestamp();
      }
      
      await _db.collection('issues').doc(issueId).update(updates);
      await _logAuditAction(
        action: 'status_change',
        entityType: 'issue',
        entityId: issueId,
        changes: {'status': status},
      );
      return true;
    } catch (e) {
      print('Error updating issue status: $e');
      return false;
    }
  }

  /// Update issue priority
  Future<bool> updateIssuePriority(String issueId, String priority) async {
    try {
      await _db.collection('issues').doc(issueId).update({'priority': priority});
      await _logAuditAction(
        action: 'priority_change',
        entityType: 'issue',
        entityId: issueId,
        changes: {'priority': priority},
      );
      return true;
    } catch (e) {
      print('Error updating issue priority: $e');
      return false;
    }
  }

  /// Add admin note to issue
  Future<bool> addIssueNote(String issueId, AdminNote note) async {
    try {
      await _db.collection('issues').doc(issueId).update({
        'adminNotes': FieldValue.arrayUnion([note.toMap()]),
      });
      return true;
    } catch (e) {
      print('Error adding issue note: $e');
      return false;
    }
  }

  /// Alias for addIssueNote
  Future<bool> addNoteToIssue(String issueId, AdminNote note) {
    return addIssueNote(issueId, note);
  }

  /// Update issue general fields
  Future<bool> updateIssue(String issueId, Map<String, dynamic> updates) async {
    try {
      await _db.collection('issues').doc(issueId).update(updates);
      await _logAuditAction(
        action: 'update',
        entityType: 'issue',
        entityId: issueId,
        changes: updates,
      );
      return true;
    } catch (e) {
      print('Error updating issue: $e');
      return false;
    }
  }

  /// Delete issue
  Future<bool> deleteIssue(String issueId) async {
    try {
      await _db.collection('issues').doc(issueId).delete();
      await _logAuditAction(
        action: 'delete',
        entityType: 'issue',
        entityId: issueId,
      );
      return true;
    } catch (e) {
      print('Error deleting issue: $e');
      return false;
    }
  }

  // ==================== MAINTENANCE MODE OPERATIONS ====================

  /// Get maintenance mode status
  Stream<MaintenanceModeModel> maintenanceModeStream() {
    return _db.collection('settings').doc('maintenance').snapshots().map((doc) {
      if (doc.exists) {
        return MaintenanceModeModel.fromFirestore(doc);
      }
      return MaintenanceModeModel();
    });
  }

  /// Update maintenance mode
  Future<bool> updateMaintenanceMode(MaintenanceModeModel mode) async {
    try {
      await _db.collection('settings').doc('maintenance').set(mode.toFirestore());
      await _logAuditAction(
        action: mode.isEnabled ? 'enable_maintenance' : 'disable_maintenance',
        entityType: 'settings',
        entityId: 'maintenance',
        changes: {'isEnabled': mode.isEnabled, 'message': mode.message},
      );
      return true;
    } catch (e) {
      print('Error updating maintenance mode: $e');
      return false;
    }
  }

  /// Alias for updateMaintenanceMode
  Future<bool> setMaintenanceMode(MaintenanceModeModel mode) {
    return updateMaintenanceMode(mode);
  }

  /// Get maintenance mode (one-time fetch)
  Future<MaintenanceModeModel?> getMaintenanceMode() async {
    try {
      final doc = await _db.collection('settings').doc('maintenance').get();
      if (doc.exists) {
        return MaintenanceModeModel.fromFirestore(doc);
      }
      return MaintenanceModeModel();
    } catch (e) {
      print('Error getting maintenance mode: $e');
      return null;
    }
  }

  // ==================== ANALYTICS OPERATIONS ====================

  /// Get total learner count
  Future<int> getTotalLearnerCount() async {
    try {
      final snapshot = await _db.collection('users').count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      print('Error getting learner count: $e');
      return 0;
    }
  }

  /// Get active learners (last 7 days)
  Future<int> getActiveLearnerCount() async {
    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final snapshot = await _db
          .collection('users')
          .where('lastLoginAt', isGreaterThan: Timestamp.fromDate(sevenDaysAgo))
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      print('Error getting active learner count: $e');
      return 0;
    }
  }

  /// Get total lessons completed
  Future<int> getTotalLessonsCompleted() async {
    try {
      // This aggregates from all user progress
      final usersSnapshot = await _db.collection('users').get();
      int total = 0;
      for (final userDoc in usersSnapshot.docs) {
        final progressSnapshot = await userDoc.reference
            .collection('progress')
            .where('status', isEqualTo: 'completed')
            .count()
            .get();
        total += progressSnapshot.count ?? 0;
      }
      return total;
    } catch (e) {
      print('Error getting total lessons completed: $e');
      return 0;
    }
  }

  /// Get learner statistics summary
  Future<Map<String, dynamic>> getAnalyticsSummary() async {
    try {
      final totalLearners = await getTotalLearnerCount();
      final activeLearners = await getActiveLearnerCount();
      
      // Get new learners this week
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      final newLearnersSnapshot = await _db
          .collection('users')
          .where('createdAt', isGreaterThan: Timestamp.fromDate(weekAgo))
          .count()
          .get();
      
      // Get total issues
      final openIssuesSnapshot = await _db
          .collection('issues')
          .where('status', whereIn: ['new', 'in-progress'])
          .count()
          .get();
      
      return {
        'totalLearners': totalLearners,
        'activeLearners': activeLearners,
        'newLearnersThisWeek': newLearnersSnapshot.count ?? 0,
        'openIssues': openIssuesSnapshot.count ?? 0,
      };
    } catch (e) {
      print('Error getting analytics summary: $e');
      return {
        'totalLearners': 0,
        'activeLearners': 0,
        'newLearnersThisWeek': 0,
        'openIssues': 0,
      };
    }
  }

  /// Get sign practice analytics
  Future<List<SignPracticeLogModel>> getSignPracticeLogs({
    String? learnerId,
    String? lessonId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    try {
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
    } catch (e) {
      print('Error getting sign practice logs: $e');
      return [];
    }
  }

  // ==================== AUDIT LOG OPERATIONS ====================

  /// Get audit logs
  Stream<List<AuditLogModel>> auditLogsStream({int limit = 50}) {
    return _db
        .collection('audit_logs')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => AuditLogModel.fromFirestore(doc)).toList());
  }

  /// Alias for auditLogsStream for backward compatibility
  Stream<List<AuditLogModel>> auditLogStream({int limit = 50}) {
    return auditLogsStream(limit: limit);
  }

  /// Log an audit action
  Future<void> _logAuditAction({
    required String action,
    required String entityType,
    String? entityId,
    Map<String, dynamic>? changes,
  }) async {
    // Note: In production, get adminId and email from the auth service
    try {
      await _db.collection('audit_logs').add({
        'adminId': 'system',
        'adminEmail': 'system@kairoai.com',
        'action': action,
        'entityType': entityType,
        'entityId': entityId,
        'changes': changes,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Failed to log audit action: $e');
    }
  }

  /// Public method to log audit with admin info
  Future<void> logAuditAction({
    required String adminId,
    required String adminEmail,
    required String action,
    required String entityType,
    String? entityId,
    Map<String, dynamic>? changes,
  }) async {
    try {
      await _db.collection('audit_logs').add({
        'adminId': adminId,
        'adminEmail': adminEmail,
        'action': action,
        'entityType': entityType,
        'entityId': entityId,
        'changes': changes,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Failed to log audit action: $e');
    }
  }

  // ==================== CATEGORY OPERATIONS (Using existing structure) ====================

  /// Get all categories
  Stream<List<CategoryModel>> categoriesStream() {
    return _db
        .collection('categories')
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => CategoryModel.fromFirestore(doc)).toList());
  }

  /// Create category
  Future<String?> createCategory(CategoryModel category) async {
    try {
      final docRef = _db.collection('categories').doc(category.id);
      await docRef.set(category.toFirestore());
      await _logAuditAction(
        action: 'create',
        entityType: 'category',
        entityId: category.id,
        changes: {'name': category.name},
      );
      return category.id;
    } catch (e) {
      print('Error creating category: $e');
      return null;
    }
  }

  /// Update category
  Future<bool> updateCategory(String categoryId, Map<String, dynamic> updates) async {
    try {
      await _db.collection('categories').doc(categoryId).update(updates);
      await _logAuditAction(
        action: 'update',
        entityType: 'category',
        entityId: categoryId,
        changes: updates,
      );
      return true;
    } catch (e) {
      print('Error updating category: $e');
      return false;
    }
  }

  /// Delete category
  Future<bool> deleteCategory(String categoryId) async {
    try {
      // Delete all lessons in the category first
      final lessonsSnapshot = await _db
          .collection('categories')
          .doc(categoryId)
          .collection('lessons')
          .get();
      
      for (final lessonDoc in lessonsSnapshot.docs) {
        // Delete signs in each lesson
        final signsSnapshot = await lessonDoc.reference.collection('signs').get();
        for (final signDoc in signsSnapshot.docs) {
          await signDoc.reference.delete();
        }
        await lessonDoc.reference.delete();
      }
      
      await _db.collection('categories').doc(categoryId).delete();
      await _logAuditAction(
        action: 'delete',
        entityType: 'category',
        entityId: categoryId,
      );
      return true;
    } catch (e) {
      print('Error deleting category: $e');
      return false;
    }
  }
}

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

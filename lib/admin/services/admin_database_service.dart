import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:math';
import 'package:kairo_ai/admin/models/admin_models.dart';
import 'package:kairo_ai/models/app_models.dart';

class AdminDatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ==================== LESSON OPERATIONS ====================
  // Lessons are stored in categories/{categoryId}/lessons subcollection
  // so learner side can read them from the same path.

  /// Get all lessons for a specific category (admin view)
  Stream<List<AdminLessonModel>> lessonsStream() {
    // Returns an empty stream — use lessonsByCategoryStream instead
    return Stream.value([]);
  }

  /// Get lesson by ID
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

  /// Create new lesson — writes to categories/{categoryId}/lessons
  Future<String?> createLesson(AdminLessonModel lesson) async {
    try {
      final docRef = await _db
          .collection('categories')
          .doc(lesson.categoryId)
          .collection('lessons')
          .add({
        ...lesson.toFirestore(),
        'totalSigns': lesson.signs.length,
        'subtitle': lesson.description,
      });

      // Sync embedded signs to the signs subcollection for learner access
      if (lesson.signs.isNotEmpty) {
        await _syncSignsToSubcollection(
            lesson.categoryId, docRef.id, lesson.signs);
      }

      await _logAuditAction(
        action: 'create',
        entityType: 'lesson',
        entityId: docRef.id,
        changes: {'name': lesson.name, 'type': lesson.type},
      );
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating lesson: $e');
      return null;
    }
  }

  /// Update lesson — updates in categories/{categoryId}/lessons
  Future<bool> updateLesson(
      String categoryId, String lessonId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _db
          .collection('categories')
          .doc(categoryId)
          .collection('lessons')
          .doc(lessonId)
          .update(updates);

      // If signs were updated, sync them to subcollection
      if (updates.containsKey('signs')) {
        final signsList = (updates['signs'] as List<dynamic>)
            .map((s) => AdminSignItem.fromMap(s as Map<String, dynamic>))
            .toList();
        await _syncSignsToSubcollection(categoryId, lessonId, signsList);
        await _db
            .collection('categories')
            .doc(categoryId)
            .collection('lessons')
            .doc(lessonId)
            .update({'totalSigns': signsList.length});
      }

      await _logAuditAction(
        action: 'update',
        entityType: 'lesson',
        entityId: lessonId,
        changes: updates,
      );
      return true;
    } catch (e) {
      debugPrint('Error updating lesson: $e');
      return false;
    }
  }

  /// Delete lesson — deletes from categories/{categoryId}/lessons + signs subcollection
  Future<bool> deleteLesson(String categoryId, String lessonId) async {
    try {
      // Delete signs subcollection first
      final signsSnapshot = await _db
          .collection('categories')
          .doc(categoryId)
          .collection('lessons')
          .doc(lessonId)
          .collection('signs')
          .get();
      for (final doc in signsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete the lesson document
      await _db
          .collection('categories')
          .doc(categoryId)
          .collection('lessons')
          .doc(lessonId)
          .delete();

      await _logAuditAction(
        action: 'delete',
        entityType: 'lesson',
        entityId: lessonId,
      );
      return true;
    } catch (e) {
      debugPrint('Error deleting lesson: $e');
      return false;
    }
  }

  /// Sync embedded signs from a lesson to the signs subcollection
  /// so the learner side can read individual sign documents.
  Future<void> _syncSignsToSubcollection(
    String categoryId,
    String lessonId,
    List<AdminSignItem> signs,
  ) async {
    try {
      final signsCollection = _db
          .collection('categories')
          .doc(categoryId)
          .collection('lessons')
          .doc(lessonId)
          .collection('signs');

      // Delete existing signs in subcollection
      final existing = await signsCollection.get();
      for (final doc in existing.docs) {
        await doc.reference.delete();
      }

      // Try to get enriched sign data from global signs collection
      List<AdminSignModel>? globalSigns;
      try {
        globalSigns = await getAllSigns();
      } catch (_) {}

      // Write each sign as a document
      for (final sign in signs) {
        // Look up enriched data from global signs collection
        AdminSignModel? globalSign;
        if (globalSigns != null) {
          for (final gs in globalSigns) {
            if (gs.word.toLowerCase() == sign.character.toLowerCase()) {
              globalSign = gs;
              break;
            }
          }
        }

        await signsCollection.add({
          'lessonId': lessonId,
          'word': sign.character,
          'wordInHindi': null,
          'order': sign.order,
          'imageUrl': sign.pictureUrl ?? globalSign?.imageUrl,
          'gifUrl': sign.animationUrl ?? globalSign?.gifUrl,
          'videoUrl': globalSign?.videoUrl,
          'description': sign.description ?? globalSign?.description ?? '',
          'instructions': <String>[],
          'tips': null,
          'difficulty': 'easy',
        });
      }
    } catch (e) {
      debugPrint('Error syncing signs to subcollection: $e');
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
      debugPrint('Error creating word group: $e');
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
      debugPrint('Error updating word group: $e');
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
      debugPrint('Error deleting word group: $e');
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
      debugPrint('Error adding word: $e');
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
      debugPrint('Error updating word: $e');
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
      debugPrint('Error deleting word: $e');
      return false;
    }
  }

  // ==================== LEARNER OPERATIONS ====================



  /// Get learner by ID
  Future<UserModel?> getLearner(String learnerId) async {
    try {
      final doc = await _db.collection('users').doc(learnerId).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting learner: $e');
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
      debugPrint('Error updating learner: $e');
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
      debugPrint('Error resetting learner progress: $e');
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
      debugPrint('Error deleting learner: $e');
      return false;
    }
  }

  /// Get learners with pagination
  Future<LearnerQueryResult> getLearners({
    int limit = 25,
    DocumentSnapshot? startAfter,
    String? searchQuery,
  }) async {
    try {
      Query query = _db.collection('users').orderBy('createdAt', descending: true);

      if (searchQuery != null && searchQuery.isNotEmpty) {
        // Simple prefix search
        query = _db
            .collection('users')
            .where('displayName', isGreaterThanOrEqualTo: searchQuery)
            .where('displayName', isLessThanOrEqualTo: '$searchQuery\uf8ff')
            .orderBy('displayName');
      }

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.limit(limit).get();
      final learners = snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();

      return LearnerQueryResult(
        learners: learners,
        lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
        hasMore: snapshot.docs.length == limit,
      );
    } catch (e) {
      debugPrint('Error getting learners: $e');
      return LearnerQueryResult(learners: [], hasMore: false);
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
      debugPrint('Error setting learner status: $e');
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
      debugPrint('Error getting learner progress: $e');
      return [];
    }
  }

  // ==================== ISSUE/FEEDBACK OPERATIONS ====================

  /// Get all issues
  Stream<List<IssueModel>> issuesStream({String? status, String? priority}) {
    Query query = _db.collection('issues');
    
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }
    if (priority != null) {
      query = query.where('priority', isEqualTo: priority);
    }
    
    return query.snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) => IssueModel.fromFirestore(doc)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
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
      debugPrint('Error getting issue: $e');
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
      debugPrint('Error updating issue status: $e');
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
      debugPrint('Error updating issue priority: $e');
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
      debugPrint('Error adding issue note: $e');
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
      debugPrint('Error updating issue: $e');
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
      debugPrint('Error deleting issue: $e');
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
      debugPrint('Error updating maintenance mode: $e');
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
      debugPrint('Error getting maintenance mode: $e');
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
      debugPrint('Error getting learner count: $e');
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
      debugPrint('Error getting active learner count: $e');
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
      debugPrint('Error getting total lessons completed: $e');
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
      debugPrint('Error getting analytics summary: $e');
      return {
        'totalLearners': 0,
        'activeLearners': 0,
        'newLearnersThisWeek': 0,
        'openIssues': 0,
      };
    }
  }

  /// Get daily lesson completions for the last 7 days
  Future<List<double>> getDailyLessonCompletions() async {
    try {
      final now = DateTime.now();
      final List<double> dailyCounts = [0, 0, 0, 0, 0, 0, 0];

      // We look at all users' progress
      final usersSnapshot = await _db.collection('users').get();

      for (final userDoc in usersSnapshot.docs) {
        final completedSnapshot = await userDoc.reference
            .collection('progress')
            .where('status', isEqualTo: 'completed')
            .get();

        for (final progressDoc in completedSnapshot.docs) {
          final data = progressDoc.data();
          final completedAt =
              (data['completedAt'] as Timestamp?)?.toDate() ??
              (data['updatedAt'] as Timestamp?)?.toDate();

          if (completedAt != null) {
            final dayIndex = 6 - now.difference(completedAt).inDays;
            if (dayIndex >= 0 && dayIndex < 7) {
              dailyCounts[dayIndex]++;
            }
          }
        }
      }
      return dailyCounts;
    } catch (e) {
      debugPrint('Error getting daily completions: $e');
      return [0, 0, 0, 0, 0, 0, 0];
    }
  }
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
      debugPrint('Error getting sign practice logs: $e');
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
      debugPrint('Failed to log audit action: $e');
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
      debugPrint('Failed to log audit action: $e');
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
      debugPrint('Error creating category: $e');
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
      debugPrint('Error updating category: $e');
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
      debugPrint('Error deleting category: $e');
      return false;
    }
  }

  // ==================== SIGNS COLLECTION OPERATIONS ====================

  /// Get all signs from the global signs collection
  Stream<List<AdminSignModel>> signsStream() {
    return _db
        .collection('signs')
        .orderBy('order')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => AdminSignModel.fromFirestore(doc)).toList());
  }

  /// Get signs by type (alphabet or number)
  Stream<List<AdminSignModel>> signsByTypeStream(String type) {
    return _db
        .collection('signs')
        .where('type', isEqualTo: type)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => AdminSignModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => a.order.compareTo(b.order));
      return list;
    });
  }

  /// Get all signs as a one-time fetch
  Future<List<AdminSignModel>> getAllSigns() async {
    try {
      final snapshot =
          await _db.collection('signs').orderBy('order').get();
      return snapshot.docs
          .map((doc) => AdminSignModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting all signs: $e');
      return [];
    }
  }

  /// Create a new sign
  Future<String?> createSign(AdminSignModel sign) async {
    try {
      final docRef = await _db.collection('signs').add(sign.toFirestore());
      await _logAuditAction(
        action: 'create',
        entityType: 'sign',
        entityId: docRef.id,
        changes: {'word': sign.word, 'type': sign.type},
      );
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating sign: $e');
      return null;
    }
  }

  /// Update a sign
  Future<bool> updateSign(String signId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _db.collection('signs').doc(signId).update(updates);
      await _logAuditAction(
        action: 'update',
        entityType: 'sign',
        entityId: signId,
        changes: updates,
      );
      return true;
    } catch (e) {
      debugPrint('Error updating sign: $e');
      return false;
    }
  }

  /// Delete a sign
  Future<bool> deleteSign(String signId) async {
    try {
      await _db.collection('signs').doc(signId).delete();
      await _logAuditAction(
        action: 'delete',
        entityType: 'sign',
        entityId: signId,
      );
      return true;
    } catch (e) {
      debugPrint('Error deleting sign: $e');
      return false;
    }
  }

  // ==================== IMAGE AUTOMATION ====================

  /// Check Firebase Storage for a matching image for a given word
  /// Checks paths like: signs/A.png, signs/A.gif, signs/A.jpg
  Future<String?> findSignImageInStorage(String word) async {
    final extensions = ['png', 'gif', 'jpg', 'jpeg', 'webp', 'mp4'];
    final folders = ['signs', 'sign_images', 'ISL'];

    for (final folder in folders) {
      for (final ext in extensions) {
        try {
          final ref = _storage.ref('$folder/$word.$ext');
          final url = await ref.getDownloadURL();
          return url;
        } catch (_) {
          // File not found, try next
        }
      }
    }
    return null;
  }

  /// Upload a sign image/video to Firebase Storage
  Future<String?> uploadSignMedia(
      String word, List<int> fileBytes, String fileName) async {
    try {
      final ext = fileName.split('.').last;
      final ref = _storage.ref('signs/$word.$ext');
      final metadata = SettableMetadata(
        contentType: _getContentType(ext),
      );
      await ref.putData(Uint8List.fromList(fileBytes), metadata);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading sign media: $e');
      return null;
    }
  }

  /// Simple upload that takes raw bytes
  Future<String?> uploadSignFile(
      String word, dynamic fileData, String extension) async {
    try {
      final ref = _storage.ref('signs/$word.$extension');
      final metadata = SettableMetadata(
        contentType: _getContentType(extension),
      );
      final task = ref.putData(fileData, metadata);
      await task;
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading sign file: $e');
      return null;
    }
  }

  String _getContentType(String ext) {
    switch (ext.toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'mp4':
        return 'video/mp4';
      case 'webm':
        return 'video/webm';
      default:
        return 'application/octet-stream';
    }
  }

  // ==================== MCQ AUTOMATION ====================

  /// Automatically generate MCQ questions for a sign
  /// Fetches 3 random incorrect options from the signs collection
  Future<MCQQuestion?> generateMCQ(AdminSignModel correctSign) async {
    try {
      final allSigns = await getAllSigns();

      // Filter out the correct sign and get candidates of the same type
      final candidates = allSigns
          .where((s) => s.id != correctSign.id && s.word != correctSign.word)
          .toList();

      if (candidates.length < 3) {
        debugPrint('Not enough signs to generate MCQ (need at least 3 distractors)');
        return null;
      }

      // Shuffle and pick 3 random wrong options
      candidates.shuffle(Random());
      final wrongOptions = candidates.take(3).toList();

      // Combine correct + wrong and shuffle
      final allOptions = [correctSign, ...wrongOptions];
      allOptions.shuffle(Random());

      return MCQQuestion(
        correctSign: correctSign,
        options: allOptions,
        questionText:
            'Which sign represents "${correctSign.word}"?',
      );
    } catch (e) {
      debugPrint('Error generating MCQ: $e');
      return null;
    }
  }

  /// Generate multiple MCQ questions for a lesson's signs
  Future<List<MCQQuestion>> generateMCQsForLesson(
      List<AdminSignItem> lessonSigns) async {
    final questions = <MCQQuestion>[];
    final allSigns = await getAllSigns();

    for (final lessonSign in lessonSigns) {
      // Find the full sign model from the global collection
      final fullSign = allSigns.firstWhere(
        (s) => s.word.toLowerCase() == lessonSign.character.toLowerCase(),
        orElse: () => AdminSignModel(
          id: '',
          word: lessonSign.character,
          imageUrl: lessonSign.pictureUrl,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      if (fullSign.id.isEmpty) continue;

      final candidates = allSigns
          .where((s) => s.id != fullSign.id && s.word != fullSign.word)
          .toList();

      if (candidates.length < 3) continue;

      candidates.shuffle(Random());
      final wrongOptions = candidates.take(3).toList();
      final allOptions = [fullSign, ...wrongOptions];
      allOptions.shuffle(Random());

      questions.add(MCQQuestion(
        correctSign: fullSign,
        options: allOptions,
        questionText:
            'Which sign represents "${fullSign.word}"?',
      ));
    }

    return questions;
  }

  // ==================== CATEGORY AUTO-CALCULATION ====================

  /// Recalculate total_lessons and total_signs for a category
  Future<void> recalculateCategoryTotals(String categoryId) async {
    try {
      // Count lessons in subcollection
      final lessonsSnapshot = await _db
          .collection('categories')
          .doc(categoryId)
          .collection('lessons')
          .get();

      int totalSigns = 0;
      for (final doc in lessonsSnapshot.docs) {
        // Count signs in subcollection
        final signsSnapshot =
            await doc.reference.collection('signs').get();
        if (signsSnapshot.docs.isNotEmpty) {
          totalSigns += signsSnapshot.docs.length;
        } else {
          // Fallback to embedded signs array
          final data = doc.data();
          final embeddedSigns = data['signs'] as List<dynamic>? ?? [];
          totalSigns += embeddedSigns.length;
        }
      }

      await _db.collection('categories').doc(categoryId).update({
        'totalLessons': lessonsSnapshot.docs.length,
        'totalSigns': totalSigns,
      });
    } catch (e) {
      debugPrint('Error recalculating category totals: $e');
    }
  }

  /// Recalculate totals for all categories
  Future<void> recalculateAllCategoryTotals() async {
    try {
      final categoriesSnapshot = await _db.collection('categories').get();
      for (final catDoc in categoriesSnapshot.docs) {
        await recalculateCategoryTotals(catDoc.id);
      }
    } catch (e) {
      debugPrint('Error recalculating all category totals: $e');
    }
  }

  // ==================== WORD CHARACTER SPLITTING ====================

  /// Split a word into individual characters and validate against signs collection
  Future<List<WordCharacter>> splitWordIntoCharacters(String word) async {
    final allSigns = await getAllSigns();
    final characters = <WordCharacter>[];

    for (final char in word.toUpperCase().split('')) {
      if (char.trim().isEmpty) continue;

      final matchingSign = allSigns.firstWhere(
        (s) => s.word.toUpperCase() == char,
        orElse: () => AdminSignModel(
          id: '',
          word: char,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      characters.add(WordCharacter(
        char: char,
        signReference: matchingSign.id.isNotEmpty ? matchingSign.id : null,
      ));
    }

    return characters;
  }

  /// Get lessons filtered by category — reads from subcollection
  Stream<List<AdminLessonModel>> lessonsByCategoryStream(String categoryId) {
    return _db
        .collection('categories')
        .doc(categoryId)
        .collection('lessons')
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AdminLessonModel.fromFirestore(doc))
            .toList());
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

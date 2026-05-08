import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:math';
import 'package:kairo_ai/admin/models/admin_models.dart';
import 'package:kairo_ai/firebase_options.dart';
import 'package:kairo_ai/models/app_models.dart';

class AdminDatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  String _normalizeIssueStatus(String status) {
    final normalized = status.trim().toLowerCase();
    if (normalized == 'in_progress' || normalized == 'inprogress') {
      return 'in-progress';
    }
    return normalized;
  }

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
        changes: {'name': group.name, 'gemCost': group.unlockGemCost},
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

  /// Maintain totalWords
  Future<void> _updateWordGroupTotalWords(String groupId) async {
    final wordsSnapshot = await _db
        .collection('word_groups')
        .doc(groupId)
        .collection('words')
        .get();
    
    await _db.collection('word_groups').doc(groupId).update({
      'totalWords': wordsSnapshot.docs.length,
    });
  }

  /// Validate word characters — only A-Z and 0-9 allowed
  void _validateWordCharacters(String text) {
    final upperText = text.toUpperCase();
    if (upperText.isEmpty) {
      throw Exception('Word text cannot be empty.');
    }
    final unsupportedRegex = RegExp(r'[^A-Z0-9]');
    if (unsupportedRegex.hasMatch(upperText)) {
      throw Exception('Only characters A-Z and 0-9 are supported.');
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
  Future<String> addWord(String groupId, WordModel word) async {
    _validateWordCharacters(word.text);
    
    // Check for duplicate normalizedText
    final duplicates = await _db
        .collection('word_groups')
        .doc(groupId)
        .collection('words')
        .where('normalizedText', isEqualTo: word.normalizedText)
        .get();
        
    if (duplicates.docs.isNotEmpty) {
      throw Exception('A word with this text already exists in this group.');
    }

    final docRef = await _db
        .collection('word_groups')
        .doc(groupId)
        .collection('words')
        .add(word.toFirestore());
        
    await _updateWordGroupTotalWords(groupId);
        
    await _logAuditAction(
      action: 'create',
      entityType: 'word',
      entityId: docRef.id,
      changes: {'text': word.text, 'groupId': groupId},
    );
    return docRef.id;
  }

  /// Update word
  Future<bool> updateWord(String groupId, String wordId, Map<String, dynamic> updates) async {
    try {
      if (updates.containsKey('text')) {
        _validateWordCharacters(updates['text']);
        final normalizedText = (updates['text'] as String).toUpperCase();
        
        // Check for duplicate
        final duplicates = await _db
            .collection('word_groups')
            .doc(groupId)
            .collection('words')
            .where('normalizedText', isEqualTo: normalizedText)
            .get();
            
        if (duplicates.docs.any((doc) => doc.id != wordId)) {
          throw Exception('A word with this text already exists in this group.');
        }
      }

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
          
      await _updateWordGroupTotalWords(groupId);
          
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
      
      // Reset canonical learner stats
      await _db.collection('users').doc(learnerId).update({
        'xp': 0,
        'currentLevel': 1,
        'totalLessonsCompleted': 0,
        'totalSignsLearned': 0,
        'totalPracticeMinutes': 0,
        'todayLessonPracticeMinutes': 0,
        'todayLessonPracticeDate': null,
        'streakDays': 0,
        'lastStreakDate': null,
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

  /// Legacy bool wrapper used by older code paths.
  Future<bool> deleteLearner(String learnerId) async {
    final result = await deleteLearnerCompletely(learnerId);
    return result.success;
  }

  /// Delete learner firestore + auth account through an admin-only backend function.
  Future<AdminActionResult> deleteLearnerCompletely(String learnerId) async {
    try {
      final callable = _functions.httpsCallable('deleteLearnerAccount');
      final response = await callable.call(<String, dynamic>{
        'learnerId': learnerId,
      });

      final payload = (response.data is Map)
          ? Map<String, dynamic>.from(response.data as Map)
          : <String, dynamic>{};
      final success = payload['success'] == true;

      if (!success) {
        final backendMessage = (payload['message'] ?? '').toString().trim();
        return AdminActionResult(
          success: false,
          message: backendMessage.isNotEmpty
              ? backendMessage
              : 'Deletion could not be completed on the backend.',
        );
      }

      await _logAuditAction(
        action: 'delete',
        entityType: 'learner',
        entityId: learnerId,
        changes: <String, dynamic>{'fullDelete': true},
      );

      return const AdminActionResult(
        success: true,
        message: 'Learner removed from Authentication and Firestore.',
      );
    } on FirebaseFunctionsException catch (e) {
      final backendMessage = (e.message ?? '').trim();
      return AdminActionResult(
        success: false,
        message: backendMessage.isNotEmpty
            ? backendMessage
            : 'Secure deletion endpoint is unavailable right now.',
      );
    } catch (e) {
      debugPrint('Error deleting learner: $e');
      return const AdminActionResult(
        success: false,
        message: 'Delete failed before completion. Nothing was removed in UI.',
      );
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
      final normalizedStatus = _normalizeIssueStatus(status);
      if (normalizedStatus == 'open') {
        query = query.where('status', whereIn: <String>['open', 'new']);
      } else if (normalizedStatus == 'in-progress') {
        query = query.where('status', whereIn: <String>['in-progress', 'in_progress']);
      } else {
        query = query.where('status', isEqualTo: normalizedStatus);
      }
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
      final normalizedStatus = _normalizeIssueStatus(status);
      final updates = <String, dynamic>{
        'status': normalizedStatus,
      };
      
      if (normalizedStatus == 'resolved' || normalizedStatus == 'closed') {
        updates['resolvedAt'] = FieldValue.serverTimestamp();
      }
      
      await _db.collection('issues').doc(issueId).update(updates);
      await _logAuditAction(
        action: 'status_change',
        entityType: 'issue',
        entityId: issueId,
        changes: {'status': normalizedStatus},
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

  // ==================== LEVEL CONFIG OPERATIONS ====================

  Stream<LevelConfigModel> levelConfigStream() {
    return _db.collection('settings').doc('level_config').snapshots().map((doc) {
      if (doc.exists) {
        return LevelConfigModel.fromFirestore(doc);
      }
      return const LevelConfigModel();
    });
  }

  Future<LevelConfigModel> getLevelConfig() async {
    try {
      final doc = await _db.collection('settings').doc('level_config').get();
      if (doc.exists) {
        return LevelConfigModel.fromFirestore(doc);
      }
    } catch (e) {
      debugPrint('Error loading level config: $e');
    }
    return const LevelConfigModel();
  }

  Future<bool> updateLevelConfig(LevelConfigModel config, {String? updatedBy}) async {
    try {
      final normalized = LevelConfigModel.normalizeThresholds(config.xpThresholds);
      final payload = config.copyWith(
        xpThresholds: normalized,
        updatedAt: DateTime.now(),
        updatedBy: updatedBy,
      );

      await _db.collection('settings').doc('level_config').set(payload.toFirestore());
      await _logAuditAction(
        action: 'update_level_config',
        entityType: 'settings',
        entityId: 'level_config',
        changes: <String, dynamic>{'xpThresholds': normalized},
      );
      return true;
    } catch (e) {
      debugPrint('Error updating level config: $e');
      return false;
    }
  }

  Future<int> recalculateAllLearnerLevels() async {
    try {
      final config = await getLevelConfig();
      final usersSnapshot = await _db.collection('users').get();

      if (usersSnapshot.docs.isEmpty) {
        return 0;
      }

      var updated = 0;
      var batch = _db.batch();
      var writesInBatch = 0;

      for (final userDoc in usersSnapshot.docs) {
        final data = userDoc.data();
        final xp = (data['xp'] as num?)?.toInt() ?? 0;
        final currentLevel = config.levelForXp(xp);

        final totalLessonsCompleted =
            (data['totalLessonsCompleted'] as num?)?.toInt() ??
            ((data['completedLessonIds'] as List?)?.length ?? 0);

        batch.set(userDoc.reference, <String, dynamic>{
          'xp': xp,
          'currentLevel': currentLevel,
          'totalLessonsCompleted': totalLessonsCompleted,
        }, SetOptions(merge: true));

        writesInBatch += 1;
        updated += 1;

        if (writesInBatch >= 400) {
          await batch.commit();
          batch = _db.batch();
          writesInBatch = 0;
        }
      }

      if (writesInBatch > 0) {
        await batch.commit();
      }

      await _logAuditAction(
        action: 'recalculate_levels',
        entityType: 'users',
        entityId: null,
        changes: <String, dynamic>{'updatedLearners': updated},
      );

      return updated;
    } catch (e) {
      debugPrint('Error recalculating learner levels: $e');
      return 0;
    }
  }

  // ==================== ADMIN MANAGEMENT OPERATIONS ====================

  Stream<List<AdminModel>> adminsStream() {
    return _db
        .collection('admins')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => AdminModel.fromFirestore(doc)).toList());
  }

  Future<int> getActiveAdminCount() async {
    final snapshot = await _db
        .collection('admins')
        .where('isActive', isEqualTo: true)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  Future<AdminActionResult> setAdminActiveStatus({
    required String adminId,
    required bool isActive,
    required String actingAdminId,
  }) async {
    try {
      final targetDoc = await _db.collection('admins').doc(adminId).get();
      if (!targetDoc.exists) {
        return const AdminActionResult(
          success: false,
          message: 'Admin record was not found.',
        );
      }

      final target = AdminModel.fromFirestore(targetDoc);
      final activeCount = await getActiveAdminCount();

      if (!isActive) {
        final isTargetActive = target.isActive;
        final isLastActive = isTargetActive && activeCount <= 1;
        if (isLastActive) {
          return const AdminActionResult(
            success: false,
            message: 'At least one active admin is required at all times.',
          );
        }
      }

      await _db.collection('admins').doc(adminId).update(<String, dynamic>{
        'isActive': isActive,
        'statusUpdatedAt': FieldValue.serverTimestamp(),
      });

      await _logAuditAction(
        action: isActive ? 'activate_admin' : 'deactivate_admin',
        entityType: 'admin',
        entityId: adminId,
        changes: <String, dynamic>{'actor': actingAdminId},
      );

      return AdminActionResult(
        success: true,
        message: isActive ? 'Admin reactivated.' : 'Admin deactivated.',
      );
    } catch (e) {
      debugPrint('Error updating admin status: $e');
      return const AdminActionResult(
        success: false,
        message: 'Could not update admin status right now.',
      );
    }
  }

  Future<AdminActionResult> removeAdminAccess({
    required String adminId,
    required String actingAdminId,
  }) async {
    try {
      final targetDoc = await _db.collection('admins').doc(adminId).get();
      if (!targetDoc.exists) {
        return const AdminActionResult(
          success: false,
          message: 'Admin record was already removed.',
        );
      }

      final target = AdminModel.fromFirestore(targetDoc);
      final activeCount = await getActiveAdminCount();

      if (target.isActive && activeCount <= 1) {
        return const AdminActionResult(
          success: false,
          message: 'Cannot remove the last active admin.',
        );
      }

      await _db.collection('admins').doc(adminId).delete();

      await _logAuditAction(
        action: 'remove_admin',
        entityType: 'admin',
        entityId: adminId,
        changes: <String, dynamic>{'actor': actingAdminId},
      );

      return const AdminActionResult(
        success: true,
        message: 'Admin access removed.',
      );
    } catch (e) {
      debugPrint('Error removing admin: $e');
      return const AdminActionResult(
        success: false,
        message: 'Failed to remove admin access.',
      );
    }
  }

  Future<AdminActionResult> promoteAdminByEmail(String email) async {
    try {
      final callable = _functions.httpsCallable('promoteAdminByEmail');
      final response = await callable.call(<String, dynamic>{'email': email.trim()});

      final payload = (response.data is Map)
          ? Map<String, dynamic>.from(response.data as Map)
          : <String, dynamic>{};
      final success = payload['success'] == true;

      if (!success) {
        final backendMessage = (payload['message'] ?? '').toString().trim();
        return AdminActionResult(
          success: false,
          message: backendMessage.isNotEmpty
              ? backendMessage
              : 'Promotion request could not be completed.',
        );
      }

      final promotedUid = (payload['uid'] ?? '').toString().trim();
      if (promotedUid.isNotEmpty) {
        await _db.collection('admins').doc(promotedUid).set(<String, dynamic>{
          'email': (payload['email'] ?? email).toString().trim().toLowerCase(),
          'displayName': (payload['displayName'] ?? '').toString().trim(),
          'isActive': true,
          'role': 'admin',
          'permissions': <String>[],
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      await _logAuditAction(
        action: 'promote_admin',
        entityType: 'admin',
        entityId: promotedUid.isNotEmpty ? promotedUid : null,
        changes: <String, dynamic>{'email': email.trim().toLowerCase()},
      );

      return const AdminActionResult(
        success: true,
        message: 'Admin access granted successfully.',
      );
    } on FirebaseFunctionsException catch (e) {
      final backendMessage = (e.message ?? '').trim();
      return AdminActionResult(
        success: false,
        message: backendMessage.isNotEmpty
            ? backendMessage
            : 'Secure promotion endpoint is unavailable.',
      );
    } catch (e) {
      debugPrint('Error promoting admin: $e');
      return const AdminActionResult(
        success: false,
        message: 'Failed to promote this account to admin.',
      );
    }
  }

  Future<AdminActionResult> createManagedUser({
    required String email,
    required String displayName,
    required String temporaryPassword,
    required bool createAsAdmin,
    required String actingAdminId,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedName = displayName.trim();
    final password = temporaryPassword.trim();

    if (normalizedEmail.isEmpty) {
      return const AdminActionResult(
        success: false,
        message: 'Email is required.',
      );
    }
    if (normalizedName.isEmpty) {
      return const AdminActionResult(
        success: false,
        message: 'Display name is required.',
      );
    }
    if (password.length < 6) {
      return const AdminActionResult(
        success: false,
        message: 'Temporary password must be at least 6 characters.',
      );
    }

    FirebaseApp? secondaryApp;
    try {
      final appName = 'admin-create-user-${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(9999)}';
      secondaryApp = await Firebase.initializeApp(
        name: appName,
        options: DefaultFirebaseOptions.currentPlatform,
      );

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      final createdUser = credential.user;
      if (createdUser == null) {
        return const AdminActionResult(
          success: false,
          message: 'User account was not created. Please retry.',
        );
      }

      await createdUser.updateDisplayName(normalizedName);
      await secondaryAuth.signOut();

      final now = DateTime.now();
      if (createAsAdmin) {
        await _db.collection('users').doc(createdUser.uid).delete().catchError((_) {});
        await _db.collection('admins').doc(createdUser.uid).set(<String, dynamic>{
          'email': normalizedEmail,
          'displayName': normalizedName,
          'isActive': true,
          'role': 'admin',
          'permissions': <String>[],
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        await _logAuditAction(
          action: 'create_admin',
          entityType: 'admin',
          entityId: createdUser.uid,
          changes: <String, dynamic>{
            'email': normalizedEmail,
            'actor': actingAdminId,
          },
        );

        return const AdminActionResult(
          success: true,
          message: 'Admin account created successfully.',
        );
      }

      await _db.collection('admins').doc(createdUser.uid).delete().catchError((_) {});
      final learner = UserModel(
        uid: createdUser.uid,
        email: normalizedEmail,
        displayName: normalizedName,
        createdAt: now,
        lastLoginAt: now,
        gems: 0,
        coins: 100,
        streakDays: 0,
        totalLessonsCompleted: 0,
        totalSignsLearned: 0,
        totalPracticeMinutes: 0,
        currentLevel: 1,
        xp: 0,
        isActive: true,
      );
      await _db.collection('users').doc(createdUser.uid).set(
            learner.toFirestore(),
            SetOptions(merge: true),
          );

      await _logAuditAction(
        action: 'create_learner',
        entityType: 'learner',
        entityId: createdUser.uid,
        changes: <String, dynamic>{
          'email': normalizedEmail,
          'actor': actingAdminId,
        },
      );

      return const AdminActionResult(
        success: true,
        message: 'Learner account created successfully.',
      );
    } on FirebaseAuthException catch (e) {
      if (createAsAdmin && e.code == 'email-already-in-use') {
        final promoteResult = await promoteAdminByEmail(normalizedEmail);
        if (promoteResult.success) {
          return const AdminActionResult(
            success: true,
            message: 'Existing account found and promoted to admin.',
          );
        }
        return promoteResult;
      }
      return AdminActionResult(
        success: false,
        message: _authCreateErrorMessage(e.code),
      );
    } catch (e) {
      debugPrint('Error creating managed user: $e');
      return const AdminActionResult(
        success: false,
        message: 'Could not create user account right now.',
      );
    } finally {
      if (secondaryApp != null) {
        try {
          await secondaryApp.delete();
        } catch (_) {}
      }
    }
  }

  Future<AdminActionResult> updateAdminDisplayName({
    required String adminId,
    required String displayName,
    required String actingAdminId,
  }) async {
    final nextName = displayName.trim();
    if (nextName.isEmpty) {
      return const AdminActionResult(
        success: false,
        message: 'Display name cannot be empty.',
      );
    }

    try {
      await _db.collection('admins').doc(adminId).update(<String, dynamic>{
        'displayName': nextName,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _logAuditAction(
        action: 'update_admin',
        entityType: 'admin',
        entityId: adminId,
        changes: <String, dynamic>{
          'displayName': nextName,
          'actor': actingAdminId,
        },
      );

      return const AdminActionResult(
        success: true,
        message: 'Admin profile updated.',
      );
    } catch (e) {
      debugPrint('Error updating admin profile: $e');
      return const AdminActionResult(
        success: false,
        message: 'Could not update admin profile.',
      );
    }
  }

  String _authCreateErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already in use.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Temporary password is too weak.';
      case 'operation-not-allowed':
        return 'Email/password sign up is disabled in Firebase Auth.';
      default:
        return 'Could not create account ($code).';
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
          .where('status', whereIn: <String>['new', 'open', 'in-progress', 'in_progress'])
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

  Future<Map<String, String>> getSignLabelsById() async {
    try {
      final labels = <String, String>{};

      void absorbLabel(String key, String value) {
        final normalizedKey = key.trim();
        final normalizedValue = value.trim();
        if (normalizedKey.isEmpty || normalizedValue.isEmpty) {
          return;
        }
        labels[normalizedKey] = normalizedValue;
      }

      Future<void> absorbSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) async {
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final label = (data['word'] ??
                  data['signCharacter'] ??
                  data['character'] ??
                  data['label'] ??
                  data['text'] ??
                  '')
              .toString()
              .trim();

          if (label.isNotEmpty) {
            absorbLabel(doc.id, label);
          }
        }
      }

      await absorbSnapshot(await _db.collection('signs').get());
      await absorbSnapshot(await _db.collectionGroup('signs').get());

      // Some logs may capture sign characters as IDs. Keep direct label map too.
      for (final value in labels.values.toList(growable: false)) {
        absorbLabel(value, value);
      }

      return labels;
    } catch (e) {
      debugPrint('Error resolving sign labels: $e');
      return <String, String>{};
    }
  }

  Future<double> getOverallPracticeAccuracy({int sampleLimit = 800}) async {
    try {
      final snapshot = await _db
          .collection('sign_practice_logs')
          .orderBy('timestamp', descending: true)
          .limit(sampleLimit)
          .get();

      if (snapshot.docs.isEmpty) {
        return 0;
      }

      var correct = 0;
      for (final doc in snapshot.docs) {
        final isCorrect = (doc.data()['isCorrect'] ?? false) == true;
        if (isCorrect) {
          correct += 1;
        }
      }

      return correct / snapshot.docs.length;
    } catch (e) {
      debugPrint('Error calculating practice accuracy: $e');
      return 0;
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

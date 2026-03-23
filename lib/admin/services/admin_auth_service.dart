import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kairo_ai/admin/models/admin_models.dart';

class AdminAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Current admin state
  AdminModel? _currentAdmin;
  AdminModel? get currentAdmin => _currentAdmin;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Sign in with email and password
  Future<AdminAuthResult> signIn(String email, String password) async {
    try {
      // First, sign in with Firebase Auth
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      if (credential.user == null) {
        return AdminAuthResult(
          success: false,
          error: 'Authentication failed. Please try again.',
        );
      }

      // Check if user exists in admins collection
      final adminDoc = await _db.collection('admins').doc(credential.user!.uid).get();

      if (!adminDoc.exists) {
        // Not an admin, sign out
        await _auth.signOut();
        return AdminAuthResult(
          success: false,
          error: 'Access denied. You are not authorized as an administrator.',
        );
      }

      final admin = AdminModel.fromFirestore(adminDoc);

      // Check if admin is active
      if (!admin.isActive) {
        await _auth.signOut();
        return AdminAuthResult(
          success: false,
          error: 'Your admin account has been deactivated. Contact support.',
        );
      }

      // Update last login
      await _db.collection('admins').doc(credential.user!.uid).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });

      // Log the login
      await _logAuditAction(
        adminId: credential.user!.uid,
        adminEmail: email,
        action: 'login',
        entityType: 'admin',
      );

      _currentAdmin = admin;

      return AdminAuthResult(
        success: true,
        admin: admin,
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No account found with this email.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address format.';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled.';
          break;
        case 'invalid-credential':
          errorMessage = 'Invalid credentials. Please check your email and password.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many failed attempts. Please try again later.';
          break;
        default:
          errorMessage = 'Authentication error: ${e.message}';
      }
      return AdminAuthResult(success: false, error: errorMessage);
    } catch (e) {
      return AdminAuthResult(
        success: false,
        error: 'An unexpected error occurred: $e',
      );
    }
  }

  /// Sign out
  Future<void> signOut() async {
    if (_currentAdmin != null) {
      await _logAuditAction(
        adminId: _currentAdmin!.uid,
        adminEmail: _currentAdmin!.email,
        action: 'logout',
        entityType: 'admin',
      );
    }
    _currentAdmin = null;
    await _auth.signOut();
  }

  /// Check if current user is an authenticated admin
  Future<AdminModel?> checkAdminStatus() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final adminDoc = await _db.collection('admins').doc(user.uid).get();
      if (!adminDoc.exists) return null;

      final admin = AdminModel.fromFirestore(adminDoc);
      if (!admin.isActive) return null;

      _currentAdmin = admin;
      return admin;
    } catch (e) {
      return null;
    }
  }

  /// Stream of admin authentication state
  Stream<AdminModel?> adminAuthStateChanges() {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) {
        _currentAdmin = null;
        return null;
      }

      try {
        final adminDoc = await _db.collection('admins').doc(user.uid).get();
        if (!adminDoc.exists) {
          _currentAdmin = null;
          return null;
        }

        final admin = AdminModel.fromFirestore(adminDoc);
        if (!admin.isActive) {
          _currentAdmin = null;
          return null;
        }

        _currentAdmin = admin;
        return admin;
      } catch (e) {
        _currentAdmin = null;
        return null;
      }
    });
  }

  /// Log audit action
  Future<void> _logAuditAction({
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
      // Silent fail - don't break the main operation
      debugPrint('Failed to log audit action: $e');
    }
  }

  /// Change password
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) return false;

      // Re-authenticate
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Change password
      await user.updatePassword(newPassword);

      await _logAuditAction(
        adminId: user.uid,
        adminEmail: user.email!,
        action: 'password_changed',
        entityType: 'admin',
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Reset password request
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return true;
    } catch (e) {
      return false;
    }
  }
}

class AdminAuthResult {
  final bool success;
  final String? error;
  final AdminModel? admin;

  AdminAuthResult({
    required this.success,
    this.error,
    this.admin,
  });
}

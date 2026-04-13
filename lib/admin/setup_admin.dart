import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

const String _adminEmail = String.fromEnvironment('ADMIN_SETUP_EMAIL');
const String _adminPassword = String.fromEnvironment('ADMIN_SETUP_PASSWORD');

void _assertAdminCredentialsConfigured() {
  if (_adminEmail.isEmpty || _adminPassword.isEmpty) {
    throw StateError(
      'Admin setup credentials are not configured. '
      'Pass --dart-define=ADMIN_SETUP_EMAIL and --dart-define=ADMIN_SETUP_PASSWORD.',
    );
  }
}

/// ⭐ MAIN FUNCTION - Creates a NEW admin account
/// Call this once: createAdminAccount()
Future<void> createAdminAccount() async {
  _assertAdminCredentialsConfigured();
  final String adminEmail = _adminEmail;
  final String adminPassword = _adminPassword;
  
  try {
    // CREATE a new user in Firebase Auth
    final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: adminEmail,
      password: adminPassword,
    );
    
    final uid = userCredential.user?.uid;
    
    if (uid == null) {
      print('Error: Could not get user UID');
      return;
    }
    
    // Create admin document in Firestore
    await FirebaseFirestore.instance.collection('admins').doc(uid).set({
      'email': adminEmail,
      'role': 'super_admin',
      'permissions': [
        'lessons',
        'word_groups', 
        'learners',
        'analytics',
        'issues',
        'settings',
        'maintenance',
      ],
      'createdAt': FieldValue.serverTimestamp(),
      'isActive': true,
      'displayName': 'Kairo Admin',
    });
    
    print('════════════════════════════════════════════');
    print('✅ ADMIN ACCOUNT CREATED SUCCESSFULLY!');
    print('════════════════════════════════════════════');
    print('   Email: $adminEmail');
    print('   UID: $uid');
    print('   Role: super_admin');
    print('════════════════════════════════════════════');
    print('⚠️  Rotate credentials after first login.');
    print('════════════════════════════════════════════');
    
  } on FirebaseAuthException catch (e) {
    if (e.code == 'email-already-in-use') {
      print('⚠️ Email already exists in Firebase Auth.');
      print('   Try signing in with that email, or use a different email.');
    } else {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
    }
  } catch (e) {
    print('Error creating admin: $e');
  }
}

/// Run this function once to set up the initial admin user.
/// Call this from a button tap or from main() temporarily.
/// 
/// Usage:
/// 1. Make sure the user with ADMIN_SETUP_EMAIL exists in Firebase Auth
/// 2. Call setupAdminUser() 
/// 3. Remove the call after setup is complete
Future<void> setupAdminUser() async {
  _assertAdminCredentialsConfigured();
  final String adminEmail = _adminEmail;
  
  try {
    // Get the user by email from Firebase Auth
    // Note: This requires the user to already exist in Firebase Auth
    final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: adminEmail,
      password: _adminPassword,
    );
    
    final uid = userCredential.user?.uid;
    
    if (uid == null) {
      print('Error: Could not get user UID');
      return;
    }
    
    // Create admin document in Firestore
    await FirebaseFirestore.instance.collection('admins').doc(uid).set({
      'email': adminEmail,
      'role': 'super_admin',
      'permissions': [
        'lessons',
        'word_groups', 
        'learners',
        'analytics',
        'issues',
        'settings',
        'maintenance',
      ],
      'createdAt': FieldValue.serverTimestamp(),
      'isActive': true,
      'displayName': 'Kairo Admin',
    });
    
    print('✅ Admin user created successfully!');
    print('   Email: $adminEmail');
    print('   UID: $uid');
    print('   Role: super_admin');
    
  } on FirebaseAuthException catch (e) {
    print('Firebase Auth Error: ${e.message}');
  } catch (e) {
    print('Error setting up admin: $e');
  }
}

/// Alternative: Create admin document directly if you know the UID
/// You can find the UID in Firebase Console > Authentication > Users
Future<void> setupAdminByUid(String uid) async {
  _assertAdminCredentialsConfigured();
  final String adminEmail = _adminEmail;
  
  try {
    await FirebaseFirestore.instance.collection('admins').doc(uid).set({
      'email': adminEmail,
      'role': 'super_admin',
      'permissions': [
        'lessons',
        'word_groups',
        'learners', 
        'analytics',
        'issues',
        'settings',
        'maintenance',
      ],
      'createdAt': FieldValue.serverTimestamp(),
      'isActive': true,
      'displayName': 'Kairo Admin',
    });
    
    print('✅ Admin user created successfully!');
    print('   Email: $adminEmail');
    print('   UID: $uid');
    print('   Role: super_admin');
    
  } catch (e) {
    print('Error setting up admin: $e');
  }
}

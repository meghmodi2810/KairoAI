import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ⭐ MAIN FUNCTION - Creates a NEW admin account
/// Call this once: createAdminAccount()
/// Password: kairo@041828@!!!!
Future<void> createAdminAccount() async {
  const String adminEmail = 'offical.kairo.ai@gmail.com';
  const String adminPassword = 'kairo@041828@!!!!'; // ← Change this after first login!
  
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
    print('   Password: $adminPassword');
    print('   UID: $uid');
    print('   Role: super_admin');
    print('════════════════════════════════════════════');
    print('⚠️  Change your password after first login!');
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
/// 1. Make sure the user with email 'offical.kairo.ai@gmail.com' exists in Firebase Auth
/// 2. Call setupAdminUser() 
/// 3. Remove the call after setup is complete
Future<void> setupAdminUser() async {
  const String adminEmail = 'offical.kairo.ai@gmail.com';
  
  try {
    // Get the user by email from Firebase Auth
    // Note: This requires the user to already exist in Firebase Auth
    final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: adminEmail,
      password: 'KairoAdmin@2026', // Default password
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
  const String adminEmail = 'offical.kairo.ai@gmail.com';
  
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

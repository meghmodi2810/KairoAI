import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'pages/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Uncomment the lines below to create a test user on first run
  // await createTestUser();
  
  runApp(const MyApp());
}

// Helper function to create a test user - run this once then comment it out
Future<void> createTestUser() async {
  try {
    await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: 'test@kairo.ai',
      password: 'testpassword123',
    );
    print('✅ Test user created: test@kairo.ai / testpassword123');
  } catch (e) {
    print('Test user already exists or error: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
    );
  }
}
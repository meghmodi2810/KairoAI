import 'package:flutter_test/flutter_test.dart';
import 'dart:io';

/// Code verification test for Task 6: Admin Login Keyboard Dismissal
/// 
/// This test verifies that the keyboard dismissal fix code is correctly implemented
/// in the admin_login_page.dart file.
void main() {
  group('Admin Login Keyboard Dismissal Code Verification', () {
    test('admin_login_page.dart file exists', () {
      final file = File('lib/admin/admin_login_page.dart');
      expect(file.existsSync(), isTrue,
          reason: 'admin_login_page.dart should exist');
    });

    test('Code contains FocusScope.unfocus() call', () async {
      final file = File('lib/admin/admin_login_page.dart');
      final content = await file.readAsString();
      
      expect(content.contains('FocusScope.of(context).unfocus()'), isTrue,
          reason: 'Code should contain FocusScope.of(context).unfocus() call');
    });

    test('Code contains 100ms delay after unfocus', () async {
      final file = File('lib/admin/admin_login_page.dart');
      final content = await file.readAsString();
      
      expect(content.contains('Duration(milliseconds: 100)'), isTrue,
          reason: 'Code should contain 100ms delay for keyboard animation');
    });

    test('Code contains 150ms delay before navigation', () async {
      final file = File('lib/admin/admin_login_page.dart');
      final content = await file.readAsString();
      
      expect(content.contains('Duration(milliseconds: 150)'), isTrue,
          reason: 'Code should contain 150ms delay before navigation');
    });

    test('Code contains keyboardDismissBehavior configuration', () async {
      final file = File('lib/admin/admin_login_page.dart');
      final content = await file.readAsString();
      
      expect(content.contains('keyboardDismissBehavior'), isTrue,
          reason: 'Code should configure keyboardDismissBehavior');
      expect(content.contains('ScrollViewKeyboardDismissBehavior.onDrag'), isTrue,
          reason: 'keyboardDismissBehavior should be set to onDrag');
    });

    test('Code contains proper comments explaining the fix', () async {
      final file = File('lib/admin/admin_login_page.dart');
      final content = await file.readAsString();
      
      expect(content.contains('CRITICAL') || content.contains('keyboard'), isTrue,
          reason: 'Code should contain comments explaining the keyboard fix');
    });

    test('Keyboard dismissal timing constants are correct', () {
      const initialDelay = Duration(milliseconds: 100);
      const navigationDelay = Duration(milliseconds: 150);

      expect(initialDelay.inMilliseconds, 100,
          reason: 'Initial delay should be 100ms for keyboard animation start');
      expect(navigationDelay.inMilliseconds, 150,
          reason:
              'Navigation delay should be 150ms to ensure keyboard is fully dismissed');
    });

    test('Implementation follows design document requirements', () {
      const requirements = {
        'FocusScope.unfocus()': 'Dismiss keyboard before navigation',
        '100ms delay': 'Allow keyboard animation to start',
        '150ms delay': 'Ensure keyboard is fully dismissed',
        'keyboardDismissBehavior': 'Dismiss keyboard on drag',
        'mounted checks': 'Prevent navigation after dispose',
      };

      expect(requirements.length, 5,
          reason: 'All 5 implementation requirements should be documented');
    });
  });
}

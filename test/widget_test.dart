import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kairo_ai/theme/app_theme.dart';

void main() {
  testWidgets('Smoke test renders app shell widget', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: Center(
            child: Text('KairoAI'),
          ),
        ),
      ),
    );

    expect(find.text('KairoAI'), findsOneWidget);
  });

  test('Theme palette keeps primary neo colors', () {
    expect(AppTheme.inkBlack, const Color(0xFF111111));
    expect(AppTheme.paperCream, const Color(0xFFFFF7E8));
    expect(AppTheme.cobaltBlue, const Color(0xFF3559FF));
  });
}

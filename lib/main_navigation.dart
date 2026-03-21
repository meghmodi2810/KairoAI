import 'package:flutter/material.dart';
import 'pages/home_page_new.dart';
import 'pages/learn_page.dart';
import 'pages/words_page.dart';
import 'pages/profile_page.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    LearnPage(),
    WordsPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border(top: BorderSide(color: cs.onSurface.withOpacity(0.08))),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, 'Home', cs),
                _buildNavItem(1, Icons.school_rounded, 'Learn', cs),
                _buildNavItem(2, Icons.text_fields_rounded, 'Words', cs),
                _buildNavItem(3, Icons.person_rounded, 'Profile', cs),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, ColorScheme cs) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? cs.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? cs.primary : cs.onSurface.withOpacity(0.4), size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? cs.primary : cs.onSurface.withOpacity(0.4),
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

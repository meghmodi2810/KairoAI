import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_models.dart';
import '../theme/app_theme.dart';
import 'category_lessons_page.dart';

/// Full-screen Learn tab — lists all categories with progress.
class LearnPage extends StatelessWidget {
  const LearnPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        automaticallyImplyLeading: false,
        title: const Text('Learn ISL', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('categories').orderBy('order').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primaryIndigo));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.school_outlined, color: AppTheme.textMuted, size: 56),
                  SizedBox(height: 16),
                  Text('No categories yet', style: TextStyle(color: AppTheme.textSecondary, fontSize: 18)),
                  SizedBox(height: 8),
                  Text('Categories will appear here once added by admin.',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
                ],
              ),
            );
          }

          final categories = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              final category = CategoryModel.fromFirestore(cat);

              return _CategoryCard(
                category: category,
                uid: uid,
              );
            },
          );
        },
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final CategoryModel category;
  final String? uid;

  const _CategoryCard({
    required this.category,
    required this.uid,
  });

  Color _parseColor(String colorVal) {
    if (colorVal.startsWith('#')) {
      final hex = colorVal.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    }
    return AppTheme.primaryIndigo;
  }

  IconData _getIcon(String emoji) {
    switch (emoji) {
      case '👋': return Icons.waving_hand;
      case '🔢': return Icons.looks_one;
      case '🔤': return Icons.abc;
      case '👨‍👩‍👧‍👦': return Icons.groups;
      case '🌈': return Icons.palette;
      case '🐾': return Icons.pets;
      default: return Icons.school;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(category.color);
    final icon = _getIcon(category.iconEmoji);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CategoryLessonsPage(category: category),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (category.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          category.description,
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        '${category.totalLessons} lessons',
                        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

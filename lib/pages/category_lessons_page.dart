import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import 'sign_learning_page.dart';

class CategoryLessonsPage extends StatefulWidget {
  final CategoryModel category;

  const CategoryLessonsPage({super.key, required this.category});

  @override
  State<CategoryLessonsPage> createState() => _CategoryLessonsPageState();
}

class _CategoryLessonsPageState extends State<CategoryLessonsPage> {
  final _db = DatabaseService();
  List<LessonModel> _lessons = [];
  Map<String, LessonProgress?> _progress = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final lessons = await _db.getLessons(widget.category.id);
      final Map<String, LessonProgress?> prog = {};
      for (final l in lessons) {
        prog[l.id] = await _db.getLessonProgress(l.id);
      }
      if (mounted) setState(() {
        _lessons = lessons; _progress = prog; _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _hex(String s) {
    try { return Color(int.parse(s.replaceFirst('#', '0xFF'))); }
    catch (_) { return AppTheme.accent; }
  }

  int get _completedCount =>
      _progress.values.where((p) => p?.status == 'completed').length;

  double get _progressValue =>
      _lessons.isEmpty ? 0 : _completedCount / _lessons.length;

  @override
  Widget build(BuildContext context) {
    final catColor = _hex(widget.category.color);

    return Scaffold(
      backgroundColor: context.surface,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : CustomScrollView(
              slivers: [
                // ── Collapsing header ─────────────────────────────
                SliverAppBar(
                  expandedHeight: 200,
                  pinned: true,
                  backgroundColor: context.surface,
                  leading: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: CollapseMode.parallax,
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [catColor.withOpacity(0.85), catColor.withOpacity(0.4)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Row(children: [
                                Container(
                                  width: 52, height: 52,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Center(child: Text(widget.category.iconEmoji,
                                    style: const TextStyle(fontSize: 28))),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(widget.category.name, style: const TextStyle(
                                      color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                                    const SizedBox(height: 2),
                                    Text(widget.category.description, style: TextStyle(
                                      color: Colors.white.withOpacity(0.75), fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ]),
                                ),
                              ]),
                              const SizedBox(height: 16),
                              // Progress bar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: _progressValue, minHeight: 6,
                                  backgroundColor: Colors.white.withOpacity(0.25),
                                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text('$_completedCount / ${_lessons.length} lessons',
                                  style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Lessons list ────────────────────────────────
                _lessons.isEmpty
                    ? SliverFillRemaining(
                        child: Center(child: Column(
                          mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.inbox_outlined, color: context.textMuted, size: 48),
                          const SizedBox(height: 12),
                          Text('No lessons yet', style: TextStyle(
                            color: context.textSecondary, fontSize: 16, fontWeight: FontWeight.w600)),
                        ])))
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, i) {
                              final lesson = _lessons[i];
                              final prog   = _progress[lesson.id];
                              final isCompleted  = prog?.status == 'completed';
                              final isInProgress = prog?.status == 'in-progress' || prog?.status == 'started';
                              final isLocked     = lesson.isLocked && !isCompleted && !isInProgress;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _LessonCard(
                                  lesson: lesson,
                                  catColor: catColor,
                                  isCompleted: isCompleted,
                                  isInProgress: isInProgress,
                                  isLocked: isLocked,
                                  onTap: isLocked ? null : () {
                                    Navigator.push(context,
                                      MaterialPageRoute(builder: (_) => SignLearningPage(
                                        lesson: lesson, categoryId: widget.category.id)));
                                  },
                                ),
                              );
                            },
                            childCount: _lessons.length,
                          ),
                        ),
                      ),
              ],
            ),
    );
  }
}

// ────────────────────────────────────────────────
//  Lesson card
// ────────────────────────────────────────────────
class _LessonCard extends StatelessWidget {
  final LessonModel lesson;
  final Color catColor;
  final bool isCompleted, isInProgress, isLocked;
  final VoidCallback? onTap;

  const _LessonCard({
    required this.lesson,
    required this.catColor,
    required this.isCompleted,
    required this.isInProgress,
    required this.isLocked,
    required this.onTap,
  });

  Color get _statusColor {
    if (isCompleted)  return AppTheme.success;
    if (isInProgress) return AppTheme.warning;
    if (isLocked)     return const Color(0xFF252530);
    return catColor;
  }

  IconData get _statusIcon {
    if (isCompleted)  return Icons.check_circle_rounded;
    if (isInProgress) return Icons.play_circle_outline_rounded;
    if (isLocked)     return Icons.lock_rounded;
    return Icons.radio_button_unchecked_rounded;
  }

  String get _statusLabel {
    if (isCompleted)  return 'Completed';
    if (isInProgress) return 'In Progress';
    if (isLocked)     return 'Locked';
    return 'Start';
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor;

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: isLocked ? 0.5 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isCompleted ? color.withOpacity(0.3) : context.border),
          ),
          child: Row(
            children: [
              // Status icon
              Icon(_statusIcon, color: color, size: 28),
              const SizedBox(width: 14),
              // Content
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Unit ${lesson.unitNumber}', style: TextStyle(
                    color: context.textMuted, fontSize: 11, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(lesson.title, style: TextStyle(
                    color: context.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  // Chips row
                  Row(children: [
                    _Chip(icon: Icons.timer_outlined, label: '${lesson.estimatedMinutes} min',
                      color: context.textMuted),
                    const SizedBox(width: 8),
                    _Chip(icon: Icons.diamond_rounded, label: '+${lesson.gemsReward}',
                      color: AppTheme.purple),
                    const SizedBox(width: 8),
                    _Chip(icon: Icons.bolt_rounded, label: '+${lesson.xpReward} XP',
                      color: AppTheme.warning),
                  ]),
                ]),
              ),
              const SizedBox(width: 8),
              // Status badge
              KairoBadge(label: _statusLabel, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Chip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: color),
      const SizedBox(width: 3),
      Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    ]);
  }
}

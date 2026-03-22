import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../services/database_service.dart';
import '../services/sign_image_service.dart';
import '../theme/app_theme.dart';
import 'lesson_practice_page.dart';

/// Phase 1 of the lesson experience — sign review.
/// Shows each sign with its image, name and instructions.
/// After the last sign the user can tap "Practice with Camera →" to launch Phase 2.
class SignLearningPage extends StatefulWidget {
  final LessonModel lesson;
  final String categoryId;

  const SignLearningPage({super.key, required this.lesson, required this.categoryId});

  @override
  State<SignLearningPage> createState() => _SignLearningPageState();
}

class _SignLearningPageState extends State<SignLearningPage>
    with SingleTickerProviderStateMixin {
  final _db     = DatabaseService();
  final _imgSvc = SignImageService();

  List<SignModel> _signs  = [];
  int  _index    = 0;
  bool _loading  = true;
  bool _showTips = false;

  final _pageController = PageController();

  // Lesson-level progress (set by database on completion)
  bool _lessonCompleted = false;

  SignModel get _current => _signs[_index];

  @override
  void initState() {
    super.initState();
    _loadSigns();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ── Data ──────────────────────────────────────────────────────

  Future<void> _loadSigns() async {
    try {
      await _db.startLesson(widget.lesson.id, widget.categoryId);
      final signs = await _db.getSigns(widget.categoryId, widget.lesson.id);
      if (mounted) setState(() { _signs = signs; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Navigation ────────────────────────────────────────────────

  void _next() {
    if (_index < _signs.length - 1) {
      setState(() { _index++; _showTips = false; });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320), curve: Curves.easeInOutCubic);
    }
  }

  void _prev() {
    if (_index > 0) {
      setState(() { _index--; _showTips = false; });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 320), curve: Curves.easeInOutCubic);
    }
  }

  // ── Complete lesson (after practice) ─────────────────────────

  Future<void> _completeLesson() async {
    if (_lessonCompleted) return;
    _lessonCompleted = true;
    try {
      await _db.completeLesson(
        lessonId: widget.lesson.id,
        categoryId: widget.categoryId,
        accuracy: 1.0,
        timeSpentSeconds: _signs.length * 20,
        gemsEarned:  widget.lesson.gemsReward,
        coinsEarned: widget.lesson.coinsReward,
        xpEarned:    widget.lesson.xpReward,
        signsCount:  _signs.length,
      );
    } catch (_) {}
  }

  // ── Launch Phase 2: camera practice ──────────────────────────

  Future<void> _launchPractice() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => LessonPracticePage(
        lesson: widget.lesson,
        signs:  _signs,
      )),
    );
    if (result == true && mounted) {
      await _completeLesson();
      _showCompletionSheet();
    }
  }

  void _showCompletionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CompletionSheet(
        lesson: widget.lesson,
        onContinue: () {
          Navigator.of(context)
            ..pop() // close sheet
            ..pop(); // close sign learning page
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: context.surface,
        body: const Center(child: CircularProgressIndicator(color: AppTheme.accent)),
      );
    }
    if (_signs.isEmpty) {
      return Scaffold(
        backgroundColor: context.surface,
        appBar: AppBar(
          backgroundColor: context.surface,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context)),
        ),
        body: Center(child: Text('No signs in this lesson.',
          style: TextStyle(color: context.textSecondary))),
      );
    }

    final isLast = _index == _signs.length - 1;
    final progress = (_index + 1) / _signs.length;

    return Scaffold(
      backgroundColor: context.surface,
      body: Column(children: [
        // ── TOP BAR ──────────────────────────────────────────────
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(children: [
              IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: context.textSecondary),
                onPressed: () => Navigator.pop(context)),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.lesson.title,
                    style: TextStyle(color: context.textPrimary, fontSize: 15,
                      fontWeight: FontWeight.w700),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 5,
                      backgroundColor: context.border,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accent),
                    ),
                  ),
                ]),
              ),
              const SizedBox(width: 8),
              Text('${_index + 1}/${_signs.length}',
                style: TextStyle(color: context.textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
            ]),
          ),
        ),

        // ── SIGN PAGES ───────────────────────────────────────────
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _signs.length,
            itemBuilder: (_, i) => _SignCard(sign: _signs[i], imgSvc: _imgSvc),
          ),
        ),

        // ── INSTRUCTIONS PANEL ───────────────────────────────────
        AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOutCubic,
          child: _showTips ? _InstructionsPanel(sign: _current) : const SizedBox.shrink(),
        ),

        // ── BOTTOM CONTROLS ──────────────────────────────────────
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(children: [
              // Tips toggle
              if (_current.instructions.isNotEmpty)
                GestureDetector(
                  onTap: () => setState(() => _showTips = !_showTips),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: context.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.border),
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.lightbulb_outline_rounded,
                        color: AppTheme.warning, size: 16),
                      const SizedBox(width: 6),
                      Text(_showTips ? 'Hide tips' : 'Show tips',
                        style: TextStyle(color: context.textSecondary, fontSize: 13,
                          fontWeight: FontWeight.w600)),
                      const SizedBox(width: 4),
                      Icon(_showTips ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                        color: context.textMuted, size: 16),
                    ]),
                  ),
                ),

              // Nav row
              Row(children: [
                // Previous
                _NavButton(
                  icon: Icons.arrow_back_rounded,
                  label: 'Prev',
                  enabled: _index > 0,
                  onTap: _prev,
                  filled: false,
                ),
                const SizedBox(width: 12),
                // Next / Practice
                Expanded(
                  child: isLast
                      ? _GradientButton(
                          label: '✋  Practice with Camera',
                          onTap: _launchPractice,
                        )
                      : _GradientButton(
                          label: 'Next →',
                          onTap: _next,
                        ),
                ),
              ]),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ── Sign card (PageView item) ─────────────────────────────────
class _SignCard extends StatelessWidget {
  final SignModel sign;
  final SignImageService imgSvc;

  const _SignCard({required this.sign, required this.imgSvc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Column(children: [
        // Word heading
        Text(sign.word,
          style: TextStyle(
            color: context.textPrimary, fontSize: 34,
            fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        const SizedBox(height: 12),

        // Image card — hero area
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: context.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: context.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(23),
              child: FutureBuilder<dynamic>(
                future: imgSvc.getRandomImage(sign.word),
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator(
                      color: AppTheme.accent, strokeWidth: 2));
                  }
                  if (snap.hasData && snap.data != null) {
                    return Image.memory(snap.data!, fit: BoxFit.contain);
                  }
                  // Fallback: large letter
                  return Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(sign.word.toUpperCase(),
                        style: TextStyle(
                          color: AppTheme.accent.withOpacity(0.4),
                          fontSize: 96, fontWeight: FontWeight.w900)),
                      Text('No image available',
                        style: TextStyle(color: context.textMuted, fontSize: 12)),
                    ]),
                  );
                },
              ),
            ),
          ),
        ),

        // Difficulty / reward chips
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _SmallChip(label: sign.difficulty, color: AppTheme.accent),
        ]),
      ]),
    );
  }
}

// ── Instructions expand panel ─────────────────────────────────
class _InstructionsPanel extends StatelessWidget {
  final SignModel sign;
  const _InstructionsPanel({required this.sign});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.lightbulb_rounded, color: AppTheme.warning, size: 16),
          const SizedBox(width: 6),
          Text('How to sign "${sign.word}"',
            style: TextStyle(color: context.textPrimary,
              fontSize: 13, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 8),
        ...sign.instructions.asMap().entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${e.key + 1}. ', style: TextStyle(
              color: AppTheme.accent, fontSize: 12, fontWeight: FontWeight.w700)),
            Expanded(child: Text(e.value,
              style: TextStyle(color: context.textSecondary, fontSize: 12))),
          ]),
        )),
      ]),
    );
  }
}

// ── Completion sheet ──────────────────────────────────────────
class _CompletionSheet extends StatelessWidget {
  final LessonModel lesson;
  final VoidCallback onContinue;

  const _CompletionSheet({required this.lesson, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).padding.bottom + 24),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: context.border)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4,
          decoration: BoxDecoration(color: context.border, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 24),

        // Icon
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: AppTheme.success.withOpacity(0.15),
            shape: BoxShape.circle),
          child: const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 40)),
        const SizedBox(height: 16),

        Text('Lesson Complete! 🎉', style: TextStyle(
          color: context.textPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(lesson.title, style: TextStyle(
          color: context.textSecondary, fontSize: 14)),

        const SizedBox(height: 20),

        // Rewards
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (lesson.gemsReward > 0)
            _RewardChip(label: '+${lesson.gemsReward}', emoji: '💎'),
          if (lesson.xpReward > 0) ...[
            const SizedBox(width: 10),
            _RewardChip(label: '+${lesson.xpReward} XP', emoji: '⚡'),
          ],
          if (lesson.coinsReward > 0) ...[
            const SizedBox(width: 10),
            _RewardChip(label: '+${lesson.coinsReward}', emoji: '🪙'),
          ],
        ]),

        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: const Text('Continue', style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700))),
        ),
      ]),
    );
  }
}

class _RewardChip extends StatelessWidget {
  final String label, emoji;
  const _RewardChip({required this.label, required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.border)),
      child: Text('$emoji $label',
        style: TextStyle(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)));
  }
}

// ── Reusable controls ─────────────────────────────────────────
class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final bool filled;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon, required this.label,
    required this.enabled, required this.filled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: enabled ? context.card : context.card.withOpacity(0.4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.border)),
        child: Icon(icon,
          color: enabled ? context.textSecondary : context.textMuted, size: 20)));
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _GradientButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.accent, AppTheme.accentDark]),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(
            color: AppTheme.accent.withOpacity(0.3),
            blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Center(
          child: Text(label, style: const TextStyle(
            color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)))));
  }
}

class _SmallChip extends StatelessWidget {
  final String label;
  final Color color;
  const _SmallChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25))),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)));
  }
}
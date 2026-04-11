import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../services/database_service.dart';
import '../services/sign_image_service.dart';
import '../theme/app_theme.dart';
import '../theme/neo_brutal_widgets.dart';
import 'lesson_practice_page.dart';

class SignLearningPage extends StatefulWidget {
  final LessonModel lesson;
  final String categoryId;

  const SignLearningPage({
    super.key,
    required this.lesson,
    required this.categoryId,
  });

  @override
  State<SignLearningPage> createState() => _SignLearningPageState();
}

class _SignLearningPageState extends State<SignLearningPage> {
  final DatabaseService _db = DatabaseService();
  final SignImageService _imageService = SignImageService();

  List<SignModel> _signs = [];
  int _index = 0;
  bool _loading = true;
  bool _showTips = false;
  bool _completed = false;

  SignModel get _current => _signs[_index];

  @override
  void initState() {
    super.initState();
    _loadSigns();
  }

  Future<void> _loadSigns() async {
    try {
      await _db.startLesson(widget.lesson.id, widget.categoryId);
      final signs = await _db.getSigns(widget.categoryId, widget.lesson.id);
      if (!mounted) return;
      setState(() {
        _signs = signs;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _completeLesson(int timeSpentSeconds) async {
    if (_completed) return;
    _completed = true;
    try {
      await _db.completeLesson(
        lessonId: widget.lesson.id,
        categoryId: widget.categoryId,
        accuracy: 1.0,
        timeSpentSeconds: timeSpentSeconds,
        gemsEarned: widget.lesson.gemsReward,
        coinsEarned: widget.lesson.coinsReward,
        xpEarned: widget.lesson.xpReward,
        signsCount: _signs.length,
      );
    } catch (_) {}
  }

  void _next() {
    if (_index >= _signs.length - 1) return;
    setState(() {
      _index++;
      _showTips = false;
    });
  }

  void _prev() {
    if (_index <= 0) return;
    setState(() {
      _index--;
      _showTips = false;
    });
  }

  Future<void> _startPractice() async {
    final result = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => LessonPracticePage(
          lesson: widget.lesson,
          signs: _signs,
        ),
      ),
    );

    if (result != null && result > 0 && mounted) {
      await _completeLesson(result);
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Lesson Complete'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Nice move. You nailed this lesson.'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                if (widget.lesson.gemsReward > 0)
                  NeoSticker(
                    label: '+${widget.lesson.gemsReward} GEMS',
                    color: AppTheme.signalYellow,
                    icon: Icons.diamond,
                  ),
                if (widget.lesson.xpReward > 0)
                  NeoSticker(
                    label: '+${widget.lesson.xpReward} XP',
                    color: AppTheme.mintGreen,
                    icon: Icons.bolt,
                  ),
              ],
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppTheme.paperCream,
        body: Center(child: CircularProgressIndicator(color: AppTheme.cobaltBlue)),
      );
    }

    if (_signs.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.paperCream,
        body: NeoEmptyState(
          icon: Icons.sign_language_outlined,
          title: 'No Signs In Lesson',
          subtitle: 'This lesson currently has no sign items.',
        ),
      );
    }

    final isLast = _index == _signs.length - 1;
    final progress = (_index + 1) / _signs.length;

    return Scaffold(
      backgroundColor: AppTheme.paperCream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.warmWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.inkBlack, width: 3),
                        boxShadow: const [
                          BoxShadow(color: AppTheme.inkBlack, blurRadius: 0, offset: Offset(3, 3)),
                        ],
                      ),
                      child: const Icon(Icons.arrow_back_rounded, color: AppTheme.inkBlack),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: NeoPanel(
                      color: AppTheme.warmWhite,
                      radius: 14,
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      shadow: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.lesson.title,
                            style: const TextStyle(
                              color: AppTheme.inkBlack,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 8,
                              backgroundColor: AppTheme.paperCream,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.cobaltBlue),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_index + 1}/${_signs.length}',
                    style: const TextStyle(
                      color: AppTheme.inkBlack,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                child: NeoPanel(
                  color: AppTheme.warmWhite,
                  radius: 18,
                  child: Column(
                    children: [
                      Text(
                        _current.word,
                        style: const TextStyle(
                          color: AppTheme.inkBlack,
                          fontSize: 46,
                          height: 1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppTheme.paperCream,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.inkBlack, width: 3),
                          ),
                          child: FutureBuilder<dynamic>(
                            future: _imageService.getRandomImage(_current.word),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(color: AppTheme.cobaltBlue),
                                );
                              }
                              if (snapshot.hasData && snapshot.data != null) {
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.memory(snapshot.data!, fit: BoxFit.contain),
                                );
                              }
                              return Center(
                                child: Text(
                                  _current.word.toUpperCase(),
                                  style: TextStyle(
                                    color: AppTheme.cobaltBlue.withValues(alpha: 0.45),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 96,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.signalYellow,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.inkBlack, width: 2),
                        ),
                        child: Text(
                          _current.difficulty.toUpperCase(),
                          style: const TextStyle(
                            color: AppTheme.inkBlack,
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_current.instructions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                child: GestureDetector(
                  onTap: () => setState(() => _showTips = !_showTips),
                  child: NeoPanel(
                    color: AppTheme.signalYellow,
                    radius: 14,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lightbulb, color: AppTheme.inkBlack, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          _showTips ? 'Hide tips' : 'Show tips',
                          style: const TextStyle(
                            color: AppTheme.inkBlack,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (_showTips)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                child: NeoPanel(
                  color: AppTheme.softPeach,
                  radius: 14,
                  shadow: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _current.instructions
                        .asMap()
                        .entries
                        .map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '${entry.key + 1}. ${entry.value}',
                              style: const TextStyle(
                                color: AppTheme.inkBlack,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
              child: Row(
                children: [
                  SizedBox(
                    width: 68,
                    child: OutlinedButton(
                      onPressed: _index > 0 ? _prev : null,
                      child: const Icon(Icons.arrow_back_rounded),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: NeoPrimaryButton(
                      label: isLast ? 'Start Practice' : 'Next Sign',
                      onPressed: isLast ? _startPractice : _next,
                      icon: isLast ? Icons.camera_alt : Icons.arrow_forward,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

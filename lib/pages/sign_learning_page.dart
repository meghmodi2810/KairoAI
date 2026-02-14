import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../services/database_service.dart';
import '../services/sign_image_service.dart';
import '../theme/app_theme.dart';

/// Full-screen sign learning experience.
/// Fetches signs for a lesson and displays them one at a time with images from Firestore.
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
  final SignImageService _signImageService = SignImageService();

  List<SignModel> _signs = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _showInstructions = false;
  final PageController _pageController = PageController();

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

  Future<void> _loadSigns() async {
    try {
      await _db.startLesson(widget.lesson.id, widget.categoryId);
      final signs = await _db.getSigns(widget.categoryId, widget.lesson.id);
      if (mounted) {
        setState(() {
          _signs = signs;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading signs: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _nextSign() {
    if (_currentIndex < _signs.length - 1) {
      setState(() {
        _currentIndex++;
        _showInstructions = false;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      // Mark sign as completed
      _db.completeSign(widget.lesson.id, _signs[_currentIndex].id);
    } else {
      _completeLesson();
    }
  }

  void _prevSign() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _showInstructions = false;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeLesson() async {
    try {
      await _db.completeLesson(
        lessonId: widget.lesson.id,
        categoryId: widget.categoryId,
        accuracy: 1.0,
        timeSpentSeconds: _signs.length * 15,
        gemsEarned: widget.lesson.gemsReward,
        coinsEarned: widget.lesson.coinsReward,
        xpEarned: widget.lesson.xpReward,
        signsCount: _signs.length,
      );
    } catch (e) {
      debugPrint('Error completing lesson: $e');
    }

    if (!mounted) return;
    _showCompletionDialog();
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.celebration, color: AppTheme.accentGreen, size: 36),
              ),
              const SizedBox(height: 20),
              const Text(
                'Lesson Complete! 🎉',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'You learned ${_signs.length} signs!',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 15),
              ),
              const SizedBox(height: 20),
              // Rewards
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _rewardChip(Icons.diamond, '+${widget.lesson.gemsReward}', AppTheme.gemPurple),
                  const SizedBox(width: 12),
                  _rewardChip(Icons.monetization_on, '+${widget.lesson.coinsReward}', AppTheme.coinGold),
                  const SizedBox(width: 12),
                  _rewardChip(Icons.bolt, '+${widget.lesson.xpReward} XP', AppTheme.accentAmber),
                ],
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rewardChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryIndigo))
          : _signs.isEmpty
              ? _buildEmpty()
              : SafeArea(
                  child: Column(
                    children: [
                      _buildHeader(),
                      Expanded(child: _buildSignView()),
                      _buildControls(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmpty() {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline, color: AppTheme.textMuted, size: 56),
            const SizedBox(height: 16),
            const Text('No signs in this lesson', style: TextStyle(color: AppTheme.textSecondary, fontSize: 18)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (_currentIndex + 1) / _signs.length,
                    minHeight: 6,
                    backgroundColor: AppTheme.cardLight,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryIndigo),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${_currentIndex + 1}/${_signs.length}',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            widget.lesson.title,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSignView() {
    return PageView.builder(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _signs.length,
      itemBuilder: (context, index) {
        final sign = _signs[index];
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 8),
              // Sign word
              Text(
                sign.word,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (sign.wordInHindi != null && sign.wordInHindi!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  sign.wordInHindi!,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                ),
              ],
              const SizedBox(height: 24),
              // Sign image from Firestore
              Container(
                width: double.infinity,
                height: 260,
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.dividerColor),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: FutureBuilder<dynamic>(
                    future: _signImageService.getRandomImage(sign.word),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: AppTheme.primaryIndigo));
                      }
                      if (snapshot.hasData && snapshot.data != null) {
                        return Image.memory(
                          snapshot.data!,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => _buildPlaceholderImage(sign.word),
                        );
                      }
                      return _buildPlaceholderImage(sign.word);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Description
              if (sign.description.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    sign.description,
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 15, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 16),
              // Instructions toggle
              if (sign.instructions.isNotEmpty)
                GestureDetector(
                  onTap: () => setState(() => _showInstructions = !_showInstructions),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryIndigo.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.primaryIndigo.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.lightbulb_outline, color: AppTheme.accentAmber, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              _showInstructions ? 'Hide Instructions' : 'Show Instructions',
                              style: const TextStyle(
                                color: AppTheme.primaryIndigo,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              _showInstructions ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                              color: AppTheme.primaryIndigo,
                            ),
                          ],
                        ),
                        if (_showInstructions) ...[
                          const SizedBox(height: 14),
                          ...sign.instructions.asMap().entries.map((entry) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryIndigo.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${entry.key + 1}',
                                          style: const TextStyle(
                                            color: AppTheme.primaryIndigo,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        entry.value,
                                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.4),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ],
                    ),
                  ),
                ),
              // Tips
              if (sign.tips != null && sign.tips!.isNotEmpty && _showInstructions) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.accentAmber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('💡', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          sign.tips!,
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlaceholderImage(String word) {
    return Container(
      color: AppTheme.cardLight,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sign_language, color: AppTheme.textMuted, size: 56),
            const SizedBox(height: 10),
            Text(
              word,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    final isLast = _currentIndex == _signs.length - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceLight,
        border: Border(top: BorderSide(color: AppTheme.dividerColor)),
      ),
      child: Row(
        children: [
          if (_currentIndex > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _prevSign,
                icon: const Icon(Icons.arrow_back_rounded, size: 20),
                label: const Text('Previous'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textSecondary,
                  side: const BorderSide(color: AppTheme.dividerColor),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          if (_currentIndex > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _nextSign,
              icon: Icon(isLast ? Icons.check_circle : Icons.arrow_forward_rounded, size: 20),
              label: Text(isLast ? 'Complete' : 'Next'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isLast ? AppTheme.accentGreen : AppTheme.primaryIndigo,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

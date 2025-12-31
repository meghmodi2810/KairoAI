import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../services/database_service.dart';
import 'practice_page.dart';

class LessonDetailPage extends StatefulWidget {
  final LessonModel lesson;
  final String categoryId;

  const LessonDetailPage({
    super.key,
    required this.lesson,
    required this.categoryId,
  });

  @override
  State<LessonDetailPage> createState() => _LessonDetailPageState();
}

class _LessonDetailPageState extends State<LessonDetailPage> {
  final DatabaseService _databaseService = DatabaseService();
  List<SignModel> _signs = [];
  int _currentSignIndex = 0;
  bool _isLoading = true;

  // Theme colors
  static const Color primaryBlue = Color(0xFF1A2151);
  static const Color darkBlue = Color(0xFF141938);
  static const Color accentYellow = Color(0xFFFFD93D);
  static const Color cardBg = Color(0xFF252A5E);
  static const Color successGreen = Color(0xFF27AE60);

  @override
  void initState() {
    super.initState();
    _loadSigns();
  }

  Future<void> _loadSigns() async {
    try {
      final signs = await _databaseService.getSigns(
        widget.categoryId,
        widget.lesson.id,
      );

      if (mounted) {
        setState(() {
          _signs = signs;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading signs: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _startPractice() async {
    if (_signs.isEmpty) return;

    // Mark lesson as started
    await _databaseService.startLesson(widget.lesson.id, widget.categoryId);

    if (mounted) {
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => PracticePage(
            lesson: widget.lesson,
            categoryId: widget.categoryId,
            signs: _signs,
          ),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBlue,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: accentYellow),
            )
          : _signs.isEmpty
              ? _buildEmptyState()
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final currentSign = _signs[_currentSignIndex];

    return SafeArea(
      child: Column(
        children: [
          // Top bar
          _buildTopBar(),
          
          // Main content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Sign illustration area
                  _buildSignDisplay(currentSign),
                  const SizedBox(height: 24),
                  
                  // Sign info
                  _buildSignInfo(currentSign),
                  const SizedBox(height: 24),
                  
                  // Focus Points
                  _buildFocusPoints(),
                  const SizedBox(height: 24),
                  
                  // Instructions
                  _buildInstructions(currentSign),
                ],
              ),
            ),
          ),
          
          // Bottom button
          _buildBottomButton(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'Unit ${widget.lesson.unitNumber}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
                Text(
                  widget.lesson.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Progress indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_currentSignIndex + 1}/${_signs.length}',
              style: const TextStyle(
                color: accentYellow,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignDisplay(SignModel sign) {
    return Container(
      width: double.infinity,
      height: 280,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cardBg,
            cardBg.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Stack(
        children: [
          // Hand gesture placeholder
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated hand icon
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: accentYellow.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      '🤟',
                      style: TextStyle(fontSize: 80),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Sign description
                Text(
                  sign.description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // Navigation arrows for multiple signs
          if (_signs.length > 1)
            Positioned(
              left: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  onPressed: _currentSignIndex > 0
                      ? () => setState(() => _currentSignIndex--)
                      : null,
                  icon: Icon(
                    Icons.chevron_left,
                    color: _currentSignIndex > 0
                        ? Colors.white70
                        : Colors.white24,
                    size: 32,
                  ),
                ),
              ),
            ),
          if (_signs.length > 1)
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  onPressed: _currentSignIndex < _signs.length - 1
                      ? () => setState(() => _currentSignIndex++)
                      : null,
                  icon: Icon(
                    Icons.chevron_right,
                    color: _currentSignIndex < _signs.length - 1
                        ? Colors.white70
                        : Colors.white24,
                    size: 32,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSignInfo(SignModel sign) {
    return Column(
      children: [
        Text(
          sign.word,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (sign.wordInHindi != null) ...[
          const SizedBox(height: 4),
          Text(
            sign.wordInHindi!,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 18,
            ),
          ),
        ],
        const SizedBox(height: 12),
        // Difficulty badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: _getDifficultyColor(sign.difficulty).withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _getDifficultyColor(sign.difficulty).withOpacity(0.4),
            ),
          ),
          child: Text(
            sign.difficulty.toUpperCase(),
            style: TextStyle(
              color: _getDifficultyColor(sign.difficulty),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  Widget _buildFocusPoints() {
    final focusPoints = widget.lesson.focusPoints;
    if (focusPoints.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline, color: accentYellow, size: 20),
              SizedBox(width: 8),
              Text(
                'Focus Points',
                style: TextStyle(
                  color: accentYellow,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...focusPoints.map((point) => _buildFocusPoint(point)),
        ],
      ),
    );
  }

  Widget _buildFocusPoint(String point) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: successGreen.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.check,
              color: successGreen,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              point,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions(SignModel sign) {
    if (sign.instructions.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white70, size: 20),
              SizedBox(width: 8),
              Text(
                'How to Sign',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...sign.instructions.asMap().entries.map((entry) {
            return _buildInstructionStep(entry.key + 1, entry.value);
          }),
          if (sign.tips != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentYellow.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accentYellow.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.tips_and_updates, color: accentYellow, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      sign.tips!,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInstructionStep(int step, String instruction) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: primaryBlue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$step',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              instruction,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: darkBlue,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Rewards preview
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildRewardChip('💎', widget.lesson.gemsReward),
                const SizedBox(width: 16),
                _buildRewardChip('🪙', widget.lesson.coinsReward),
                const SizedBox(width: 16),
                _buildRewardChip('⭐', widget.lesson.xpReward),
              ],
            ),
            const SizedBox(height: 16),
            // Start button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _startPractice,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentYellow,
                  foregroundColor: darkBlue,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_arrow, size: 24),
                    SizedBox(width: 8),
                    Text(
                      "I'm Ready to Try",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardChip(String emoji, int value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(
            '+$value',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.front_hand_outlined,
                    color: Colors.white.withOpacity(0.3),
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No signs in this lesson yet',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Check back soon!',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage>
    with TickerProviderStateMixin {
  // Theme Colors - Matching the Duolingo-style design with Pink accent
  static const Color primaryBg = Color(0xFF181E34);
  static const Color cardBg = Color(0xFF262F4D);
  static const Color accentPink = Color(0xFFFF4B8C); // Primary Pink Accent
  static const Color accentPinkLight = Color(0xFFFF6B9D); // Lighter Pink
  static const Color accentBlue = Color(0xFF5CB6F9);
  static const Color lockedBlue = Color(0xFF3A4A6B);
  static const Color pathColor = Color(0xFF2A3A5A);
  static const Color streakOrange = Color(0xFFFF9500);

  late AnimationController _pulseController;
  late AnimationController _bounceController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _bounceAnimation;

  // User stats
  int gems = 144;
  int coins = 2321;
  int streakDays = 12;
  int quizScore = 850;

  // Quiz data with ISL-specific icons
  final List<QuizNodeData> _quizzes = [
    QuizNodeData(
      id: 1,
      iconType: QuizIconType.basicSigns,
      title: 'Basic Signs Quiz',
      status: QuizStatus.completed,
      questionsCount: 10,
    ),
    QuizNodeData(
      id: 2,
      iconType: QuizIconType.alphabet,
      title: 'Alphabet Challenge',
      status: QuizStatus.completed,
      questionsCount: 26,
    ),
    QuizNodeData(
      id: 3,
      iconType: QuizIconType.numbers,
      title: 'Numbers Quiz',
      status: QuizStatus.active,
      questionsCount: 15,
    ),
    QuizNodeData(
      id: 4,
      iconType: QuizIconType.greetings,
      title: 'Greetings Test',
      status: QuizStatus.locked,
      questionsCount: 12,
    ),
    QuizNodeData(
      id: 5,
      iconType: QuizIconType.phrases,
      title: 'Daily Phrases',
      status: QuizStatus.locked,
      questionsCount: 20,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _bounceAnimation = Tween<double>(begin: 0, end: -6).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              _buildTopBar(),
              const SizedBox(height: 16),
              _buildQuizHeader(),
              const SizedBox(height: 10),
              _buildQuizPath(),
              const SizedBox(height: 20),
              _buildNextQuizPreview(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // Quiz icon badge
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cardBg,
              border: Border.all(color: accentPink.withOpacity(0.5), width: 2),
            ),
            child: const Icon(
              Icons.quiz,
              color: accentPink,
              size: 26,
            ),
          ),
          const Spacer(),
          // Streak Counter (Fire icon)
          _buildStreakPill(),
          const SizedBox(width: 10),
          // Quiz Score Pill
          _buildStatPill(
            icon: Icons.star,
            value: quizScore.toString(),
            iconColor: accentPink,
          ),
          const SizedBox(width: 10),
          // Gems Pill
          _buildStatPill(
            icon: Icons.diamond,
            value: gems.toString(),
            iconColor: accentBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildStreakPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department, color: streakOrange, size: 20),
          const SizedBox(width: 4),
          Text(
            '$streakDays Days',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill({
    required IconData icon,
    required String value,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 5),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        height: 140,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [accentPink, accentPinkLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: accentPink.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background decoration
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              left: -30,
              bottom: -30,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Quiz Section:',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'ISL Challenges',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Progress Bar
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Container(
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: 0.4, // 40% progress
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.5),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const Spacer(flex: 2),
                    ],
                  ),
                ],
              ),
            ),
            // Quiz mascot/icon
            Positioned(
              right: 15,
              top: 0,
              bottom: 0,
              child: Center(
                child: _buildQuizMascot(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizMascot() {
    return Container(
      width: 90,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Quiz trophy/brain icon representation
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.psychology,
                  color: accentPink,
                  size: 35,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'QUIZ',
                  style: TextStyle(
                    color: accentPink,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          // Sparkle decorations
          Positioned(
            top: 10,
            right: 10,
            child: Icon(
              Icons.auto_awesome,
              color: Colors.white.withOpacity(0.8),
              size: 16,
            ),
          ),
          Positioned(
            bottom: 15,
            left: 8,
            child: Icon(
              Icons.star,
              color: Colors.white.withOpacity(0.6),
              size: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizPath() {
    return Container(
      height: 580,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Stack(
        children: [
          // The curved path behind nodes
          Positioned.fill(
            child: CustomPaint(
              painter: QuizPathPainter(
                pathColor: pathColor,
                nodePositions: _getNodePositions(),
              ),
            ),
          ),
          // Quiz nodes
          ..._buildQuizNodes(),
        ],
      ),
    );
  }

  List<Offset> _getNodePositions() {
    // Define the zigzag positions for the S-shaped path
    return const [
      Offset(0.28, 0.06),  // Node 1 - left
      Offset(0.70, 0.20),  // Node 2 - right
      Offset(0.30, 0.38),  // Node 3 - left
      Offset(0.22, 0.56),  // Node 4 - more left
      Offset(0.68, 0.75),  // Node 5 - right
    ];
  }

  List<Widget> _buildQuizNodes() {
    final positions = _getNodePositions();
    final widgets = <Widget>[];
    final screenWidth = MediaQuery.of(context).size.width - 40; // Account for padding

    for (int i = 0; i < _quizzes.length; i++) {
      final quiz = _quizzes[i];
      final position = positions[i];

      widgets.add(
        Positioned(
          left: position.dx * screenWidth - 40,
          top: position.dy * 580 - 40,
          child: _buildQuizNode(quiz),
        ),
      );
    }

    return widgets;
  }

  Widget _buildQuizNode(QuizNodeData quiz) {
    final isActive = quiz.status == QuizStatus.active;
    final isCompleted = quiz.status == QuizStatus.completed;
    final isLocked = quiz.status == QuizStatus.locked;

    return GestureDetector(
      onTap: () => _onQuizTap(quiz),
      child: AnimatedBuilder(
        animation: isActive ? _bounceAnimation : const AlwaysStoppedAnimation(0),
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, isActive ? _bounceAnimation.value : 0),
            child: child,
          );
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Glow effect for active node
            if (isActive)
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Container(
                    width: 95 * _pulseAnimation.value,
                    height: 95 * _pulseAnimation.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accentPink.withOpacity(0.4),
                          blurRadius: 25,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                  );
                },
              ),
            // Main circle
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted || isActive ? accentPink : lockedBlue,
                border: Border.all(
                  color: isCompleted || isActive
                      ? accentPink.withOpacity(0.8)
                      : lockedBlue.withOpacity(0.6),
                  width: 4,
                ),
                boxShadow: isActive || isCompleted
                    ? [
                        BoxShadow(
                          color: accentPink.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Center(
                child: _buildQuizIcon(quiz),
              ),
            ),
            // Checkmark badge for completed
            if (isCompleted)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF4CAF50),
                    border: Border.all(color: primaryBg, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            // Question count badge
            if (!isLocked)
              Positioned(
                left: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Text(
                    '${quiz.questionsCount}Q',
                    style: TextStyle(
                      color: isCompleted || isActive ? accentPink : lockedBlue,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizIcon(QuizNodeData quiz) {
    final isLocked = quiz.status == QuizStatus.locked;
    final color = isLocked ? Colors.white.withOpacity(0.5) : Colors.white;

    switch (quiz.iconType) {
      case QuizIconType.basicSigns:
        return Icon(Icons.pan_tool, color: color, size: 32);
      case QuizIconType.alphabet:
        return Text(
          'ABC',
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        );
      case QuizIconType.numbers:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '123',
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      case QuizIconType.greetings:
        return Icon(Icons.waving_hand, color: color, size: 32);
      case QuizIconType.phrases:
        return Icon(Icons.chat_bubble, color: color, size: 30);
    }
  }

  void _onQuizTap(QuizNodeData quiz) {
    if (quiz.status == QuizStatus.locked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.lock, color: Colors.white70, size: 20),
              SizedBox(width: 12),
              Text('Complete previous quizzes first!'),
            ],
          ),
          backgroundColor: cardBg,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // Navigate to quiz
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildQuizBottomSheet(quiz),
    );
  }

  Widget _buildQuizBottomSheet(QuizNodeData quiz) {
    return Container(
      decoration: const BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentPink,
              boxShadow: [
                BoxShadow(
                  color: accentPink.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Center(child: _buildQuizIcon(quiz)),
          ),
          const SizedBox(height: 20),
          Text(
            quiz.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Quiz ${quiz.id} • ${quiz.questionsCount} Questions',
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, color: accentPink, size: 18),
              const SizedBox(width: 4),
              const Text(
                '+50 XP',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.access_time, color: accentBlue, size: 18),
              const SizedBox(width: 4),
              Text(
                '~${quiz.questionsCount} min',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Quiz difficulty indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDifficultyDot(true),
              const SizedBox(width: 4),
              _buildDifficultyDot(quiz.id > 1),
              const SizedBox(width: 4),
              _buildDifficultyDot(quiz.id > 3),
              const SizedBox(width: 8),
              Text(
                quiz.id <= 2 ? 'Easy' : quiz.id <= 4 ? 'Medium' : 'Hard',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Navigate to quiz detail
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: accentPink,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                quiz.status == QuizStatus.completed
                    ? 'RETAKE QUIZ'
                    : 'START QUIZ',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDifficultyDot(bool active) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? accentPink : Colors.white.withOpacity(0.3),
      ),
    );
  }

  Widget _buildNextQuizPreview() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: cardBg.withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Next Challenge:',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Advanced Signs',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: lockedBlue.withOpacity(0.6),
              ),
              child: Icon(
                Icons.lock,
                color: Colors.white.withOpacity(0.5),
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Painter for the winding S-shaped path
class QuizPathPainter extends CustomPainter {
  final Color pathColor;
  final List<Offset> nodePositions;

  QuizPathPainter({
    required this.pathColor,
    required this.nodePositions,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = pathColor
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (nodePositions.length < 2) return;

    final path = Path();

    // Convert relative positions to actual coordinates
    final points = nodePositions.map((pos) {
      return Offset(pos.dx * size.width, pos.dy * size.height);
    }).toList();

    // Start at first point
    path.moveTo(points[0].dx, points[0].dy);

    // Draw smooth S-curves between points
    for (int i = 0; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];

      // Calculate control points for smooth S-curve
      final midY = (current.dy + next.dy) / 2;
      
      // Create bezier curves for smooth transitions
      path.cubicTo(
        current.dx,
        midY,
        next.dx,
        midY,
        next.dx,
        next.dy,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Data models
enum QuizStatus { locked, active, completed }

enum QuizIconType {
  basicSigns,
  alphabet,
  numbers,
  greetings,
  phrases,
}

class QuizNodeData {
  final int id;
  final QuizIconType iconType;
  final String title;
  final QuizStatus status;
  final int questionsCount;

  QuizNodeData({
    required this.id,
    required this.iconType,
    required this.title,
    required this.status,
    required this.questionsCount,
  });
}

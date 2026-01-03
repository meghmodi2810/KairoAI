import 'package:flutter/material.dart';
import 'dart:math' as math;

class DuolingoHomePage extends StatefulWidget {
  const DuolingoHomePage({super.key});

  @override
  State<DuolingoHomePage> createState() => _DuolingoHomePageState();
}

class _DuolingoHomePageState extends State<DuolingoHomePage>
    with TickerProviderStateMixin {
  // Theme Colors - Matching the Duolingo-style design
  static const Color primaryBg = Color(0xFF181E34);
  static const Color cardBg = Color(0xFF262F4D);
  static const Color accentYellow = Color(0xFFFFC800);
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

  // Lesson data with ISL-specific icons
  final List<LessonNodeData> _lessons = [
    LessonNodeData(
      id: 1,
      iconType: LessonIconType.waveHand,
      title: 'Greetings',
      status: LessonStatus.completed,
    ),
    LessonNodeData(
      id: 2,
      iconType: LessonIconType.alphabet,
      title: 'Alphabet A-Z',
      status: LessonStatus.completed,
    ),
    LessonNodeData(
      id: 3,
      iconType: LessonIconType.handSign,
      title: 'Basic Signs',
      status: LessonStatus.active,
    ),
    LessonNodeData(
      id: 4,
      iconType: LessonIconType.numbers,
      title: 'Numbers 1-10',
      status: LessonStatus.locked,
    ),
    LessonNodeData(
      id: 5,
      iconType: LessonIconType.conversation,
      title: 'Simple Phrases',
      status: LessonStatus.locked,
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
              _buildUnitHeader(),
              const SizedBox(height: 10),
              _buildLessonPath(),
              const SizedBox(height: 20),
              _buildNextUnitPreview(),
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
          // User Avatar with robot mascot
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cardBg,
              border: Border.all(color: accentYellow.withOpacity(0.5), width: 2),
            ),
            child: ClipOval(
              child: Image.network(
                'https://api.dicebear.com/7.x/bottts/png?seed=kairo&backgroundColor=262F4D',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.smart_toy,
                    color: accentYellow,
                    size: 28,
                  );
                },
              ),
            ),
          ),
          const Spacer(),
          // Streak Counter (Fire icon)
          _buildStreakPill(),
          const SizedBox(width: 10),
          // Gems Pill
          _buildStatPill(
            icon: Icons.diamond,
            value: gems.toString(),
            iconColor: accentBlue,
          ),
          const SizedBox(width: 10),
          // Coins Pill
          _buildStatPill(
            icon: Icons.monetization_on,
            value: _formatNumber(coins),
            iconColor: const Color(0xFFFFAA00),
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

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }

  Widget _buildUnitHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        height: 140,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [accentBlue, accentBlue.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: accentBlue.withOpacity(0.3),
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
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Unit 1:',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Basics',
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
                            widthFactor: 0.6,
                            child: Container(
                              decoration: BoxDecoration(
                                color: accentYellow,
                                borderRadius: BorderRadius.circular(5),
                                boxShadow: [
                                  BoxShadow(
                                    color: accentYellow.withOpacity(0.5),
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
            // Robot Mascot
            Positioned(
              right: 15,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  width: 100,
                  height: 110,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Image.network(
                    'https://i.imgur.com/placeholder.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildRobotMascot();
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRobotMascot() {
    return Container(
      width: 90,
      height: 100,
      decoration: BoxDecoration(
        color: cardBg.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Robot body
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Head with eyes
              Container(
                width: 50,
                height: 45,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B7355),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    // Eyes
                    Positioned(
                      top: 12,
                      left: 8,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: accentYellow,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: accentYellow.withOpacity(0.5),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 8,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: accentYellow,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: accentYellow.withOpacity(0.5),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Antenna
                    Positioned(
                      top: -8,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          width: 4,
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6B5545),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              // Body
              Container(
                width: 40,
                height: 30,
                decoration: BoxDecoration(
                  color: accentBlue.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
          // Waving hand
          Positioned(
            right: 5,
            top: 25,
            child: Transform.rotate(
              angle: 0.3,
              child: const Icon(
                Icons.pan_tool,
                color: Color(0xFF8B7355),
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonPath() {
    return Container(
      height: 580,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Stack(
        children: [
          // The curved path behind nodes
          Positioned.fill(
            child: CustomPaint(
              painter: LessonPathPainter(
                pathColor: pathColor,
                nodePositions: _getNodePositions(),
              ),
            ),
          ),
          // Lesson nodes
          ..._buildLessonNodes(),
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

  List<Widget> _buildLessonNodes() {
    final positions = _getNodePositions();
    final widgets = <Widget>[];
    final screenWidth = MediaQuery.of(context).size.width - 40; // Account for padding

    for (int i = 0; i < _lessons.length; i++) {
      final lesson = _lessons[i];
      final position = positions[i];

      widgets.add(
        Positioned(
          left: position.dx * screenWidth - 40,
          top: position.dy * 580 - 40,
          child: _buildLessonNode(lesson),
        ),
      );
    }

    return widgets;
  }

  Widget _buildLessonNode(LessonNodeData lesson) {
    final isActive = lesson.status == LessonStatus.active;
    final isCompleted = lesson.status == LessonStatus.completed;
    final isLocked = lesson.status == LessonStatus.locked;

    return GestureDetector(
      onTap: () => _onLessonTap(lesson),
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
                          color: accentYellow.withOpacity(0.4),
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
                color: isCompleted || isActive ? accentYellow : lockedBlue,
                border: Border.all(
                  color: isCompleted || isActive
                      ? accentYellow.withOpacity(0.8)
                      : lockedBlue.withOpacity(0.6),
                  width: 4,
                ),
                boxShadow: isActive || isCompleted
                    ? [
                        BoxShadow(
                          color: accentYellow.withOpacity(0.4),
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
                child: _buildLessonIcon(lesson),
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
          ],
        ),
      ),
    );
  }

  Widget _buildLessonIcon(LessonNodeData lesson) {
    final isLocked = lesson.status == LessonStatus.locked;
    final color = isLocked ? Colors.white.withOpacity(0.5) : Colors.white;

    switch (lesson.iconType) {
      case LessonIconType.waveHand:
        return Icon(Icons.waving_hand, color: color, size: 32);
      case LessonIconType.alphabet:
        return Text(
          'ABZ',
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        );
      case LessonIconType.handSign:
        return Icon(Icons.pan_tool, color: color, size: 32);
      case LessonIconType.numbers:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '1²3',
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '₆',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      case LessonIconType.conversation:
        return Icon(Icons.chat_bubble, color: color, size: 30);
    }
  }

  void _onLessonTap(LessonNodeData lesson) {
    if (lesson.status == LessonStatus.locked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.lock, color: Colors.white70, size: 20),
              const SizedBox(width: 12),
              const Text('Complete previous lessons first!'),
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

    // Navigate to lesson
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildLessonBottomSheet(lesson),
    );
  }

  Widget _buildLessonBottomSheet(LessonNodeData lesson) {
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
              color: accentYellow,
              boxShadow: [
                BoxShadow(
                  color: accentYellow.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Center(child: _buildLessonIcon(lesson)),
          ),
          const SizedBox(height: 20),
          Text(
            lesson.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Lesson ${lesson.id} • ${lesson.status == LessonStatus.completed ? "Completed" : "5 exercises"}',
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star, color: accentYellow, size: 18),
              const SizedBox(width: 4),
              const Text(
                '+10 XP',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.access_time, color: accentBlue, size: 18),
              const SizedBox(width: 4),
              const Text(
                '~5 min',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
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
                // Navigate to lesson detail
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: accentYellow,
                foregroundColor: primaryBg,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                lesson.status == LessonStatus.completed
                    ? 'PRACTICE AGAIN'
                    : 'START LESSON',
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

  Widget _buildNextUnitPreview() {
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
                    'Unit 2:',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Daily Life',
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
class LessonPathPainter extends CustomPainter {
  final Color pathColor;
  final List<Offset> nodePositions;

  LessonPathPainter({
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
enum LessonStatus { locked, active, completed }

enum LessonIconType {
  waveHand,
  alphabet,
  handSign,
  numbers,
  conversation,
}

class LessonNodeData {
  final int id;
  final LessonIconType iconType;
  final String title;
  final LessonStatus status;

  LessonNodeData({
    required this.id,
    required this.iconType,
    required this.title,
    required this.status,
  });
}

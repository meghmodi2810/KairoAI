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

class _LessonDetailPageState extends State<LessonDetailPage>
    with TickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  List<SignModel> _signs = [];
  int _currentSignIndex = 0;
  bool _isLoading = true;
  int _currentStep = 0; // 0: Overview, 1: Learn Signs, 2: Ready to Practice

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _bounceController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _bounceAnimation;

  // Theme colors
  static const Color primaryBlue = Color(0xFF1A2151);
  static const Color darkBlue = Color(0xFF141938);
  static const Color accentYellow = Color(0xFFFFD93D);
  static const Color cardBg = Color(0xFF252A5E);
  static const Color successGreen = Color(0xFF27AE60);
  static const Color accentPink = Color(0xFFFF6B9D);
  static const Color accentPurple = Color(0xFF9B59B6);

  // Hand sign emojis for visual variety
  final List<String> _handEmojis = ['🤟', '👋', '✋', '🖐️', '👍', '🤙', '✌️', '🤞'];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadSigns();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _bounceAnimation = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  Future<void> _loadSigns() async {
    try {
      debugPrint('Loading signs for category: ${widget.categoryId}, lesson: ${widget.lesson.id}');
      
      final signs = await _databaseService.getSigns(
        widget.categoryId,
        widget.lesson.id,
      );

      debugPrint('Loaded ${signs.length} signs from Firebase');

      if (mounted) {
        if (signs.isEmpty) {
          // Use fallback local data if Firebase is empty
          debugPrint('Using fallback local signs data');
          final fallbackSigns = _getFallbackSigns();
          setState(() {
            _signs = fallbackSigns;
            _isLoading = false;
          });
        } else {
          setState(() {
            _signs = signs;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading signs: $e');
      // On error, use fallback data
      if (mounted) {
        final fallbackSigns = _getFallbackSigns();
        setState(() {
          _signs = fallbackSigns;
          _isLoading = false;
        });
      }
    }
  }

  // Local fallback sign data when Firebase is unavailable
  List<SignModel> _getFallbackSigns() {
    final categoryId = widget.categoryId.toLowerCase();
    final lessonId = widget.lesson.id.toLowerCase();
    
    // Greetings signs
    if (categoryId == 'greetings' || lessonId.contains('greeting')) {
      return [
        SignModel(
          id: 'hello_fallback',
          lessonId: widget.lesson.id,
          word: 'Hello',
          wordInHindi: 'नमस्ते',
          description: 'A friendly wave to greet someone',
          instructions: [
            '1. Raise your right hand up with palm facing forward',
            '2. Keep fingers together and thumb relaxed',
            '3. Wave your hand side to side gently',
            '4. Smile while greeting! 😊',
          ],
          tips: 'Make eye contact when signing hello - it shows respect!',
          order: 1,
        ),
        SignModel(
          id: 'thank_you_fallback',
          lessonId: widget.lesson.id,
          word: 'Thank You',
          wordInHindi: 'धन्यवाद',
          description: 'Express gratitude and appreciation',
          instructions: [
            '1. Touch your chin with fingertips of flat hand',
            '2. Move hand forward and down like blowing a kiss',
            '3. Keep a grateful expression on your face',
            '4. Make it smooth and gentle',
          ],
          tips: 'This sign is like blowing gratitude from your mouth to the person!',
          order: 2,
        ),
        SignModel(
          id: 'please_fallback',
          lessonId: widget.lesson.id,
          word: 'Please',
          wordInHindi: 'कृपया',
          description: 'Making a polite request',
          instructions: [
            '1. Place your flat hand on your chest',
            '2. Move your hand in a circular motion',
            '3. Keep a polite, hopeful expression',
            '4. The circle shows sincerity',
          ],
          tips: 'Rubbing your heart shows you really mean your request!',
          order: 3,
        ),
        SignModel(
          id: 'goodbye_fallback',
          lessonId: widget.lesson.id,
          word: 'Goodbye',
          wordInHindi: 'अलविदा',
          description: 'Farewell wave when leaving',
          instructions: [
            '1. Raise your hand up near your shoulder',
            '2. Palm faces the person you\'re saying bye to',
            '3. Open and close your fingers repeatedly',
            '4. Like a friendly wave bye-bye!',
          ],
          tips: 'Keep waving until they wave back - it\'s polite!',
          order: 4,
        ),
      ];
    }
    
    // Numbers signs
    if (categoryId == 'numbers' || lessonId.contains('number')) {
      return [
        SignModel(
          id: 'one_fallback',
          lessonId: widget.lesson.id,
          word: 'One',
          wordInHindi: 'एक',
          description: 'The number 1',
          instructions: [
            '1. Make a fist with your hand',
            '2. Point your index finger straight up',
            '3. Keep other fingers curled in',
            '4. Hold steady and clear',
          ],
          tips: 'Keep your finger straight like a candle!',
          order: 1,
        ),
        SignModel(
          id: 'two_fallback',
          lessonId: widget.lesson.id,
          word: 'Two',
          wordInHindi: 'दो',
          description: 'The number 2',
          instructions: [
            '1. Make a fist with your hand',
            '2. Extend index and middle fingers up',
            '3. Keep them together like a peace sign',
            '4. Thumb holds other fingers down',
          ],
          tips: 'Like making a peace sign or bunny ears!',
          order: 2,
        ),
        SignModel(
          id: 'three_fallback',
          lessonId: widget.lesson.id,
          word: 'Three',
          wordInHindi: 'तीन',
          description: 'The number 3',
          instructions: [
            '1. Extend thumb, index, and middle finger',
            '2. Keep ring and pinky curled in',
            '3. Spread the three fingers slightly',
            '4. Palm can face either way',
          ],
          tips: 'Thumb counts as a finger in ISL numbers!',
          order: 3,
        ),
        SignModel(
          id: 'four_fallback',
          lessonId: widget.lesson.id,
          word: 'Four',
          wordInHindi: 'चार',
          description: 'The number 4',
          instructions: [
            '1. Extend all fingers except thumb',
            '2. Keep thumb tucked across palm',
            '3. Fingers should be together',
            '4. Palm faces forward',
          ],
          tips: 'Like showing four fingers to a shopkeeper!',
          order: 4,
        ),
        SignModel(
          id: 'five_fallback',
          lessonId: widget.lesson.id,
          word: 'Five',
          wordInHindi: 'पांच',
          description: 'The number 5',
          instructions: [
            '1. Open your hand completely',
            '2. Spread all five fingers wide',
            '3. Palm faces the person',
            '4. Like giving a high five!',
          ],
          tips: 'This is also used for "stop" so context matters!',
          order: 5,
        ),
      ];
    }
    
    // Alphabets signs
    if (categoryId == 'alphabets' || lessonId.contains('alphabet')) {
      return [
        SignModel(
          id: 'a_fallback',
          lessonId: widget.lesson.id,
          word: 'Letter A',
          wordInHindi: 'अक्षर A',
          description: 'The letter A in sign language',
          instructions: [
            '1. Make a fist with your hand',
            '2. Thumb rests on the side of fist',
            '3. Keep palm facing forward',
            '4. Fingers tightly closed',
          ],
          tips: 'Think of it as a closed fist with thumb as the marker!',
          order: 1,
        ),
        SignModel(
          id: 'b_fallback',
          lessonId: widget.lesson.id,
          word: 'Letter B',
          wordInHindi: 'अक्षर B',
          description: 'The letter B in sign language',
          instructions: [
            '1. Hold hand up with fingers together',
            '2. Extend all four fingers straight up',
            '3. Tuck thumb across palm',
            '4. Palm faces forward',
          ],
          tips: 'Like a flat wall with your fingers!',
          order: 2,
        ),
        SignModel(
          id: 'c_fallback',
          lessonId: widget.lesson.id,
          word: 'Letter C',
          wordInHindi: 'अक्षर C',
          description: 'The letter C in sign language',
          instructions: [
            '1. Curve your hand into a C shape',
            '2. Fingers and thumb form a half circle',
            '3. Like holding a cup',
            '4. Palm faces sideways',
          ],
          tips: 'Imagine holding a small ball or cup!',
          order: 3,
        ),
        SignModel(
          id: 'd_fallback',
          lessonId: widget.lesson.id,
          word: 'Letter D',
          wordInHindi: 'अक्षर D',
          description: 'The letter D in sign language',
          instructions: [
            '1. Touch thumb tip to middle, ring, pinky tips',
            '2. Point index finger straight up',
            '3. Forms a "d" shape',
            '4. Palm faces forward',
          ],
          tips: 'The circle below is the belly of the D!',
          order: 4,
        ),
      ];
    }
    
    // Family signs
    if (categoryId == 'family' || lessonId.contains('family')) {
      return [
        SignModel(
          id: 'mother_fallback',
          lessonId: widget.lesson.id,
          word: 'Mother',
          wordInHindi: 'माँ',
          description: 'Sign for mother/mom',
          instructions: [
            '1. Open hand with fingers spread',
            '2. Touch thumb to your chin',
            '3. Keep fingers pointing up',
            '4. Tap chin gently twice',
          ],
          tips: 'Chin is the feminine area in ISL family signs!',
          order: 1,
        ),
        SignModel(
          id: 'father_fallback',
          lessonId: widget.lesson.id,
          word: 'Father',
          wordInHindi: 'पिता',
          description: 'Sign for father/dad',
          instructions: [
            '1. Open hand with fingers spread',
            '2. Touch thumb to your forehead',
            '3. Keep fingers pointing up',
            '4. Tap forehead gently twice',
          ],
          tips: 'Forehead is the masculine area in ISL family signs!',
          order: 2,
        ),
        SignModel(
          id: 'brother_fallback',
          lessonId: widget.lesson.id,
          word: 'Brother',
          wordInHindi: 'भाई',
          description: 'Sign for brother',
          instructions: [
            '1. Make "L" shapes with both hands',
            '2. Stack right hand on top of left',
            '3. Both thumbs point up',
            '4. Move down together once',
          ],
          tips: 'The movement down shows family connection!',
          order: 3,
        ),
        SignModel(
          id: 'sister_fallback',
          lessonId: widget.lesson.id,
          word: 'Sister',
          wordInHindi: 'बहन',
          description: 'Sign for sister',
          instructions: [
            '1. Touch thumb to chin (like mother)',
            '2. Then make "L" shape with hand',
            '3. Move hand down to meet other hand',
            '4. Combines female + sibling',
          ],
          tips: 'Female marker at chin + sibling sign!',
          order: 4,
        ),
      ];
    }
    
    // Colors signs
    if (categoryId == 'colors' || lessonId.contains('color')) {
      return [
        SignModel(
          id: 'red_fallback',
          lessonId: widget.lesson.id,
          word: 'Red',
          wordInHindi: 'लाल',
          description: 'The color red',
          instructions: [
            '1. Point index finger at your lips',
            '2. Draw finger down from lips',
            '3. Like showing red lips',
            '4. Single downward stroke',
          ],
          tips: 'Red lips help you remember this sign!',
          order: 1,
        ),
        SignModel(
          id: 'blue_fallback',
          lessonId: widget.lesson.id,
          word: 'Blue',
          wordInHindi: 'नीला',
          description: 'The color blue',
          instructions: [
            '1. Make "B" handshape',
            '2. Shake hand slightly side to side',
            '3. Palm faces outward',
            '4. Small wiggling motion',
          ],
          tips: 'B for Blue - shake it like water!',
          order: 2,
        ),
        SignModel(
          id: 'green_fallback',
          lessonId: widget.lesson.id,
          word: 'Green',
          wordInHindi: 'हरा',
          description: 'The color green',
          instructions: [
            '1. Make "G" handshape',
            '2. Shake hand slightly',
            '3. Twist wrist back and forth',
            '4. Like leaves in wind',
          ],
          tips: 'G for Green - like grass swaying!',
          order: 3,
        ),
        SignModel(
          id: 'yellow_fallback',
          lessonId: widget.lesson.id,
          word: 'Yellow',
          wordInHindi: 'पीला',
          description: 'The color yellow',
          instructions: [
            '1. Make "Y" handshape',
            '2. Extend thumb and pinky',
            '3. Shake hand side to side',
            '4. Like sunshine rays',
          ],
          tips: 'Y for Yellow - bright like the sun!',
          order: 4,
        ),
      ];
    }
    
    // Default fallback for any lesson
    return [
      SignModel(
        id: 'default_1',
        lessonId: widget.lesson.id,
        word: 'Basic Sign 1',
        wordInHindi: 'मूल संकेत 1',
        description: 'A fundamental sign to learn',
        instructions: [
          '1. Watch the demonstration carefully',
          '2. Position your hand as shown',
          '3. Practice the movement slowly',
          '4. Repeat until comfortable',
        ],
        tips: 'Practice makes perfect! Take your time.',
        order: 1,
      ),
      SignModel(
        id: 'default_2',
        lessonId: widget.lesson.id,
        word: 'Basic Sign 2',
        wordInHindi: 'मूल संकेत 2',
        description: 'Another important sign',
        instructions: [
          '1. Start with relaxed hands',
          '2. Form the handshape shown',
          '3. Add the movement smoothly',
          '4. Practice in front of a mirror',
        ],
        tips: 'Mirrors are your best practice partner!',
        order: 2,
      ),
      SignModel(
        id: 'default_3',
        lessonId: widget.lesson.id,
        word: 'Basic Sign 3',
        wordInHindi: 'मूल संकेत 3',
        description: 'Keep learning more signs',
        instructions: [
          '1. Focus on hand position',
          '2. Note the palm orientation',
          '3. Observe any movement',
          '4. Practice with expression',
        ],
        tips: 'Facial expressions are part of sign language too!',
        order: 3,
      ),
    ];
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  void _nextSign() {
    if (_currentSignIndex < _signs.length - 1) {
      setState(() {
        _currentSignIndex++;
      });
    } else {
      _nextStep();
    }
  }

  void _previousSign() {
    if (_currentSignIndex > 0) {
      setState(() {
        _currentSignIndex--;
      });
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
          ? _buildLoadingState()
          : _signs.isEmpty
              ? _buildEmptyState()
              : _buildContent(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: const Text('🤟', style: TextStyle(fontSize: 64)),
              );
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Loading lesson...',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 16),
          const SizedBox(
            width: 120,
            child: LinearProgressIndicator(
              backgroundColor: cardBg,
              valueColor: AlwaysStoppedAnimation<Color>(accentYellow),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SafeArea(
      child: Column(
        children: [
          _buildTopBar(),
          _buildStepIndicator(),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildCurrentStepContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Close button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.close, color: Colors.white70, size: 24),
            ),
          ),
          const SizedBox(width: 12),
          // Lesson title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unit ${widget.lesson.unitNumber}',
                  style: TextStyle(
                    color: accentYellow.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  widget.lesson.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Reward preview
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accentYellow.withOpacity(0.2),
                  accentPink.withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accentYellow.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('💎', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  '+${widget.lesson.gemsReward}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    final steps = ['Learn', 'Practice', 'Master!'];
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: List.generate(steps.length, (index) {
          final isActive = index <= _currentStep;
          final isCurrent = index == _currentStep;
          
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      // Step circle
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: isCurrent ? 40 : 32,
                        height: isCurrent ? 40 : 32,
                        decoration: BoxDecoration(
                          color: isActive ? accentYellow : cardBg,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isActive 
                                ? accentYellow 
                                : Colors.white.withOpacity(0.2),
                            width: 2,
                          ),
                          boxShadow: isCurrent
                              ? [
                                  BoxShadow(
                                    color: accentYellow.withOpacity(0.4),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  )
                                ]
                              : null,
                        ),
                        child: Center(
                          child: isActive && index < _currentStep
                              ? const Icon(
                                  Icons.check,
                                  color: darkBlue,
                                  size: 18,
                                )
                              : Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: isActive ? darkBlue : Colors.white54,
                                    fontWeight: FontWeight.bold,
                                    fontSize: isCurrent ? 16 : 14,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        steps[index],
                        style: TextStyle(
                          color: isActive ? Colors.white : Colors.white38,
                          fontSize: 11,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                // Connector line
                if (index < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: index < _currentStep
                            ? accentYellow
                            : Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildOverviewStep();
      case 1:
        return _buildLearnSignsStep();
      case 2:
        return _buildReadyToPracticeStep();
      default:
        return _buildOverviewStep();
    }
  }

  // ==================== STEP 1: OVERVIEW ====================
  Widget _buildOverviewStep() {
    return SingleChildScrollView(
      key: const ValueKey('overview'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Welcome illustration
          _buildWelcomeIllustration(),
          const SizedBox(height: 24),
          
          // Lesson description
          _buildLessonDescription(),
          const SizedBox(height: 24),
          
          // What you'll learn
          _buildWhatYouWillLearn(),
          const SizedBox(height: 24),
          
          // Signs preview grid
          _buildSignsPreview(),
          const SizedBox(height: 24),
          
          // Continue button
          _buildContinueButton(
            'Let\'s Start Learning! 🎉',
            _nextStep,
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeIllustration() {
    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _bounceAnimation.value),
          child: Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accentPurple.withOpacity(0.3),
                  accentPink.withOpacity(0.3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Stack(
              children: [
                // Floating decorations
                Positioned(
                  top: 20,
                  left: 20,
                  child: _buildFloatingIcon('⭐', 30),
                ),
                Positioned(
                  top: 40,
                  right: 30,
                  child: _buildFloatingIcon('✨', 24),
                ),
                Positioned(
                  bottom: 30,
                  left: 40,
                  child: _buildFloatingIcon('🌟', 20),
                ),
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: _buildFloatingIcon('💫', 26),
                ),
                // Main mascot
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: const Text(
                              '👋',
                              style: TextStyle(fontSize: 64),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Ready to learn ${widget.lesson.title}?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingIcon(String emoji, double size) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: 0.5 + (_pulseAnimation.value - 1) * 2,
          child: Text(
            emoji,
            style: TextStyle(fontSize: size),
          ),
        );
      },
    );
  }

  Widget _buildLessonDescription() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentYellow.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: accentYellow,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'About This Lesson',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.lesson.description,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('🤟', '${_signs.length}', 'Signs'),
              _buildStatItem('⏱️', '${widget.lesson.estimatedMinutes}', 'Minutes'),
              _buildStatItem('📊', widget.lesson.difficulty, 'Level'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildWhatYouWillLearn() {
    final focusPoints = widget.lesson.focusPoints;
    if (focusPoints.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            successGreen.withOpacity(0.2),
            successGreen.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: successGreen.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🎯', style: TextStyle(fontSize: 24)),
              SizedBox(width: 10),
              Text(
                'What You\'ll Learn',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...focusPoints.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: successGreen.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.check,
                        color: successGreen,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSignsPreview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('✋', style: TextStyle(fontSize: 24)),
              SizedBox(width: 10),
              Text(
                'Signs in This Lesson',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _signs.asMap().entries.map((entry) {
              final sign = entry.value;
              final emoji = _handEmojis[entry.key % _handEmojis.length];
              
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: primaryBlue,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(
                      sign.word,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ==================== STEP 2: LEARN SIGNS ====================
  Widget _buildLearnSignsStep() {
    if (_signs.isEmpty) return const SizedBox.shrink();
    
    final currentSign = _signs[_currentSignIndex];
    final emoji = _handEmojis[_currentSignIndex % _handEmojis.length];

    return SingleChildScrollView(
      key: ValueKey('learn_$_currentSignIndex'),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Progress indicator
          _buildSignProgress(),
          const SizedBox(height: 20),
          
          // Sign display card
          _buildSignDisplayCard(currentSign, emoji),
          const SizedBox(height: 20),
          
          // Instructions
          _buildSignInstructions(currentSign),
          const SizedBox(height: 20),
          
          // Tips
          if (currentSign.tips != null)
            _buildTipsCard(currentSign.tips!),
          const SizedBox(height: 24),
          
          // Navigation buttons
          _buildSignNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildSignProgress() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sign ${_currentSignIndex + 1} of ${_signs.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: accentYellow.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${((_currentSignIndex + 1) / _signs.length * 100).toInt()}%',
                  style: const TextStyle(
                    color: accentYellow,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (_currentSignIndex + 1) / _signs.length,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(accentYellow),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignDisplayCard(SignModel sign, String emoji) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
        border: Border.all(color: accentYellow.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: accentYellow.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          // Animated hand gesture
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: accentYellow.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accentYellow.withOpacity(0.3),
                      width: 3,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 72),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          
          // Sign word
          Text(
            sign.word,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          
          // Hindi translation
          if (sign.wordInHindi != null) ...[
            const SizedBox(height: 8),
            Text(
              sign.wordInHindi!,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 20,
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Description
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: primaryBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              sign.description,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 15,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Difficulty badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: _getDifficultyColor(sign.difficulty).withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _getDifficultyColor(sign.difficulty).withOpacity(0.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getDifficultyIcon(sign.difficulty),
                  color: _getDifficultyColor(sign.difficulty),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  sign.difficulty.toUpperCase(),
                  style: TextStyle(
                    color: _getDifficultyColor(sign.difficulty),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return successGreen;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return accentYellow;
    }
  }

  IconData _getDifficultyIcon(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Icons.sentiment_satisfied;
      case 'medium':
        return Icons.sentiment_neutral;
      case 'hard':
        return Icons.sentiment_very_satisfied;
      default:
        return Icons.star;
    }
  }

  Widget _buildSignInstructions(SignModel sign) {
    if (sign.instructions.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentPurple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.school,
                  color: accentPurple,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'How to Sign',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...sign.instructions.asMap().entries.map((entry) {
            final step = entry.key + 1;
            final instruction = entry.value;
            
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 300 + (entry.key * 100)),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(20 * (1 - value), 0),
                    child: child,
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [accentYellow, accentPink],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          '$step',
                          style: const TextStyle(
                            color: darkBlue,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: primaryBlue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          instruction,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTipsCard(String tips) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentYellow.withOpacity(0.2),
            accentYellow.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentYellow.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedBuilder(
            animation: _bounceAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _bounceAnimation.value / 2),
                child: const Text('💡', style: TextStyle(fontSize: 28)),
              );
            },
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pro Tip!',
                  style: TextStyle(
                    color: accentYellow,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  tips,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignNavigationButtons() {
    final isFirstSign = _currentSignIndex == 0;
    final isLastSign = _currentSignIndex == _signs.length - 1;

    return Row(
      children: [
        // Previous button
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isFirstSign ? _previousStep : _previousSign,
            icon: const Icon(Icons.arrow_back),
            label: Text(isFirstSign ? 'Back' : 'Previous'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              side: BorderSide(color: Colors.white.withOpacity(0.3)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Next button
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: _nextSign,
            icon: Icon(isLastSign ? Icons.check : Icons.arrow_forward),
            label: Text(
              isLastSign ? 'I Got It!' : 'Next Sign',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentYellow,
              foregroundColor: darkBlue,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==================== STEP 3: READY TO PRACTICE ====================
  Widget _buildReadyToPracticeStep() {
    return SingleChildScrollView(
      key: const ValueKey('ready'),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Celebration animation
          _buildCelebrationCard(),
          const SizedBox(height: 24),
          
          // Recap of what you learned
          _buildLearningRecap(),
          const SizedBox(height: 24),
          
          // Rewards preview
          _buildRewardsPreview(),
          const SizedBox(height: 24),
          
          // Practice button
          _buildPracticeButton(),
          const SizedBox(height: 12),
          
          // Back to review button
          TextButton.icon(
            onPressed: () {
              setState(() {
                _currentStep = 1;
                _currentSignIndex = 0;
              });
            },
            icon: const Icon(Icons.replay, color: Colors.white60),
            label: const Text(
              'Review Signs Again',
              style: TextStyle(color: Colors.white60),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCelebrationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            successGreen.withOpacity(0.3),
            accentYellow.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          // Animated celebration emoji
          AnimatedBuilder(
            animation: _bounceAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _bounceAnimation.value),
                child: Transform.scale(
                  scale: _pulseAnimation.value,
                  child: const Text('🎉', style: TextStyle(fontSize: 80)),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          const Text(
            'Amazing Progress!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'You\'ve learned ${_signs.length} new signs!\nNow let\'s practice with your camera.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLearningRecap() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('📚', style: TextStyle(fontSize: 24)),
              SizedBox(width: 10),
              Text(
                'Signs You Learned',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...(_signs.asMap().entries.map((entry) {
            final sign = entry.value;
            final emoji = _handEmojis[entry.key % _handEmojis.length];
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: successGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sign.word,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (sign.wordInHindi != null)
                          Text(
                            sign.wordInHindi!,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.check_circle,
                    color: successGreen,
                    size: 24,
                  ),
                ],
              ),
            );
          })),
        ],
      ),
    );
  }

  Widget _buildRewardsPreview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentPurple.withOpacity(0.2),
            accentPink.withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentPurple.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Text(
            '🏆 Complete & Earn',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildRewardItem('💎', widget.lesson.gemsReward, 'Gems'),
              _buildRewardItem('🪙', widget.lesson.coinsReward, 'Coins'),
              _buildRewardItem('⭐', widget.lesson.xpReward, 'XP'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRewardItem(String emoji, int value, String label) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: 0.9 + (_pulseAnimation.value - 1) * 0.3,
              child: Text(emoji, style: const TextStyle(fontSize: 36)),
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          '+$value',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildPracticeButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _startPractice,
        style: ElevatedButton.styleFrom(
          backgroundColor: accentYellow,
          foregroundColor: darkBlue,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          shadowColor: accentYellow.withOpacity(0.4),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt, size: 26),
            SizedBox(width: 12),
            Text(
              "Let's Practice!",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 8),
            Text('🤟', style: TextStyle(fontSize: 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: accentYellow,
          foregroundColor: darkBlue,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated empty state
              AnimatedBuilder(
                animation: _bounceAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _bounceAnimation.value),
                    child: const Text('📭', style: TextStyle(fontSize: 80)),
                  );
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'No Signs Yet!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'This lesson is still being prepared.\nCheck back soon for new content!',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 16,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Go Back'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: BorderSide(color: Colors.white.withOpacity(0.3)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


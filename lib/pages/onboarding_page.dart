import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'signup_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  // User selections
  String? _selectedGoal;
  String? _selectedDailyGoal;

  // Colors matching the app theme
  static const Color primaryBlue = Color(0xFF1A2151);
  static const Color darkBlue = Color(0xFF141938);
  static const Color accentYellow = Color(0xFFFFD93D);
  static const Color lightYellow = Color(0xFFFFF3B0);

  final List<String> _goals = [
    'Communicate with family',
    'Boost my career',
    'Help others',
    'Just for fun',
  ];

  final List<Map<String, String>> _dailyGoals = [
    {'title': 'Casual', 'subtitle': '5 min/day'},
    {'title': 'Regular', 'subtitle': '10 min/day'},
    {'title': 'Serious', 'subtitle': '15 min/day'},
    {'title': 'Intense', 'subtitle': '20 min/day'},
  ];

  final List<IconData> _goalIcons = [
    Icons.family_restroom,
    Icons.work_outline,
    Icons.volunteer_activism,
    Icons.emoji_emotions_outlined,
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    
    // Save user preferences
    if (_selectedGoal != null) {
      await prefs.setString('user_goal', _selectedGoal!);
    }
    if (_selectedDailyGoal != null) {
      await prefs.setString('daily_goal', _selectedDailyGoal!);
    }
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
      );
    }
  }

  void _navigateToSignUp() async {
    await _completeOnboarding();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const SignUpPage(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    }
  }

  void _navigateToLogin() async {
    await _completeOnboarding();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const LoginPage(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [primaryBlue, darkBlue],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Progress indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: List.generate(4, (index) {
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: index <= _currentPage
                              ? accentYellow
                              : Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              
              // Page content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildWelcomePage(),
                    _buildGoalPage(),
                    _buildDailyGoalPage(),
                    _buildReadyPage(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo/Mascot area
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  primaryBlue.withOpacity(0.8),
                  darkBlue.withOpacity(0.4),
                ],
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: Image.asset(
                'assets/logo/logo.jpeg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.sign_language,
                    size: 100,
                    color: accentYellow,
                  );
                },
              ),
            ),
          ),
          
          const SizedBox(height: 48),
          
          // Title
          const Text(
            'Learn to Sign!',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Subtitle
          Text(
            'Master sign language through fun,\ninteractive lessons with AI.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
              height: 1.5,
            ),
          ),
          
          const SizedBox(height: 60),
          
          // Continue button
          _buildPrimaryButton('Continue', _nextPage),
        ],
      ),
    );
  }

  Widget _buildGoalPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Hand icon
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: accentYellow.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.waving_hand,
              size: 60,
              color: accentYellow,
            ),
          ),
          
          const SizedBox(height: 32),
          
          const Text(
            'What brings you\nhere?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Goal options
          ...List.generate(_goals.length, (index) {
            final isSelected = _selectedGoal == _goals[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildOptionCard(
                icon: _goalIcons[index],
                title: _goals[index],
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    _selectedGoal = _goals[index];
                  });
                },
              ),
            );
          }),
          
          const SizedBox(height: 24),
          
          // Continue button
          _buildPrimaryButton(
            'Continue',
            _selectedGoal != null ? _nextPage : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDailyGoalPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Progress icon
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  value: 0.7,
                  strokeWidth: 8,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(accentYellow),
                ),
              ),
              const Icon(
                Icons.timer_outlined,
                size: 40,
                color: accentYellow,
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          const Text(
            'Set Your Daily Goal',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'We\'ll remind you to practice',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Daily goal options
          ...List.generate(_dailyGoals.length, (index) {
            final goal = _dailyGoals[index];
            final isSelected = _selectedDailyGoal == goal['title'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildDailyGoalCard(
                title: goal['title']!,
                subtitle: goal['subtitle']!,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    _selectedDailyGoal = goal['title'];
                  });
                },
              ),
            );
          }),
          
          const SizedBox(height: 24),
          
          // Continue button
          _buildPrimaryButton(
            'Continue',
            _selectedDailyGoal != null ? _nextPage : null,
          ),
        ],
      ),
    );
  }

  Widget _buildReadyPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Celebration icon
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: accentYellow.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.celebration,
              size: 80,
              color: accentYellow,
            ),
          ),
          
          const SizedBox(height: 40),
          
          const Text(
            'Ready to start?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'Join our community of learners\nand start your sign language journey!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
              height: 1.5,
            ),
          ),
          
          const SizedBox(height: 48),
          
          // Create Profile button
          _buildPrimaryButton('Create Profile', _navigateToSignUp),
          
          const SizedBox(height: 20),
          
          // Already have account
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Already have an account? ',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              GestureDetector(
                onTap: _navigateToLogin,
                child: const Text(
                  'Log in',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: accentYellow,
                    decoration: TextDecoration.underline,
                    decorationColor: accentYellow,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton(String text, VoidCallback? onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: onPressed != null ? accentYellow : accentYellow.withOpacity(0.5),
          foregroundColor: darkBlue,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
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

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? accentYellow : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? accentYellow.withOpacity(0.2) : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected ? accentYellow : Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? darkBlue : Colors.white,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: accentYellow,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyGoalCard({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? accentYellow : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? darkBlue : Colors.white,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? accentYellow : accentYellow.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? darkBlue : Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

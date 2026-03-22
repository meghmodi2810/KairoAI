import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'signup_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String? _selectedGoal;
  String? _selectedDailyGoal;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnim;

  // Design tokens
  static const _bg       = Color(0xFF0D0D12);
  static const _card     = Color(0xFF14141C);
  static const _border   = Color(0xFF252530);
  static const _accent   = Color(0xFF6C63FF);
  static const _textP    = Color(0xFFF0F0FF);
  static const _textS    = Color(0xFF8888A8);

  final List<String> _goals = [
    'Communicate with family',
    'Boost my career',
    'Help others',
    'Just for fun',
  ];

  final List<IconData> _goalIcons = [
    Icons.family_restroom_rounded,
    Icons.work_outline_rounded,
    Icons.volunteer_activism_rounded,
    Icons.emoji_emotions_outlined,
  ];

  final List<Map<String, dynamic>> _dailyGoals = [
    {'title': 'Casual',  'sub': '5 min/day',  'mins': 5},
    {'title': 'Regular', 'sub': '10 min/day', 'mins': 10},
    {'title': 'Serious', 'sub': '15 min/day', 'mins': 15},
    {'title': 'Intense', 'sub': '20 min/day', 'mins': 20},
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (_selectedGoal != null) await prefs.setString('user_goal', _selectedGoal!);
    if (_selectedDailyGoal != null) await prefs.setString('daily_goal', _selectedDailyGoal!);
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _goTo(String page) async {
    await _completeOnboarding();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            page == 'signup' ? const SignUpPage() : const LoginPage(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: Column(
            children: [
              // ── Top bar (skip + dots) ──────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Page dots
                    Row(
                      children: List.generate(4, (i) {
                        final active = i == _currentPage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(right: 6),
                          width: active ? 20 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: active ? _accent : _border,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    ),
                    // Skip
                    if (_currentPage < 3)
                      TextButton(
                        onPressed: () => _goTo('login'),
                        child: const Text('Skip',
                          style: TextStyle(color: _textS, fontSize: 14, fontWeight: FontWeight.w500)),
                      ),
                  ],
                ),
              ),

              // ── Pages ─────────────────────────────────────────
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _WelcomePage(onNext: _nextPage),
                    _GoalPage(
                      goals: _goals,
                      icons: _goalIcons,
                      selected: _selectedGoal,
                      onSelect: (g) => setState(() => _selectedGoal = g),
                      onNext: _selectedGoal != null ? _nextPage : null,
                    ),
                    _DailyGoalPage(
                      goals: _dailyGoals,
                      selected: _selectedDailyGoal,
                      onSelect: (g) => setState(() => _selectedDailyGoal = g),
                      onNext: _selectedDailyGoal != null ? _nextPage : null,
                    ),
                    _ReadyPage(
                      onSignUp: () => _goTo('signup'),
                      onLogin:  () => _goTo('login'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────
//  Shared button
// ────────────────────────────────────────────────
class _ContinueButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const _ContinueButton({required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: enabled
                ? [const Color(0xFF6C63FF), const Color(0xFF9B94FF)]
                : [const Color(0xFF6C63FF).withOpacity(0.3), const Color(0xFF9B94FF).withOpacity(0.3)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: enabled
              ? [BoxShadow(color: const Color(0xFF6C63FF).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 6))]
              : null,
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────
//  Page 1 — Welcome
// ────────────────────────────────────────────────
class _WelcomePage extends StatelessWidget {
  final VoidCallback onNext;
  const _WelcomePage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
      child: Column(
        children: [
          const Spacer(),
          // Hero icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF9B94FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(36),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C63FF).withOpacity(0.4),
                  blurRadius: 32,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.sign_language_rounded, color: Colors.white, size: 56),
          ),
          const SizedBox(height: 40),
          // Headline
          RichText(
            textAlign: TextAlign.center,
            text: const TextSpan(
              style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, height: 1.2, letterSpacing: -0.5),
              children: [
                TextSpan(text: 'Learn ISL\n', style: TextStyle(color: Color(0xFFF0F0FF))),
                TextSpan(text: 'Speak without\nwords', style: TextStyle(color: Color(0xFF6C63FF))),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Master Indian Sign Language through AI-powered interactive lessons.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF8888A8), fontSize: 16, height: 1.6),
          ),
          const Spacer(),
          // Feature pills
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: const [
              _FeaturePill(icon: Icons.auto_awesome_rounded, label: 'AI Recognition'),
              _FeaturePill(icon: Icons.school_rounded, label: 'Structured Lessons'),
              _FeaturePill(icon: Icons.local_fire_department_rounded, label: 'Daily Streaks'),
            ],
          ),
          const SizedBox(height: 40),
          _ContinueButton(label: 'Get Started', onPressed: onNext),
        ],
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeaturePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF14141C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF252530), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF6C63FF)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Color(0xFF8888A8), fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────
//  Page 2 — Goal Selection
// ────────────────────────────────────────────────
class _GoalPage extends StatelessWidget {
  final List<String> goals;
  final List<IconData> icons;
  final String? selected;
  final ValueChanged<String> onSelect;
  final VoidCallback? onNext;

  const _GoalPage({
    required this.goals,
    required this.icons,
    required this.selected,
    required this.onSelect,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('What brings\nyou here?',
            style: TextStyle(color: Color(0xFFF0F0FF), fontSize: 30, fontWeight: FontWeight.w800, height: 1.2, letterSpacing: -0.5)),
          const SizedBox(height: 8),
          const Text('This helps us personalise your experience.',
            style: TextStyle(color: Color(0xFF8888A8), fontSize: 15, height: 1.5)),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.separated(
              itemCount: goals.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final isSelected = selected == goals[i];
                return _OptionTile(
                  icon: icons[i],
                  label: goals[i],
                  isSelected: isSelected,
                  onTap: () => onSelect(goals[i]),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          _ContinueButton(label: 'Continue', onPressed: onNext),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────
//  Page 3 — Daily Goal
// ────────────────────────────────────────────────
class _DailyGoalPage extends StatelessWidget {
  final List<Map<String, dynamic>> goals;
  final String? selected;
  final ValueChanged<String> onSelect;
  final VoidCallback? onNext;

  const _DailyGoalPage({
    required this.goals,
    required this.selected,
    required this.onSelect,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Set your\ndaily goal',
            style: TextStyle(color: Color(0xFFF0F0FF), fontSize: 30, fontWeight: FontWeight.w800, height: 1.2, letterSpacing: -0.5)),
          const SizedBox(height: 8),
          const Text("We'll gently remind you to keep the streak alive.",
            style: TextStyle(color: Color(0xFF8888A8), fontSize: 15, height: 1.5)),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.separated(
              itemCount: goals.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final g = goals[i];
                final isSelected = selected == g['title'];
                return _DailyGoalTile(
                  title: g['title'] as String,
                  sub: g['sub'] as String,
                  isSelected: isSelected,
                  onTap: () => onSelect(g['title'] as String),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          _ContinueButton(label: 'Continue', onPressed: onNext),
        ],
      ),
    );
  }
}

class _DailyGoalTile extends StatelessWidget {
  final String title;
  final String sub;
  final bool isSelected;
  final VoidCallback onTap;

  const _DailyGoalTile({
    required this.title,
    required this.sub,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6C63FF).withOpacity(0.12) : const Color(0xFF14141C),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF6C63FF) : const Color(0xFF252530),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title,
              style: TextStyle(
                color: isSelected ? const Color(0xFFF0F0FF) : const Color(0xFF8888A8),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              )),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF6C63FF) : const Color(0xFF252530),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(sub,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF8888A8),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                )),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────
//  Page 4 — Ready
// ────────────────────────────────────────────────
class _ReadyPage extends StatelessWidget {
  final VoidCallback onSignUp;
  final VoidCallback onLogin;

  const _ReadyPage({required this.onSignUp, required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
      child: Column(
        children: [
          const Spacer(),
          // Celebration
          Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              color: const Color(0xFF4ADE80).withOpacity(0.12),
              borderRadius: BorderRadius.circular(36),
              border: Border.all(color: const Color(0xFF4ADE80).withOpacity(0.3)),
            ),
            child: const Icon(Icons.celebration_rounded, color: Color(0xFF4ADE80), size: 52),
          ),
          const SizedBox(height: 36),
          const Text("You're all set!", textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFFF0F0FF), fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          const SizedBox(height: 16),
          const Text('Create your profile to start learning ISL with AI.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF8888A8), fontSize: 16, height: 1.6)),
          const Spacer(),
          _ContinueButton(label: 'Create Profile', onPressed: onSignUp),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: onLogin,
            child: RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 14),
                children: [
                  TextSpan(text: 'Already have an account? ', style: TextStyle(color: Color(0xFF8888A8))),
                  TextSpan(text: 'Sign in', style: TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────
//  Reusable option tile
// ────────────────────────────────────────────────
class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6C63FF).withOpacity(0.12) : const Color(0xFF14141C),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF6C63FF) : const Color(0xFF252530),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF6C63FF).withOpacity(0.2) : const Color(0xFF252530),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                size: 20,
                color: isSelected ? const Color(0xFF6C63FF) : const Color(0xFF8888A8)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                style: TextStyle(
                  color: isSelected ? const Color(0xFFF0F0FF) : const Color(0xFF8888A8),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                )),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: Color(0xFF6C63FF), size: 20),
          ],
        ),
      ),
    );
  }
}

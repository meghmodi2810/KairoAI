import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../theme/neo_brutal_widgets.dart';
import 'login_page.dart';
import 'signup_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();

  int _page = 0;
  String? _selectedGoal;
  String? _selectedDailyGoal;

  final List<String> _goals = const [
    'Talk with family',
    'Learn for school',
    'Build confidence',
    'Learn for fun',
  ];

  final List<String> _dailyGoals = const [
    '5 min',
    '10 min',
    '15 min',
    '20 min',
  ];

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (_selectedGoal != null) {
      await prefs.setString('user_goal', _selectedGoal!);
    }
    if (_selectedDailyGoal != null) {
      await prefs.setString('daily_goal', _selectedDailyGoal!);
    }
  }

  void _nextPage() {
    if (_page >= 3) return;
    _controller.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _goToAuth({required bool signup}) async {
    await _completeOnboarding();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => signup ? const SignUpPage() : const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.paperCream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: [
                  ...List.generate(4, (i) {
                    final active = _page == i;
                    return Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        margin: EdgeInsets.only(right: i == 3 ? 0 : 8),
                        height: 10,
                        decoration: BoxDecoration(
                          color: active ? AppTheme.cobaltBlue : AppTheme.warmWhite,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.inkBlack, width: 2),
                          boxShadow: active
                              ? const [
                                  BoxShadow(
                                    color: AppTheme.inkBlack,
                                    blurRadius: 0,
                                    offset: Offset(2, 2),
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    );
                  }),
                  const SizedBox(width: 10),
                  if (_page < 3)
                    TextButton(
                      onPressed: () => _goToAuth(signup: false),
                      child: const Text('Skip'),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (value) => setState(() => _page = value),
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _WelcomeSlide(onNext: _nextPage),
                  _GoalSlide(
                    goals: _goals,
                    selectedGoal: _selectedGoal,
                    onSelect: (value) => setState(() => _selectedGoal = value),
                    onNext: _selectedGoal == null ? null : _nextPage,
                  ),
                  _DailySlide(
                    goals: _dailyGoals,
                    selectedGoal: _selectedDailyGoal,
                    onSelect: (value) => setState(() => _selectedDailyGoal = value),
                    onNext: _selectedDailyGoal == null ? null : _nextPage,
                  ),
                  _ReadySlide(
                    onSignup: () => _goToAuth(signup: true),
                    onLogin: () => _goToAuth(signup: false),
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

class _WelcomeSlide extends StatelessWidget {
  final VoidCallback onNext;

  const _WelcomeSlide({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const NeoSticker(
            label: 'WELCOME TO SIGN STUDIO',
            color: AppTheme.signalYellow,
            icon: Icons.rocket_launch,
          ),
          const SizedBox(height: 18),
          const Text(
            'LEARN\nINDIAN SIGN\nLANGUAGE',
            style: TextStyle(
              color: AppTheme.inkBlack,
              fontSize: 44,
              height: 0.95,
              letterSpacing: -0.8,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Practice real signs with camera AI. Win streaks, gems, and confidence every day.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.inkBlack.withValues(alpha: 0.8),
                ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: NeoPanel(
              color: AppTheme.electricBlue,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      _IconTile(icon: Icons.front_hand, label: 'Signs'),
                      SizedBox(width: 10),
                      _IconTile(icon: Icons.camera_alt, label: 'Camera'),
                      SizedBox(width: 10),
                      _IconTile(icon: Icons.emoji_events, label: 'Rewards'),
                    ],
                  ),
                  const Spacer(),
                  const Text(
                    'HANDS READY?',
                    style: TextStyle(
                      color: AppTheme.inkBlack,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Let us set your learning rhythm in 20 seconds.',
                    style: TextStyle(
                      color: AppTheme.inkBlack,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          NeoPrimaryButton(label: 'Start', onPressed: onNext),
        ],
      ),
    );
  }
}

class _GoalSlide extends StatelessWidget {
  final List<String> goals;
  final String? selectedGoal;
  final ValueChanged<String> onSelect;
  final VoidCallback? onNext;

  const _GoalSlide({
    required this.goals,
    required this.selectedGoal,
    required this.onSelect,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'WHY ARE YOU LEARNING?',
            style: TextStyle(
              color: AppTheme.inkBlack,
              fontSize: 34,
              height: 1,
              letterSpacing: -0.7,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pick one. We will tune your path around it.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: goals.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final goal = goals[index];
                final selected = goal == selectedGoal;
                return GestureDetector(
                  onTap: () => onSelect(goal),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.mintGreen : AppTheme.warmWhite,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.inkBlack, width: 3),
                      boxShadow: selected
                          ? const [
                              BoxShadow(
                                color: AppTheme.inkBlack,
                                blurRadius: 0,
                                offset: Offset(4, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: selected ? AppTheme.signalYellow : AppTheme.electricBlue,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.inkBlack, width: 2),
                          ),
                          child: Icon(
                            selected ? Icons.check_rounded : Icons.flag_rounded,
                            color: AppTheme.inkBlack,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            goal,
                            style: const TextStyle(
                              color: AppTheme.inkBlack,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          NeoPrimaryButton(label: 'Continue', onPressed: onNext),
        ],
      ),
    );
  }
}

class _DailySlide extends StatelessWidget {
  final List<String> goals;
  final String? selectedGoal;
  final ValueChanged<String> onSelect;
  final VoidCallback? onNext;

  const _DailySlide({
    required this.goals,
    required this.selectedGoal,
    required this.onSelect,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DAILY RHYTHM',
            style: TextStyle(
              color: AppTheme.inkBlack,
              fontSize: 34,
              letterSpacing: -0.7,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Small steps keep streaks alive.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              itemCount: goals.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.25,
              ),
              itemBuilder: (context, index) {
                final label = goals[index];
                final selected = label == selectedGoal;
                return GestureDetector(
                  onTap: () => onSelect(label),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.signalYellow : AppTheme.warmWhite,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.inkBlack, width: 3),
                      boxShadow: selected
                          ? const [
                              BoxShadow(color: AppTheme.inkBlack, blurRadius: 0, offset: Offset(4, 4)),
                            ]
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.electricBlue,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.inkBlack, width: 2),
                          ),
                          child: const Icon(Icons.timer_rounded, color: AppTheme.inkBlack),
                        ),
                        const Spacer(),
                        Text(
                          label,
                          style: const TextStyle(
                            color: AppTheme.inkBlack,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Text(
                          'per day',
                          style: TextStyle(
                            color: AppTheme.inkBlack,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          NeoPrimaryButton(label: 'Lock Goal', onPressed: onNext),
        ],
      ),
    );
  }
}

class _ReadySlide extends StatelessWidget {
  final VoidCallback onSignup;
  final VoidCallback onLogin;

  const _ReadySlide({required this.onSignup, required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'YOU ARE READY',
            style: TextStyle(
              color: AppTheme.inkBlack,
              fontSize: 36,
              letterSpacing: -0.8,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start your first sign lesson and keep the streak alive.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 18),
          Expanded(
            child: NeoPanel(
              color: AppTheme.softPeach,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const NeoSticker(
                    label: 'BOOSTERS READY',
                    color: AppTheme.signalYellow,
                    icon: Icons.local_fire_department,
                  ),
                  const SizedBox(height: 16),
                  const _ReadyMetric(icon: Icons.bolt, label: 'XP', value: '+25 first lesson'),
                  const SizedBox(height: 10),
                  const _ReadyMetric(icon: Icons.diamond, label: 'GEMS', value: '+5 first win'),
                  const SizedBox(height: 10),
                  const _ReadyMetric(icon: Icons.front_hand, label: 'SIGNS', value: 'A-Z and 1-9'),
                  const Spacer(),
                  const Text(
                    'Nice move. Let us begin.',
                    style: TextStyle(
                      color: AppTheme.inkBlack,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          NeoPrimaryButton(label: 'Create Account', onPressed: onSignup),
          const SizedBox(height: 10),
          NeoSecondaryButton(label: 'I Already Have Account', onPressed: onLogin),
        ],
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  final IconData icon;
  final String label;

  const _IconTile({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.warmWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.inkBlack, width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.inkBlack, size: 18),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.inkBlack,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadyMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ReadyMetric({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.warmWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.inkBlack, width: 2),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.inkBlack, size: 18),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: const TextStyle(
              color: AppTheme.inkBlack,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppTheme.inkBlack,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

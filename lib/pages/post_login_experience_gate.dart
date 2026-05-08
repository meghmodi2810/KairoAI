import 'dart:async';
import 'package:flutter/material.dart';
import '../main_navigation.dart';
import '../models/experience_models.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../theme/neo_brutal_widgets.dart';
import '../widgets/kairo_coach_overlay.dart';
import 'learn_page.dart';
import 'profile_page.dart';
import 'sign_learning_page.dart';
import 'words_page.dart';

class PostLoginExperienceGate extends StatefulWidget {
  final Widget? child;
  final Widget Function(MainNavigationController controller)? builder;

  const PostLoginExperienceGate({super.key, this.child, this.builder})
    : assert(child != null || builder != null);

  @override
  State<PostLoginExperienceGate> createState() =>
      _PostLoginExperienceGateState();
}

class _PostLoginExperienceGateState extends State<PostLoginExperienceGate> {
  final DatabaseService _db = DatabaseService();
  final MainNavigationController _navigationController =
      MainNavigationController();
  int _tourIndex = 0;
  bool _activationRouteOpen = false;
  bool _resolvingActivation = false;
  bool _showActivationBanner = false;
  String? _lastPushedActivationKey;
  Timer? _activationBannerTimer;

  static const List<_TourCopy> _tour = [
    _TourCopy(
      id: 'welcome',
      title: 'Welcome to Kairo',
      message:
          'I will show you the main parts first. Then we will finish one real lesson together.',
      pose: KairoCoachPose.wave,
    ),
    _TourCopy(
      id: 'learn',
      title: 'Lessons live here',
      message:
          'Use Learn to find categories and lessons. I will move there with you.',
      pose: KairoCoachPose.point,
    ),
    _TourCopy(
      id: 'lesson_characters',
      title: 'Check the sign chips',
      message:
          'Each category opens lesson cards. The little chips under a lesson show the signs inside.',
      pose: KairoCoachPose.thinking,
    ),
    _TourCopy(
      id: 'gems',
      title: 'Gems unlock words',
      message:
          'Complete lessons to earn gems. Spend them on word packs when you are ready.',
      pose: KairoCoachPose.celebrate,
    ),
    _TourCopy(
      id: 'word_prerequisites',
      title: 'Words need signs first',
      message:
          'A word becomes practice-ready once you have learned every character needed for that word.',
      pose: KairoCoachPose.point,
    ),
    _TourCopy(
      id: 'profile',
      title: 'Your progress lives in Profile',
      message:
          'Profile shows gems, XP, lessons, and the signs you have completed.',
      pose: KairoCoachPose.idle,
    ),
  ];

  Future<void> _nextTourStep() async {
    if (_tourIndex >= _tour.length - 1) {
      await _db.updateExperience(
        tourStatus: ExperienceStatus.completed,
        clearTourStep: true,
      );
      return;
    }

    final next = _tourIndex + 1;
    _jumpForTourStep(_tour[next].id);
    setState(() => _tourIndex = next);
    await _db.updateExperience(
      tourStatus: ExperienceStatus.inProgress,
      tourStep: _tour[next].id,
    );
  }

  void _jumpForTourStep(String stepId) {
    final index = switch (stepId) {
      'welcome' => 0,
      'learn' || 'lesson_characters' => 1,
      'gems' || 'word_prerequisites' => 2,
      'profile' => 3,
      _ => null,
    };
    if (index != null) {
      _navigationController.jumpTo(index);
    }
  }

  GlobalKey? _targetForTourStep(String stepId) {
    return switch (stepId) {
      'learn' => MainNavigationTourTargets.learnTab,
      'lesson_characters' => LearnTourTargets.firstCategory,
      'gems' => WordsTourTargets.gems,
      'word_prerequisites' => WordsTourTargets.firstWordGroup,
      'profile' => ProfileTourTargets.completedSigns,
      _ => null,
    };
  }

  Future<void> _skipTour() async {
    await _db.updateExperience(
      tourStatus: ExperienceStatus.skipped,
      clearTourStep: true,
    );
  }

  void _maybeStartActivation(ExperienceState state) {
    if (!state.tourDone || !state.needsActivation || _activationRouteOpen) {
      return;
    }

    final routeKey =
        '${state.activationCategoryId}/${state.activationLessonId}/${state.activationStatus.value}';
    if (_lastPushedActivationKey == routeKey && _resolvingActivation) {
      return;
    }

    _lastPushedActivationKey = routeKey;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _startActivation(state);
      }
    });
  }

  Future<void> _startActivation(ExperienceState state) async {
    if (_activationRouteOpen || _resolvingActivation) return;
    _resolvingActivation = true;
    _activationBannerTimer?.cancel();
    if (mounted) {
      setState(() => _showActivationBanner = false);
    }
    _activationBannerTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted || !_resolvingActivation) return;
      setState(() => _showActivationBanner = true);
    });

    try {
      var categoryId = state.activationCategoryId;
      var lessonId = state.activationLessonId;

      if (categoryId == null || lessonId == null) {
        final ref = await _db.resolveFirstActivationLesson();
        if (ref == null) {
          await _db.updateExperience(
            activationRequired: false,
            activationStatus: ExperienceStatus.completed,
            activationStage: ActivationStage.done,
            completedAt: DateTime.now(),
          );
          return;
        }
        categoryId = ref.categoryId;
        lessonId = ref.lessonId;
      }

      final lesson = await _db.getLesson(categoryId, lessonId);
      if (!mounted) return;

      if (lesson == null) {
        await _db.updateExperience(
          activationRequired: false,
          activationStatus: ExperienceStatus.completed,
          activationStage: ActivationStage.done,
          completedAt: DateTime.now(),
        );
        return;
      }

      await _db.updateExperience(
        activationStatus: ExperienceStatus.inProgress,
        activationCategoryId: categoryId,
        activationLessonId: lessonId,
        activationStage: ActivationStage.openLesson,
        clearCompletedAt: true,
      );

      _activationRouteOpen = true;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SignLearningPage(
            lesson: lesson,
            categoryId: categoryId!,
            activationMode: true,
          ),
        ),
      );
    } finally {
      _activationBannerTimer?.cancel();
      _activationBannerTimer = null;
      if (mounted) {
        setState(() => _showActivationBanner = false);
      }
      _activationRouteOpen = false;
      _resolvingActivation = false;
    }
  }

  @override
  void dispose() {
    _activationBannerTimer?.cancel();
    _navigationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ExperienceState>(
      stream: _db.experienceStateStream(),
      initialData: const ExperienceState(),
      builder: (context, snapshot) {
        final state = snapshot.data ?? const ExperienceState();
        final showTour = state.needsTour;

        if (!showTour) {
          _maybeStartActivation(state);
        }

        final savedTourIndex = state.tourStep == null
            ? -1
            : _tour.indexWhere((step) => step.id == state.tourStep);
        if (showTour && savedTourIndex >= 0 && _tourIndex == 0) {
          _tourIndex = savedTourIndex;
        }
        final tourStep = _tour[_tourIndex.clamp(0, _tour.length - 1)];
        if (showTour) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _jumpForTourStep(tourStep.id);
            }
          });
        }
        final appChild =
            widget.builder?.call(_navigationController) ?? widget.child!;

        return KairoCoachOverlay(
          visible: showTour,
          targetKey: _targetForTourStep(tourStep.id),
          title: tourStep.title,
          message: tourStep.message,
          primaryLabel: _tourIndex >= _tour.length - 1
              ? 'Start lesson'
              : 'Next',
          onPrimary: _nextTourStep,
          showSkip: true,
          onSkip: _skipTour,
          pose: tourStep.pose,
          child: Stack(
            children: [
              appChild,
              if (!showTour && _showActivationBanner)
                const _ResolvingActivationBanner(),
            ],
          ),
        );
      },
    );
  }
}

class _ResolvingActivationBanner extends StatelessWidget {
  const _ResolvingActivationBanner();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      top: MediaQuery.of(context).padding.top + 12,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: NeoPanel(
            color: AppTheme.signalYellow,
            radius: 14,
            shadowOffset: 4,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: const Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: AppTheme.inkBlack,
                    strokeWidth: 2,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Starting your first lesson...',
                    style: TextStyle(
                      color: AppTheme.inkBlack,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TourCopy {
  final String id;
  final String title;
  final String message;
  final KairoCoachPose pose;

  const _TourCopy({
    required this.id,
    required this.title,
    required this.message,
    required this.pose,
  });
}

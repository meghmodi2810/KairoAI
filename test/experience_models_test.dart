import 'package:flutter_test/flutter_test.dart';
import 'package:kairo_ai/models/experience_models.dart';

void main() {
  test('missing experience state defaults to completed for existing users', () {
    final state = ExperienceState.fromMap(null);

    expect(state.needsTour, isFalse);
    expect(state.needsActivation, isFalse);
    expect(state.lessonTourCompleted, isTrue);
  });

  test('new learner experience requires tour and activation', () {
    const state = ExperienceState.newLearner();

    expect(state.needsTour, isTrue);
    expect(state.needsActivation, isTrue);
    expect(state.activationStage, ActivationStage.openLesson);
    expect(state.lessonTourCompleted, isFalse);
  });

  test('legacy completed activation infers lesson tour completed', () {
    final state = ExperienceState.fromMap({
      'tourStatus': 'completed',
      'activationRequired': true,
      'activationStatus': 'completed',
    });

    expect(state.lessonTourCompleted, isTrue);
    expect(state.needsActivation, isFalse);
  });

  test('legacy active activation still needs lesson tour', () {
    final state = ExperienceState.fromMap({
      'tourStatus': 'completed',
      'activationRequired': true,
      'activationStatus': 'in_progress',
    });

    expect(state.lessonTourCompleted, isFalse);
    expect(state.needsActivation, isTrue);
  });

  test('explicit lesson tour completion suppresses activation repeat', () {
    final state = ExperienceState.fromMap({
      'tourStatus': 'completed',
      'activationRequired': true,
      'activationStatus': 'in_progress',
      'lessonTourCompleted': true,
    });

    expect(state.lessonTourCompleted, isTrue);
    expect(state.needsActivation, isFalse);
  });
}

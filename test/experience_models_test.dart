import 'package:flutter_test/flutter_test.dart';
import 'package:kairo_ai/models/experience_models.dart';

void main() {
  test('missing experience state defaults to completed for existing users', () {
    final state = ExperienceState.fromMap(null);

    expect(state.needsTour, isFalse);
    expect(state.needsActivation, isFalse);
  });

  test('new learner experience requires tour and activation', () {
    const state = ExperienceState.newLearner();

    expect(state.needsTour, isTrue);
    expect(state.needsActivation, isTrue);
    expect(state.activationStage, ActivationStage.openLesson);
  });
}

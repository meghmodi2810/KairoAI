import 'package:cloud_firestore/cloud_firestore.dart';

enum ExperienceStatus {
  notStarted('not_started'),
  inProgress('in_progress'),
  completed('completed'),
  skipped('skipped');

  const ExperienceStatus(this.value);
  final String value;

  static ExperienceStatus fromValue(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    return ExperienceStatus.values.firstWhere(
      (status) => status.value == normalized,
      orElse: () => ExperienceStatus.notStarted,
    );
  }
}

enum ActivationStage {
  openLesson('open_lesson'),
  viewSign('view_sign'),
  tapPractice('tap_practice'),
  practicing('practicing'),
  assessments('assessments'),
  done('done');

  const ActivationStage(this.value);
  final String value;

  static ActivationStage fromValue(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    return ActivationStage.values.firstWhere(
      (stage) => stage.value == normalized,
      orElse: () => ActivationStage.openLesson,
    );
  }
}

class ExperienceState {
  final ExperienceStatus tourStatus;
  final String? tourStep;
  final bool activationRequired;
  final ExperienceStatus activationStatus;
  final String? activationCategoryId;
  final String? activationLessonId;
  final ActivationStage activationStage;
  final DateTime? updatedAt;
  final DateTime? completedAt;

  const ExperienceState({
    this.tourStatus = ExperienceStatus.completed,
    this.tourStep,
    this.activationRequired = false,
    this.activationStatus = ExperienceStatus.completed,
    this.activationCategoryId,
    this.activationLessonId,
    this.activationStage = ActivationStage.done,
    this.updatedAt,
    this.completedAt,
  });

  const ExperienceState.newLearner()
    : tourStatus = ExperienceStatus.notStarted,
      tourStep = null,
      activationRequired = true,
      activationStatus = ExperienceStatus.notStarted,
      activationCategoryId = null,
      activationLessonId = null,
      activationStage = ActivationStage.openLesson,
      updatedAt = null,
      completedAt = null;

  bool get needsTour =>
      tourStatus == ExperienceStatus.notStarted ||
      tourStatus == ExperienceStatus.inProgress;

  bool get tourDone =>
      tourStatus == ExperienceStatus.completed ||
      tourStatus == ExperienceStatus.skipped;

  bool get needsActivation =>
      activationRequired && activationStatus != ExperienceStatus.completed;

  factory ExperienceState.fromMap(Map<String, dynamic>? data) {
    if (data == null) {
      return const ExperienceState();
    }

    return ExperienceState(
      tourStatus: ExperienceStatus.fromValue(data['tourStatus']?.toString()),
      tourStep: _stringOrNull(data['tourStep']),
      activationRequired: data['activationRequired'] == true,
      activationStatus: ExperienceStatus.fromValue(
        data['activationStatus']?.toString(),
      ),
      activationCategoryId: _stringOrNull(data['activationCategoryId']),
      activationLessonId: _stringOrNull(data['activationLessonId']),
      activationStage: ActivationStage.fromValue(
        data['activationStage']?.toString(),
      ),
      updatedAt: _dateOrNull(data['updatedAt']),
      completedAt: _dateOrNull(data['completedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'tourStatus': tourStatus.value,
      'tourStep': tourStep,
      'activationRequired': activationRequired,
      'activationStatus': activationStatus.value,
      'activationCategoryId': activationCategoryId,
      'activationLessonId': activationLessonId,
      'activationStage': activationStage.value,
      'updatedAt': updatedAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(updatedAt!),
      'completedAt': completedAt == null
          ? null
          : Timestamp.fromDate(completedAt!),
    };
  }

  ExperienceState copyWith({
    ExperienceStatus? tourStatus,
    String? tourStep,
    bool clearTourStep = false,
    bool? activationRequired,
    ExperienceStatus? activationStatus,
    String? activationCategoryId,
    String? activationLessonId,
    bool clearActivationLesson = false,
    ActivationStage? activationStage,
    DateTime? updatedAt,
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) {
    return ExperienceState(
      tourStatus: tourStatus ?? this.tourStatus,
      tourStep: clearTourStep ? null : tourStep ?? this.tourStep,
      activationRequired: activationRequired ?? this.activationRequired,
      activationStatus: activationStatus ?? this.activationStatus,
      activationCategoryId: clearActivationLesson
          ? null
          : activationCategoryId ?? this.activationCategoryId,
      activationLessonId: clearActivationLesson
          ? null
          : activationLessonId ?? this.activationLessonId,
      activationStage: activationStage ?? this.activationStage,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: clearCompletedAt ? null : completedAt ?? this.completedAt,
    );
  }
}

class ActivationLessonRef {
  final String categoryId;
  final String lessonId;

  const ActivationLessonRef({required this.categoryId, required this.lessonId});
}

String? _stringOrNull(Object? value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

DateTime? _dateOrNull(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

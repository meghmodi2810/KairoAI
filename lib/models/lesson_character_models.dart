String normalizeSignCharacter(String value) {
  final normalized = value.trim().toUpperCase();
  if (normalized.isEmpty) return '';
  return normalized;
}

List<String> normalizeSignCharacters(Iterable<String> values) {
  final seen = <String>{};
  final output = <String>[];

  for (final value in values) {
    final normalized = normalizeSignCharacter(value);
    if (normalized.isEmpty || seen.contains(normalized)) continue;
    seen.add(normalized);
    output.add(normalized);
  }

  return output;
}

bool isAlphabetSignCharacter(String value) {
  final normalized = normalizeSignCharacter(value);
  return normalized.length == 1 && RegExp(r'^[A-Z]$').hasMatch(normalized);
}

bool isNumberSignCharacter(String value) {
  final normalized = normalizeSignCharacter(value);
  return normalized.length == 1 && RegExp(r'^[0-9]$').hasMatch(normalized);
}

class CoachTarget {
  final String id;
  final String label;

  const CoachTarget({required this.id, required this.label});
}

class CoachStep {
  final String id;
  final String title;
  final String message;
  final CoachTarget? target;
  final bool canSkip;

  const CoachStep({
    required this.id,
    required this.title,
    required this.message,
    this.target,
    this.canSkip = true,
  });
}

class LessonCharacterCandidate {
  final String categoryId;
  final String categoryName;
  final String lessonId;
  final String lessonTitle;
  final int categoryOrder;
  final int lessonOrder;
  final Set<String> characters;

  const LessonCharacterCandidate({
    required this.categoryId,
    required this.categoryName,
    required this.lessonId,
    required this.lessonTitle,
    required this.categoryOrder,
    required this.lessonOrder,
    required this.characters,
  });

  int coveredMissingCount(Set<String> missingCharacters) {
    return characters.intersection(missingCharacters).length;
  }
}

class LessonCharacterIndex {
  final List<LessonCharacterCandidate> candidates;

  const LessonCharacterIndex(this.candidates);

  Map<String, List<LessonCharacterCandidate>> candidatesByCharacter(
    Set<String> characters,
  ) {
    final normalizedCharacters = normalizeSignCharacters(characters).toSet();
    final result = <String, List<LessonCharacterCandidate>>{};

    for (final character in normalizedCharacters) {
      final matches =
          candidates
              .where((candidate) => candidate.characters.contains(character))
              .toList()
            ..sort(_candidateSorter(normalizedCharacters));
      result[character] = matches;
    }

    return result;
  }

  List<LessonCharacterCandidate> rankedCandidatesFor(Set<String> characters) {
    final normalizedCharacters = normalizeSignCharacters(characters).toSet();
    final ranked =
        candidates
            .where(
              (candidate) => candidate.characters
                  .intersection(normalizedCharacters)
                  .isNotEmpty,
            )
            .toList()
          ..sort(_candidateSorter(normalizedCharacters));
    return ranked;
  }

  int Function(LessonCharacterCandidate, LessonCharacterCandidate)
  _candidateSorter(Set<String> missingCharacters) {
    return (a, b) {
      final coveredCompare = b
          .coveredMissingCount(missingCharacters)
          .compareTo(a.coveredMissingCount(missingCharacters));
      if (coveredCompare != 0) return coveredCompare;

      final categoryCompare = a.categoryOrder.compareTo(b.categoryOrder);
      if (categoryCompare != 0) return categoryCompare;

      return a.lessonOrder.compareTo(b.lessonOrder);
    };
  }
}

class WordPrerequisiteResult {
  final Set<String> requiredCharacters;
  final Set<String> completedCharacters;
  final Set<String> missingCharacters;

  const WordPrerequisiteResult({
    required this.requiredCharacters,
    required this.completedCharacters,
    required this.missingCharacters,
  });

  bool get isReady => missingCharacters.isEmpty;
}

WordPrerequisiteResult buildWordPrerequisiteResult({
  required Iterable<String> requiredCharacters,
  required Iterable<String> completedCharacters,
}) {
  final required = normalizeSignCharacters(requiredCharacters).toSet();
  final completed = normalizeSignCharacters(completedCharacters).toSet();
  return WordPrerequisiteResult(
    requiredCharacters: required,
    completedCharacters: completed,
    missingCharacters: required.difference(completed),
  );
}

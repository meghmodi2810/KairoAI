class LessonCategoryIds {
  static const alphabet = 'alphabet';
  static const number = 'number';
  static const alphaNumeric = 'alpha-numeric';

  static const canonical = <String>[
    alphabet,
    number,
    alphaNumeric,
  ];
}

class LessonCategoryDefinition {
  final String id;
  final String label;
  final String description;
  final String iconEmoji;
  final String color;
  final int order;

  const LessonCategoryDefinition({
    required this.id,
    required this.label,
    required this.description,
    required this.iconEmoji,
    required this.color,
    required this.order,
  });
}

const kLessonCategoryDefinitions = <LessonCategoryDefinition>[
  LessonCategoryDefinition(
    id: LessonCategoryIds.alphabet,
    label: 'Alphabet',
    description: 'Learn individual alphabet signs (A-Z)',
    iconEmoji: 'ABC',
    color: '#4A90D9',
    order: 0,
  ),
  LessonCategoryDefinition(
    id: LessonCategoryIds.number,
    label: 'Number',
    description: 'Learn individual number signs (0-9)',
    iconEmoji: '123',
    color: '#5DBE6E',
    order: 1,
  ),
  LessonCategoryDefinition(
    id: LessonCategoryIds.alphaNumeric,
    label: 'Alpha Numeric',
    description: 'Learn alphabet and number signs together',
    iconEmoji: 'A1',
    color: '#9B59B6',
    order: 2,
  ),
];

const kAlphabetSignLabels = <String>[
  'A',
  'B',
  'C',
  'D',
  'E',
  'F',
  'G',
  'H',
  'I',
  'J',
  'K',
  'L',
  'M',
  'N',
  'P',
  'Q',
  'R',
  'S',
  'T',
  'U',
  'V',
  'W',
  'X',
  'Y',
  'Z',
  'O / 0',
];

const kNumberSignLabels = <String>[
  '1',
  '2',
  '3',
  '4',
  '5',
  '6',
  '7',
  '8',
  '9',
  'O / 0',
];

LessonCategoryDefinition lessonCategoryDefinition(String categoryId) {
  final normalized = normalizeLessonCategoryId(categoryId);
  return kLessonCategoryDefinitions.firstWhere(
    (definition) => definition.id == normalized,
    orElse: () => kLessonCategoryDefinitions.last,
  );
}

String lessonCategoryLabel(String categoryId) =>
    lessonCategoryDefinition(categoryId).label;

int lessonCategoryOrder(String categoryId) =>
    lessonCategoryDefinition(categoryId).order;

bool isCanonicalLessonCategoryId(String? categoryId) =>
    normalizeLessonCategoryId(categoryId) == categoryId?.trim().toLowerCase();

String? normalizeLessonCategoryId(String? rawCategoryId) {
  final value = rawCategoryId?.trim().toLowerCase();
  if (value == null || value.isEmpty) return null;

  final compact = value
      .replaceAll('_', '-')
      .replaceAll(RegExp(r'\s+'), '-')
      .replaceAll('--', '-');

  if (compact == LessonCategoryIds.alphabet || compact == 'alphabets') {
    return LessonCategoryIds.alphabet;
  }
  if (compact == LessonCategoryIds.number ||
      compact == 'numbers' ||
      compact == 'numeric') {
    return LessonCategoryIds.number;
  }
  if (compact == LessonCategoryIds.alphaNumeric ||
      compact == 'alphanumeric' ||
      compact == 'alpha-numeric' ||
      compact == 'alpha-numerics' ||
      compact == 'both') {
    return LessonCategoryIds.alphaNumeric;
  }
  return null;
}

List<String> lessonSignPoolLabelsForCategory(String categoryId) {
  final normalized =
      normalizeLessonCategoryId(categoryId) ?? LessonCategoryIds.alphaNumeric;
  return switch (normalized) {
    LessonCategoryIds.alphabet => List<String>.from(kAlphabetSignLabels),
    LessonCategoryIds.number => List<String>.from(kNumberSignLabels),
    _ => <String>[
        ...kAlphabetSignLabels.where((label) => label != 'O / 0'),
        ...kNumberSignLabels.where((label) => label != 'O / 0'),
        'O / 0',
      ],
  };
}

String normalizeLessonSignLabel(String value) {
  final normalized = value.trim().toUpperCase();
  if (normalized == 'O / 0' || normalized == '0' || normalized == 'O') {
    return 'O';
  }
  return normalized;
}

bool isAmbiguousZeroOrO(String value) => normalizeLessonSignLabel(value) == 'O';

bool isAlphabetLessonSign(String value) {
  final normalized = normalizeLessonSignLabel(value);
  return RegExp(r'^[A-Z]$').hasMatch(normalized);
}

bool isNumberLessonSign(String value) {
  final normalized = normalizeLessonSignLabel(value);
  return normalized == 'O' || RegExp(r'^[1-9]$').hasMatch(normalized);
}

bool isSignAllowedForLessonCategory(String categoryId, String signLabel) {
  final normalizedCategory =
      normalizeLessonCategoryId(categoryId) ?? LessonCategoryIds.alphaNumeric;
  return switch (normalizedCategory) {
    LessonCategoryIds.alphabet => isAlphabetLessonSign(signLabel),
    LessonCategoryIds.number => isNumberLessonSign(signLabel),
    _ => isAlphabetLessonSign(signLabel) || isNumberLessonSign(signLabel),
  };
}

List<String> invalidLessonSignsForCategory(
  String categoryId,
  Iterable<String> signLabels,
) {
  return signLabels
      .where((sign) => !isSignAllowedForLessonCategory(categoryId, sign))
      .map(normalizeLessonSignLabel)
      .toSet()
      .toList()
    ..sort();
}

String classifyLessonCategoryFromSigns(
  Iterable<String> signLabels, {
  String? fallbackCategoryId,
}) {
  final fallback = normalizeLessonCategoryId(fallbackCategoryId);
  final normalizedSigns = signLabels
      .map(normalizeLessonSignLabel)
      .where((sign) => sign.isNotEmpty)
      .toList(growable: false);

  if (normalizedSigns.isEmpty) {
    return fallback ?? LessonCategoryIds.alphaNumeric;
  }

  var hasAlphabet = false;
  var hasNumber = false;
  var hasNonAmbiguousSign = false;

  for (final sign in normalizedSigns) {
    if (isAmbiguousZeroOrO(sign)) {
      continue;
    }
    hasNonAmbiguousSign = true;
    if (isAlphabetLessonSign(sign)) {
      hasAlphabet = true;
    } else if (isNumberLessonSign(sign)) {
      hasNumber = true;
    }
  }

  if (!hasNonAmbiguousSign) {
    return fallback ?? LessonCategoryIds.alphaNumeric;
  }
  if (hasAlphabet && hasNumber) return LessonCategoryIds.alphaNumeric;
  if (hasAlphabet) return LessonCategoryIds.alphabet;
  if (hasNumber) return LessonCategoryIds.number;
  return fallback ?? LessonCategoryIds.alphaNumeric;
}

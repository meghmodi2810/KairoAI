import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service to resolve local bundled sign assets from normalized labels.
class SignImageService {
  static final SignImageService _instance = SignImageService._internal();
  factory SignImageService() => _instance;
  SignImageService._internal();

  final Map<String, String?> _bundledImageRefCache = {};

  static const List<String> availableSigns = [
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J',
    'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T',
    'U', 'V', 'W', 'X', 'Y', 'Z',
    '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
  ];

  static const Map<String, String> _numberWordToDigit = {
    'ZERO': '0',
    'ONE': '1',
    'TWO': '2',
    'THREE': '3',
    'FOUR': '4',
    'FIVE': '5',
    'SIX': '6',
    'SEVEN': '7',
    'EIGHT': '8',
    'NINE': '9',
  };

  /// Maps a word to its sign folder key.
  String? _mapWordToFolder(String word) {
    if (word.isEmpty) return null;

    final upper = word.toUpperCase().trim();

    if (availableSigns.contains(upper)) return upper;
    if (_numberWordToDigit.containsKey(upper)) return _numberWordToDigit[upper];

    final alnumOnly = upper.replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (availableSigns.contains(alnumOnly)) return alnumOnly;
    if (_numberWordToDigit.containsKey(alnumOnly)) {
      return _numberWordToDigit[alnumOnly];
    }

    // Handle compact values like "SIGN2" or "LEVEL_3" by preferring
    // an embedded digit when one exists.
    final digitMatch = RegExp(r'[0-9]').firstMatch(upper);
    if (digitMatch != null) {
      final digit = digitMatch.group(0)!;
      if (availableSigns.contains(digit)) return digit;
    }

    final tokens = upper
        .split(RegExp(r'[^A-Z0-9]+'))
        .where((token) => token.isNotEmpty)
        .toList(growable: false);

    for (final token in tokens) {
      if (availableSigns.contains(token)) return token;
      if (_numberWordToDigit.containsKey(token)) {
        return _numberWordToDigit[token];
      }
    }

    final firstChar = upper[0];
    if (availableSigns.contains(firstChar)) return firstChar;

    return null;
  }

  bool _looksLikeAssetPath(String value) {
    return value.startsWith('assets/');
  }

  String? _normalizeLocalAssetRef(String? rawValue) {
    final value = (rawValue ?? '').trim();
    if (value.isEmpty) return null;
    if (_looksLikeAssetPath(value)) {
      return value;
    }
    return null;
  }

  Future<bool> _assetExists(String assetPath) async {
    try {
      await rootBundle.load(assetPath);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Resolve bundled local asset path for a sign label using the canonical
  /// contract: assets/signs/<LABEL>/image.png.
  Future<String?> getBundledImageRef(String word) async {
    final folder = _mapWordToFolder(word);
    debugPrint('[SignImageService] getBundledImageRef: word="$word" -> folder=$folder');
    if (folder == null) return null;

    if (_bundledImageRefCache.containsKey(folder)) {
      debugPrint('[SignImageService] Cache hit for folder: $folder = ${_bundledImageRefCache[folder]}');
      return _bundledImageRefCache[folder];
    }

    final candidate = 'assets/signs/$folder/image.png';
    debugPrint('[SignImageService] Checking asset existence: $candidate');
    final exists = await _assetExists(candidate);
    debugPrint('[SignImageService] Asset exists: $exists');
    if (exists) {
      _bundledImageRefCache[folder] = candidate;
      return candidate;
    }

    _bundledImageRefCache[folder] = null;
    return null;
  }

  /// Resolve image ref for a sign label from local bundled assets only.
  /// Returns the exact local asset path when it exists, otherwise null.
  Future<String?> resolveImageRefForWord(
    String word, {
    String? lessonImageRef,
    String? lessonFallbackRef,
    String? fallbackLabel,
  }) async {
    debugPrint('[SignImageService] Resolving image for word: "$word"');
    debugPrint('[SignImageService] lessonImageRef: $lessonImageRef');
    debugPrint('[SignImageService] lessonFallbackRef: $lessonFallbackRef');
    debugPrint('[SignImageService] fallbackLabel: $fallbackLabel');

    final lessonPrimary = _normalizeLocalAssetRef(lessonImageRef);
    final lessonFallback = _normalizeLocalAssetRef(lessonFallbackRef);
    debugPrint('[SignImageService] normalized lessonPrimary: $lessonPrimary');
    debugPrint('[SignImageService] normalized lessonFallback: $lessonFallback');

    if (lessonPrimary != null && await _assetExists(lessonPrimary)) {
      debugPrint('[SignImageService] Found lessonPrimary: $lessonPrimary');
      return lessonPrimary;
    }
    if (lessonFallback != null && await _assetExists(lessonFallback)) {
      debugPrint('[SignImageService] Found lessonFallback: $lessonFallback');
      return lessonFallback;
    }

    final folder = _mapWordToFolder(word);
    debugPrint('[SignImageService] Mapped word "$word" to folder: $folder');

    final bundled = await getBundledImageRef(word);
    debugPrint('[SignImageService] Bundled ref result: $bundled');
    if (bundled != null) return bundled;

    // Safe same-item fallback: if caller passes a label-like id, use it.
    final bundledFallback = await getBundledImageRef(fallbackLabel ?? '');
    debugPrint('[SignImageService] Bundled fallback result: $bundledFallback');
    if (bundledFallback != null) return bundledFallback;

    debugPrint('[SignImageService] No image found for word: "$word"');
    return null;
  }

  /// Whether this sign has images available.
  bool hasSign(String word) {
    return _mapWordToFolder(word) != null;
  }

  /// Returns the folder name for a word.
  String? getFolderName(String word) {
    return _mapWordToFolder(word);
  }

  /// Splits a word into individual sign characters.
  List<String> splitWordToCharacters(String word) {
    final result = <String>[];
    for (final char in word.toUpperCase().split('')) {
      if (availableSigns.contains(char)) {
        result.add(char);
      }
    }
    return result;
  }

  /// Pre-fetch all bundled image refs into cache.
  Future<void> preloadAll() async {
    for (final sign in availableSigns) {
      await getBundledImageRef(sign);
    }
  }

  /// Clear the cache.
  void clearCache() {
    _bundledImageRefCache.clear();
  }
}

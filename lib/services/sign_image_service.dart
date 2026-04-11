import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service to fetch ISL sign images from Firestore (stored as Base64).
/// The 'sign_images' collection has one doc per sign (A-Z, 1-9),
/// each with an 'images' array of Base64-encoded JPEGs.
class SignImageService {
  static final SignImageService _instance = SignImageService._internal();
  factory SignImageService() => _instance;
  SignImageService._internal();

  final Random _random = Random();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // In-memory cache: sign key -> list of decoded image bytes
  final Map<String, List<Uint8List>> _cache = {};

  static const List<String> availableSigns = [
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J',
    'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T',
    'U', 'V', 'W', 'X', 'Y', 'Z',
    '1', '2', '3', '4', '5', '6', '7', '8', '9',
  ];

  /// Maps a word to its sign folder key.
  String? _mapWordToFolder(String word) {
    if (word.isEmpty) return null;
    final upper = word.toUpperCase().trim();
    if (upper.length == 1 && availableSigns.contains(upper)) return upper;
    final firstChar = upper[0];
    if (availableSigns.contains(firstChar)) return firstChar;
    return null;
  }

  /// Fetches images for a sign from Firestore, with caching.
  /// Returns a list of decoded image bytes.
  Future<List<Uint8List>> _getImages(String signKey) async {
    if (_cache.containsKey(signKey)) return _cache[signKey]!;

    try {
      final doc = await _firestore.collection('sign_images').doc(signKey).get();
      if (!doc.exists) return [];

      final data = doc.data()!;
      final List<dynamic> base64List = data['images'] ?? [];
      final images = base64List
          .map((b64) => base64Decode(b64 as String))
          .toList();

      _cache[signKey] = images;
      return images;
    } catch (e) {
      return [];
    }
  }

  /// Returns a random image (as bytes) for the given sign word.
  Future<Uint8List?> getRandomImage(String word) async {
    final folder = _mapWordToFolder(word);
    if (folder == null) return null;

    final images = await _getImages(folder);
    if (images.isEmpty) return null;

    return images[_random.nextInt(images.length)];
  }

  /// Returns a specific image by index (for previews).
  Future<Uint8List?> getImageAtIndex(String word, {int index = 0}) async {
    final folder = _mapWordToFolder(word);
    if (folder == null) return null;

    final images = await _getImages(folder);
    if (images.isEmpty || index >= images.length) return null;

    return images[index];
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

  /// Pre-fetch all sign images into cache (call on app start for speed).
  Future<void> preloadAll() async {
    for (final sign in availableSigns) {
      await _getImages(sign);
    }
  }

  /// Clear the cache.
  void clearCache() => _cache.clear();
}

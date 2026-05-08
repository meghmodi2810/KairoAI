import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _clickPlayer = AudioPlayer();
  final AudioPlayer _successPlayer = AudioPlayer();
  
  bool _initialized = false;
  bool _soundEnabled = true;

  bool get soundEnabled => _soundEnabled;

  Future<void> init() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;

      await _clickPlayer.setSource(AssetSource('sounds/click.mp3'));
      await _clickPlayer.setReleaseMode(ReleaseMode.stop);
      
      await _successPlayer.setSource(AssetSource('sounds/success.mp3'));
      await _successPlayer.setReleaseMode(ReleaseMode.stop);
      
      _initialized = true;
    } catch (e) {
      if (kDebugMode) {
        print('AudioService init failed: $e');
      }
    }
  }

  /// Call this when the user toggles sound in Settings.
  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', enabled);
  }

  Future<void> playClick() async {
    if (!_soundEnabled) return;
    try {
      if (_clickPlayer.state == PlayerState.playing) {
        await _clickPlayer.stop();
      }
      await _clickPlayer.resume();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to play click sound: $e');
      }
    }
  }

  Future<void> playSuccess() async {
    if (!_soundEnabled) return;
    try {
      if (_successPlayer.state == PlayerState.playing) {
        await _successPlayer.stop();
      }
      await _successPlayer.resume();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to play success sound: $e');
      }
    }
  }
}

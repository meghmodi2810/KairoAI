import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class SignDetectionService {
  // Method channel for commands
  static const MethodChannel _methodChannel =
      MethodChannel('com.kairo.ai/detection');
  
  // Event channel for continuous detection stream
  static const EventChannel _eventChannel =
      EventChannel('com.kairo.ai/detection_stream');
  
  Stream<DetectionResult>? _detectionStream;
  StreamSubscription? _subscription;
  
  int? _textureId;
  /// The ID of the native SurfaceTexture to render the camera preview
  int? get textureId => _textureId;

  /// Native detection pipeline is available on mobile platforms.
  bool get isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);
  
  /// Start hand sign detection
  Future<void> startDetection() async {
    if (!isSupportedPlatform) {
      throw UnsupportedError(
        'Live sign detection is currently available only on Android and iOS.',
      );
    }

    try {
      // Reset prediction state before starting
      await resetPrediction();
      final dynamic result = await _methodChannel.invokeMethod('startDetection');
      if (result is Map) {
        final tid = result['textureId'];
        if (tid != null && tid is int) {
           _textureId = tid;
        } else if (tid is num) {
           _textureId = tid.toInt(); // Handle JS/Num casting 
        }
      }
      debugPrint('✅ Detection started (textureId : $_textureId)');
    } catch (e) {
      if (e is PlatformException) {
        debugPrint('❌ Error starting detection: ${e.message}');
      } else {
        debugPrint('❌ Error starting detection: $e');
      }
      rethrow;
    }
  }
  
  /// Stop hand sign detection
  Future<void> stopDetection() async {
    if (!isSupportedPlatform) {
      _textureId = null;
      return;
    }

    try {
      _subscription?.cancel();
      _subscription = null;
      _detectionStream = null;
      _textureId = null;
      await _methodChannel.invokeMethod('stopDetection');
      debugPrint('✅ Detection stopped');
    } catch (e) {
      if (e is PlatformException) {
        debugPrint('❌ Error stopping detection: ${e.message}');
      } else {
        debugPrint('❌ Error stopping detection: $e');
      }
      rethrow;
    }
  }
  
  /// Switch between front and back camera
  Future<bool> switchCamera() async {
    if (!isSupportedPlatform) {
      throw UnsupportedError(
        'Camera switching is currently available only on Android and iOS.',
      );
    }

    try {
      // Reset predictions when switching camera
      await resetPrediction();
      final bool isFrontCamera = await _methodChannel.invokeMethod('switchCamera');
      debugPrint('📷 Switched to ${isFrontCamera ? "front" : "back"} camera');
      return isFrontCamera;
    } catch (e) {
      if (e is PlatformException) {
        debugPrint('❌ Error switching camera: ${e.message}');
      } else {
        debugPrint('❌ Error switching camera: $e');
      }
      rethrow;
    }
  }
  
  /// Reset prediction state (clear history)
  Future<void> resetPrediction() async {
    if (!isSupportedPlatform) {
      return;
    }

    try {
      await _methodChannel.invokeMethod('resetPrediction');
      debugPrint('🔄 Prediction state reset');
    } catch (e) {
      if (e is PlatformException) {
        debugPrint('❌ Error resetting prediction: ${e.message}');
      } else {
        debugPrint('❌ Error resetting prediction: $e');
      }
      // Non-critical error, don't rethrow
    }
  }
  
  /// Check if using front camera
  Future<bool> isFrontCamera() async {
    if (!isSupportedPlatform) {
      return true;
    }

    try {
      final bool isFront = await _methodChannel.invokeMethod('isFrontCamera');
      return isFront;
    } catch (e) {
      if (e is PlatformException) {
        debugPrint('❌ Error checking camera: ${e.message}');
      } else {
        debugPrint('❌ Error checking camera: $e');
      }
      return true; // Default to front
    }
  }
  
  /// Get continuous stream of detection results
  Stream<DetectionResult> get detectionStream {
    if (!isSupportedPlatform) {
      return Stream<DetectionResult>.error(
        UnsupportedError('Live sign detection is currently available only on Android and iOS.'),
      );
    }

    // Always create a fresh stream to avoid stale data
    _detectionStream = _eventChannel
        .receiveBroadcastStream()
        .map((event) {
          debugPrint('📥 Received event from native: $event');
          final data = Map<String, dynamic>.from(event);
          return DetectionResult.fromMap(data);
        })
        .handleError((error) {
          debugPrint('❌ Stream error: $error');
        });
    
    return _detectionStream!;
  }
  
  /// Check camera permission status
  Future<bool> checkCameraPermission() async {
    if (!isSupportedPlatform) {
      return false;
    }

    try {
      final bool hasPermission =
          await _methodChannel.invokeMethod('checkCameraPermission');
      return hasPermission;
    } catch (e) {
      if (e is PlatformException) {
        debugPrint('❌ Error checking permission: ${e.message}');
      } else {
        debugPrint('❌ Error checking permission: $e');
      }
      return false;
    }
  }
  
  /// Request camera permission
  Future<bool> requestCameraPermission() async {
    if (!isSupportedPlatform) {
      return false;
    }

    try {
      final dynamic result = await _methodChannel.invokeMethod('requestCameraPermission');
      if (result is bool && result) {
        return true;
      }

      for (int i = 0; i < 8; i++) {
        final granted = await checkCameraPermission();
        if (granted) return true;
        await Future.delayed(const Duration(milliseconds: 250));
      }

      return false;
    } catch (e) {
      if (e is PlatformException) {
        debugPrint('❌ Error requesting permission: ${e.message}');
      } else {
        debugPrint('❌ Error requesting permission: $e');
      }
      return false;
    }
  }
}

/// Data class for detection results
class DetectionResult {
  final bool handDetected;
  final String landmarksLog;
  final String detectedSign;
  final double confidence;
  final int timestamp;
  final bool isFrontCamera;
  
  DetectionResult({
    required this.handDetected,
    required this.landmarksLog,
    required this.detectedSign,
    required this.confidence,
    required this.timestamp,
    required this.isFrontCamera,
  });
  
  factory DetectionResult.fromMap(Map<String, dynamic> map) {
    return DetectionResult(
      handDetected: map['handDetected'] as bool? ?? false,
      landmarksLog: map['landmarksLog'] as String? ?? '',
      detectedSign: map['detectedSign'] as String? ?? '',
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.0,
      timestamp: map['timestamp'] as int? ?? 0,
      isFrontCamera: map['isFrontCamera'] as bool? ?? true,
    );
  }
  
  /// Get confidence as percentage string
  String get confidencePercent => '${(confidence * 100).toStringAsFixed(1)}%';
  
  @override
  String toString() {
    return 'DetectionResult(sign: $detectedSign, confidence: $confidencePercent, handDetected: $handDetected)';
  }
}

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
  
  /// Start hand sign detection
  Future<void> startDetection() async {
    try {
      // Reset prediction state before starting
      await resetPrediction();
      await _methodChannel.invokeMethod('startDetection');
      print('✅ Detection started');
    } on PlatformException catch (e) {
      print('❌ Error starting detection: ${e.message}');
      rethrow;
    }
  }
  
  /// Stop hand sign detection
  Future<void> stopDetection() async {
    try {
      _subscription?.cancel();
      _subscription = null;
      _detectionStream = null;
      await _methodChannel.invokeMethod('stopDetection');
      print('✅ Detection stopped');
    } on PlatformException catch (e) {
      print('❌ Error stopping detection: ${e.message}');
      rethrow;
    }
  }
  
  /// Switch between front and back camera
  Future<bool> switchCamera() async {
    try {
      // Reset predictions when switching camera
      await resetPrediction();
      final bool isFrontCamera = await _methodChannel.invokeMethod('switchCamera');
      print('📷 Switched to ${isFrontCamera ? "front" : "back"} camera');
      return isFrontCamera;
    } on PlatformException catch (e) {
      print('❌ Error switching camera: ${e.message}');
      rethrow;
    }
  }
  
  /// Reset prediction state (clear history)
  Future<void> resetPrediction() async {
    try {
      await _methodChannel.invokeMethod('resetPrediction');
      print('🔄 Prediction state reset');
    } on PlatformException catch (e) {
      print('❌ Error resetting prediction: ${e.message}');
      // Non-critical error, don't rethrow
    }
  }
  
  /// Check if using front camera
  Future<bool> isFrontCamera() async {
    try {
      final bool isFront = await _methodChannel.invokeMethod('isFrontCamera');
      return isFront;
    } on PlatformException catch (e) {
      print('❌ Error checking camera: ${e.message}');
      return true; // Default to front
    }
  }
  
  /// Get continuous stream of detection results
  Stream<DetectionResult> get detectionStream {
    // Always create a fresh stream to avoid stale data
    _detectionStream = _eventChannel
        .receiveBroadcastStream()
        .map((event) {
          print('📥 Received event from native: $event');
          final data = Map<String, dynamic>.from(event);
          return DetectionResult.fromMap(data);
        })
        .handleError((error) {
          print('❌ Stream error: $error');
        });
    
    return _detectionStream!;
  }
  
  /// Check camera permission status
  Future<bool> checkCameraPermission() async {
    try {
      final bool hasPermission =
          await _methodChannel.invokeMethod('checkCameraPermission');
      return hasPermission;
    } on PlatformException catch (e) {
      print('❌ Error checking permission: ${e.message}');
      return false;
    }
  }
  
  /// Request camera permission
  Future<bool> requestCameraPermission() async {
    try {
      await _methodChannel.invokeMethod('requestCameraPermission');
      // Wait a bit for permission dialog
      await Future.delayed(const Duration(milliseconds: 500));
      return await checkCameraPermission();
    } on PlatformException catch (e) {
      print('❌ Error requesting permission: ${e.message}');
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

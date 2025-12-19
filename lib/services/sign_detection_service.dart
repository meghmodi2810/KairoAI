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
  
  /// Start hand sign detection
  Future<void> startDetection() async {
    try {
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
      await _methodChannel.invokeMethod('stopDetection');
      print('✅ Detection stopped');
    } on PlatformException catch (e) {
      print('❌ Error stopping detection: ${e.message}');
      rethrow;
    }
  }
  
  /// Get continuous stream of detection results
  Stream<DetectionResult> get detectionStream {
    _detectionStream ??= _eventChannel
        .receiveBroadcastStream()
        .map((event) {
          final data = Map<String, dynamic>.from(event);
          return DetectionResult.fromMap(data);
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
  final int timestamp;
  
  DetectionResult({
    required this.handDetected,
    required this.landmarksLog,
    required this.timestamp,
  });
  
  factory DetectionResult.fromMap(Map<String, dynamic> map) {
    return DetectionResult(
      handDetected: map['handDetected'] as bool,
      landmarksLog: map['landmarksLog'] as String,
      timestamp: map['timestamp'] as int,
    );
  }
  
  @override
  String toString() {
    return 'DetectionResult(handDetected: $handDetected, timestamp: $timestamp)';
  }
}

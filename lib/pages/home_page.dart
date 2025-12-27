import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import '../services/sign_detection_service.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final SignDetectionService _detectionService = SignDetectionService();
  
  // Camera controller for preview (only used when detection is NOT active)
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isCameraInitializing = false;
  
  // Detection state
  bool _isDetectionActive = false;
  bool _handDetected = false;
  bool _isFrontCamera = true;
  String _detectedSign = '';
  double _confidence = 0.0;
  String _landmarkLog = 'Tap "Start Detection" to begin';
  String _statusMessage = 'Ready';
  
  // Stream subscription
  StreamSubscription? _detectionSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCameras();
  }

  Future<void> _initializeCameras() async {
    if (_isCameraInitializing) return;
    _isCameraInitializing = true;
    
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty && !_isDetectionActive) {
        // Find front camera
        final frontCamera = _cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => _cameras.first,
        );
        await _initializeCameraController(frontCamera);
      }
    } catch (e) {
      print('Error initializing cameras: $e');
    } finally {
      _isCameraInitializing = false;
    }
  }

  Future<void> _initializeCameraController(CameraDescription camera) async {
    // Don't initialize Flutter camera if detection is active (native camera is in use)
    if (_isDetectionActive) {
      print('Skipping Flutter camera init - detection is active');
      return;
    }
    
    // Dispose existing controller first - safely
    final oldController = _cameraController;
    _cameraController = null;
    if (mounted) {
      setState(() {
        _isCameraInitialized = false;
      });
    }
    
    if (oldController != null) {
      try {
        await oldController.dispose();
      } catch (e) {
        print('Error disposing old camera: $e');
      }
    }
    
    // Check again after async operation
    if (_isDetectionActive || !mounted) {
      return;
    }
    
    final newController = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await newController.initialize();
      
      // Check if still valid to use this controller
      if (mounted && !_isDetectionActive) {
        _cameraController = newController;
        setState(() {
          _isCameraInitialized = true;
          _isFrontCamera = camera.lensDirection == CameraLensDirection.front;
        });
      } else {
        // If detection started while we were initializing, dispose the new controller
        await newController.dispose();
      }
    } catch (e) {
      print('Error initializing camera controller: $e');
      try {
        await newController.dispose();
      } catch (_) {}
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
        });
      }
    }
  }
  
  Future<void> _disposeFlutterCamera() async {
    // First, mark camera as not initialized to prevent UI from trying to use it
    final controllerToDispose = _cameraController;
    _cameraController = null;
    
    if (mounted) {
      setState(() {
        _isCameraInitialized = false;
      });
    }
    
    // Now safely dispose the old controller
    if (controllerToDispose != null) {
      try {
        await controllerToDispose.dispose();
      } catch (e) {
        print('Error disposing camera: $e');
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopDetection();
    _disposeFlutterCamera();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      // Stop detection and dispose camera when app goes to background
      if (_isDetectionActive) {
        _stopDetection();
      }
      _disposeFlutterCamera();
    } else if (state == AppLifecycleState.resumed) {
      // Reinitialize when app comes back to foreground
      if (!_isDetectionActive && !_isCameraInitialized) {
        _initializeCameras();
      }
    }
  }

  Future<void> _startDetection() async {
    // Check permission
    final hasPermission = await _detectionService.checkCameraPermission();
    
    if (!hasPermission) {
      await _detectionService.requestCameraPermission();
      // Wait for permission result
      await Future.delayed(const Duration(seconds: 1));
      final granted = await _detectionService.checkCameraPermission();
      if (!granted) {
        _showSnackBar('Camera permission is required', Colors.red);
        return;
      }
    }

    try {
      // IMPORTANT: Set detection active FIRST to prevent camera preview from rendering
      if (mounted) {
        setState(() {
          _isDetectionActive = true;
          _statusMessage = 'Starting...';
          _isCameraInitialized = false;  // Immediately mark camera as not initialized
        });
      }
      
      // Now safely dispose Flutter camera
      await _disposeFlutterCamera();
      
      // Small delay to ensure camera is fully released
      await Future.delayed(const Duration(milliseconds: 300));
      
      await _detectionService.startDetection();
      
      if (mounted) {
        setState(() {
          _landmarkLog = 'Detection started - Show your hand!';
          _statusMessage = 'Detection Active';
        });
      }

      // Listen to detection stream
      _detectionSubscription = _detectionService.detectionStream.listen(
        (result) {
          if (mounted) {
            setState(() {
              _handDetected = result.handDetected;
              _detectedSign = result.detectedSign;
              _confidence = result.confidence;
              _landmarkLog = result.landmarksLog;
              _isFrontCamera = result.isFrontCamera;
            });
          }
        },
        onError: (error) {
          print('❌ Detection stream error: $error');
          _showSnackBar('Detection error', Colors.red);
        },
      );

      _showSnackBar('Detection started! Show your hand', Colors.green);
    } catch (e) {
      setState(() {
        _statusMessage = 'Error';
        _isDetectionActive = false;
      });
      _showSnackBar('Error starting detection: $e', Colors.red);
      // Try to reinitialize Flutter camera on error
      _initializeCameras();
    }
  }

  Future<void> _stopDetection() async {
    try {
      _detectionSubscription?.cancel();
      _detectionSubscription = null;
      await _detectionService.stopDetection();
      
      if (mounted) {
        setState(() {
          _isDetectionActive = false;
          _handDetected = false;
          _detectedSign = '';
          _confidence = 0.0;
          _landmarkLog = 'Detection stopped';
          _statusMessage = 'Ready';
        });
        
        // Reinitialize Flutter camera for preview after stopping detection
        await Future.delayed(const Duration(milliseconds: 300));
        await _initializeCameras();
      }
    } catch (e) {
      print('Error stopping detection: $e');
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) {
      _showSnackBar('Only one camera available', Colors.orange);
      return;
    }
    
    try {
      // Switch the detection service camera
      final newIsFrontCamera = await _detectionService.switchCamera();
      
      if (mounted) {
        setState(() {
          _isFrontCamera = newIsFrontCamera;
        });
      }
      
      _showSnackBar(
        'Switched to ${newIsFrontCamera ? "front" : "back"} camera',
        const Color(0xFF9C7DD6),
      );
    } catch (e) {
      _showSnackBar('Error switching camera: $e', Colors.red);
    }
  }

  Future<void> _signOut() async {
    await _stopDetection();
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F1EB),
      appBar: AppBar(
        title: const Text('KairoAI - Sign Detection'),
        backgroundColor: const Color(0xFF9C7DD6),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Status indicator
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _isDetectionActive ? Colors.green : Colors.grey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _statusMessage,
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
              ),
            ),
          ),
          // Sign out button
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: Column(
        children: [
          // Main detection display area
          Expanded(
            flex: 2,
            child: _buildDetectionDisplay(),
          ),
          
          // Detected sign display
          _buildSignDisplay(),
          
          // Landmark logs
          Expanded(
            flex: 2,
            child: _buildLandmarkLogs(),
          ),
          
          // Control buttons
          _buildControlButtons(),
        ],
      ),
    );
  }

  Widget _buildDetectionDisplay() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Camera preview or detection active indicator
            if (_isDetectionActive)
              // When detection is active, show detection animation (native camera is processing)
              Container(
                color: Colors.black87,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated detection indicator
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.8, end: 1.2),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeInOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Icon(
                              _handDetected ? Icons.front_hand : Icons.videocam,
                              size: 80,
                              color: _handDetected ? Colors.green : const Color(0xFF9C7DD6),
                            ),
                          );
                        },
                        onEnd: () {
                          // This creates a continuous animation
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _handDetected 
                            ? '🖐️ Hand Detected!'
                            : '📷 Detection Active',
                        style: TextStyle(
                          color: _handDetected ? Colors.green : const Color(0xFF9C7DD6),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _handDetected 
                            ? 'Processing sign language...'
                            : 'Show your hand to the camera',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Camera indicator
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isFrontCamera ? Icons.camera_front : Icons.camera_rear,
                              color: Colors.white54,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _isFrontCamera ? 'Front Camera' : 'Back Camera',
                              style: const TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (_isCameraInitialized && _cameraController != null && _cameraController!.value.isInitialized)
              Center(
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..scale(_isFrontCamera ? -1.0 : 1.0, 1.0, 1.0), // Mirror front camera
                  child: Builder(
                    builder: (context) {
                      // Extra safety check before building camera preview
                      try {
                        if (_cameraController == null || !_cameraController!.value.isInitialized) {
                          return const SizedBox.shrink();
                        }
                        return CameraPreview(_cameraController!);
                      } catch (e) {
                        print('Error building camera preview: $e');
                        return const SizedBox.shrink();
                      }
                    },
                  ),
                ),
              )
            else
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.videocam_off,
                      size: 80,
                      color: Colors.white30,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _cameras.isEmpty 
                          ? '📷 No camera available'
                          : '📷 Initializing camera...',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            
            // Detection status overlay (only when not detecting but camera is ready)
            if (!_isDetectionActive && _isCameraInitialized)
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.play_circle_outline,
                        color: Colors.white54,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Tap Start to begin detection',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            // Hand detection indicator when detecting
            if (_isDetectionActive && _handDetected)
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Hand Detected',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            
            // Camera switch button (only when detection is active)
            if (_isDetectionActive && _cameras.length > 1)
              Positioned(
                top: 12,
                right: 12,
                child: IconButton(
                  onPressed: _switchCamera,
                  icon: Icon(
                    _isFrontCamera ? Icons.camera_front : Icons.camera_rear,
                    color: Colors.white,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black45,
                  ),
                  tooltip: 'Switch Camera',
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignDisplay() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _handDetected && _detectedSign.isNotEmpty
              ? [const Color(0xFF9C7DD6), const Color(0xFF7B5FB8)]
              : [Colors.grey.shade300, Colors.grey.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (_handDetected ? const Color(0xFF9C7DD6) : Colors.grey)
                .withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Detected sign letter
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _detectedSign.isEmpty ? '?' : _detectedSign,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: _handDetected
                      ? const Color(0xFF9C7DD6)
                      : Colors.grey.shade400,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          
          // Sign info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _handDetected && _detectedSign.isNotEmpty
                      ? 'Detected Sign'
                      : 'Waiting for Sign',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _detectedSign.isEmpty
                      ? 'Show your hand'
                      : 'Letter: $_detectedSign',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Confidence bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Confidence: ${(_confidence * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _confidence.clamp(0.0, 1.0),
                        backgroundColor: Colors.white30,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _confidence > 0.7
                              ? Colors.greenAccent
                              : _confidence > 0.4
                                  ? Colors.yellowAccent
                                  : Colors.redAccent,
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLandmarkLogs() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                const Icon(Icons.code, size: 18, color: Color(0xFF9C7DD6)),
                const SizedBox(width: 8),
                const Text(
                  'Detection Log',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF9C7DD6),
                  ),
                ),
                const Spacer(),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isDetectionActive ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Text(
                _landmarkLog,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: Colors.grey.shade800,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Start/Stop button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isDetectionActive ? _stopDetection : _startDetection,
              icon: Icon(_isDetectionActive ? Icons.stop : Icons.play_arrow),
              label: Text(_isDetectionActive ? 'Stop Detection' : 'Start Detection'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isDetectionActive
                    ? Colors.red.shade400
                    : const Color(0xFF9C7DD6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Camera switch button - only enabled during detection
          ElevatedButton(
            onPressed: _isDetectionActive && _cameras.length > 1 ? _switchCamera : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9C7DD6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              disabledBackgroundColor: Colors.grey.shade300,
            ),
            child: Icon(
              _isFrontCamera ? Icons.camera_rear : Icons.camera_front,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}

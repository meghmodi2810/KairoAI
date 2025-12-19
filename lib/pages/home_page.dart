import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/sign_detection_service.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SignDetectionService _detectionService = SignDetectionService();
  bool _isCameraActive = false;
  bool _handDetected = false;
  String _landmarkLog = 'No hand detected';
  
  @override
  void dispose() {
    if (_isCameraActive) {
      _detectionService.stopDetection();
    }
    super.dispose();
  }

  Future<void> _startDetection() async {
    // Request camera permission first
    final hasPermission = await _detectionService.checkCameraPermission();
    
    if (!hasPermission) {
      final granted = await _detectionService.requestCameraPermission();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Camera permission is required for hand detection'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    // Start detection
    try {
      await _detectionService.startDetection();
      setState(() {
        _isCameraActive = true;
      });

      // Listen to detection stream
      _detectionService.detectionStream.listen((result) {
        if (mounted) {
          setState(() {
            _handDetected = result.handDetected;
            if (result.handDetected) {
              _landmarkLog = result.landmarksLog;
            } else {
              _landmarkLog = 'No hand detected';
            }
          });
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera started! Show your hand'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting camera: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopDetection() async {
    try {
      await _detectionService.stopDetection();
      setState(() {
        _isCameraActive = false;
        _handDetected = false;
        _landmarkLog = 'No hand detected';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera stopped'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error stopping camera: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F1EB),
      appBar: AppBar(
        title: const Text('KairoAI - Hand Detection'),
        backgroundColor: const Color(0xFF9C7DD6),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Camera Frame
            Expanded(
              flex: 3,
              child: Container(
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _handDetected ? Colors.green : const Color(0xFF9C7DD6),
                    width: 4,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isCameraActive 
                                  ? (_handDetected ? Icons.check_circle : Icons.videocam)
                                  : Icons.videocam_off,
                              size: 80,
                              color: _isCameraActive 
                                  ? (_handDetected ? Colors.green : Colors.white54)
                                  : Colors.white24,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              _isCameraActive 
                                  ? (_handDetected ? 'Hand Detected!' : 'Show your hand')
                                  : 'Camera Preview',
                              style: TextStyle(
                                color: _isCameraActive 
                                    ? (_handDetected ? Colors.green : Colors.white70)
                                    : Colors.white38,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Status indicator
                      if (_isCameraActive)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.fiber_manual_record, color: Colors.white, size: 12),
                                SizedBox(width: 4),
                                Text(
                                  'LIVE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Landmark Logs Section
            Expanded(
              flex: 2,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.data_object, color: Color(0xFF9C7DD6)),
                        const SizedBox(width: 8),
                        const Text(
                          'Hand Landmarks (x, y, z)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E2A38),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SingleChildScrollView(
                          child: Text(
                            _landmarkLog,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Control Button
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isCameraActive ? _stopDetection : _startDetection,
                  icon: Icon(
                    _isCameraActive ? Icons.stop : Icons.play_arrow,
                    size: 28,
                  ),
                  label: Text(
                    _isCameraActive ? 'Stop Camera' : 'Start Hand Detection',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isCameraActive 
                        ? Colors.red 
                        : const Color(0xFF9C7DD6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

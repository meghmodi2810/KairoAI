import 'dart:async';
import 'package:flutter/material.dart';
import '../services/sign_detection_service.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../models/admin_models.dart';
import '../models/app_models.dart';
import '../theme/neo_brutal_widgets.dart';

class WordPracticePage extends StatefulWidget {
  final String groupId;
  final WordModel wordModel;

  const WordPracticePage({
    super.key,
    required this.groupId,
    required this.wordModel,
  });

  @override
  State<WordPracticePage> createState() => _WordPracticePageState();
}

class _WordPracticePageState extends State<WordPracticePage> with WidgetsBindingObserver {
  final SignDetectionService _detectionService = SignDetectionService();
  final DatabaseService _db = DatabaseService();

  StreamSubscription<DetectionResult>? _subscription;
  DetectionResult? _result;

  bool _detecting = false;
  bool _loading = true;
  bool _hasPermission = false;
  bool _frontCamera = true;
  
  int _activeCharIndex = 0;
  int _matchCount = 0;
  bool _isCompleted = false;

  static const int _requiredMatches = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopDetection();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _stopDetection();
    }
    if (state == AppLifecycleState.resumed && _hasPermission && !_isCompleted) {
      _startDetection();
    }
  }

  Future<void> _initialize() async {
    bool allowed = await _detectionService.checkCameraPermission();
    if (!allowed) {
      allowed = await _detectionService.requestCameraPermission();
    }

    if (!mounted) return;
    setState(() {
      _hasPermission = allowed;
      _loading = false;
    });

    if (allowed) {
      await _startDetection();
    }
  }

  Future<void> _startDetection({bool retryOnFail = true}) async {
    if (_detecting) return;
    try {
      setState(() => _loading = true);
      await _detectionService.startDetection();
      _frontCamera = await _detectionService.isFrontCamera();

      _subscription = _detectionService.detectionStream.listen(
        (data) {
          if (!mounted || _isCompleted) return;
          setState(() {
            _result = data;
            _loading = false;
            _detecting = true;
          });

          final targetChar = widget.wordModel.characters[_activeCharIndex].char.toUpperCase();

          if (data.handDetected &&
              data.detectedSign.toUpperCase() == targetChar &&
              data.confidence > 0.6) {
            _matchCount++;
            if (_matchCount >= _requiredMatches) {
              _handleCharacterMatch();
            }
          }
        },
        onError: (error) {
          if (!mounted) return;
          setState(() {
            _loading = false;
            _detecting = false;
          });
        },
      );

      if (!mounted) return;
      setState(() {
        _loading = false;
        _detecting = true;
      });
    } catch (e) {
      if (retryOnFail && _hasPermission) {
        await Future.delayed(const Duration(milliseconds: 260));
        if (!mounted) return;
        await _startDetection(retryOnFail: false);
        return;
      }
      if (!mounted) return;
      setState(() {
        _loading = false;
        _detecting = false;
      });
    }
  }

  Future<void> _stopDetection() async {
    await _subscription?.cancel();
    _subscription = null;
    try {
      await _detectionService.stopDetection();
    } catch (_) {}
    if (!mounted) return;
    setState(() => _detecting = false);
  }

  Future<void> _switchCamera() async {
    try {
      final value = await _detectionService.switchCamera();
      if (!mounted) return;
      setState(() {
        _frontCamera = value;
      });
    } catch (e) {}
  }

  void _handleCharacterMatch() {
    setState(() {
      _matchCount = 0;
      _activeCharIndex++;
    });

    if (_activeCharIndex >= widget.wordModel.characters.length) {
      _handleWordCompleted();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Great! Now sign ${widget.wordModel.characters[_activeCharIndex].char}'),
          backgroundColor: AppTheme.mintGreen,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _handleWordCompleted() async {
    setState(() => _isCompleted = true);
    await _stopDetection();
    
    // Save progress and give rewards
    final xp = widget.wordModel.characters.length * 10;
    final coins = widget.wordModel.characters.length * 5;

    await _db.updateWordProgress(WordProgressModel(
      wordId: widget.wordModel.id,
      groupId: widget.groupId,
      status: 'completed',
      lastPracticedAt: DateTime.now(),
      firstCompletedAt: DateTime.now(),
      lastAccuracy: 100.0,
      attemptsCount: 1,
    ));

    await _db.grantWordCompletionReward(
      xpEarned: xp,
      coinsEarned: coins,
      gemsEarned: 0,
    );

    await _db.saveWordPracticeLog({
      'contextType': 'word',
      'groupId': widget.groupId,
      'wordId': widget.wordModel.id,
      'accuracy': 100.0,
      'durationSecs': 0, // Could track time taken
    });

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => _buildCompletionSheet(xp, coins),
    );
  }

  Widget _buildCompletionSheet(int xp, int coins) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppTheme.paperCream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppTheme.inkBlack, width: 3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.star_rounded, color: AppTheme.signalYellow, size: 64),
          const SizedBox(height: 16),
          Text(
            'Word Completed!',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppTheme.inkBlack,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            widget.wordModel.text,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.electricBlue,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              NeoSticker(label: '+$xp XP', icon: Icons.flash_on, color: AppTheme.mintGreen),
              const SizedBox(width: 12),
              NeoSticker(label: '+$coins COINS', icon: Icons.monetization_on, color: AppTheme.signalYellow),
            ],
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.inkBlack,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context); // Close sheet
              Navigator.pop(context); // Close practice page
            },
            child: const Text('Continue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Color _confidenceColor(double confidence) {
    if (confidence > 0.7) return AppTheme.mintGreen;
    if (confidence > 0.4) return AppTheme.signalYellow;
    return AppTheme.punchRed;
  }

  @override
  Widget build(BuildContext context) {
    final confidence = _result?.confidence ?? 0;
    final confidenceColor = _confidenceColor(confidence);
    final targetChar = _isCompleted ? '' : widget.wordModel.characters[_activeCharIndex].char.toUpperCase();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: _detecting && _detectionService.textureId != null
                ? Align(
                    alignment: Alignment.topCenter,
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: 480,
                        height: 640,
                        child: Texture(textureId: _detectionService.textureId!),
                      ),
                    ),
                  )
                : const ColoredBox(color: Colors.black),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      _circleButton(
                        icon: Icons.close_rounded,
                        onTap: () {
                          _stopDetection();
                          Navigator.pop(context);
                        },
                      ),
                      const Spacer(),
                      _circleButton(
                        icon: Icons.cameraswitch_rounded,
                        onTap: _switchCamera,
                        background: AppTheme.electricBlue,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Word Display
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: List.generate(widget.wordModel.characters.length, (index) {
                      final isCompleted = index < _activeCharIndex;
                      final isActive = index == _activeCharIndex;
                      final char = widget.wordModel.characters[index].char.toUpperCase();
                      
                      return Container(
                        width: 48,
                        height: 56,
                        decoration: BoxDecoration(
                          color: isCompleted 
                              ? AppTheme.mintGreen 
                              : isActive ? AppTheme.signalYellow : AppTheme.warmWhite,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isActive ? Colors.white : AppTheme.inkBlack, 
                            width: isActive ? 4 : 2
                          ),
                          boxShadow: [
                            BoxShadow(color: AppTheme.inkBlack, offset: Offset(isActive ? 4 : 2, isActive ? 4 : 2)),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          char,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.inkBlack,
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
          if (_loading || !_hasPermission)
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.warmWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.inkBlack, width: 3),
                  boxShadow: const [
                    BoxShadow(color: AppTheme.inkBlack, blurRadius: 0, offset: Offset(6, 6)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_loading)
                      const CircularProgressIndicator(color: AppTheme.cobaltBlue)
                    else
                      const Icon(Icons.no_photography_rounded, color: AppTheme.inkBlack, size: 46),
                    const SizedBox(height: 10),
                    Text(
                      _loading
                          ? 'Starting camera...'
                          : 'Need camera access to practice.',
                      style: const TextStyle(
                        color: AppTheme.inkBlack,
                        fontWeight: FontWeight.w900,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (!_loading && !_hasPermission) ...[
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: _initialize,
                        icon: const Icon(Icons.camera_alt_rounded),
                        label: const Text('Grant Permission'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          if (!_isCompleted)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: EdgeInsets.fromLTRB(12, 10, 12, MediaQuery.of(context).padding.bottom + 10),
                decoration: BoxDecoration(
                  color: AppTheme.warmWhite,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  border: Border.all(color: AppTheme.inkBlack, width: 3),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.electricBlue,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.inkBlack, width: 2),
                          ),
                          child: Text(
                            'NOW SIGN: $targetChar',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          (_result?.handDetected ?? false) ? Icons.front_hand : Icons.pan_tool_alt,
                          color: (_result?.handDetected ?? false) ? AppTheme.mintGreen : AppTheme.punchRed,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          (_result?.handDetected ?? false) ? 'Hand detected' : 'Show hand',
                          style: const TextStyle(
                            color: AppTheme.inkBlack,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 12,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.inkBlack, width: 2),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: confidence,
                                backgroundColor: AppTheme.paperCream,
                                valueColor: AlwaysStoppedAnimation<Color>(confidenceColor),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(confidence * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: AppTheme.inkBlack,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        ...List.generate(
                          _requiredMatches,
                          (i) => Expanded(
                            child: Container(
                              margin: EdgeInsets.only(right: i == _requiredMatches - 1 ? 0 : 6),
                              height: 12,
                              decoration: BoxDecoration(
                                color: i < _matchCount ? AppTheme.mintGreen : AppTheme.paperCream,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.inkBlack, width: 2),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
    Color background = AppTheme.warmWhite,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.inkBlack, width: 3),
          boxShadow: const [
            BoxShadow(color: AppTheme.inkBlack, blurRadius: 0, offset: Offset(3, 3)),
          ],
        ),
        child: Icon(icon, color: AppTheme.inkBlack),
      ),
    );
  }
}

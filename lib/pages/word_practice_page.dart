import 'dart:async';
import 'package:flutter/material.dart';
import '../services/sign_detection_service.dart';
import '../services/database_service.dart';
import '../services/sign_image_service.dart';
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
  final SignImageService _imageService = SignImageService();

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
    final allowed = await _detectionService.checkCameraPermission();

    if (!mounted) return;
    setState(() {
      _hasPermission = allowed;
      _loading = false;
    });

    if (allowed) {
      await _startDetection();
    }
  }

  Future<void> _requestCameraPermission() async {
    setState(() => _loading = true);
    final allowed = await _detectionService.requestCameraPermission();
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

  String _currentTargetChar() {
    if (widget.wordModel.characters.isEmpty) return '';
    if (_isCompleted) return '';
    return widget.wordModel.characters[_activeCharIndex].char.toUpperCase();
  }

  Widget _buildSignMedia(String resolvedRef) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.asset(
        resolvedRef,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            _buildSignPlaceholder(_currentTargetChar()),
      ),
    );
  }

  Widget _buildSignPlaceholder(String char) {
    return Center(
      child: Text(
        char,
        style: TextStyle(
          color: AppTheme.cobaltBlue.withValues(alpha: 0.45),
          fontWeight: FontWeight.w900,
          fontSize: 96,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final charCount = widget.wordModel.characters.length;
    final confidence = _result?.confidence ?? 0;
    final confidenceColor = _confidenceColor(confidence);
    final targetChar = _currentTargetChar();
    final progress = charCount == 0 ? 0.0 : (_activeCharIndex + 1) / charCount;
    final stepLabel = charCount == 0 ? '0/0' : '${_activeCharIndex + 1}/$charCount';

    if (charCount == 0) {
      return Scaffold(
        backgroundColor: AppTheme.paperCream,
        body: NeoEmptyState(
          icon: Icons.text_fields,
          title: 'No Characters Found',
          subtitle: 'This word has no valid sign characters.',
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.paperCream,
      body: SafeArea(
        child: Column(
          children: [
            if (_detecting && _detectionService.textureId != null)
              SizedBox(
                width: 1,
                height: 1,
                child: Opacity(
                  opacity: 0,
                  child: Texture(textureId: _detectionService.textureId!),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      _stopDetection();
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.warmWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.inkBlack, width: 3),
                        boxShadow: const [
                          BoxShadow(
                            color: AppTheme.inkBlack,
                            blurRadius: 0,
                            offset: Offset(3, 3),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.arrow_back_rounded, color: AppTheme.inkBlack),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: NeoPanel(
                      color: AppTheme.warmWhite,
                      radius: 14,
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      shadow: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.wordModel.text,
                            style: const TextStyle(
                              color: AppTheme.inkBlack,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 8,
                              backgroundColor: AppTheme.paperCream,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppTheme.cobaltBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    stepLabel,
                    style: const TextStyle(
                      color: AppTheme.inkBlack,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _circleButton(
                    icon: Icons.cameraswitch_rounded,
                    onTap: _switchCamera,
                    background: AppTheme.electricBlue,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                child: NeoPanel(
                  color: AppTheme.warmWhite,
                  radius: 18,
                  child: Column(
                    children: [
                      Text(
                        targetChar,
                        style: const TextStyle(
                          color: AppTheme.inkBlack,
                          fontSize: 46,
                          height: 1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppTheme.paperCream,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.inkBlack, width: 3),
                          ),
                          child: FutureBuilder<String?>(
                            future: _imageService.resolveImageRefForWord(targetChar),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(
                                    color: AppTheme.cobaltBlue,
                                  ),
                                );
                              }

                              final resolvedRef = (snapshot.data ?? '').trim();
                              if (resolvedRef.isNotEmpty) {
                                return _buildSignMedia(resolvedRef);
                              }

                              return _buildSignPlaceholder(targetChar);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.signalYellow,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.inkBlack, width: 2),
                        ),
                        child: Text(
                          'STEP $stepLabel',
                          style: const TextStyle(
                            color: AppTheme.inkBlack,
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_isCompleted)
              const SizedBox(height: 16)
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
                child: _loading || !_hasPermission
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
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
                                onPressed: _requestCameraPermission,
                                icon: const Icon(Icons.camera_alt_rounded),
                                label: const Text('Grant Permission'),
                              ),
                            ],
                          ],
                        ),
                      )
                    : Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.warmWhite,
                          borderRadius: BorderRadius.circular(16),
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
                                  (_result?.handDetected ?? false)
                                      ? Icons.front_hand
                                      : Icons.pan_tool_alt,
                                  color: (_result?.handDetected ?? false)
                                      ? AppTheme.mintGreen
                                      : AppTheme.punchRed,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  (_result?.handDetected ?? false)
                                      ? 'Hand detected'
                                      : 'Show hand',
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
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          confidenceColor,
                                        ),
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
                                      margin: EdgeInsets.only(
                                        right: i == _requiredMatches - 1 ? 0 : 6,
                                      ),
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: i < _matchCount
                                            ? AppTheme.mintGreen
                                            : AppTheme.paperCream,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppTheme.inkBlack,
                                          width: 2,
                                        ),
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

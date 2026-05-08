import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive;
import '../theme/app_theme.dart';
import '../theme/neo_brutal_widgets.dart';

enum KairoCoachPose { idle, wave, point, nudge, celebrate, thinking }

class KairoCoachOverlay extends StatelessWidget {
  final Widget child;
  final bool visible;
  final GlobalKey? targetKey;
  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final bool showSkip;
  final VoidCallback? onSkip;
  final KairoCoachPose pose;
  final bool blockOutsideTouches;

  const KairoCoachOverlay({
    super.key,
    required this.child,
    required this.visible,
    required this.title,
    required this.message,
    required this.primaryLabel,
    this.targetKey,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.showSkip = false,
    this.onSkip,
    this.pose = KairoCoachPose.idle,
    this.blockOutsideTouches = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (visible)
          Positioned.fill(
            child: _CoachLayer(
              targetKey: targetKey,
              title: title,
              message: message,
              primaryLabel: primaryLabel,
              onPrimary: onPrimary,
              secondaryLabel: secondaryLabel,
              onSecondary: onSecondary,
              showSkip: showSkip,
              onSkip: onSkip,
              pose: pose,
              blockOutsideTouches: blockOutsideTouches,
            ),
          ),
      ],
    );
  }
}

class KairoCoachPortal {
  static OverlayEntry show({
    required BuildContext context,
    required String title,
    required String message,
    required String primaryLabel,
    required VoidCallback onPrimary,
    GlobalKey? targetKey,
    String? secondaryLabel,
    VoidCallback? onSecondary,
    bool showSkip = false,
    VoidCallback? onSkip,
    KairoCoachPose pose = KairoCoachPose.idle,
  }) {
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _CoachLayer(
        targetKey: targetKey,
        title: title,
        message: message,
        primaryLabel: primaryLabel,
        onPrimary: onPrimary,
        secondaryLabel: secondaryLabel,
        onSecondary: onSecondary,
        showSkip: showSkip,
        onSkip: onSkip,
        pose: pose,
        blockOutsideTouches: true,
      ),
    );
    Overlay.of(context).insert(entry);
    return entry;
  }
}

class _CoachLayer extends StatefulWidget {
  final GlobalKey? targetKey;
  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final bool showSkip;
  final VoidCallback? onSkip;
  final KairoCoachPose pose;
  final bool blockOutsideTouches;

  const _CoachLayer({
    required this.targetKey,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.onSecondary,
    required this.showSkip,
    required this.onSkip,
    required this.pose,
    required this.blockOutsideTouches,
  });

  @override
  State<_CoachLayer> createState() => _CoachLayerState();
}

class _CoachLayerState extends State<_CoachLayer> {
  Rect? _targetRect;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureTarget());
  }

  @override
  void didUpdateWidget(covariant _CoachLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetKey != widget.targetKey) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _measureTarget());
    }
  }

  void _measureTarget() {
    final targetContext = widget.targetKey?.currentContext;
    if (targetContext == null || !mounted) {
      setState(() => _targetRect = null);
      return;
    }

    final box = targetContext.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      setState(() => _targetRect = null);
      return;
    }

    final offset = box.localToGlobal(Offset.zero);
    setState(() {
      _targetRect = offset & box.size;
    });
  }

  @override
  Widget build(BuildContext context) {
    final safe = MediaQuery.of(context).padding;
    final target = _targetRect;
    final bubbleTop = target == null
        ? null
        : target.center.dy > MediaQuery.of(context).size.height * 0.55;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: AbsorbPointer(
              absorbing: widget.blockOutsideTouches,
              child: CustomPaint(
                painter: _CoachScrimPainter(targetRect: target),
              ),
            ),
          ),
          if (target != null)
            Positioned.fromRect(
              rect: target.inflate(8),
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.signalYellow, width: 4),
                    boxShadow: AppTheme.hardShadow(
                      color: AppTheme.signalYellow.withValues(alpha: 0.65),
                      offset: 0,
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            left: 14,
            right: 14,
            top: bubbleTop == true ? safe.top + 14 : null,
            bottom: bubbleTop == true ? null : safe.bottom + 18,
            child: _CoachBubble(
              title: widget.title,
              message: widget.message,
              primaryLabel: widget.primaryLabel,
              onPrimary: widget.onPrimary,
              secondaryLabel: widget.secondaryLabel,
              onSecondary: widget.onSecondary,
              showSkip: widget.showSkip,
              onSkip: widget.onSkip,
              pose: widget.pose,
            ),
          ),
        ],
      ),
    );
  }
}

class _CoachScrimPainter extends CustomPainter {
  final Rect? targetRect;

  const _CoachScrimPainter({required this.targetRect});

  @override
  void paint(Canvas canvas, Size size) {
    final fullPath = Path()..addRect(Offset.zero & size);
    final target = targetRect;
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.64);

    if (target == null) {
      canvas.drawPath(fullPath, paint);
      return;
    }

    final cutout = Path()
      ..addRRect(
        RRect.fromRectAndRadius(target.inflate(10), const Radius.circular(18)),
      );
    final path = Path.combine(PathOperation.difference, fullPath, cutout);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CoachScrimPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect;
  }
}

class _CoachBubble extends StatelessWidget {
  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final bool showSkip;
  final VoidCallback? onSkip;
  final KairoCoachPose pose;

  const _CoachBubble({
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.onSecondary,
    required this.showSkip,
    required this.onSkip,
    required this.pose,
  });

  @override
  Widget build(BuildContext context) {
    return NeoPanel(
      color: AppTheme.warmWhite,
      radius: 20,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 84, height: 96, child: KairoCoachMascot(pose: pose)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.inkBlack,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  message,
                  style: const TextStyle(
                    color: AppTheme.inkBlack,
                    fontSize: 13,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (showSkip)
                      TextButton(onPressed: onSkip, child: const Text('Skip')),
                    if (secondaryLabel != null) ...[
                      if (!showSkip) const Spacer(),
                      TextButton(
                        onPressed: onSecondary,
                        child: Text(secondaryLabel!),
                      ),
                    ] else if (showSkip)
                      const Spacer()
                    else
                      const Spacer(),
                    ElevatedButton(
                      onPressed: onPrimary,
                      child: Text(primaryLabel),
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
}

class KairoCoachMascot extends StatefulWidget {
  final KairoCoachPose pose;

  const KairoCoachMascot({super.key, this.pose = KairoCoachPose.idle});

  @override
  State<KairoCoachMascot> createState() => _KairoCoachMascotState();
}

class _KairoCoachMascotState extends State<KairoCoachMascot> {
  late final rive.FileLoader _fileLoader;

  @override
  void initState() {
    super.initState();
    _fileLoader = rive.FileLoader.fromAsset(
      'assets/mascot/kairo_coach.riv',
      riveFactory: rive.Factory.rive,
    );
  }

  @override
  void dispose() {
    _fileLoader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return rive.RiveWidgetBuilder(
      fileLoader: _fileLoader,
      builder: (context, state) => switch (state) {
        rive.RiveLoaded() => rive.RiveWidget(
          controller: state.controller,
          fit: rive.Fit.contain,
        ),
        rive.RiveLoading() => _FallbackMascot(pose: widget.pose),
        rive.RiveFailed() => _FallbackMascot(pose: widget.pose),
      },
    );
  }
}

class _FallbackMascot extends StatelessWidget {
  final KairoCoachPose pose;

  const _FallbackMascot({required this.pose});

  @override
  Widget build(BuildContext context) {
    final icon = switch (pose) {
      KairoCoachPose.wave => Icons.waving_hand_rounded,
      KairoCoachPose.point => Icons.pan_tool_alt_rounded,
      KairoCoachPose.nudge => Icons.touch_app_rounded,
      KairoCoachPose.celebrate => Icons.celebration_rounded,
      KairoCoachPose.thinking => Icons.psychology_rounded,
      KairoCoachPose.idle => Icons.auto_awesome_rounded,
    };

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.signalYellow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.inkBlack, width: 3),
        boxShadow: AppTheme.hardShadow(offset: 3),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Padding(
            padding: const EdgeInsets.all(7),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: Image.asset(
                'assets/logo/main_logo.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Icon(icon, color: AppTheme.inkBlack, size: 34),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppTheme.electricBlue,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.inkBlack, width: 2),
              ),
              child: Icon(icon, color: AppTheme.inkBlack, size: 17),
            ),
          ),
        ],
      ),
    );
  }
}

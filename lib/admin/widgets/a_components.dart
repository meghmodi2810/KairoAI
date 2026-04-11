import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:kairo_ai/admin/theme/admin_theme.dart';
import 'package:kairo_ai/admin/widgets/a_inputs.dart';

enum AdminTagVariant { active, banned, draft, live, inactive, pending, custom }

class AdminCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? radius;
  final Color? color;
  final bool showBorder;
  final bool showShadow;

  const AdminCard({
    super.key,
    required this.child,
    this.padding,
    this.radius,
    this.color,
    this.showBorder = true,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final c = ac(context);
    return Container(
      padding: padding ?? const EdgeInsets.all(cardPad),
      decoration: BoxDecoration(
        color: color ?? c.bgSurface,
        borderRadius: BorderRadius.circular(radius ?? radiusCard),
        border: showBorder ? Border.all(color: c.border, width: 2.5) : null,
        boxShadow: showShadow ? [
          const BoxShadow(
            color: Color(0xFF111111),
            offset: Offset(5, 5),
            blurRadius: 0,
          ),
        ] : null,
      ),
      child: child,
    );
  }
}

class AdminTag extends StatelessWidget {
  final String label;
  final AdminTagVariant variant;
  final Color? customBg;
  final Color? customText;

  const AdminTag({
    super.key,
    required this.label,
    this.variant = AdminTagVariant.active,
    this.customBg,
    this.customText,
  });

  @override
  Widget build(BuildContext context) {
    final c = ac(context);
    Color bg, text;

    switch (variant) {
      case AdminTagVariant.active:
        bg = c.successFill;
        text = c.successText;
      case AdminTagVariant.banned:
        bg = c.errorFill;
        text = c.errorText;
      case AdminTagVariant.draft:
        bg = c.warningFill;
        text = c.warningText;
      case AdminTagVariant.live:
        bg = c.accentFill2;
        text = c.isDark ? c.accentBright : c.accent;
      case AdminTagVariant.inactive:
        bg = c.bgSurface3;
        text = c.textMuted;
      case AdminTagVariant.pending:
        bg = c.warningFill;
        text = c.warningText;
      case AdminTagVariant.custom:
        bg = customBg ?? c.bgSurface3;
        text = customText ?? c.textMuted;
    }

    return Container(
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radiusTag),
        border: Border.all(color: c.isDark ? dBorder : lBorder, width: 1.5),
      ),
      child: Center(
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: text,
            letterSpacing: 0.02,
          ),
        ),
      ),
    );
  }
}

class AdminSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AdminSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final c = ac(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(rowPadH, 14, rowPadH, 6),
      decoration: BoxDecoration(
        color: c.bgBase,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: adminLabel(c.textMuted),
            ),
          ),
          if (actionLabel != null && onAction != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionLabel!,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: c.isDark ? c.accentBright : c.accent,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class AdminRow extends StatefulWidget {
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;
  final bool isLast;
  final double minHeight;

  const AdminRow({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showChevron = false,
    this.isLast = false,
    this.minHeight = 44, // Matched to HTML row heights
  });

  @override
  State<AdminRow> createState() => _AdminRowState();
}

class _AdminRowState extends State<AdminRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final c = ac(context);
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        constraints: BoxConstraints(minHeight: widget.minHeight),
        padding: const EdgeInsets.symmetric(
          horizontal: rowPadH,
          vertical: rowPadV,
        ),
        decoration: BoxDecoration(
          color: _pressed ? c.bgSurface3 : c.bgSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(color: c.border, width: 1.5),
            right: BorderSide(color: c.border, width: 1.5),
            top: BorderSide(color: c.border, width: 1.5),
            bottom: widget.isLast
                ? BorderSide(color: c.border, width: 1.5)
                : BorderSide(color: c.border, width: 1),
          ),
        ),
        child: Row(
          children: [
            if (widget.leading != null) ...[
              widget.leading!,
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.title != null) widget.title!,
                  if (widget.subtitle != null) ...[
                    const SizedBox(height: 1),
                    widget.subtitle!,
                  ],
                ],
              ),
            ),
            if (widget.trailing != null) ...[
              const SizedBox(width: 8),
              widget.trailing!,
            ],
            if (widget.showChevron) ...[
              const SizedBox(width: 4),
              Icon(
                LucideIcons.chevronRight,
                size: 12,
                color: ac(context).textMuted,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AdminStatStrip extends StatelessWidget {
  final List<AdminStat> stats;

  const AdminStatStrip({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final c = ac(context);
    return Container(
      decoration: BoxDecoration(
        color: c.bgSurface,
        border: Border.all(color: c.border, width: 2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color(0xFF111111), blurRadius: 0, offset: Offset(4, 4)),
        ],
      ),
      child: Row(
        children: stats.asMap().entries.map((e) {
          final i = e.key;
          final stat = e.value;
          return Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                border: i < stats.length - 1
                    ? Border(right: BorderSide(color: c.border))
                    : null,
              ),
              child: _StatCell(stat: stat),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class AdminStat {
  final String label;
  final String value;
  final double? delta;
  final VoidCallback? onTap;

  const AdminStat({
    required this.label,
    required this.value,
    this.delta,
    this.onTap,
  });
}

class _StatCell extends StatelessWidget {
  final AdminStat stat;
  const _StatCell({required this.stat});

  @override
  Widget build(BuildContext context) {
    final c = ac(context);
    return GestureDetector(
      onTap: stat.onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(stat.value, style: statValue(c.textPrimary)),
          const SizedBox(height: 2),
          Text(
            stat.label.toUpperCase(),
            style: adminLabel(c.textMuted),
          ),
          if (stat.delta != null) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  stat.delta! >= 0
                      ? LucideIcons.trendingUp
                      : LucideIcons.trendingDown,
                  size: 10,
                  color: stat.delta! >= 0 ? c.success : c.error,
                ),
                const SizedBox(width: 2),
                Text(
                  stat.delta!.abs().toStringAsFixed(0),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: stat.delta! >= 0 ? c.success : c.error,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class AdminProgressBar extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final double height;
  final Color? color;

  const AdminProgressBar({
    super.key,
    required this.value,
    this.height = 3,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = ac(context);
    final clampedValue = value.clamp(0.0, 1.0);
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        return Container(
          height: height,
          width: totalWidth,
          decoration: BoxDecoration(
            color: c.bgSurface3,
            borderRadius: BorderRadius.circular(radiusPill),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
              height: height,
              width: totalWidth * clampedValue,
              decoration: BoxDecoration(
                color: color ??
                    (clampedValue >= 1.0
                        ? c.success
                        : (c.isDark ? c.accentBright : c.accent)),
                borderRadius: BorderRadius.circular(radiusPill),
              ),
            ),
          ),
        );
      },
    );
  }
}

class AdminSkeletonLoader extends StatefulWidget {
  final List<AdminSkeletonRow> rows;

  const AdminSkeletonLoader({super.key, required this.rows});

  static AdminSkeletonLoader listRows({int count = 5}) {
    return AdminSkeletonLoader(
      rows: List.generate(
        count,
        (i) => AdminSkeletonRow(
          leading: true,
          titleWidth: 0.6 + (i % 3) * 0.1,
          subtitleWidth: 0.4 + (i % 2) * 0.1,
        ),
      ),
    );
  }

  @override
  State<AdminSkeletonLoader> createState() => _AdminSkeletonLoaderState();
}

class AdminSkeletonRow {
  final bool leading;
  final double titleWidth;
  final double subtitleWidth;
  const AdminSkeletonRow({
    this.leading = false,
    this.titleWidth = 0.6,
    this.subtitleWidth = 0.4,
  });
}

class _AdminSkeletonLoaderState extends State<AdminSkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
    _shimmer = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = ac(context);
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, child) {
        return Column(
          children: widget.rows.map((row) {
            return _SkeletonRowWidget(
              row: row,
              shimmerValue: _shimmer.value,
              baseColor: c.bgSurface3,
              shimmerColor: c.border2,
            );
          }).toList(),
        );
      },
    );
  }
}

class _SkeletonRowWidget extends StatelessWidget {
  final AdminSkeletonRow row;
  final double shimmerValue;
  final Color baseColor;
  final Color shimmerColor;

  const _SkeletonRowWidget({
    required this.row,
    required this.shimmerValue,
    required this.baseColor,
    required this.shimmerColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: ac(context).border)),
      ),
      child: Row(
        children: [
          if (row.leading) ...[
            _shimmerBox(32, 32, circular: true),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    return _shimmerBox(
                      constraints.maxWidth * row.titleWidth,
                      14,
                    );
                  },
                ),
                const SizedBox(height: 6),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return _shimmerBox(
                      constraints.maxWidth * row.subtitleWidth,
                      11,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _shimmerBox(double width, double height, {bool circular = false}) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) {
        return LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            baseColor,
            shimmerColor,
            baseColor,
          ],
          stops: [
            (shimmerValue - 1).clamp(0.0, 1.0),
            shimmerValue.clamp(0.0, 1.0),
            (shimmerValue + 1).clamp(0.0, 1.0),
          ],
        ).createShader(bounds);
      },
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(
            circular ? height / 2 : 4,
          ),
        ),
      ),
    );
  }
}

class AdminBarChart extends StatefulWidget {
  final List<double> values;
  final List<String> labels;
  final double height;
  final int? highlightIndex;

  const AdminBarChart({
    super.key,
    required this.values,
    required this.labels,
    this.height = 120,
    this.highlightIndex,
  });

  @override
  State<AdminBarChart> createState() => _AdminBarChartState();
}

class _AdminBarChartState extends State<AdminBarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _progress;
  int? _tappedIndex;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _progress = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = ac(context);
    if (widget.values.isEmpty) return const SizedBox.shrink();

    final maxVal = widget.values.reduce((a, b) => a > b ? a : b);
    if (maxVal <= 0) return const SizedBox.shrink();

    final highlightIdx = _tappedIndex ??
        widget.highlightIndex ??
        (widget.values.length - 1);

    return SizedBox(
      height: widget.height + 30,
      child: AnimatedBuilder(
        animation: _progress,
        builder: (context, child) {
          return Column(
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: widget.values.asMap().entries.map((e) {
                    final i = e.key;
                    final v = e.value;
                    final frac = (v / maxVal) * _progress.value;
                    final isHighlight = i == highlightIdx;
                    
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _tappedIndex = i),
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (_tappedIndex == i) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: c.isDark ? c.bgSurface3 : c.bgSurface,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: c.border2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    v.toInt().toString(),
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: c.textPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                              ],
                              Container(
                                height: (widget.height * frac).clamp(4.0, widget.height),
                                decoration: BoxDecoration(
                                  color: isHighlight
                                      ? (c.isDark ? c.accentBright : c.accent)
                                      : c.accentFill.withValues(alpha: 0.6),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: widget.labels.map((l) {
                  return Expanded(
                    child: Text(
                      l,
                      textAlign: TextAlign.center,
                      style: adminMeta(c.textMuted),
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class AdminEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AdminEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final c = ac(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: c.textMuted),
            const SizedBox(height: 12),
            Text(title, style: adminH3(c.textPrimary), textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(body, style: adminBody(c.textSecondary), textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              AdminButton(
                label: actionLabel!,
                onTap: onAction,
                variant: AdminButtonVariant.accent,
                fullWidth: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AdminErrorState extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;

  const AdminErrorState({super.key, this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final c = ac(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.alertTriangle, size: 28, color: c.error),
            const SizedBox(height: 12),
            Text('Something went wrong', style: adminH3(c.textPrimary)),
            const SizedBox(height: 4),
            Text(
              message ?? 'Could not load data. Try again.',
              style: adminBody(c.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              AdminButton(
                label: 'Try again',
                onTap: onRetry,
                variant: AdminButtonVariant.secondary,
                fullWidth: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

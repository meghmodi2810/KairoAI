import 'package:flutter/material.dart';
import 'app_theme.dart';

class NeoPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final double radius;
  final bool shadow;
  final double shadowOffset;

  const NeoPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.radius = 16,
    this.shadow = true,
    this.shadowOffset = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? context.card,
        borderRadius: BorderRadius.circular(radius),
        border: context.neoBorder,
        boxShadow: shadow
            ? AppTheme.hardShadow(
                color: context.isDark ? Colors.white : AppTheme.inkBlack,
                offset: shadowOffset,
              )
            : null,
      ),
      child: child,
    );
  }
}

class NeoCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final VoidCallback? onTap;
  final double radius;

  const NeoCard({
    super.key,
    required this.child,
    this.color,
    this.onTap,
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: NeoPanel(
        padding: EdgeInsets.zero,
        color: color,
        radius: radius,
        child: child,
      ),
    );
  }
}

class NeoSectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const NeoSectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: context.textMuted,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class NeoSticker extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final double rotation;

  const NeoSticker({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.rotation = -0.05,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.inkBlack, width: 3),
          boxShadow: AppTheme.hardShadow(offset: 4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: AppTheme.inkBlack),
              const SizedBox(width: 8),
            ],
            Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppTheme.inkBlack,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class NeoButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? textColor;
  final IconData? icon;
  final bool loading;
  final EdgeInsetsGeometry padding;

  const NeoButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color,
    this.textColor,
    this.icon,
    this.loading = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 24),
  });

  @override
  State<NeoButton> createState() => _NeoButtonState();
}

class _NeoButtonState extends State<NeoButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final double translateOffset = _isPressed ? 6 : 0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: Matrix4.translationValues(translateOffset, translateOffset, 0),
        decoration: BoxDecoration(
          color: widget.color ?? (context.isDark ? AppTheme.cobaltBlue : AppTheme.cobaltBlue),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: context.isDark ? Colors.white : AppTheme.inkBlack,
            width: 3,
          ),
          boxShadow: _isPressed
              ? null
              : [
                  BoxShadow(
                    color: context.isDark ? Colors.white : AppTheme.inkBlack,
                    offset: const Offset(6, 6),
                    blurRadius: 0,
                  ),
                ],
        ),
        child: Container(
          height: 56,
          padding: widget.padding,
          child: Center(
            child: widget.loading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, color: widget.textColor ?? Colors.white),
                        const SizedBox(width: 10),
                      ],
                      Text(
                        widget.label.toUpperCase(),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: widget.textColor ?? Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class NeoTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final String? hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;

  const NeoTextField({
    super.key,
    this.controller,
    required this.label,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: context.isDark ? AppTheme.charcoalNight : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: context.isDark ? Colors.white : AppTheme.inkBlack,
              width: 3,
            ),
            boxShadow: AppTheme.hardShadow(
              color: context.isDark ? Colors.white : AppTheme.inkBlack,
              offset: 4,
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: AppTheme.inkBlack) : null,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}

class NeoPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  const NeoPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return NeoButton(
      label: label,
      onPressed: onPressed,
      loading: loading,
      icon: icon,
      color: AppTheme.cobaltBlue,
      textColor: Colors.white,
    );
  }
}

class NeoSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  const NeoSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return NeoButton(
      label: label,
      onPressed: onPressed,
      loading: loading,
      icon: icon,
      color: AppTheme.paperCream,
      textColor: AppTheme.inkBlack,
    );
  }
}

class NeoEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const NeoEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: NeoPanel(
          color: AppTheme.warmWhite,
          radius: 18,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.signalYellow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.inkBlack, width: 3),
                ),
                child: Icon(icon, size: 34, color: AppTheme.inkBlack),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.inkBlack,
                      fontWeight: FontWeight.w900,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.inkBlack.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w700,
                    ),
                textAlign: TextAlign.center,
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 14),
                NeoPrimaryButton(
                  label: actionLabel!,
                  onPressed: onAction,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}


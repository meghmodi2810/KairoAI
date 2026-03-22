import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:kairo_ai/admin/theme/admin_theme.dart';

enum AdminButtonVariant { primary, secondary, accent, destructive, ghost }

class AdminSegmentedControl<T> extends StatelessWidget {
  final List<AdminSegmentedOption<T>> options;
  final T selectedValue;
  final Function(T) onSelected;

  const AdminSegmentedControl({
    super.key,
    required this.options,
    required this.selectedValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final c = ac(context);
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: c.bgSurface2,
        borderRadius: BorderRadius.circular(radiusCard), // Even if 0, it follows the token
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: options.map((opt) {
          final isSelected = opt.value == selectedValue;
          final isLast = options.indexOf(opt) == options.length - 1;

          return Expanded(
            child: GestureDetector(
              onTap: () => onSelected(opt.value),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected ? c.accentFill : Colors.transparent,
                  border: isLast ? null : Border(right: BorderSide(color: c.border)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      opt.icon,
                      size: 18,
                      color: isSelected ? (c.isDark ? c.accentBright : c.accent) : c.textMuted,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      opt.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? (c.isDark ? c.accentBright : c.accent) : c.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class AdminSegmentedOption<T> {
  final String label;
  final T value;
  final IconData icon;

  const AdminSegmentedOption({
    required this.label,
    required this.value,
    required this.icon,
  });
}

class AdminButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final AdminButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;
  final double height;

  const AdminButton({
    super.key,
    required this.label,
    this.onTap,
    this.variant = AdminButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.fullWidth = true,
    this.height = 40,
  });

  @override
  State<AdminButton> createState() => _AdminButtonState();
}

class _AdminButtonState extends State<AdminButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 130),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleTapDown(_) {
    if (widget.onTap != null && !widget.isLoading) _ctrl.forward();
  }

  void _handleTapUp(_) {
    _ctrl.reverse();
  }

  void _handleTapCancel() {
    _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final c = ac(context);
    final disabled = (widget.onTap == null) && !widget.isLoading;

    Color bg, fg;
    Border? border;

    switch (widget.variant) {
      case AdminButtonVariant.primary:
        bg = c.btnPrimary;
        fg = c.btnPrimaryFg;
      case AdminButtonVariant.secondary:
        bg = c.btnSecondary;
        fg = c.btnSecondaryFg;
        border = Border.all(color: c.border2);
      case AdminButtonVariant.accent:
        bg = c.accent;
        fg = Colors.white;
      case AdminButtonVariant.destructive:
        bg = c.error;
        fg = Colors.white;
      case AdminButtonVariant.ghost:
        bg = Colors.transparent;
        fg = (c.isDark ? c.accentBright : c.accent);
    }

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!widget.isLoading && widget.icon != null) ...[
          Icon(widget.icon, size: 14, color: fg),
          const SizedBox(width: 6),
        ],
        if (widget.isLoading)
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
          )
        else
          Text(
            widget.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: disabled ? fg.withValues(alpha: 0.4) : fg,
              letterSpacing: -0.1,
            ),
          ),
      ],
    );

    Widget button = GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.isLoading ? null : widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
        child: AnimatedOpacity(
          opacity: disabled ? 0.4 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: Container(
            height: widget.variant == AdminButtonVariant.ghost ? null : widget.height,
            padding: widget.variant == AdminButtonVariant.ghost
                ? const EdgeInsets.symmetric(vertical: 8, horizontal: 8)
                : const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(radiusBtn),
              border: border,
            ),
            child: Center(child: content),
          ),
        ),
      ),
    );

    if (widget.fullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}

class AdminInput extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final int maxLines;
  final String? errorText;
  final String? helperText;
  final Widget? prefix;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final bool autofocus;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final int? maxLength;

  const AdminInput({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.errorText,
    this.helperText,
    this.prefix,
    this.suffix,
    this.onChanged,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
    this.textInputAction,
    this.maxLength,
  });

  @override
  State<AdminInput> createState() => _AdminInputState();
}

class _AdminInputState extends State<AdminInput> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) setState(() => _isFocused = _focusNode.hasFocus);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = ac(context);
    final hasError = widget.errorText != null;

    Color borderColor;
    Color labelColor;
    if (hasError) {
      borderColor = c.error;
      labelColor = c.error;
    } else if (_isFocused) {
      borderColor = c.isDark ? c.accentBright : c.accent;
      labelColor = c.isDark ? c.accentBright : c.accent;
    } else {
      borderColor = c.border3;
      labelColor = c.textMuted;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label.toUpperCase(),
          style: adminLabel(labelColor),
        ),
        const SizedBox(height: 6),
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radiusInput),
            border: Border.all(
              color: borderColor,
              width: _isFocused || hasError ? 1.5 : 1.0,
            ),
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            maxLines: widget.obscureText ? 1 : widget.maxLines,
            onChanged: widget.onChanged,
            enabled: widget.enabled,
            autofocus: widget.autofocus,
            textInputAction: widget.textInputAction,
            style: adminBody(c.textPrimary),
            maxLength: widget.maxLength,
            decoration: InputDecoration(
              counterText: '', // Hide default counter for cleaner Stripe look
              hintText: widget.hint,
              hintStyle: adminBody(c.textMuted),
              filled: true,
              fillColor: c.bgSurface2, // Slightly lighter than base usually
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              prefixIcon: widget.prefix,
              suffixIcon: widget.suffix,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(LucideIcons.alertCircle, size: 12, color: c.error),
              const SizedBox(width: 4),
              Text(widget.errorText!, style: adminBodySm(c.error)),
            ],
          ),
        ] else if (widget.helperText != null) ...[
          const SizedBox(height: 4),
          Text(widget.helperText!, style: adminBodySm(c.textMuted)),
        ],
      ],
    );
  }
}

class AdminSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  const AdminSearchBar({
    super.key,
    required this.controller,
    this.hint = 'Search...',
    this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final c = ac(context);
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: c.bgSurface2,
        borderRadius: BorderRadius.circular(radiusInput),
        border: Border.all(color: c.border2),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: adminBody(c.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: adminBody(c.textMuted),
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Icon(LucideIcons.search, size: 14, color: c.textMuted),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          suffixIcon: controller.text.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    controller.clear();
                    onClear?.call();
                    onChanged?.call('');
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(LucideIcons.x, size: 14, color: c.textMuted),
                  ),
                )
              : null,
          suffixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }
}

class AdminFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const AdminFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = ac(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? c.accentFill : c.bgSurface2,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? (c.isDark ? c.accentBright : c.accent) : c.border2,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: selected
                  ? (c.isDark ? c.accentBright : c.accent)
                  : c.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// Admin Portal Theme Constants – kept for backward compatibility
/// New code should prefer Theme.of(context).colorScheme
class AdminTheme {
  // Kept as fallback aliases – prefer colorScheme in new code
  static const Color primaryDark = Color(0xFF1A1F38);
  static const Color primaryBlue = Color(0xFF1A2151);
  static const Color darkBlue = Color(0xFF0D1333);
  static const Color cardBg = Color(0xFF252A5E);
  static const Color cardBgLight = Color(0xFF2E3468);
  static const Color accentYellow = Color(0xFFFFD93D);
  static const Color accentPink = Color(0xFFFF6B9D);
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color accentRed = Color(0xFFE53935);
  static const Color accentOrange = Color(0xFFFF9800);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB0B8C4);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF2196F3);
  static const Color inputBorder = Color(0xFF3D4470);

  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;

  /// Legacy ThemeData – used by pages not yet migrated to colorScheme
  static ThemeData get theme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: primaryDark,
    colorScheme: const ColorScheme.dark(
      primary: accentYellow,
      secondary: accentPink,
      surface: cardBg,
      error: error,
    ),
    appBarTheme: const AppBarTheme(backgroundColor: primaryDark, elevation: 0),
    cardColor: cardBg,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cardBg,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(borderRadiusMedium), borderSide: const BorderSide(color: inputBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(borderRadiusMedium), borderSide: const BorderSide(color: inputBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(borderRadiusMedium), borderSide: const BorderSide(color: accentYellow)),
      labelStyle: const TextStyle(color: textSecondary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(backgroundColor: accentYellow, foregroundColor: primaryDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadiusMedium))),
    ),
  );
}

/// Reusable Admin Card Widget
class AdminCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? color;
  final VoidCallback? onTap;

  const AdminCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: AdminTheme.spacingMd),
      decoration: BoxDecoration(
        color: color ?? cs.surface,
        borderRadius: BorderRadius.circular(AdminTheme.borderRadiusMedium),
        border: Border.all(color: cs.onSurface.withOpacity(0.06)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AdminTheme.borderRadiusMedium),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(AdminTheme.spacingMd),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Stat Card Widget
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final String? subtitle;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = iconColor ?? cs.primary;
    return AdminCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AdminTheme.borderRadiusSmall),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: AdminTheme.spacingMd),
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: cs.onSurface)),
          const SizedBox(height: AdminTheme.spacingXs),
          Text(title, style: TextStyle(fontSize: 14, color: cs.onSurface.withOpacity(0.55))),
          if (subtitle != null) ...[
            const SizedBox(height: AdminTheme.spacingXs),
            Text(subtitle!, style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.4))),
          ],
        ],
      ),
    );
  }
}

/// Status Badge Widget
class StatusBadge extends StatelessWidget {
  final String status;
  final Color? color;
  final bool small;

  const StatusBadge({
    super.key,
    required this.status,
    this.color,
    this.small = false,
  });

  Color _getStatusColor() {
    if (color != null) return color!;
    
    switch (status.toLowerCase()) {
      case 'active':
      case 'completed':
      case 'resolved':
      case 'success':
        return AdminTheme.success;
      case 'pending':
      case 'in-progress':
      case 'in_progress':
      case 'warning':
        return AdminTheme.warning;
      case 'inactive':
      case 'new':
      case 'open':
        return AdminTheme.info;
      case 'failed':
      case 'error':
      case 'critical':
      case 'closed':
        return AdminTheme.error;
      default:
        return AdminTheme.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 12,
        vertical: small ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AdminTheme.borderRadiusSmall),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(
          color: statusColor,
          fontSize: small ? 10 : 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Loading Overlay Widget
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black54,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(cs.primary)),
                  if (message != null) ...[
                    const SizedBox(height: AdminTheme.spacingMd),
                    Text(message!, style: TextStyle(color: cs.onSurface, fontSize: 16)),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Empty State Widget
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AdminTheme.spacingXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: cs.onSurface.withOpacity(0.25)),
            const SizedBox(height: AdminTheme.spacingMd),
            Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: cs.onSurface), textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: AdminTheme.spacingSm),
              Text(subtitle!, style: TextStyle(fontSize: 14, color: cs.onSurface.withOpacity(0.5)), textAlign: TextAlign.center),
            ],
            if (action != null) ...[
              const SizedBox(height: AdminTheme.spacingLg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Confirmation Dialog
class AdminConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final Color? confirmColor;
  final bool isDangerous;

  const AdminConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    this.confirmColor,
    this.isDangerous = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: cs.onSurface)),
      content: Text(message, style: TextStyle(color: cs.onSurface.withOpacity(0.6))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(cancelText)),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            backgroundColor: confirmColor ?? (isDangerous ? Colors.red : cs.primary),
          ),
          child: Text(confirmText),
        ),
      ],
    );
  }

  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    Color? confirmColor,
    bool isDangerous = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AdminConfirmDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        confirmColor: confirmColor,
        isDangerous: isDangerous,
      ),
    );
    return result ?? false;
  }
}

/// Search Bar Widget
class AdminSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  const AdminSearchBar({
    super.key,
    required this.controller,
    this.hintText = 'Search...',
    this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(Icons.search, color: cs.onSurface.withOpacity(0.35)),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.clear, color: cs.onSurface.withOpacity(0.35)),
                onPressed: () {
                  controller.clear();
                  onClear?.call();
                },
              )
            : null,
        filled: true,
        fillColor: cs.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// Admin Portal Theme Constants
class AdminTheme {
  // Primary Colors
  static const Color primaryDark = Color(0xFF1A1F38);
  static const Color primaryBlue = Color(0xFF1A2151);
  static const Color darkBlue = Color(0xFF141938);
  static const Color cardBg = Color(0xFF252A5E);
  static const Color cardBgLight = Color(0xFF2D3461);
  
  // Accent Colors
  static const Color accentYellow = Color(0xFFFFD93D);
  static const Color accentPink = Color(0xFFFF6B9D);
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color accentRed = Color(0xFFE53935);
  static const Color accentOrange = Color(0xFFFF9800);
  static const Color accentPurple = Color(0xFF9C27B0);
  
  // Text Colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB0B8C4);
  static const Color textMuted = Color(0xFF6B7280);
  
  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF2196F3);
  
  // Input/Form Colors
  static const Color inputBg = Color(0xFF252A5E);
  static const Color inputBorder = Color(0xFF3D4470);
  static const Color inputFocusBorder = accentYellow;
  static const Color cardBorder = Color(0xFF3D4470);
  
  // Shadow
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.2),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];
  
  // Border Radius
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
  
  // Spacing
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;

  // Get ThemeData for admin portal
  static ThemeData get theme {
    return ThemeData(
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: primaryDark,
      fontFamily: 'Roboto',
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: accentYellow,
        secondary: accentPink,
        surface: cardBg,
        error: error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryBlue,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusSmall),
          borderSide: const BorderSide(color: inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusSmall),
          borderSide: const BorderSide(color: inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusSmall),
          borderSide: const BorderSide(color: inputFocusBorder, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusSmall),
          borderSide: const BorderSide(color: error),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentYellow,
          foregroundColor: primaryDark,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusSmall),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentYellow,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentYellow,
          side: const BorderSide(color: accentYellow),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusSmall),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentYellow,
        foregroundColor: primaryDark,
      ),
      dividerTheme: const DividerThemeData(
        color: inputBorder,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cardBg,
        contentTextStyle: const TextStyle(color: textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusSmall),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: cardBg,
        selectedItemColor: accentYellow,
        unselectedItemColor: textSecondary,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: accentYellow,
        unselectedLabelColor: textSecondary,
        indicatorColor: accentYellow,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: cardBgLight,
        selectedColor: accentYellow,
        labelStyle: const TextStyle(color: textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusSmall),
        ),
      ),
    );
  }
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
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: AdminTheme.spacingMd),
      decoration: BoxDecoration(
        color: color ?? AdminTheme.cardBg,
        borderRadius: BorderRadius.circular(AdminTheme.borderRadiusMedium),
        boxShadow: AdminTheme.cardShadow,
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
    return AdminCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (iconColor ?? AdminTheme.accentYellow).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AdminTheme.borderRadiusSmall),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? AdminTheme.accentYellow,
                  size: 24,
                ),
              ),
              const Spacer(),
              if (onTap != null)
                const Icon(
                  Icons.arrow_forward_ios,
                  color: AdminTheme.textMuted,
                  size: 16,
                ),
            ],
          ),
          const SizedBox(height: AdminTheme.spacingMd),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AdminTheme.textPrimary,
            ),
          ),
          const SizedBox(height: AdminTheme.spacingXs),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: AdminTheme.textSecondary,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AdminTheme.spacingXs),
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 12,
                color: AdminTheme.textMuted,
              ),
            ),
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
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AdminTheme.accentYellow),
                  ),
                  if (message != null) ...[
                    const SizedBox(height: AdminTheme.spacingMd),
                    Text(
                      message!,
                      style: const TextStyle(
                        color: AdminTheme.textPrimary,
                        fontSize: 16,
                      ),
                    ),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AdminTheme.spacingXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: AdminTheme.textMuted,
            ),
            const SizedBox(height: AdminTheme.spacingMd),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AdminTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AdminTheme.spacingSm),
              Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: 14,
                  color: AdminTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
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
    return AlertDialog(
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: AdminTheme.textPrimary,
        ),
      ),
      content: Text(
        message,
        style: const TextStyle(color: AdminTheme.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelText),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor ?? (isDangerous ? AdminTheme.error : AdminTheme.accentYellow),
            foregroundColor: AdminTheme.textPrimary,
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
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search, color: AdminTheme.textMuted),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: AdminTheme.textMuted),
                onPressed: () {
                  controller.clear();
                  onClear?.call();
                },
              )
            : null,
      ),
    );
  }
}

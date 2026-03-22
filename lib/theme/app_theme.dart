import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// KairoAI Design System — Linear/Vercel-inspired dark-first aesthetic.
/// Electric violet accent, deep navy surfaces, hairline borders, glow shadows.
class AppTheme {
  // ─────────────────────────────────────────────
  //  Brand Palette
  // ─────────────────────────────────────────────
  static const Color accent       = Color(0xFF6C63FF); // Electric violet
  static const Color accentLight  = Color(0xFF9B94FF);
  static const Color accentDark   = Color(0xFF4B44CC);
  static const Color accentGlow   = Color(0x336C63FF); // 20% opacity glow

  // Semantic gamification colors (kept for data, not for UI chrome)
  static const Color success      = Color(0xFF4ADE80);
  static const Color warning      = Color(0xFFFBBF24);
  static const Color danger       = Color(0xFFF87171);
  static const Color info         = Color(0xFF60A5FA);
  static const Color purple       = Color(0xFFA78BFA);
  static const Color gold         = Color(0xFFF59E0B);

  // Legacy aliases so existing screens compile without changes
  static const Color primaryIndigo  = accent;
  static const Color primaryDark    = accentDark;
  static const Color accentAmber    = warning;
  static const Color accentGreen    = success;
  static const Color accentPink     = danger;
  static const Color accentBlue     = info;
  static const Color gemPurple      = purple;
  static const Color coinGold       = gold;
  static const Color errorRed       = danger;
  static const Color successGreen   = success;

  // Dark surface tokens
  static const Color surfaceDark    = Color(0xFF0D0D12);
  static const Color cardDark       = Color(0xFF14141C);
  static const Color cardAltDark    = Color(0xFF1A1A26);
  static const Color borderDark     = Color(0xFF252530);
  static const Color textPrimaryDark   = Color(0xFFF0F0FF);
  static const Color textSecondaryDark = Color(0xFF8888A8);
  static const Color textMutedDark     = Color(0xFF50506A);

  // Light surface tokens
  static const Color surfaceLight_    = Color(0xFFF8F8FE);
  static const Color cardLight_       = Color(0xFFFFFFFF);
  static const Color cardAltLight     = Color(0xFFF1F1F9);
  static const Color borderLight      = Color(0xFFE4E4F0);
  static const Color textPrimaryLight   = Color(0xFF12121E);
  static const Color textSecondaryLight = Color(0xFF5C5C7A);
  static const Color textMutedLight     = Color(0xFFA0A0B8);

  // Legacy static aliases used in old screens
  static const Color surface      = cardDark;
  static const Color surfaceLight = cardAltDark;
  static const Color cardLight    = Color(0xFFFFFFFF);
  static const Color textPrimary  = textPrimaryDark;
  static const Color textSecondary = textSecondaryDark;
  static const Color textMuted    = textMutedDark;
  static const Color dividerColor = borderDark;

  // ─────────────────────────────────────────────
  //  Gradients
  // ─────────────────────────────────────────────
  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF9B94FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─────────────────────────────────────────────
  //  Category accent colors (zigzag path nodes)
  // ─────────────────────────────────────────────
  static const List<Color> categoryColors = [
    Color(0xFF6C63FF), // violet
    Color(0xFF10B981), // emerald
    Color(0xFFF59E0B), // amber
    Color(0xFFEF4444), // red
    Color(0xFF3B82F6), // blue
    Color(0xFFA78BFA), // purple
    Color(0xFF14B8A6), // teal
    Color(0xFFF97316), // orange
  ];

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [accent, accentDark],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient warmGradient = LinearGradient(
    colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient darkSurface = LinearGradient(
    colors: [Color(0xFF0D0D12), Color(0xFF12121E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ─────────────────────────────────────────────
  //  Shadows & Glows
  // ─────────────────────────────────────────────
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.25),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> accentGlowShadow = [
    BoxShadow(
      color: accent.withOpacity(0.35),
      blurRadius: 24,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> lightCardShadow = [
    BoxShadow(
      color: const Color(0xFF6C63FF).withOpacity(0.06),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  // ─────────────────────────────────────────────
  //  Typography helpers
  // ─────────────────────────────────────────────
  static TextStyle heading1(BuildContext context) => TextStyle(
    color: context.textPrimary,
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static TextStyle heading2(BuildContext context) => TextStyle(
    color: context.textPrimary,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    height: 1.3,
  );

  static TextStyle body(BuildContext context) => TextStyle(
    color: context.textSecondary,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle label(BuildContext context) => TextStyle(
    color: context.textSecondary,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
  );

  // ─────────────────────────────────────────────
  //  DARK THEME
  // ─────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: surfaceDark,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        onPrimary: Colors.white,
        secondary: warning,
        onSecondary: Colors.white,
        surface: cardDark,
        onSurface: textPrimaryDark,
        error: danger,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          color: textPrimaryDark,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: textSecondaryDark),
      ),
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderDark, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimaryDark,
          side: const BorderSide(color: borderDark, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardAltDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderDark, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderDark, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: danger, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: danger, width: 1.5),
        ),
        hintStyle: const TextStyle(
          color: textMutedDark,
          fontWeight: FontWeight.w400,
          fontSize: 15,
        ),
        labelStyle: const TextStyle(color: textSecondaryDark),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      dividerTheme: const DividerThemeData(color: borderDark, thickness: 1),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: accent,
        linearTrackColor: borderDark,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cardAltDark,
        contentTextStyle: const TextStyle(color: textPrimaryDark, fontSize: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: borderDark),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderDark),
        ),
        elevation: 0,
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  LIGHT THEME
  // ─────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: surfaceLight_,
      colorScheme: const ColorScheme.light(
        primary: accent,
        onPrimary: Colors.white,
        secondary: warning,
        onSecondary: Colors.white,
        surface: cardLight_,
        onSurface: textPrimaryLight,
        error: danger,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceLight_,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          color: textPrimaryLight,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: textSecondaryLight),
      ),
      cardTheme: CardThemeData(
        color: cardLight_,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderLight, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimaryLight,
          side: const BorderSide(color: borderLight, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardAltLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderLight, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderLight, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: danger, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: danger, width: 1.5),
        ),
        hintStyle: const TextStyle(
          color: textMutedLight,
          fontWeight: FontWeight.w400,
          fontSize: 15,
        ),
        labelStyle: const TextStyle(color: textSecondaryLight),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      dividerTheme: const DividerThemeData(color: borderLight, thickness: 1),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: accent,
        linearTrackColor: borderLight,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cardLight_,
        contentTextStyle: const TextStyle(color: textPrimaryLight, fontSize: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: borderLight),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardLight_,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderLight),
        ),
        elevation: 0,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Context extension — access theme-aware colors from any widget
// ─────────────────────────────────────────────────────────────────
extension AppColors on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  // Surfaces
  Color get surface    => isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight_;
  Color get card       => isDark ? AppTheme.cardDark : AppTheme.cardLight_;
  Color get cardAlt    => isDark ? AppTheme.cardAltDark : AppTheme.cardAltLight;

  // Text
  Color get textPrimary   => isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight;
  Color get textSecondary => isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight;
  Color get textMuted     => isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight;

  // Borders
  Color get divider => isDark ? AppTheme.borderDark : AppTheme.borderLight;
  Color get border  => isDark ? AppTheme.borderDark : AppTheme.borderLight;

  // Always-accent
  Color get accent => AppTheme.accent;
}

// ─────────────────────────────────────────────────────────────────
//  Reusable widget helpers
// ─────────────────────────────────────────────────────────────────

/// A card built with the new design system tokens.
class KairoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final VoidCallback? onTap;
  final bool glowAccent;
  final BorderRadius? borderRadius;

  const KairoCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.onTap,
    this.glowAccent = false,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final bg = color ?? context.card;
    final br = borderRadius ?? BorderRadius.circular(16);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: br,
          border: Border.all(color: context.border, width: 1),
          boxShadow: glowAccent ? AppTheme.accentGlowShadow : AppTheme.cardShadow,
        ),
        child: ClipRRect(
          borderRadius: br,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              splashColor: AppTheme.accent.withOpacity(0.08),
              highlightColor: AppTheme.accent.withOpacity(0.04),
              child: Padding(
                padding: padding ?? const EdgeInsets.all(16),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Primary CTA button with gradient fill.
class KairoPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double? width;

  const KairoPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: onPressed != null
              ? AppTheme.accentGradient
              : LinearGradient(
                  colors: [
                    AppTheme.accent.withOpacity(0.4),
                    AppTheme.accentLight.withOpacity(0.4),
                  ],
                ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: onPressed != null ? AppTheme.accentGlowShadow : null,
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 18),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Secondary outlined button.
class KairoSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const KairoSecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: context.border, width: 1),
          foregroundColor: context.textPrimary,
          backgroundColor: context.cardAlt,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(context.textSecondary),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// A small badge / chip.
class KairoBadge extends StatelessWidget {
  final String label;
  final Color color;

  const KairoBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

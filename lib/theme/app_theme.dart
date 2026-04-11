import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// KairoAI neo-brutalist learner theme.
/// High-contrast, tactile surfaces with bold outlines and hard offset shadows.
class AppTheme {
  // Core brand palette (Neo-Brutalist)
  static const Color inkBlack = Color(0xFF111111);
  static const Color paperCream = Color(0xFFFFF7E8);
  static const Color electricBlue = Color(0xFF58B9FF);
  static const Color signalYellow = Color(0xFFFFD84D);
  static const Color punchRed = Color(0xFFFF6B57);
  static const Color mintGreen = Color(0xFF78E8A0);
  static const Color cobaltBlue = Color(0xFF3559FF);
  static const Color softPeach = Color(0xFFFFC8A2);
  static const Color warmWhite = Color(0xFFFFFCF7);
  static const Color charcoalNight = Color(0xFF171717);

  // Status Colors (Semantic but Flat)
  static const Color success = mintGreen;
  static const Color warning = signalYellow;
  static const Color danger = punchRed;
  static const Color info = electricBlue;

  static const List<Color> categoryColors = [
    electricBlue,
    mintGreen,
    signalYellow,
    punchRed,
    cobaltBlue,
    softPeach,
    Color(0xFFFFB38A), // Extra playful orange
    Color(0xFFB599FF), // Playful purple
  ];

  static const Radius _radius12 = Radius.circular(12);
  static const Radius _radius16 = Radius.circular(16);
  static const Radius _radius20 = Radius.circular(20);

  // Borders & Shadows
  static BorderSide neoBorderSide([double width = 3, Color? color]) => BorderSide(
        color: color ?? inkBlack,
        width: width,
      );

  static List<BoxShadow> hardShadow({
    Color color = inkBlack,
    double offset = 6,
  }) =>
      [
        BoxShadow(
          color: color,
          offset: Offset(offset, offset),
          blurRadius: 0,
          spreadRadius: 0,
        ),
      ];

  static TextTheme _learnerTextTheme(TextTheme base) {
    return base.copyWith(
      // Headings: Archivo Black (Poster-like)
      displayLarge: GoogleFonts.archivoBlack(
        fontSize: 48,
        height: 1.0,
        letterSpacing: -1.0,
        color: inkBlack,
      ),
      displayMedium: GoogleFonts.archivoBlack(
        fontSize: 38,
        height: 1.05,
        letterSpacing: -0.5,
        color: inkBlack,
      ),
      headlineLarge: GoogleFonts.archivoBlack(
        fontSize: 32,
        height: 1.1,
        color: inkBlack,
      ),
      headlineMedium: GoogleFonts.archivoBlack(
        fontSize: 26,
        height: 1.1,
        color: inkBlack,
      ),
      // Body: Space Grotesk (Personality-rich)
      titleLarge: GoogleFonts.spaceGrotesk(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: inkBlack,
      ),
      titleMedium: GoogleFonts.spaceGrotesk(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: inkBlack,
      ),
      bodyLarge: GoogleFonts.spaceGrotesk(
        fontSize: 16,
        height: 1.4,
        fontWeight: FontWeight.w500,
        color: inkBlack,
      ),
      bodyMedium: GoogleFonts.spaceGrotesk(
        fontSize: 14,
        height: 1.4,
        fontWeight: FontWeight.w500,
        color: inkBlack,
      ),
      // Metrics & AI Labels: IBM Plex Mono
      labelLarge: GoogleFonts.ibmPlexMono(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
        color: inkBlack,
      ),
      labelMedium: GoogleFonts.ibmPlexMono(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: inkBlack,
      ),
    );
  }

  static ThemeData _buildNeoTheme({required bool isDark}) {
    final bg = isDark ? charcoalNight : paperCream;
    final surfaceColor = isDark ? const Color(0xFF222222) : warmWhite;
    final onSurface = isDark ? warmWhite : inkBlack;
    final borderColor = isDark ? warmWhite : inkBlack;

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: cobaltBlue,
        onPrimary: warmWhite,
        secondary: signalYellow,
        onSecondary: inkBlack,
        error: punchRed,
        onError: warmWhite,
        surface: surfaceColor,
        onSurface: onSurface,
      ),
      textTheme: _learnerTextTheme(
        ThemeData(brightness: isDark ? Brightness.dark : Brightness.light).textTheme,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: onSurface,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.archivoBlack(
          color: onSurface,
          fontSize: 24,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(_radius16),
          side: neoBorderSide(3, borderColor),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cobaltBlue,
          foregroundColor: warmWhite,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.all(_radius12),
            side: neoBorderSide(3, borderColor),
          ),
          textStyle: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ).copyWith(
          // Material state property for the hard shadow feel
          elevation: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) return 0;
            return 0; // Handled by custom NeoButton for better control
          }),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? charcoalNight : warmWhite,
        contentPadding: const EdgeInsets.all(18),
        border: OutlineInputBorder(
          borderRadius: const BorderRadius.all(_radius12),
          borderSide: neoBorderSide(3, borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(_radius12),
          borderSide: neoBorderSide(3, borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(_radius12),
          borderSide: neoBorderSide(3, cobaltBlue),
        ),
        labelStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, color: onSurface),
        hintStyle: GoogleFonts.spaceGrotesk(color: onSurface.withValues(alpha: 0.5)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? charcoalNight : warmWhite,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: neoBorderSide(3, borderColor),
        ),
        contentTextStyle: GoogleFonts.spaceGrotesk(
          color: onSurface,
          fontWeight: FontWeight.w800,
        ),
      ),
      extensions: [
        NeoShadows(isDark: isDark, hardShadow: hardShadow(color: borderColor)),
      ],
    );
  }

      dividerTheme: DividerThemeData(
        color: isDark ? warmWhite.withValues(alpha: 0.35) : inkBlack.withValues(alpha: 0.25),
        thickness: 1.5,
      ),
      chipTheme: base.chipTheme.copyWith(
        side: BorderSide(color: isDark ? warmWhite : inkBlack, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        labelStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(_radius16),
          side: BorderSide(color: isDark ? warmWhite : inkBlack, width: 3),
        ),
      ),
      extensions: [
        NeoShadows(isDark: isDark, hardShadow: _hardShadow()),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════
  //  DARK THEME
  // ══════════════════════════════════════════════════════════
  static ThemeData get darkTheme {
    return _buildNeoTheme(isDark: true);
  }

  // ══════════════════════════════════════════════════════════
  //  LIGHT THEME
  // ══════════════════════════════════════════════════════════
  static ThemeData get lightTheme {
    return _buildNeoTheme(isDark: false);
  }
}

@immutable
class NeoShadows extends ThemeExtension<NeoShadows> {
  final bool isDark;
  final List<BoxShadow> hardShadow;

  const NeoShadows({required this.isDark, required this.hardShadow});

  @override
  NeoShadows copyWith({bool? isDark, List<BoxShadow>? hardShadow}) {
    return NeoShadows(
      isDark: isDark ?? this.isDark,
      hardShadow: hardShadow ?? this.hardShadow,
    );
  }

  @override
  NeoShadows lerp(ThemeExtension<NeoShadows>? other, double t) {
    if (other is! NeoShadows) return this;
    return t < 0.5 ? this : other;
  }
}

/// Extension to provide theme-aware colors anywhere via context.
extension AppColors on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get surface => isDark ? AppTheme.charcoalNight : AppTheme.paperCream;
  Color get card => isDark ? const Color(0xFF232323) : AppTheme.warmWhite;
  Color get cardAlt => isDark ? const Color(0xFF2F2F2F) : const Color(0xFFFFF1D6);
  Color get textPrimary => isDark ? AppTheme.warmWhite : AppTheme.inkBlack;
  Color get textSecondary => isDark ? const Color(0xFFE0E0E0) : const Color(0xFF3E3E3E);
  Color get textMuted => isDark ? const Color(0xFFB9B9B9) : const Color(0xFF646464);
  Color get divider => isDark
      ? AppTheme.warmWhite.withValues(alpha: 0.35)
      : AppTheme.inkBlack.withValues(alpha: 0.2);
  Color get border => divider;

  Border get neoBorder => Border.all(
        color: isDark ? AppTheme.warmWhite : AppTheme.inkBlack,
        width: 3,
      );

  List<BoxShadow> get neoShadow => Theme.of(this)
          .extension<NeoShadows>()
          ?.hardShadow ??
      const [
        BoxShadow(
          color: AppTheme.inkBlack,
          offset: Offset(6, 6),
          blurRadius: 0,
        ),
      ];
}

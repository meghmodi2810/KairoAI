import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── LIGHT MODE COLORS ──────────────────────────────────────────
const Color lBgBase      = Color(0xFFFFFCF7);
const Color lBgSurface   = Color(0xFFFFF7E8);
const Color lBgSurface2  = Color(0xFFFFFFFF);
const Color lBgSurface3  = Color(0xFFFFEFD1);

const Color lBorder      = Color(0xFF111111);
const Color lBorder2     = Color(0xFF1B1B1B);
const Color lBorder3     = Color(0xFF303030);

const Color lTextPrimary   = Color(0xFF111111);
const Color lTextSecondary = Color(0xFF303030);
const Color lTextMuted     = Color(0xFF525252);
const Color lTextDisabled  = Color(0xFFA8A8A8);

const Color lAccent        = Color(0xFF3559FF);
const Color lAccentBright  = Color(0xFF58B9FF);
const Color lAccentFill    = Color(0xFFE5ECFF);
const Color lAccentFill2   = Color(0xFFCEE1FF);

const Color lBtnPrimary    = Color(0xFF171717);
const Color lBtnPrimaryFg  = Color(0xFFFFFCF7);
const Color lBtnSecondary  = Color(0xFFFFFCF7);
const Color lBtnSecondaryFg = Color(0xFF111111);

const Color lSuccess      = Color(0xFF10B981);
const Color lSuccessFill  = Color(0xFFDCFCE7);
const Color lSuccessText  = Color(0xFF166534);
const Color lWarning      = Color(0xFFF59E0B);
const Color lWarningFill  = Color(0xFFFEF3C7);
const Color lWarningText  = Color(0xFF92400E);
const Color lError        = Color(0xFFEF4444);
const Color lErrorFill    = Color(0xFFFEE2E2);
const Color lErrorText    = Color(0xFF991B1B);

// ── DARK MODE COLORS ──────────────────────────────────────────
const Color dBgBase      = Color(0xFF151515);
const Color dBgSurface   = Color(0xFF1F1F1F);
const Color dBgSurface2  = Color(0xFF262626);
const Color dBgSurface3  = Color(0xFF2E2E2E);

const Color dBorder      = Color(0xFFF5F5F5);
const Color dBorder2     = Color(0xFFDFDFDF);
const Color dBorder3     = Color(0xFFC7C7C7);

const Color dTextPrimary   = Color(0xFFFFFCF7);
const Color dTextSecondary = Color(0xFFF0EBDD);
const Color dTextMuted     = Color(0xFFD6D0C3);
const Color dTextDisabled  = Color(0xFF8B8B8B);

const Color dAccent        = Color(0xFF58B9FF);
const Color dAccentBright  = Color(0xFF7FC7FF);
const Color dAccentFill    = Color(0xFF24344A);
const Color dAccentFill2   = Color(0xFF314666);

const Color dBtnPrimary    = Color(0xFFFFFCF7);
const Color dBtnPrimaryFg  = Color(0xFF111111);
const Color dBtnSecondary  = Color(0xFF2A2A2A);
const Color dBtnSecondaryFg = Color(0xFFFFFCF7);

const Color dSuccess      = Color(0xFF10B981);
const Color dSuccessFill  = Color(0xFF064E3B);
const Color dSuccessText  = Color(0xFF34D399);
const Color dWarning      = Color(0xFFF59E0B);
const Color dWarningFill  = Color(0xFF422006);
const Color dWarningText  = Color(0xFFFCD34D);
const Color dError        = Color(0xFFF87171);
const Color dErrorFill    = Color(0xFF450A0A);
const Color dErrorText    = Color(0xFFFCA5A5);

// ── DESIGN TOKENS ──────────────────────────────────────────────
const double screenPad    = 16.0;
const double rowPadV      = 10.0;
const double rowPadH      = 14.0;
const double cardPad      = 16.0;
const double bottomBuf    = 80.0;
const double radiusBtn    = 12.0;
const double radiusCard   = 14.0;
const double radiusModal  = 16.0;
const double radiusInput  = 12.0;
const double radiusTag    = 8.0;
const double radiusPill   = 100.0;
const double pillRadius   = 100.0;
const double radiusSignCell = 10.0;
const double navH         = 58.0;
const double topBarH      = 48.0;

// ── TYPOGRAPHY ────────────────────────────────────────────────
TextStyle adminH1(Color color) => GoogleFonts.archivoBlack(
  fontSize: 18, fontWeight: FontWeight.w800,
  letterSpacing: -0.4, height: 1.2, color: color,
);
TextStyle adminH2(Color color) => GoogleFonts.archivoBlack(
  fontSize: 15, fontWeight: FontWeight.w800,
  letterSpacing: -0.3, height: 1.25, color: color,
);
TextStyle adminH3(Color color) => GoogleFonts.spaceGrotesk(
  fontSize: 13, fontWeight: FontWeight.w700,
  letterSpacing: -0.1, height: 1.3, color: color,
);
TextStyle adminBody(Color color) => GoogleFonts.spaceGrotesk(
  fontSize: 13, fontWeight: FontWeight.w500,
  height: 1.5, color: color,
);
TextStyle adminBodySm(Color color) => GoogleFonts.spaceGrotesk(
  fontSize: 12, fontWeight: FontWeight.w500,
  height: 1.5, color: color,
);
TextStyle adminMeta(Color color) => GoogleFonts.spaceGrotesk(
  fontSize: 10, fontWeight: FontWeight.w600,
  height: 1.4, color: color,
);
TextStyle adminLabel(Color color) => GoogleFonts.ibmPlexMono(
  fontSize: 10, fontWeight: FontWeight.w800,
  letterSpacing: 0.07, height: 1.2, color: color,
);
TextStyle adminMono(Color color) => GoogleFonts.robotoMono(
  fontSize: 11, fontWeight: FontWeight.w700,
  height: 1.4, color: color,
);
TextStyle signLetter(Color color) => TextStyle(
  fontSize: 13, fontWeight: FontWeight.w700,
  fontFamily: 'serif', height: 1.0, color: color,
);
TextStyle statValue(Color color) => GoogleFonts.archivoBlack(
  fontSize: 17, fontWeight: FontWeight.w700,
  letterSpacing: -0.5, height: 1.1, color: color,
);
TextStyle statValueSm(Color color) => GoogleFonts.archivoBlack(
  fontSize: 14, fontWeight: FontWeight.w700,
  letterSpacing: -0.4, height: 1.1, color: color,
);

// ── THEME EXTENSION ──────────────────────────────────────────
@immutable
class AdminColors extends ThemeExtension<AdminColors> {
  final Color bgBase;
  final Color bgSurface;
  final Color bgSurface2;
  final Color bgSurface3;
  final Color border;
  final Color border2;
  final Color border3;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textDisabled;
  final Color accent;
  final Color accentBright;
  final Color accentFill;
  final Color accentFill2;
  final Color btnPrimary;
  final Color btnPrimaryFg;
  final Color btnSecondary;
  final Color btnSecondaryFg;
  final Color success;
  final Color successFill;
  final Color successText;
  final Color warning;
  final Color warningFill;
  final Color warningText;
  final Color error;
  final Color errorFill;
  final Color errorText;
  final bool isDark;

  const AdminColors({
    required this.bgBase,
    required this.bgSurface,
    required this.bgSurface2,
    required this.bgSurface3,
    required this.border,
    required this.border2,
    required this.border3,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textDisabled,
    required this.accent,
    required this.accentBright,
    required this.accentFill,
    required this.accentFill2,
    required this.btnPrimary,
    required this.btnPrimaryFg,
    required this.btnSecondary,
    required this.btnSecondaryFg,
    required this.success,
    required this.successFill,
    required this.successText,
    required this.warning,
    required this.warningFill,
    required this.warningText,
    required this.error,
    required this.errorFill,
    required this.errorText,
    required this.isDark,
  });

  static const AdminColors light = AdminColors(
    bgBase: lBgBase, bgSurface: lBgSurface, bgSurface2: lBgSurface2, bgSurface3: lBgSurface3,
    border: lBorder, border2: lBorder2, border3: lBorder3,
    textPrimary: lTextPrimary, textSecondary: lTextSecondary, textMuted: lTextMuted, textDisabled: lTextDisabled,
    accent: lAccent, accentBright: lAccentBright, accentFill: lAccentFill, accentFill2: lAccentFill2,
    btnPrimary: lBtnPrimary, btnPrimaryFg: lBtnPrimaryFg, btnSecondary: lBtnSecondary, btnSecondaryFg: lBtnSecondaryFg,
    success: lSuccess, successFill: lSuccessFill, successText: lSuccessText,
    warning: lWarning, warningFill: lWarningFill, warningText: lWarningText,
    error: lError, errorFill: lErrorFill, errorText: lErrorText,
    isDark: false,
  );

  static const AdminColors dark = AdminColors(
    bgBase: dBgBase, bgSurface: dBgSurface, bgSurface2: dBgSurface2, bgSurface3: dBgSurface3,
    border: dBorder, border2: dBorder2, border3: dBorder3,
    textPrimary: dTextPrimary, textSecondary: dTextSecondary, textMuted: dTextMuted, textDisabled: dTextDisabled,
    accent: dAccent, accentBright: dAccentBright, accentFill: dAccentFill, accentFill2: dAccentFill2,
    btnPrimary: dBtnPrimary, btnPrimaryFg: dBtnPrimaryFg, btnSecondary: dBtnSecondary, btnSecondaryFg: dBtnSecondaryFg,
    success: dSuccess, successFill: dSuccessFill, successText: dSuccessText,
    warning: dWarning, warningFill: dWarningFill, warningText: dWarningText,
    error: dError, errorFill: dErrorFill, errorText: dErrorText,
    isDark: true,
  );

  @override
  AdminColors copyWith({
    Color? bgBase, Color? bgSurface, Color? bgSurface2, Color? bgSurface3,
    Color? border, Color? border2, Color? border3,
    Color? textPrimary, Color? textSecondary, Color? textMuted, Color? textDisabled,
    Color? accent, Color? accentBright, Color? accentFill, Color? accentFill2,
    Color? btnPrimary, Color? btnPrimaryFg, Color? btnSecondary, Color? btnSecondaryFg,
    Color? success, Color? successFill, Color? successText,
    Color? warning, Color? warningFill, Color? warningText,
    Color? error, Color? errorFill, Color? errorText,
    bool? isDark,
  }) {
    return AdminColors(
      bgBase: bgBase ?? this.bgBase, bgSurface: bgSurface ?? this.bgSurface,
      bgSurface2: bgSurface2 ?? this.bgSurface2, bgSurface3: bgSurface3 ?? this.bgSurface3,
      border: border ?? this.border, border2: border2 ?? this.border2, border3: border3 ?? this.border3,
      textPrimary: textPrimary ?? this.textPrimary, textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted, textDisabled: textDisabled ?? this.textDisabled,
      accent: accent ?? this.accent, accentBright: accentBright ?? this.accentBright,
      accentFill: accentFill ?? this.accentFill, accentFill2: accentFill2 ?? this.accentFill2,
      btnPrimary: btnPrimary ?? this.btnPrimary, btnPrimaryFg: btnPrimaryFg ?? this.btnPrimaryFg,
      btnSecondary: btnSecondary ?? this.btnSecondary, btnSecondaryFg: btnSecondaryFg ?? this.btnSecondaryFg,
      success: success ?? this.success, successFill: successFill ?? this.successFill, successText: successText ?? this.successText,
      warning: warning ?? this.warning, warningFill: warningFill ?? this.warningFill, warningText: warningText ?? this.warningText,
      error: error ?? this.error, errorFill: errorFill ?? this.errorFill, errorText: errorText ?? this.errorText,
      isDark: isDark ?? this.isDark,
    );
  }

  @override
  AdminColors lerp(AdminColors? other, double t) {
    if (other is! AdminColors) return this;
    return AdminColors(
      bgBase: Color.lerp(bgBase, other.bgBase, t)!,
      bgSurface: Color.lerp(bgSurface, other.bgSurface, t)!,
      bgSurface2: Color.lerp(bgSurface2, other.bgSurface2, t)!,
      bgSurface3: Color.lerp(bgSurface3, other.bgSurface3, t)!,
      border: Color.lerp(border, other.border, t)!,
      border2: Color.lerp(border2, other.border2, t)!,
      border3: Color.lerp(border3, other.border3, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentBright: Color.lerp(accentBright, other.accentBright, t)!,
      accentFill: Color.lerp(accentFill, other.accentFill, t)!,
      accentFill2: Color.lerp(accentFill2, other.accentFill2, t)!,
      btnPrimary: Color.lerp(btnPrimary, other.btnPrimary, t)!,
      btnPrimaryFg: Color.lerp(btnPrimaryFg, other.btnPrimaryFg, t)!,
      btnSecondary: Color.lerp(btnSecondary, other.btnSecondary, t)!,
      btnSecondaryFg: Color.lerp(btnSecondaryFg, other.btnSecondaryFg, t)!,
      success: Color.lerp(success, other.success, t)!,
      successFill: Color.lerp(successFill, other.successFill, t)!,
      successText: Color.lerp(successText, other.successText, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningFill: Color.lerp(warningFill, other.warningFill, t)!,
      warningText: Color.lerp(warningText, other.warningText, t)!,
      error: Color.lerp(error, other.error, t)!,
      errorFill: Color.lerp(errorFill, other.errorFill, t)!,
      errorText: Color.lerp(errorText, other.errorText, t)!,
      isDark: t > 0.5 ? other.isDark : isDark,
    );
  }
}

// ── THEME DATA ────────────────────────────────────────────────
ThemeData adminThemeLight() {
  final base = ThemeData.light(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: lBgBase,
    colorScheme: const ColorScheme.light(
      primary: lAccent,
      surface: lBgSurface,
      error: lError,
      onPrimary: Colors.white,
      onSurface: lTextPrimary,
    ),
    textTheme: GoogleFonts.spaceGroteskTextTheme(base.textTheme),
    extensions: const [AdminColors.light],
    appBarTheme: AppBarTheme(
      backgroundColor: lBgSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      shadowColor: Colors.transparent,
    ),
    dividerColor: lBorder,
    dividerTheme: const DividerThemeData(color: lBorder, thickness: 1.5, space: 0),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lBgSurface3,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusInput),
        borderSide: const BorderSide(color: lBorder2, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusInput),
        borderSide: const BorderSide(color: lBorder2, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusInput),
        borderSide: const BorderSide(color: lAccent, width: 2.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusInput),
        borderSide: const BorderSide(color: lError, width: 2.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
    cardTheme: CardThemeData(
      color: lBgSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusCard),
        side: const BorderSide(color: lBorder, width: 2.5),
      ),
    ),
  );
}

/// Helper to get AdminColors from context
AdminColors ac(BuildContext context) =>
    Theme.of(context).extension<AdminColors>() ?? AdminColors.light;

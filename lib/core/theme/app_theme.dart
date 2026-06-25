import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF4F46E5);
  static const Color surface = Color(0xFFF8FAFC);
  static const Color darkSurface = Color(0xFF0F172A);
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF334155);

  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFFCBD5E1);

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final textPrimary = isDark ? darkTextPrimary : lightTextPrimary;
    final textSecondary = isDark ? darkTextSecondary : lightTextSecondary;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
      surface: isDark ? darkSurface : surface,
    ).copyWith(
      onSurface: textPrimary,
      onSurfaceVariant: textSecondary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark ? darkSurface : surface,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: isDark ? darkSurface : Colors.white,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: isDark ? darkCard : Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: textSecondary,
        textColor: textPrimary,
        selectedColor: primary,
        selectedTileColor: primary.withValues(alpha: isDark ? 0.22 : 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? darkBorder : const Color(0xFFE2E8F0),
        thickness: 1,
      ),
      textTheme: TextTheme(
        headlineMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 24),
        headlineSmall: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 22),
        titleLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 18),
        titleMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 16),
        bodyLarge: TextStyle(color: textPrimary, fontSize: 15),
        bodyMedium: TextStyle(color: textPrimary, fontSize: 14),
        bodySmall: TextStyle(color: textSecondary, fontSize: 13),
        labelLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w500, fontSize: 14),
        labelMedium: TextStyle(color: textSecondary, fontSize: 12),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? darkCard : Colors.white,
        labelStyle: TextStyle(color: textSecondary),
        hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.75)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? darkBorder : Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? darkCard : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: isDark ? darkBorder : const Color(0xFFE2E8F0)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? const Color(0xFFA5B4FC) : primary,
          side: BorderSide(color: isDark ? darkBorder : const Color(0xFFCBD5E1)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? darkCard : Colors.white,
        indicatorColor: primary.withValues(alpha: isDark ? 0.24 : 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? primary : textSecondary,
          );
        }),
      ),
    );
  }
}

extension AppThemeContext on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  Color get appTextPrimary => colorScheme.onSurface;

  Color get appTextSecondary => colorScheme.onSurfaceVariant;

  Color get appCardColor => Theme.of(this).cardTheme.color ?? colorScheme.surface;

  Color get appBorderColor => isDarkMode ? AppTheme.darkBorder : const Color(0xFFE2E8F0);

  Color get appBubbleAiBg => isDarkMode ? AppTheme.darkCard : const Color(0xFFF1F5F9);

  TextStyle get appHeadingStyle => TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: appTextPrimary,
      );

  TextStyle get appSectionTitleStyle => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: appTextPrimary,
      );

  TextStyle get appBodyStyle => TextStyle(
        fontSize: 14,
        color: appTextPrimary,
        height: 1.45,
      );

  TextStyle get appCaptionStyle => TextStyle(
        fontSize: 13,
        color: appTextSecondary,
        height: 1.45,
      );

  TextStyle get appLabelStyle => TextStyle(
        fontSize: 12,
        color: appTextSecondary,
      );
}

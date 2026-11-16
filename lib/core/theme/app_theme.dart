import 'package:material_ui/material_ui.dart';

import 'package:radar_vila/core/theme/app_palette.dart';
import 'package:radar_vila/core/theme/app_spacing.dart';

/// Temas do app: claro, escuro e alto contraste (claro/escuro).
class AppTheme {
  AppTheme._();

  static const Color _brand = Color(0xFF0B6E69);

  static ThemeData get light => _build(
        ColorScheme.fromSeed(seedColor: _brand, brightness: Brightness.light)
            .copyWith(primary: _brand, surface: const Color(0xFFF4F7F6)),
        AppPalette.light,
      );

  static ThemeData get dark => _build(
        ColorScheme.fromSeed(seedColor: _brand, brightness: Brightness.dark)
            .copyWith(surface: const Color(0xFF0E1615)),
        AppPalette.dark,
      );

  static ThemeData get highContrastLight => _build(
        const ColorScheme(
          brightness: Brightness.light,
          primary: Color(0xFF00332F),
          onPrimary: Color(0xFFFFFFFF),
          secondary: Color(0xFF5A2E00),
          onSecondary: Color(0xFFFFFFFF),
          error: Color(0xFF7A0000),
          onError: Color(0xFFFFFFFF),
          surface: Color(0xFFFFFFFF),
          onSurface: Color(0xFF000000),
          outline: Color(0xFF000000),
        ),
        AppPalette.highContrastLight,
      );

  static ThemeData get highContrastDark => _build(
        const ColorScheme(
          brightness: Brightness.dark,
          primary: Color(0xFFFFE500),
          onPrimary: Color(0xFF000000),
          secondary: Color(0xFF7FFFF0),
          onSecondary: Color(0xFF000000),
          error: Color(0xFFFF9C9C),
          onError: Color(0xFF000000),
          surface: Color(0xFF000000),
          onSurface: Color(0xFFFFFFFF),
          outline: Color(0xFFFFFFFF),
        ),
        AppPalette.highContrastDark,
      );

  static ThemeData _build(ColorScheme scheme, AppPalette palette) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: scheme.brightness,
    );
    final text = base.textTheme;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.sm),
    );

    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      extensions: <ThemeExtension<dynamic>>[palette],
      dividerColor: palette.border,
      textTheme: text.copyWith(
        headlineSmall: text.headlineSmall
            ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3),
        titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        titleSmall: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        bodyMedium: text.bodyMedium?.copyWith(height: 1.4),
        bodySmall: text.bodySmall?.copyWith(height: 1.35),
        labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: scheme.onSurface,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          shape: shape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          side: BorderSide(color: palette.border, width: 1.2),
          shape: shape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: const Size(48, 44)),
      ),
      snackBarTheme:
          const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}

import 'package:material_ui/material_ui.dart';

import 'package:radar_vila/core/theme/app_palette.dart';

/// Atalhos para acessar o tema a partir do BuildContext.
extension ThemeContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;

  TextTheme get textStyles => Theme.of(this).textTheme;

  ColorScheme get colors => Theme.of(this).colorScheme;

  TextStyle? get mutedSmall =>
      Theme.of(this).textTheme.bodySmall?.copyWith(color: palette.muted);
}

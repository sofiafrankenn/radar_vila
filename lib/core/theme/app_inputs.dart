import 'package:material_ui/material_ui.dart';

import 'package:radar_vila/core/theme/app_spacing.dart';
import 'package:radar_vila/core/theme/theme_context.dart';

/// Decoração padrão dos campos de formulário.
class AppInputs {
  AppInputs._();

  static InputDecoration decoration(
    BuildContext context, {
    required String label,
    String? hint,
    String? helper,
    IconData? icon,
    String? suffix,
  }) {
    final palette = context.palette;
    final colors = context.colors;

    OutlineInputBorder border(Color color, [double width = 1.2]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: color, width: width),
        );

    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      helperMaxLines: 3,
      errorMaxLines: 3,
      prefixIcon: icon == null ? null : Icon(icon),
      suffixText: suffix,
      filled: true,
      fillColor: palette.card,
      border: border(palette.border),
      enabledBorder: border(palette.border),
      focusedBorder: border(colors.primary, 2),
      errorBorder: border(colors.error),
      focusedErrorBorder: border(colors.error, 2),
    );
  }
}

import 'package:material_ui/material_ui.dart';

import 'package:radar_vila/core/theme/theme_context.dart';
import 'package:radar_vila/models/alert.dart';
import 'package:radar_vila/models/indicator.dart';

Color severityColor(BuildContext context, AlertSeverity severity) {
  final p = context.palette;
  return switch (severity) {
    AlertSeverity.informativo => p.info,
    AlertSeverity.atencao => p.atencao,
    AlertSeverity.critico => p.critico,
  };
}

Color dashboardColor(BuildContext context, DashboardType type) {
  final p = context.palette;
  return switch (type) {
    DashboardType.agua => p.agua,
    DashboardType.energia => p.energia,
    DashboardType.clima => p.clima,
  };
}

/// Texto preto ou branco, o que tiver mais contraste com o fundo.
Color onColor(Color background) =>
    ThemeData.estimateBrightnessForColor(background) == Brightness.dark
        ? Colors.white
        : Colors.black;

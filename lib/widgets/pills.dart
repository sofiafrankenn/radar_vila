import 'package:material_ui/material_ui.dart';

import 'package:radar_vila/core/theme/app_spacing.dart';
import 'package:radar_vila/core/theme/theme_context.dart';
import 'package:radar_vila/models/alert.dart';
import 'package:radar_vila/models/indicator.dart';
import 'package:radar_vila/widgets/semantic_colors.dart';

/// Etiqueta neutra com ícone.
class InfoPill extends StatelessWidget {
  const InfoPill({super.key, required this.text, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: palette.muted),
            const SizedBox(width: AppSpacing.xs),
          ],
          Flexible(
            child: Text(
              text,
              style: context.textStyles.labelMedium
                  ?.copyWith(color: palette.muted),
            ),
          ),
        ],
      ),
    );
  }
}

/// Severidade do alerta (cor + ícone + texto, nunca só cor).
class SeverityChip extends StatelessWidget {
  const SeverityChip({super.key, required this.severity, this.label});

  final AlertSeverity severity;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final bg = severityColor(context, severity);
    final fg = onColor(bg);
    return Semantics(
      label: 'Severidade ${severity.label}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(severity.icon, size: 16, color: fg),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label ?? severity.label,
              style: context.textStyles.labelMedium
                  ?.copyWith(color: fg, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

/// Indica se o dado é real (API pública) ou sintético.
class OriginBadge extends StatelessWidget {
  const OriginBadge({super.key, required this.origin});

  final DataOrigin origin;

  @override
  Widget build(BuildContext context) => InfoPill(
        text: origin.label,
        icon: origin == DataOrigin.real ? Icons.public : Icons.science_outlined,
      );
}

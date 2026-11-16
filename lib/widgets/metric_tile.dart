import 'package:material_ui/material_ui.dart';

import 'package:radar_vila/core/theme/theme_context.dart';
import 'package:radar_vila/core/utils/formatters.dart';

class MetricTile extends StatelessWidget {
  const MetricTile(
      {super.key, required this.label, required this.value, this.unit});

  final String label;
  final String value;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      label: '$label: $value ${unit ?? ''}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: context.textStyles.labelSmall
                  ?.copyWith(color: palette.muted)),
          const SizedBox(height: 2),
          Text.rich(
            TextSpan(
              text: value,
              style: context.textStyles.titleMedium,
              children: [
                if (unit != null)
                  TextSpan(
                    text: ' $unit',
                    style: context.textStyles.bodySmall
                        ?.copyWith(color: palette.muted),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Seta + variação semanal; vermelho quando piora, verde quando melhora.
class TrendBadge extends StatelessWidget {
  const TrendBadge(
      {super.key, required this.change, required this.higherIsWorse});

  final double? change;
  final bool higherIsWorse;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final c = change;
    if (c == null) {
      return Text('Sem comparação semanal', style: context.mutedSmall);
    }
    final up = c > 0.005;
    final down = c < -0.005;
    final worse = (up && higherIsWorse) || (down && !higherIsWorse);
    final color = (up || down)
        ? (worse ? palette.critico : palette.sucesso)
        : palette.muted;
    final icon = up
        ? Icons.trending_up
        : (down ? Icons.trending_down : Icons.trending_flat);
    final text = '${Fmt.signed(c * 100)}% vs. semana anterior';

    return Semantics(
      label: 'Variação semanal: $text${worse ? ', piora' : ''}',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: context.textStyles.labelMedium
                  ?.copyWith(color: color, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

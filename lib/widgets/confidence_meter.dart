import 'package:material_ui/material_ui.dart';

import 'package:radar_vila/core/theme/app_spacing.dart';
import 'package:radar_vila/core/theme/theme_context.dart';
import 'package:radar_vila/core/utils/formatters.dart';
import 'package:radar_vila/models/alert.dart';

class ConfidenceMeter extends StatelessWidget {
  const ConfidenceMeter({super.key, required this.confidence});

  final double confidence;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final label = TerritoryAlert.confidenceLabelFor(confidence);
    final color = confidence >= 0.7
        ? palette.sucesso
        : (confidence >= 0.4 ? palette.atencao : palette.critico);
    final pct = Fmt.percent(confidence);

    return Semantics(
      label: 'Nível de confiança $label, $pct',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Confiança: $label',
                    style: context.textStyles.titleSmall),
              ),
              Text(pct,
                  style: context.textStyles.titleSmall?.copyWith(color: color)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: confidence,
              minHeight: 10,
              color: color,
              backgroundColor: palette.border,
            ),
          ),
        ],
      ),
    );
  }
}

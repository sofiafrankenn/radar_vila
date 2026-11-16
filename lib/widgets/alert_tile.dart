import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:radar_vila/core/theme/app_spacing.dart';
import 'package:radar_vila/core/theme/theme_context.dart';
import 'package:radar_vila/core/utils/formatters.dart';
import 'package:radar_vila/models/alert.dart';
import 'package:radar_vila/providers/territory_provider.dart';
import 'package:radar_vila/routes/app_routes.dart';
import 'package:radar_vila/widgets/app_card.dart';
import 'package:radar_vila/widgets/pills.dart';
import 'package:radar_vila/widgets/semantic_colors.dart';

class AlertTile extends StatelessWidget {
  const AlertTile({super.key, required this.alert});

  final TerritoryAlert alert;

  @override
  Widget build(BuildContext context) {
    final decision = context.select<TerritoryProvider, HumanDecision>(
        (t) => t.decisionFor(alert.id));
    return AppCard(
      accent: severityColor(context, alert.severity),
      onTap: () => Navigator.pushNamed(context, AppRoutes.alertDetail,
          arguments: alert.id),
      semanticLabel: 'Alerta ${alert.severity.label}: ${alert.title}. '
          '${alert.horizonLabel}. Confiança ${alert.confidenceLabel}. '
          '${decision.label}. Toque para ver a justificativa.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SeverityChip(severity: alert.severity),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  alert.horizonLabel,
                  textAlign: TextAlign.right,
                  style: context.mutedSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(alert.title, style: context.textStyles.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(alert.summary, maxLines: 3, overflow: TextOverflow.ellipsis),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              InfoPill(
                icon: Icons.speed,
                text:
                    'Confiança ${alert.confidenceLabel} (${Fmt.percent(alert.confidence)})',
              ),
              InfoPill(icon: decision.icon, text: decision.label),
            ],
          ),
        ],
      ),
    );
  }
}

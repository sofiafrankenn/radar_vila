import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:radar_vila/core/theme/app_spacing.dart';
import 'package:radar_vila/core/theme/theme_context.dart';
import 'package:radar_vila/core/utils/formatters.dart';
import 'package:radar_vila/models/indicator.dart';
import 'package:radar_vila/providers/territory_provider.dart';
import 'package:radar_vila/routes/app_routes.dart';
import 'package:radar_vila/widgets/app_card.dart';
import 'package:radar_vila/widgets/metric_tile.dart';
import 'package:radar_vila/widgets/pills.dart';
import 'package:radar_vila/widgets/semantic_colors.dart';

/// Atalho da visão geral para cada um dos 3 dashboards.
class DashboardEntryCard extends StatelessWidget {
  const DashboardEntryCard({super.key, required this.type});

  final DashboardType type;

  @override
  Widget build(BuildContext context) {
    final territory = context.watch<TerritoryProvider>();
    final indicators = territory.indicatorsFor(type);
    final main = indicators.isEmpty ? null : indicators.first;
    final latest = main?.latest;
    final alerts = territory.alertsForDashboard(type);
    final color = dashboardColor(context, type);

    final valueText = (latest == null || main == null)
        ? 'sem dados'
        : '${Fmt.number(latest.value, decimals: main.decimals)} ${main.unit}';

    return AppCard(
      accent: color,
      onTap: () =>
          Navigator.pushNamed(context, AppRoutes.dashboard, arguments: type),
      semanticLabel: 'Painel ${type.label}. ${main?.name ?? ''}: $valueText. '
          '${alerts.isEmpty ? 'Sem alertas' : Fmt.count(alerts.length, 'alerta', 'alertas')}. '
          'Toque para abrir.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(type.icon, color: color),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                  child:
                      Text(type.label, style: context.textStyles.titleMedium)),
              if (alerts.isNotEmpty)
                SeverityChip(
                    severity: alerts.first.severity, label: '${alerts.length}'),
              const Icon(Icons.chevron_right),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(type.subtitle, style: context.mutedSmall),
          const SizedBox(height: AppSpacing.md),
          if (main == null || latest == null)
            Text('Sem dados disponíveis no momento.', style: context.mutedSmall)
          else ...[
            MetricTile(
                label: main.name,
                value: Fmt.number(latest.value, decimals: main.decimals),
                unit: main.unit),
            const SizedBox(height: AppSpacing.xs),
            TrendBadge(
                change: main.weeklyChange, higherIsWorse: main.higherIsWorse),
          ],
        ],
      ),
    );
  }
}

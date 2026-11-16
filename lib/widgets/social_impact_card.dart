import 'package:material_ui/material_ui.dart';

import 'package:radar_vila/core/constants.dart';
import 'package:radar_vila/core/theme/app_spacing.dart';
import 'package:radar_vila/core/theme/theme_context.dart';
import 'package:radar_vila/core/utils/formatters.dart';
import 'package:radar_vila/domain/social_impact.dart';
import 'package:radar_vila/widgets/app_card.dart';
import 'package:radar_vila/widgets/metric_tile.dart';

/// Indicador de benefício social.
class SocialImpactCard extends StatelessWidget {
  const SocialImpactCard({super.key, required this.impact});

  final SocialImpact impact;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = context.textStyles;
    final avg = impact.averageConsumption;

    Widget waterBlock;
    if (avg == null) {
      waterBlock = Text('Sem dados de consumo para estimar economia.',
          style: context.mutedSmall);
    } else if (impact.withinTarget) {
      waterBlock = Text(
        'O consumo médio (${Fmt.number(avg, decimals: 0)} L/hab/dia) está dentro da '
        'meta de consumo consciente de '
        '${Fmt.number(ImpactReference.conscientConsumption, decimals: 0)} L/hab/dia.',
      );
    } else {
      waterBlock = Semantics(
        label:
            'Economia potencial de ${Fmt.compact(impact.potentialSavingLitersPerWeek)} '
            'litros por semana, o equivalente a abastecer '
            '${Fmt.compact(impact.peopleSuppliedPerDay)} pessoas por dia.',
        excludeSemantics: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(TextSpan(
              text: Fmt.compact(impact.potentialSavingLitersPerWeek),
              style: text.headlineSmall?.copyWith(color: palette.sucesso),
              children: [
                TextSpan(text: ' litros/semana', style: text.titleSmall)
              ],
            )),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'poderiam ser economizados se o consumo médio '
              '(${Fmt.number(avg, decimals: 0)} L/hab/dia) voltasse à meta de '
              '${Fmt.number(ImpactReference.conscientConsumption, decimals: 0)} L/hab/dia.',
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '≈ ${Fmt.compact(impact.peopleSuppliedPerDay)} pessoas abastecidas por dia '
              '(referência ONU: ${Fmt.number(ImpactReference.unDailyNeed, decimals: 0)} L/pessoa/dia).',
              style: text.titleSmall,
            ),
          ],
        ),
      );
    }

    return AppCard(
      accent: palette.sucesso,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.volunteer_activism_outlined, color: palette.sucesso),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                  child: Text('Benefício social estimado',
                      style: text.titleMedium)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          waterBlock,
          const Divider(height: AppSpacing.xl),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: MetricTile(
                  label: 'Alertas avaliados por pessoas',
                  value: '${impact.reviewedAlerts}',
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: MetricTile(
                  label: 'Ocorrências cidadãs registradas',
                  value: '${impact.citizenReports}',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Estimativa ilustrativa para ${TerritoryInfo.name} '
            '(≈ ${Fmt.compact(TerritoryInfo.population.toDouble())} habitantes). '
            'O resultado real depende da adesão da população e de ações da concessionária.',
            style: context.mutedSmall,
          ),
        ],
      ),
    );
  }
}

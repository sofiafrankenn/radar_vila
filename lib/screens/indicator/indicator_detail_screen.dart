import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:radar_vila/core/theme/app_spacing.dart';
import 'package:radar_vila/core/theme/theme_context.dart';
import 'package:radar_vila/core/utils/formatters.dart';
import 'package:radar_vila/domain/statistics.dart';
import 'package:radar_vila/models/indicator.dart';
import 'package:radar_vila/providers/load_status.dart';
import 'package:radar_vila/providers/settings_provider.dart';
import 'package:radar_vila/providers/territory_provider.dart';
import 'package:radar_vila/routes/app_routes.dart';
import 'package:radar_vila/widgets/alert_tile.dart';
import 'package:radar_vila/widgets/app_card.dart';
import 'package:radar_vila/widgets/metric_tile.dart';
import 'package:radar_vila/widgets/pills.dart';
import 'package:radar_vila/widgets/section_header.dart';
import 'package:radar_vila/widgets/semantic_colors.dart';
import 'package:radar_vila/widgets/state_views.dart';
import 'package:radar_vila/widgets/trend_chart.dart';

/// Detalhe de um indicador — recebe o id pela rota.
class IndicatorDetailScreen extends StatelessWidget {
  const IndicatorDetailScreen({super.key, required this.indicatorId});

  final String indicatorId;

  @override
  Widget build(BuildContext context) {
    final territory = context.watch<TerritoryProvider>();
    final indicator = territory.indicatorById(indicatorId);

    return Scaffold(
      appBar: AppBar(title: Text(indicator?.name ?? 'Indicador')),
      body: () {
        if (!territory.hasData) {
          return territory.status == LoadStatus.error
              ? ErrorView(
                  message: territory.errorMessage ?? 'Erro ao carregar.',
                  onRetry: territory.load)
              : const LoadingView();
        }
        if (indicator == null) {
          return const EmptyView(
            icon: Icons.search_off,
            title: 'Indicador não encontrado',
            message: 'Ele pode ter sido removido da fonte de dados.',
          );
        }
        return _Content(indicator: indicator);
      }(),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.indicator});

  final Indicator indicator;

  @override
  Widget build(BuildContext context) {
    final territory = context.watch<TerritoryProvider>();
    final threshold =
        context.watch<SettingsProvider>().thresholds.forIndicator(indicator.id);
    final color = dashboardColor(context, indicator.dashboard);
    final related = territory.alertsForIndicator(indicator.id);
    final hist = indicator.history;
    final values = hist.map((p) => p.value).toList();
    final window =
        values.length > 14 ? values.sublist(values.length - 14) : values;
    final reg = Stats.linearRegression(window);
    String f(double v) => Fmt.number(v, decimals: indicator.decimals);

    final recent = [
      ...indicator.forecast.reversed,
      ...hist.reversed.take(7),
    ];

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(indicator.description, style: context.textStyles.bodyLarge),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            OriginBadge(origin: indicator.origin),
            InfoPill(
                icon: indicator.dashboard.icon,
                text: 'Painel ${indicator.dashboard.label}'),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text('Fonte: ${indicator.source}', style: context.mutedSmall),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: TrendChart(
            series: indicator.series,
            color: color,
            unit: indicator.unit,
            threshold: threshold,
            decimals: indicator.decimals,
            height: 240,
            asBars: indicator.preferBars,
          ),
        ),
        SectionHeader(title: 'Estatísticas (${hist.length} dias de histórico)'),
        if (values.isEmpty)
          const EmptyView(
            compact: true,
            icon: Icons.query_stats,
            title: 'Sem histórico',
            message: 'Não há registros suficientes para calcular estatísticas.',
          )
        else
          AppCard(
            child: Wrap(
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.lg,
              children: [
                for (final m in [
                  MetricTile(
                      label: 'Mínimo',
                      value: f(values.reduce(math.min)),
                      unit: indicator.unit),
                  MetricTile(
                      label: 'Máximo',
                      value: f(values.reduce(math.max)),
                      unit: indicator.unit),
                  MetricTile(
                      label: 'Média',
                      value: f(Stats.mean(values)),
                      unit: indicator.unit),
                  MetricTile(
                      label: 'Desvio padrão',
                      value: f(Stats.stdDev(values)),
                      unit: indicator.unit),
                  MetricTile(
                    label: 'Tendência (14 dias)',
                    value: Fmt.signed(reg.slope, decimals: 2),
                    unit: '${indicator.unit}/dia',
                  ),
                  MetricTile(
                      label: 'Ajuste da tendência (R²)',
                      value: Fmt.number(reg.r2, decimals: 2)),
                ])
                  SizedBox(width: 140, child: m),
              ],
            ),
          ),
        const SectionHeader(title: 'Limiar de alerta'),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                threshold == null
                    ? 'Este indicador não tem limiar: é monitorado apenas por '
                        'detecção de anomalias (z-score ≥ 2,5).'
                    : 'Limiar atual: ${f(threshold)} ${indicator.unit}. '
                        'Definido por uma pessoa, pode ser ajustado a qualquer momento.',
              ),
              if (threshold != null) ...[
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.thresholds),
                  icon: const Icon(Icons.tune),
                  label: const Text('Ajustar limiares'),
                ),
              ],
            ],
          ),
        ),
        const SectionHeader(title: 'Registros recentes'),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Column(
            children: [
              for (final p in recent)
                ListTile(
                  dense: true,
                  leading: Icon(
                    p.isForecast ? Icons.auto_graph : Icons.event_available,
                    color: p.isForecast ? context.palette.forecast : color,
                  ),
                  title:
                      Text('${Fmt.weekday(p.date)}, ${Fmt.dayMonth(p.date)}'),
                  subtitle: p.isForecast ? const Text('Previsão') : null,
                  trailing: Text(
                    '${f(p.value)} ${indicator.unit}',
                    style: context.textStyles.titleSmall,
                  ),
                ),
            ],
          ),
        ),
        const SectionHeader(title: 'Alertas relacionados'),
        if (related.isEmpty)
          const EmptyView(
            compact: true,
            icon: Icons.notifications_none,
            title: 'Nenhum alerta para este indicador',
            message:
                'Os dados estão dentro do esperado com os limiares atuais.',
          )
        else
          for (final alert in related)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AlertTile(alert: alert),
            ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

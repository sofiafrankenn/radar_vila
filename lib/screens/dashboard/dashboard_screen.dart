import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:radar_vila/core/theme/app_spacing.dart';
import 'package:radar_vila/core/theme/theme_context.dart';
import 'package:radar_vila/core/utils/formatters.dart';
import 'package:radar_vila/models/indicator.dart';
import 'package:radar_vila/providers/load_status.dart';
import 'package:radar_vila/providers/settings_provider.dart';
import 'package:radar_vila/providers/territory_provider.dart';
import 'package:radar_vila/routes/app_routes.dart';
import 'package:radar_vila/widgets/alert_tile.dart';
import 'package:radar_vila/widgets/app_card.dart';
import 'package:radar_vila/widgets/banners.dart';
import 'package:radar_vila/widgets/metric_tile.dart';
import 'package:radar_vila/widgets/pills.dart';
import 'package:radar_vila/widgets/responsive_grid.dart';
import 'package:radar_vila/widgets/section_header.dart';
import 'package:radar_vila/widgets/semantic_colors.dart';
import 'package:radar_vila/widgets/state_views.dart';
import 'package:radar_vila/widgets/trend_chart.dart';

/// Dashboard territorial (Água, Energia ou Clima) — recebe o tipo pela rota.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.type});

  final DashboardType type;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _range = 14; // estado LOCAL: período exibido nos gráficos

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Painel · ${widget.type.label}')),
      body: _body(context),
    );
  }

  Widget _body(BuildContext context) {
    final territory = context.watch<TerritoryProvider>();
    final thresholds = context.watch<SettingsProvider>().thresholds;

    if (!territory.hasData) {
      return territory.status == LoadStatus.error
          ? ErrorView(
              message: territory.errorMessage ?? 'Erro ao carregar.',
              onRetry: territory.load)
          : const LoadingView(message: 'Carregando painel…');
    }

    final indicators = territory.indicatorsFor(widget.type);
    if (indicators.isEmpty || indicators.every((i) => i.isEmpty)) {
      return EmptyView(
        icon: Icons.inbox_outlined,
        title: 'Sem dados para este painel',
        message: 'A fonte de dados não respondeu e não há cópia salva. '
            'Verifique a conexão e tente de novo.',
        action: FilledButton.icon(
          onPressed: territory.load,
          icon: const Icon(Icons.refresh),
          label: const Text('Tentar novamente'),
        ),
      );
    }

    final snapshot = territory.snapshot!;
    final dashAlerts = territory.alertsForDashboard(widget.type);
    final color = dashboardColor(context, widget.type);

    return RefreshIndicator(
      onRefresh: territory.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(widget.type.subtitle, style: context.textStyles.bodyLarge),
          if (snapshot.fromCache || snapshot.warning != null) ...[
            const SizedBox(height: AppSpacing.md),
            OfflineBanner(snapshot: snapshot, onRetry: territory.load),
          ],
          const SizedBox(height: AppSpacing.lg),
          Semantics(
            label: 'Período exibido nos gráficos',
            child: SegmentedButton<int>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 7, label: Text('7 dias')),
                ButtonSegment(value: 14, label: Text('14 dias')),
                ButtonSegment(value: 30, label: Text('30 dias')),
              ],
              selected: {_range},
              onSelectionChanged: (s) => setState(() => _range = s.first),
            ),
          ),
          if (dashAlerts.isNotEmpty) ...[
            const SectionHeader(title: 'Alertas deste painel'),
            for (final alert in dashAlerts)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AlertTile(alert: alert),
              ),
          ],
          const SectionHeader(title: 'Indicadores'),
          ResponsiveGrid(
            minItemWidth: 340,
            maxColumns: 2,
            children: [
              for (final ind in indicators)
                _IndicatorPanel(
                  indicator: ind,
                  range: _range,
                  color: color,
                  threshold: thresholds.forIndicator(ind.id),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const HumanDecisionBanner(compact: true),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _IndicatorPanel extends StatelessWidget {
  const _IndicatorPanel({
    required this.indicator,
    required this.range,
    required this.color,
    required this.threshold,
  });

  final Indicator indicator;
  final int range;
  final Color color;
  final double? threshold;

  @override
  Widget build(BuildContext context) {
    final hist = indicator.history;
    final forecast = indicator.forecast;
    final visible = [
      ...hist.skip(math.max(0, hist.length - range)),
      ...forecast,
    ];
    final latest = indicator.latest;
    final avg7 = indicator.last7Average;
    final peak =
        forecast.isEmpty ? null : forecast.map((p) => p.value).reduce(math.max);
    String f(double? v) =>
        v == null ? '—' : Fmt.number(v, decimals: indicator.decimals);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(indicator.name,
                      style: context.textStyles.titleMedium)),
              OriginBadge(origin: indicator.origin),
            ],
          ),
          if (indicator.isEmpty)
            const EmptyView(
              compact: true,
              icon: Icons.inbox_outlined,
              title: 'Sem dados',
              message: 'Este indicador ainda não tem registros.',
            )
          else ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                    child: MetricTile(
                        label: 'Último',
                        value: f(latest?.value),
                        unit: indicator.unit)),
                Expanded(
                    child: MetricTile(
                        label: 'Média 7 dias',
                        value: f(avg7),
                        unit: indicator.unit)),
                Expanded(
                    child: MetricTile(
                        label: 'Previsão máx.',
                        value: f(peak),
                        unit: indicator.unit)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            TrendBadge(
                change: indicator.weeklyChange,
                higherIsWorse: indicator.higherIsWorse),
            const SizedBox(height: AppSpacing.md),
            TrendChart(
              series: visible,
              color: color,
              unit: indicator.unit,
              threshold: threshold,
              decimals: indicator.decimals,
              asBars: indicator.preferBars,
            ),
          ],
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => Navigator.pushNamed(
                context,
                AppRoutes.indicator,
                arguments: indicator.id,
              ),
              icon: const Icon(Icons.analytics_outlined),
              label: const Text('Ver detalhes'),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:radar_vila/core/constants.dart';
import 'package:radar_vila/core/theme/app_spacing.dart';
import 'package:radar_vila/core/theme/theme_context.dart';
import 'package:radar_vila/core/utils/formatters.dart';
import 'package:radar_vila/domain/social_impact.dart';
import 'package:radar_vila/models/indicator.dart';
import 'package:radar_vila/models/territory_snapshot.dart';
import 'package:radar_vila/providers/load_status.dart';
import 'package:radar_vila/providers/occurrence_provider.dart';
import 'package:radar_vila/providers/territory_provider.dart';
import 'package:radar_vila/routes/app_routes.dart';
import 'package:radar_vila/widgets/alert_tile.dart';
import 'package:radar_vila/widgets/app_card.dart';
import 'package:radar_vila/widgets/app_logo.dart';
import 'package:radar_vila/widgets/banners.dart';
import 'package:radar_vila/widgets/dashboard_entry_card.dart';
import 'package:radar_vila/widgets/responsive_grid.dart';
import 'package:radar_vila/widgets/section_header.dart';
import 'package:radar_vila/widgets/social_impact_card.dart';
import 'package:radar_vila/widgets/state_views.dart';

/// Visão geral do território: entrada para os 3 dashboards e alertas.
class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key, required this.onOpenTab});

  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context) {
    final territory = context.watch<TerritoryProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const AppLogo(size: 30),
        actions: [
          IconButton(
            tooltip: 'Mapa do território',
            icon: const Icon(Icons.map_outlined),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.map),
          ),
          IconButton(
            tooltip: 'Sobre os dados e limitações',
            icon: const Icon(Icons.info_outline),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.about),
          ),
          IconButton(
            tooltip: 'Atualizar dados',
            icon: const Icon(Icons.refresh),
            onPressed: territory.isLoading ? null : territory.load,
          ),
        ],
      ),
      // Transição suave entre carregando → erro → conteúdo.
      body: AnimatedSwitcher(
        duration: MediaQuery.of(context).disableAnimations
            ? Duration.zero
            : const Duration(milliseconds: 300),
        child: KeyedSubtree(
          key: ValueKey(territory.hasData
              ? 'data'
              : territory.status == LoadStatus.error
                  ? 'error'
                  : 'loading'),
          child: _body(context, territory),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, TerritoryProvider territory) {
    if (!territory.hasData) {
      if (territory.status == LoadStatus.error) {
        return ErrorView(
          message:
              territory.errorMessage ?? 'Não foi possível carregar os dados.',
          onRetry: territory.load,
        );
      }
      return const LoadingView(message: 'Carregando dados do território…');
    }

    final snapshot = territory.snapshot!;
    final occurrences = context.watch<OccurrenceProvider>();
    final impact = SocialImpact.compute(
      water: territory.indicatorById(IndicatorIds.aguaConsumo),
      reviewedAlerts: territory.reviewedAlertsCount,
      citizenReports: occurrences.items.length,
    );
    final topAlerts = territory.alerts.take(3).toList();

    return RefreshIndicator(
      onRefresh: territory.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _TerritoryHeader(snapshot: snapshot, loading: territory.isLoading),
          if (snapshot.fromCache || snapshot.warning != null) ...[
            const SizedBox(height: AppSpacing.md),
            OfflineBanner(snapshot: snapshot, onRetry: territory.load),
          ],
          const SizedBox(height: AppSpacing.md),
          const HumanDecisionBanner(compact: true),
          const SectionHeader(title: 'Painéis do território'),
          ResponsiveGrid(
            children: [
              for (final type in DashboardType.values)
                DashboardEntryCard(type: type),
            ],
          ),
          SectionHeader(
            title: 'Alertas prioritários',
            actionLabel: 'Ver todos',
            onAction: () => onOpenTab(1),
          ),
          if (topAlerts.isEmpty)
            const EmptyView(
              compact: true,
              icon: Icons.check_circle_outline,
              title: 'Nenhum alerta ativo',
              message: 'Com os limiares atuais, os dados não indicam riscos.',
            )
          else
            for (final alert in topAlerts)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AlertTile(alert: alert),
              ),
          const SectionHeader(title: 'Impacto social'),
          SocialImpactCard(impact: impact),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _TerritoryHeader extends StatelessWidget {
  const _TerritoryHeader({required this.snapshot, required this.loading});

  final TerritorySnapshot snapshot;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Icon(Icons.location_on_outlined,
              color: context.colors.primary, size: 32),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(TerritoryInfo.name,
                      style: context.textStyles.titleLarge),
                ),
                Text(
                  '${TerritoryInfo.city} · ≈ '
                  '${Fmt.compact(TerritoryInfo.population.toDouble())} habitantes',
                ),
                const SizedBox(height: 2),
                Text(
                  'Atualizado em ${Fmt.dateTime(snapshot.fetchedAt)}',
                  style: context.mutedSmall,
                ),
              ],
            ),
          ),
          if (loading)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                  strokeWidth: 2.4, semanticsLabel: 'Atualizando'),
            ),
        ],
      ),
    );
  }
}

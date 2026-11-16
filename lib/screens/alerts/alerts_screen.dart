import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:radar_vila/core/theme/app_spacing.dart';
import 'package:radar_vila/models/alert.dart';
import 'package:radar_vila/providers/load_status.dart';
import 'package:radar_vila/providers/territory_provider.dart';
import 'package:radar_vila/widgets/alert_tile.dart';
import 'package:radar_vila/widgets/banners.dart';
import 'package:radar_vila/widgets/state_views.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  // Estado LOCAL dos filtros.
  AlertSeverity? _severity;
  bool _onlyPending = false;

  @override
  Widget build(BuildContext context) {
    final territory = context.watch<TerritoryProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Alertas preditivos')),
      body: () {
        if (!territory.hasData) {
          return territory.status == LoadStatus.error
              ? ErrorView(
                  message: territory.errorMessage ?? 'Erro ao carregar.',
                  onRetry: territory.load)
              : const LoadingView(message: 'Calculando alertas…');
        }

        final all = territory.alerts;
        final filtered = all.where((a) {
          if (_severity != null && a.severity != _severity) return false;
          if (_onlyPending &&
              territory.decisionFor(a.id) != HumanDecision.pendente) {
            return false;
          }
          return true;
        }).toList();

        return RefreshIndicator(
          onRefresh: territory.load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              const HumanDecisionBanner(),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  ChoiceChip(
                    label: Text('Todos (${all.length})'),
                    selected: _severity == null,
                    onSelected: (_) => setState(() => _severity = null),
                  ),
                  for (final s in AlertSeverity.values.reversed)
                    ChoiceChip(
                      avatar: Icon(s.icon, size: 18),
                      label: Text(
                          '${s.label} (${all.where((a) => a.severity == s).length})'),
                      selected: _severity == s,
                      onSelected: (_) => setState(() => _severity = s),
                    ),
                  FilterChip(
                    label: const Text('Só aguardando decisão'),
                    selected: _onlyPending,
                    onSelected: (v) => setState(() => _onlyPending = v),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              if (filtered.isEmpty)
                EmptyView(
                  icon: Icons.notifications_off_outlined,
                  title: all.isEmpty
                      ? 'Nenhum alerta ativo'
                      : 'Nenhum alerta neste filtro',
                  message: all.isEmpty
                      ? 'Com os limiares atuais, os dados não indicam riscos. '
                          'Você pode ajustar os limiares em Ajustes.'
                      : 'Troque o filtro para ver os demais alertas.',
                )
              else
                for (final alert in filtered)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: AlertTile(alert: alert),
                  ),
            ],
          ),
        );
      }(),
    );
  }
}

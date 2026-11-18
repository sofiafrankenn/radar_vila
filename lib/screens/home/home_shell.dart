import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:radar_vila/core/utils/formatters.dart';
import 'package:radar_vila/models/alert.dart';
import 'package:radar_vila/providers/territory_provider.dart';
import 'package:radar_vila/routes/app_routes.dart';
import 'package:radar_vila/screens/alerts/alerts_screen.dart';
import 'package:radar_vila/screens/home/overview_screen.dart';
import 'package:radar_vila/screens/occurrences/occurrences_screen.dart';
import 'package:radar_vila/screens/settings/settings_screen.dart';

/// Estrutura principal com navegação inferior entre as 4 abas.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0; // estado LOCAL da aba selecionada

  /// Alertas críticos já avisados nesta sessão (evita aviso repetido).
  final Set<String> _notifiedCritical = {};
  late final TerritoryProvider _territory;

  void _goTo(int index) => setState(() => _index = index);

  @override
  void initState() {
    super.initState();
    _territory = context.read<TerritoryProvider>();
    _territory.addListener(_checkCriticalAlerts);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkCriticalAlerts());
  }

  @override
  void dispose() {
    _territory.removeListener(_checkCriticalAlerts);
    super.dispose();
  }

  /// Notificação no app quando surge um alerta CRÍTICO ainda sem decisão.
  /// O aviso só chama a atenção do gestor; nenhuma ação é tomada sozinha.
  void _checkCriticalAlerts() {
    if (!mounted) return;
    final fresh = _territory.alerts
        .where((a) =>
            a.severity == AlertSeverity.critico &&
            _territory.decisionFor(a.id) == HumanDecision.pendente &&
            !_notifiedCritical.contains(a.id))
        .toList();
    if (fresh.isEmpty) return;
    _notifiedCritical.addAll(fresh.map((a) => a.id));

    final single = fresh.length == 1 ? fresh.first : null;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
        persist: false, // some sozinho para não cobrir formulários
        showCloseIcon: true,
        content: Semantics(
          liveRegion: true,
          child: Text(single != null
              ? 'Alerta crítico: ${single.title}. Requer avaliação humana.'
              : '${fresh.length} alertas críticos aguardam avaliação humana.'),
        ),
        action: SnackBarAction(
          label: 'Ver',
          onPressed: () {
            if (single != null) {
              Navigator.pushNamed(context, AppRoutes.alertDetail,
                  arguments: single.id);
            } else {
              _goTo(1);
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending =
        context.select<TerritoryProvider, int>((t) => t.pendingAlertsCount);

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          OverviewScreen(onOpenTab: _goTo),
          const AlertsScreen(),
          const OccurrencesScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _goTo,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard),
            label: 'Visão geral',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: pending > 0,
              label: Text('$pending'),
              child: const Icon(Icons.notifications_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: pending > 0,
              label: Text('$pending'),
              child: const Icon(Icons.notifications),
            ),
            label: 'Alertas',
            tooltip: pending > 0
                ? '${Fmt.count(pending, 'alerta', 'alertas')} aguardando decisão'
                : 'Alertas',
          ),
          const NavigationDestination(
            icon: Icon(Icons.campaign_outlined),
            selectedIcon: Icon(Icons.campaign),
            label: 'Ocorrências',
          ),
          const NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}

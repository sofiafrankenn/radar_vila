import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:radar_vila/providers/territory_provider.dart';
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

  void _goTo(int index) => setState(() => _index = index);

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
            tooltip:
                pending > 0 ? '$pending alertas aguardando decisão' : 'Alertas',
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

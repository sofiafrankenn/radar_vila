import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:radar_vila/core/theme/app_spacing.dart';
import 'package:radar_vila/core/theme/theme_context.dart';
import 'package:radar_vila/core/utils/formatters.dart';
import 'package:radar_vila/providers/occurrence_provider.dart';
import 'package:radar_vila/providers/settings_provider.dart';
import 'package:radar_vila/providers/territory_provider.dart';
import 'package:radar_vila/routes/app_routes.dart';
import 'package:radar_vila/widgets/app_card.dart';
import 'package:radar_vila/widgets/confirm_dialog.dart';
import 'package:radar_vila/widgets/section_header.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _clearOccurrences(BuildContext context) async {
    final provider = context.read<OccurrenceProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showConfirmDialog(
      context,
      title: 'Apagar suas ocorrências?',
      message: 'Todos os registros feitos neste aparelho serão apagados. '
          'Essa ação não pode ser desfeita.',
      confirmLabel: 'Apagar tudo',
      destructive: true,
    );
    if (!ok) return;
    await provider.clear();
    messenger
        .showSnackBar(const SnackBar(content: Text('Ocorrências apagadas.')));
  }

  Future<void> _revokeConsent(BuildContext context) async {
    final settings = context.read<SettingsProvider>();
    final occurrences = context.read<OccurrenceProvider>();
    final navigator = Navigator.of(context);
    final ok = await showConfirmDialog(
      context,
      title: 'Revogar consentimento?',
      message: 'Suas ocorrências serão apagadas e o app voltará à tela de '
          'consentimento.',
      confirmLabel: 'Revogar',
      destructive: true,
    );
    if (!ok) return;
    navigator.popUntil((r) => r.isFirst);
    await occurrences.clear();
    await settings.revokeConsent();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final t = settings.thresholds;
    final text = context.textStyles;

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const SectionHeader(title: 'Aparência e acessibilidade'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tema', style: text.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                          value: ThemeMode.system,
                          label: Text('Sistema'),
                          icon: Icon(Icons.brightness_auto)),
                      ButtonSegment(
                          value: ThemeMode.light,
                          label: Text('Claro'),
                          icon: Icon(Icons.light_mode)),
                      ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text('Escuro'),
                          icon: Icon(Icons.dark_mode)),
                    ],
                    selected: {settings.themeMode},
                    onSelectionChanged: (s) => settings.setThemeMode(s.first),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: settings.highContrast,
                  onChanged: settings.setHighContrast,
                  title: const Text('Alto contraste'),
                  subtitle: const Text(
                      'Cores com contraste reforçado e bordas marcadas.'),
                ),
                const Divider(),
                Text(
                  'Tamanho do texto: ${Fmt.percent(settings.textScale)}',
                  style: text.titleSmall,
                ),
                Slider(
                  value: settings.textScale,
                  min: 1.0,
                  max: 1.6,
                  divisions: 6,
                  label: Fmt.percent(settings.textScale),
                  semanticFormatterCallback: (v) =>
                      'Tamanho do texto ${(v * 100).round()} por cento',
                  onChanged: settings.setTextScale,
                ),
                Text(
                  'Somado ao tamanho de fonte do sistema. Leitores de tela '
                  '(TalkBack/VoiceOver) são suportados em todas as telas.',
                  style: context.mutedSmall,
                ),
              ],
            ),
          ),
          const SectionHeader(title: 'Alertas'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.tune),
                  title: const Text('Limiares de alerta'),
                  subtitle: Text(
                    'Água ${Fmt.number(t.aguaConsumo, decimals: 0)} L · '
                    'Perdas ${Fmt.number(t.aguaPerdas, decimals: 0)}% · '
                    'Pico ${Fmt.number(t.energiaPico, decimals: 0)} MW · '
                    'Calor ${Fmt.number(t.calor, decimals: 0)} °C · '
                    'Chuva ${Fmt.number(t.chuva, decimals: 0)} mm',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.thresholds),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.menu_book_outlined),
                  title: const Text('Como os alertas são gerados'),
                  subtitle: const Text('Métricas, limitações e vieses'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pushNamed(context, AppRoutes.about),
                ),
              ],
            ),
          ),
          const SectionHeader(title: 'Dados e conexão'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.wifi_off),
                  value: settings.simulateOffline,
                  onChanged: settings.setSimulateOffline,
                  title: const Text('Simular falta de conexão'),
                  subtitle: const Text(
                    'Demonstração: o app passa a usar apenas os dados salvos no aparelho.',
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.refresh),
                  title: const Text('Atualizar dados agora'),
                  onTap: () => context.read<TerritoryProvider>().load(),
                ),
              ],
            ),
          ),
          const SectionHeader(title: 'Privacidade (LGPD)'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.verified_user_outlined),
                  title: const Text('Consentimento concedido'),
                  subtitle: Text(
                    settings.consentDate == null
                        ? '—'
                        : 'em ${Fmt.date(settings.consentDate!)}',
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.groups_outlined),
                  value: settings.shareAggregated,
                  onChanged: settings.setShareAggregated,
                  title: const Text(
                      'Usar minhas ocorrências em indicadores agregados'),
                  subtitle: const Text('Sempre anonimizadas. Opcional.'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_sweep_outlined),
                  title: const Text('Apagar minhas ocorrências'),
                  onTap: () => _clearOccurrences(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.logout, color: context.colors.error),
                  title: Text('Revogar consentimento',
                      style: TextStyle(color: context.colors.error)),
                  subtitle: const Text(
                      'Apaga suas ocorrências e volta à tela inicial.'),
                  onTap: () => _revokeConsent(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: Text(
              'RadarVila 1.0 · FIAP Global Solution 2026.2',
              style: context.mutedSmall,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

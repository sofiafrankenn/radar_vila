import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:radar_vila/core/theme/app_spacing.dart';
import 'package:radar_vila/core/theme/theme_context.dart';
import 'package:radar_vila/providers/settings_provider.dart';
import 'package:radar_vila/widgets/app_card.dart';
import 'package:radar_vila/widgets/app_logo.dart';

class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  // Estado LOCAL: só existe nesta tela.
  bool _accepted = false;
  bool _shareAggregated = false;

  void _continue() {
    context
        .read<SettingsProvider>()
        .giveConsent(shareAggregated: _shareAggregated);
  }

  @override
  Widget build(BuildContext context) {
    final text = context.textStyles;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                const Align(
                    alignment: Alignment.centerLeft, child: AppLogo(size: 52)),
                const SizedBox(height: AppSpacing.xl),
                Semantics(
                  header: true,
                  child: Text('Antes de começar', style: text.headlineSmall),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'O RadarVila é o painel de inteligência territorial da Vila '
                  'Mariana: acompanha água, energia e clima do bairro e emite '
                  'alertas que antecipam problemas.',
                ),
                const SizedBox(height: AppSpacing.lg),
                const _InfoItem(
                  icon: Icons.public,
                  title: 'Dados usados',
                  text: 'Clima real (Open-Meteo) e dados sintéticos de consumo '
                      'para demonstração.',
                ),
                const _InfoItem(
                  icon: Icons.shield_outlined,
                  title: 'Sua privacidade',
                  text: 'Ocorrências ficam somente neste aparelho. Não pedimos '
                      'nome, telefone nem endereço: o CEP é cortado (04101-***) '
                      'e você recebe um apelido aleatório.',
                ),
                const _InfoItem(
                  icon: Icons.person_search_outlined,
                  title: 'Decisão humana',
                  text: 'Os alertas apoiam a decisão. Nenhuma ação é tomada '
                      'automaticamente: um gestor sempre decide.',
                ),
                const _InfoItem(
                  icon: Icons.delete_outline,
                  title: 'Seus direitos (LGPD)',
                  text: 'Você pode revogar o consentimento e apagar seus '
                      'registros a qualquer momento em Ajustes.',
                ),
                const SizedBox(height: AppSpacing.md),
                CheckboxListTile(
                  value: _accepted,
                  onChanged: (v) => setState(() => _accepted = v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                      'Li e concordo com o uso descrito acima (obrigatório)'),
                ),
                CheckboxListTile(
                  value: _shareAggregated,
                  onChanged: (v) =>
                      setState(() => _shareAggregated = v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Permitir que minhas ocorrências anonimizadas componham '
                    'indicadores agregados do bairro (opcional)',
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  onPressed: _accepted ? _continue : null,
                  icon: const Icon(Icons.check),
                  label: const Text('Concordo e quero continuar'),
                ),
                if (!_accepted) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Marque a caixa obrigatória para continuar.',
                    textAlign: TextAlign.center,
                    style: context.mutedSmall,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem(
      {required this.icon, required this.title, required this.text});

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: context.colors.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.textStyles.titleSmall),
                  const SizedBox(height: 2),
                  Text(text, style: context.textStyles.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

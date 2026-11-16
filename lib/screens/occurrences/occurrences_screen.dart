import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:radar_vila/core/theme/app_spacing.dart';
import 'package:radar_vila/core/theme/theme_context.dart';
import 'package:radar_vila/core/utils/formatters.dart';
import 'package:radar_vila/models/occurrence.dart';
import 'package:radar_vila/providers/load_status.dart';
import 'package:radar_vila/providers/occurrence_provider.dart';
import 'package:radar_vila/routes/app_routes.dart';
import 'package:radar_vila/widgets/app_card.dart';
import 'package:radar_vila/widgets/confirm_dialog.dart';
import 'package:radar_vila/widgets/pills.dart';
import 'package:radar_vila/widgets/section_header.dart';
import 'package:radar_vila/widgets/state_views.dart';

class OccurrencesScreen extends StatelessWidget {
  const OccurrencesScreen({super.key});

  void _openForm(BuildContext context) =>
      Navigator.pushNamed(context, AppRoutes.occurrenceForm);

  @override
  Widget build(BuildContext context) {
    final occurrences = context.watch<OccurrenceProvider>();
    final items = occurrences.items;

    Widget body;
    if (occurrences.status == LoadStatus.error) {
      body = ErrorView(
        message: occurrences.errorMessage ?? 'Erro ao carregar ocorrências.',
        onRetry: occurrences.load,
      );
    } else if (items.isEmpty &&
        (occurrences.isLoading || occurrences.status == LoadStatus.initial)) {
      body = const LoadingView(message: 'Carregando ocorrências…');
    } else if (items.isEmpty) {
      body = EmptyView(
        icon: Icons.campaign_outlined,
        title: 'Nenhuma ocorrência registrada',
        message: 'Viu um vazamento, falta de água ou alagamento? '
            'Registre de forma anônima e ajude a priorizar a resposta.',
        action: FilledButton.icon(
          onPressed: () => _openForm(context),
          icon: const Icon(Icons.add),
          label: const Text('Registrar ocorrência'),
        ),
      );
    } else {
      final counts = occurrences.countByCategory;
      body = ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 96),
        children: [
          const InfoPill(
            icon: Icons.lock_outline,
            text: 'Registros anônimos, salvos somente neste aparelho',
          ),
          const SectionHeader(title: 'Resumo por categoria'),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final entry in counts.entries)
                InfoPill(
                    icon: entry.key.icon,
                    text: '${entry.key.label}: ${entry.value}'),
            ],
          ),
          SectionHeader(title: 'Registros (${items.length})'),
          for (final o in items)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _OccurrenceTile(occurrence: o),
            ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Ocorrências cidadãs')),
      floatingActionButton: items.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openForm(context),
              tooltip: 'Registrar nova ocorrência',
              icon: const Icon(Icons.add),
              label: const Text('Registrar'),
            ),
      body: body,
    );
  }
}

class _OccurrenceTile extends StatelessWidget {
  const _OccurrenceTile({required this.occurrence});

  final Occurrence occurrence;

  Future<void> _delete(BuildContext context) async {
    final provider = context.read<OccurrenceProvider>();
    final confirmed = await showConfirmDialog(
      context,
      title: 'Excluir ocorrência?',
      message: 'O registro será apagado deste aparelho.',
      confirmLabel: 'Excluir',
      destructive: true,
    );
    if (confirmed) await provider.remove(occurrence.id);
  }

  @override
  Widget build(BuildContext context) {
    final o = occurrence;
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(o.category.icon, color: context.colors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(o.category.label, style: context.textStyles.titleSmall),
                Text('${o.region} · ${Fmt.date(o.date)}',
                    style: context.mutedSmall),
                const SizedBox(height: AppSpacing.xs),
                Text(o.description),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${o.reporterAlias}${o.cepPrefix != null ? ' · CEP ${o.cepPrefix}' : ''}',
                  style: context.mutedSmall,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Excluir ocorrência',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _delete(context),
          ),
        ],
      ),
    );
  }
}

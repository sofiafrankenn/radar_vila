import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:radar_vila/core/theme/app_inputs.dart';
import 'package:radar_vila/core/theme/app_spacing.dart';
import 'package:radar_vila/core/theme/theme_context.dart';
import 'package:radar_vila/core/utils/formatters.dart';
import 'package:radar_vila/models/alert.dart';
import 'package:radar_vila/providers/settings_provider.dart';
import 'package:radar_vila/providers/territory_provider.dart';
import 'package:radar_vila/widgets/app_card.dart';
import 'package:radar_vila/widgets/banners.dart';
import 'package:radar_vila/widgets/confidence_meter.dart';
import 'package:radar_vila/widgets/pills.dart';
import 'package:radar_vila/widgets/section_header.dart';
import 'package:radar_vila/widgets/semantic_colors.dart';
import 'package:radar_vila/widgets/state_views.dart';
import 'package:radar_vila/widgets/trend_chart.dart';

/// Detalhe do alerta: evidências, confiança, limitações e decisão humana.
class AlertDetailScreen extends StatelessWidget {
  const AlertDetailScreen({super.key, required this.alertId});

  final String alertId;

  @override
  Widget build(BuildContext context) {
    final territory = context.watch<TerritoryProvider>();
    final alert = territory.alertById(alertId);

    if (alert == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Alerta')),
        body: territory.isLoading
            ? const LoadingView()
            : const EmptyView(
                icon: Icons.notifications_off_outlined,
                title: 'Este alerta não está mais ativo',
                message:
                    'Os dados ou os limiares mudaram e o alerta deixou de ser gerado.',
              ),
      );
    }

    final indicator = territory.indicatorById(alert.indicatorId);
    final threshold = context
        .watch<SettingsProvider>()
        .thresholds
        .forIndicator(alert.indicatorId);
    final text = context.textStyles;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalhe do alerta')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              SeverityChip(severity: alert.severity),
              InfoPill(icon: Icons.schedule, text: alert.horizonLabel),
              InfoPill(icon: Icons.sensors, text: alert.indicatorName),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Semantics(
              header: true,
              child: Text(alert.title, style: text.headlineSmall)),
          const SizedBox(height: AppSpacing.sm),
          Text(alert.summary, style: text.bodyLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Gerado em ${Fmt.dateTime(alert.generatedAt)} · ${alert.method.label}',
            style: context.mutedSmall,
          ),
          const SectionHeader(title: 'Nível de confiança'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ConfidenceMeter(confidence: alert.confidence),
                const SizedBox(height: AppSpacing.md),
                Text(alert.confidenceRationale, style: text.bodySmall),
              ],
            ),
          ),
          const SectionHeader(title: 'Evidências (justificativa)'),
          AppCard(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            child: Column(
              children: [
                for (var i = 0; i < alert.evidence.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  Semantics(
                    label:
                        '${alert.evidence[i].label}: ${alert.evidence[i].value}',
                    excludeSemantics: true,
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: Text(alert.evidence[i].label)),
                          const SizedBox(width: AppSpacing.md),
                          Text(alert.evidence[i].value, style: text.titleSmall),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (indicator != null && !indicator.isEmpty) ...[
            const SectionHeader(title: 'Dados que geraram o alerta'),
            AppCard(
              child: TrendChart(
                series: [
                  ...indicator.history
                      .skip(math.max(0, indicator.history.length - 14)),
                  ...indicator.forecast,
                ],
                color: dashboardColor(context, indicator.dashboard),
                unit: indicator.unit,
                threshold: threshold,
                decimals: indicator.decimals,
                asBars: indicator.preferBars,
              ),
            ),
          ],
          const SectionHeader(title: 'Limitações — quando não confiar'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final item in alert.limitations)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.report_gmailerrorred,
                            size: 18, color: context.palette.atencao),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: Text(item)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SectionHeader(title: 'Em linguagem simples'),
          AppCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.record_voice_over_outlined,
                    color: context.colors.primary),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: Text(alert.citizenExplanation)),
              ],
            ),
          ),
          const SectionHeader(title: 'Sugestão para avaliação'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert.suggestedAction),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Sugestão não executada automaticamente.',
                  style:
                      context.mutedSmall?.copyWith(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const HumanDecisionBanner(),
          const SectionHeader(title: 'Decisão do gestor'),
          _DecisionPanel(alert: alert),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

class _DecisionPanel extends StatelessWidget {
  const _DecisionPanel({required this.alert});

  final TerritoryAlert alert;

  Future<void> _decide(BuildContext context, HumanDecision decision) async {
    final territory = context.read<TerritoryProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final note = await showDialog<String>(
      context: context,
      builder: (_) => _DecisionNoteDialog(decision: decision),
    );
    if (note == null) return;
    await territory.setDecision(alert.id, decision, note);
    messenger.showSnackBar(
      SnackBar(content: Text('Decisão registrada: ${decision.label}.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final territory = context.watch<TerritoryProvider>();
    final record = territory.decisionRecordFor(alert.id);
    final current = record?.decision ?? HumanDecision.pendente;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(current.icon, color: context.colors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                  child: Text(current.label,
                      style: context.textStyles.titleSmall)),
            ],
          ),
          if (record != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text('Registrado em ${Fmt.dateTime(record.decidedAt)}',
                style: context.mutedSmall),
            if (record.note.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text('Justificativa: ${record.note}'),
            ],
          ],
          const SizedBox(height: AppSpacing.lg),
          if (current == HumanDecision.pendente) ...[
            FilledButton.icon(
              onPressed: () => _decide(context, HumanDecision.emAnalise),
              icon: Icon(HumanDecision.emAnalise.icon),
              label: Text(HumanDecision.emAnalise.actionLabel),
            ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton.tonalIcon(
              onPressed: () => _decide(context, HumanDecision.acaoEncaminhada),
              icon: Icon(HumanDecision.acaoEncaminhada.icon),
              label: Text(HumanDecision.acaoEncaminhada.actionLabel),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () => _decide(context, HumanDecision.descartado),
              icon: Icon(HumanDecision.descartado.icon),
              label: Text(HumanDecision.descartado.actionLabel),
            ),
          ] else ...[
            if (current == HumanDecision.emAnalise) ...[
              FilledButton.tonalIcon(
                onPressed: () =>
                    _decide(context, HumanDecision.acaoEncaminhada),
                icon: Icon(HumanDecision.acaoEncaminhada.icon),
                label: Text(HumanDecision.acaoEncaminhada.actionLabel),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            OutlinedButton.icon(
              onPressed: () => _decide(context, HumanDecision.pendente),
              icon: const Icon(Icons.undo),
              label: const Text('Reabrir alerta'),
            ),
          ],
        ],
      ),
    );
  }
}

class _DecisionNoteDialog extends StatefulWidget {
  const _DecisionNoteDialog({required this.decision});

  final HumanDecision decision;

  @override
  State<_DecisionNoteDialog> createState() => _DecisionNoteDialogState();
}

class _DecisionNoteDialogState extends State<_DecisionNoteDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  bool get _required =>
      widget.decision == HumanDecision.descartado ||
      widget.decision == HumanDecision.acaoEncaminhada;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, _controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.decision == HumanDecision.pendente
        ? 'Reabrir alerta'
        : widget.decision.actionLabel;
    return AlertDialog(
      title: Text(title),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          maxLines: 3,
          maxLength: 200,
          decoration: AppInputs.decoration(
            context,
            label: _required ? 'Justificativa *' : 'Observação (opcional)',
            helper: 'Fica registrada junto à decisão, para transparência.',
          ),
          validator: (value) {
            final v = value?.trim() ?? '';
            if (_required && v.length < 10) {
              return 'Explique a decisão com pelo menos 10 caracteres.';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        FilledButton(onPressed: _confirm, child: const Text('Confirmar')),
      ],
    );
  }
}

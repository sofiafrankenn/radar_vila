import 'package:material_ui/material_ui.dart';

enum AlertSeverity {
  informativo('Informativo', Icons.info_outline, 0),
  atencao('Atenção', Icons.warning_amber_rounded, 1),
  critico('Crítico', Icons.error_outline, 2);

  const AlertSeverity(this.label, this.icon, this.weight);

  final String label;
  final IconData icon;
  final int weight;
}

enum AlertMethod {
  regraLimiar('Regra de limiar sobre a média de 7 dias'),
  regressaoLinear('Regressão linear (tendência de 14 dias)'),
  previsaoMeteorologica('Previsão meteorológica Open-Meteo + regra de limiar'),
  anomaliaEstatistica('Detecção de anomalia (z-score)');

  const AlertMethod(this.label);
  final String label;
}

/// Decisão registrada por uma pessoa. O app nunca muda isso sozinho.
enum HumanDecision {
  pendente('Aguardando decisão humana', 'Reabrir', Icons.hourglass_empty),
  emAnalise(
      'Em análise pela equipe', 'Encaminhar para análise', Icons.manage_search),
  acaoEncaminhada('Ação encaminhada', 'Registrar ação encaminhada',
      Icons.assignment_turned_in_outlined),
  descartado('Descartado pelo gestor', 'Descartar alerta', Icons.block);

  const HumanDecision(this.label, this.actionLabel, this.icon);

  final String label;
  final String actionLabel;
  final IconData icon;
}

class Evidence {
  const Evidence(this.label, this.value);

  final String label;
  final String value;
}

class TerritoryAlert {
  const TerritoryAlert({
    required this.id,
    required this.indicatorId,
    required this.indicatorName,
    required this.title,
    required this.summary,
    required this.severity,
    required this.method,
    required this.confidence,
    required this.confidenceRationale,
    required this.evidence,
    required this.limitations,
    required this.suggestedAction,
    required this.citizenExplanation,
    required this.generatedAt,
    required this.horizonDays,
    required this.referenceDate,
  });

  final String id;
  final String indicatorId;
  final String indicatorName;
  final String title;
  final String summary;
  final AlertSeverity severity;
  final AlertMethod method;

  /// 0 a 1.
  final double confidence;
  final String confidenceRationale;
  final List<Evidence> evidence;
  final List<String> limitations;
  final String suggestedAction;
  final String citizenExplanation;
  final DateTime generatedAt;

  /// 0 = situação atual; 1 = amanhã; ...
  final int horizonDays;
  final DateTime referenceDate;

  String get confidenceLabel => confidenceLabelFor(confidence);

  String get horizonLabel => switch (horizonDays) {
        0 => 'Situação atual',
        1 => 'Previsto para amanhã',
        _ => 'Previsto em $horizonDays dias',
      };

  static String confidenceLabelFor(double c) {
    if (c >= 0.7) return 'Alta';
    if (c >= 0.4) return 'Média';
    return 'Baixa';
  }
}

class AlertDecisionRecord {
  const AlertDecisionRecord({
    required this.decision,
    required this.note,
    required this.decidedAt,
  });

  final HumanDecision decision;
  final String note;
  final DateTime decidedAt;

  Map<String, dynamic> toJson() => {
        'decision': decision.name,
        'note': note,
        'decidedAt': decidedAt.toIso8601String(),
      };

  factory AlertDecisionRecord.fromJson(Map<String, dynamic> json) =>
      AlertDecisionRecord(
        decision: HumanDecision.values.firstWhere(
          (d) => d.name == json['decision'],
          orElse: () => HumanDecision.pendente,
        ),
        note: json['note'] as String? ?? '',
        decidedAt: DateTime.tryParse(json['decidedAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

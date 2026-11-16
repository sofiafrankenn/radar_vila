import 'package:material_ui/material_ui.dart';

enum OccurrenceCategory {
  vazamento('Vazamento de água', Icons.water_drop_outlined),
  faltaAgua('Falta de água', Icons.format_color_reset_outlined),
  quedaEnergia('Queda de energia', Icons.power_off_outlined),
  alagamento('Alagamento', Icons.flood_outlined),
  calorExtremo('Calor extremo / falta de sombra', Icons.wb_sunny_outlined),
  outro('Outro', Icons.more_horiz);

  const OccurrenceCategory(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// Ocorrência registrada pelo cidadão — já anonimizada.
class Occurrence {
  const Occurrence({
    required this.id,
    required this.category,
    required this.region,
    required this.description,
    required this.date,
    required this.reporterAlias,
    required this.createdAt,
    this.cepPrefix,
  });

  final String id;
  final OccurrenceCategory category;
  final String region;
  final String description;
  final DateTime date;

  /// Apelido aleatório (nunca o nome real).
  final String reporterAlias;

  /// Só os 5 primeiros dígitos do CEP ("04101-***").
  final String? cepPrefix;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category.name,
        'region': region,
        'description': description,
        'date': date.toIso8601String(),
        'reporterAlias': reporterAlias,
        'cepPrefix': cepPrefix,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Occurrence.fromJson(Map<String, dynamic> json) => Occurrence(
        id: json['id'] as String,
        category: OccurrenceCategory.values.firstWhere(
          (c) => c.name == json['category'],
          orElse: () => OccurrenceCategory.outro,
        ),
        region: json['region'] as String,
        description: json['description'] as String,
        date: DateTime.parse(json['date'] as String),
        reporterAlias: json['reporterAlias'] as String? ?? 'Cidadão anônimo',
        cepPrefix: json['cepPrefix'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

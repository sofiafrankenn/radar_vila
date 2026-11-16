import 'package:radar_vila/models/indicator.dart';

/// Limiares de alerta definidos por pessoas (gestores), nunca pelo app.
class Thresholds {
  const Thresholds({
    required this.aguaConsumo,
    required this.aguaPerdas,
    required this.energiaPico,
    required this.calor,
    required this.chuva,
  });

  /// L/hab/dia
  final double aguaConsumo;

  /// % da água distribuída
  final double aguaPerdas;

  /// MW na subestação
  final double energiaPico;

  /// °C (2+ dias seguidos)
  final double calor;

  /// mm/dia
  final double chuva;

  static const Thresholds defaults = Thresholds(
    aguaConsumo: 180,
    aguaPerdas: 30,
    energiaPico: 44,
    calor: 32,
    chuva: 40,
  );

  double? forIndicator(String id) => switch (id) {
        IndicatorIds.aguaConsumo => aguaConsumo,
        IndicatorIds.aguaPerdas => aguaPerdas,
        IndicatorIds.energiaPico => energiaPico,
        IndicatorIds.climaTempMax => calor,
        IndicatorIds.climaChuva => chuva,
        _ => null,
      };

  Thresholds copyWith({
    double? aguaConsumo,
    double? aguaPerdas,
    double? energiaPico,
    double? calor,
    double? chuva,
  }) =>
      Thresholds(
        aguaConsumo: aguaConsumo ?? this.aguaConsumo,
        aguaPerdas: aguaPerdas ?? this.aguaPerdas,
        energiaPico: energiaPico ?? this.energiaPico,
        calor: calor ?? this.calor,
        chuva: chuva ?? this.chuva,
      );

  Map<String, dynamic> toJson() => {
        'aguaConsumo': aguaConsumo,
        'aguaPerdas': aguaPerdas,
        'energiaPico': energiaPico,
        'calor': calor,
        'chuva': chuva,
      };

  factory Thresholds.fromJson(Map<String, dynamic> json) {
    double read(String key, double fallback) =>
        (json[key] as num?)?.toDouble() ?? fallback;
    return Thresholds(
      aguaConsumo: read('aguaConsumo', defaults.aguaConsumo),
      aguaPerdas: read('aguaPerdas', defaults.aguaPerdas),
      energiaPico: read('energiaPico', defaults.energiaPico),
      calor: read('calor', defaults.calor),
      chuva: read('chuva', defaults.chuva),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Thresholds &&
      other.aguaConsumo == aguaConsumo &&
      other.aguaPerdas == aguaPerdas &&
      other.energiaPico == energiaPico &&
      other.calor == calor &&
      other.chuva == chuva;

  @override
  int get hashCode =>
      Object.hash(aguaConsumo, aguaPerdas, energiaPico, calor, chuva);
}

import 'package:material_ui/material_ui.dart';

import 'package:radar_vila/domain/statistics.dart';
import 'package:radar_vila/models/data_point.dart';

/// IDs estáveis dos indicadores monitorados.
class IndicatorIds {
  IndicatorIds._();

  static const String aguaConsumo = 'agua_consumo';
  static const String aguaPerdas = 'agua_perdas';
  static const String energiaConsumo = 'energia_consumo';
  static const String energiaPico = 'energia_pico';
  static const String climaTempMax = 'clima_temp_max';
  static const String climaChuva = 'clima_chuva';
}

/// Os três dashboards territoriais.
enum DashboardType {
  agua(
      'Água', 'Consumo per capita e perdas na rede', Icons.water_drop_outlined),
  energia(
      'Energia', 'Consumo residencial e pico de demanda', Icons.bolt_outlined),
  clima('Clima local', 'Temperatura e chuva — dados reais (Open-Meteo)',
      Icons.thermostat_outlined);

  const DashboardType(this.label, this.subtitle, this.icon);

  final String label;
  final String subtitle;
  final IconData icon;
}

enum DataOrigin {
  real('Dado real'),
  sintetico('Dado sintético');

  const DataOrigin(this.label);
  final String label;
}

class Indicator {
  const Indicator({
    required this.id,
    required this.name,
    required this.unit,
    required this.dashboard,
    required this.origin,
    required this.source,
    required this.description,
    required this.series,
    this.higherIsWorse = true,
    this.decimals = 1,
    this.preferBars = false,
  });

  final String id;
  final String name;
  final String unit;
  final DashboardType dashboard;
  final DataOrigin origin;
  final String source;
  final String description;
  final List<DataPoint> series;
  final bool higherIsWorse;
  final int decimals;
  final bool preferBars;

  List<DataPoint> get history =>
      series.where((p) => !p.isForecast).toList(growable: false);

  List<DataPoint> get forecast =>
      series.where((p) => p.isForecast).toList(growable: false);

  bool get isEmpty => series.isEmpty;

  DataPoint? get latest {
    final h = history;
    return h.isEmpty ? null : h.last;
  }

  /// Variação da média dos últimos 7 dias contra os 7 anteriores.
  double? get weeklyChange =>
      Stats.weeklyChange(history.map((p) => p.value).toList());

  double? get last7Average {
    final h = history;
    if (h.isEmpty) return null;
    final start = h.length > 7 ? h.length - 7 : 0;
    return Stats.mean(h.sublist(start).map((p) => p.value).toList());
  }

  Indicator copyWith({List<DataPoint>? series}) => Indicator(
        id: id,
        name: name,
        unit: unit,
        dashboard: dashboard,
        origin: origin,
        source: source,
        description: description,
        series: series ?? this.series,
        higherIsWorse: higherIsWorse,
        decimals: decimals,
        preferBars: preferBars,
      );
}

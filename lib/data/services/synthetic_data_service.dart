import 'dart:math' as math;

import 'package:radar_vila/models/data_point.dart';
import 'package:radar_vila/models/indicator.dart';

/// "API" simulada de consumo de água e energia.
///
/// Gera séries determinísticas (mesma data = mesmo valor) com:
/// tendência, efeito de fim de semana e ruído. O cenário representa um
/// período de estresse hídrico para demonstrar os alertas.
class SyntheticDataService {
  SyntheticDataService({this.latency = const Duration(milliseconds: 700)});

  final Duration latency;

  Future<Map<String, List<DataPoint>>> fetch({DateTime? today}) async {
    await Future<void>.delayed(latency);
    return generate(today: today ?? DateTime.now());
  }

  static Map<String, List<DataPoint>> generate({
    required DateTime today,
    int days = 30,
  }) {
    final end = DateTime(today.year, today.month, today.day - 1); // ontem
    return {
      IndicatorIds.aguaConsumo: _series(
          seed: 11,
          end: end,
          days: days,
          base: 179,
          trendPerDay: 0.9,
          weekendDelta: 7,
          noise: 3),
      IndicatorIds.aguaPerdas: _series(
          seed: 23,
          end: end,
          days: days,
          base: 31.5,
          trendPerDay: 0.05,
          weekendDelta: 0,
          noise: 1.2),
      IndicatorIds.energiaConsumo: _series(
          seed: 37,
          end: end,
          days: days,
          base: 10.2,
          trendPerDay: 0.03,
          weekendDelta: 0.8,
          noise: 0.35),
      IndicatorIds.energiaPico: _series(
          seed: 41,
          end: end,
          days: days,
          base: 41.5,
          trendPerDay: 0.12,
          weekendDelta: -2.5,
          noise: 0.8),
    };
  }

  static List<DataPoint> _series({
    required int seed,
    required DateTime end,
    required int days,
    required double base,
    required double trendPerDay,
    required double weekendDelta,
    required double noise,
  }) {
    final epoch = DateTime.utc(2020);
    final points = <DataPoint>[];
    for (var i = 0; i < days; i++) {
      final daysBack = days - 1 - i;
      final date = DateTime(end.year, end.month, end.day - daysBack);
      final dayKey = DateTime.utc(date.year, date.month, date.day)
          .difference(epoch)
          .inDays;
      final rnd = math.Random(seed * 100003 + dayKey);
      final weekend = date.weekday >= DateTime.saturday ? weekendDelta : 0.0;
      final value = base -
          trendPerDay * daysBack +
          weekend +
          (rnd.nextDouble() * 2 - 1) * noise;
      points.add(DataPoint(
        date: date,
        value: double.parse(math.max(0.0, value).toStringAsFixed(2)),
      ));
    }
    return points;
  }
}

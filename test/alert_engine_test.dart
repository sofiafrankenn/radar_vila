import 'package:flutter_test/flutter_test.dart';

import 'package:radar_vila/data/indicator_catalog.dart';
import 'package:radar_vila/domain/alert_engine.dart';
import 'package:radar_vila/models/alert.dart';
import 'package:radar_vila/models/data_point.dart';
import 'package:radar_vila/models/indicator.dart';
import 'package:radar_vila/models/thresholds.dart';

final _now = DateTime(2026, 11, 10, 12);
final _yesterday = DateTime(2026, 11, 9);

List<DataPoint> _linear(
        {required double start, required double step, int days = 21}) =>
    List.generate(
      days,
      (i) => DataPoint(
        date: DateTime(
            _yesterday.year, _yesterday.month, _yesterday.day - (days - 1 - i)),
        value: start + step * i,
      ),
    );

List<DataPoint> _forecast(List<double> values) => [
      for (var i = 0; i < values.length; i++)
        DataPoint(
          date: DateTime(_now.year, _now.month, _now.day + i),
          value: values[i],
          isForecast: true,
        ),
    ];

void main() {
  group('Regra de tendência (consumo de água)', () {
    test('gera alerta com evidência, confiança e limitações', () {
      final ind = IndicatorCatalog.build(
        IndicatorIds.aguaConsumo,
        _linear(start: 150, step: 1.5), // termina em 180
      );
      final alerts = AlertEngine(thresholds: Thresholds.defaults, now: _now)
          .evaluate([ind]);
      final alert =
          alerts.firstWhere((a) => a.method == AlertMethod.regressaoLinear);

      expect(alert.severity, AlertSeverity.critico);
      expect(alert.evidence, isNotEmpty);
      expect(alert.limitations, isNotEmpty);
      expect(alert.confidence, inInclusiveRange(0.05, 0.95));
      expect(
          alert.confidence, greaterThanOrEqualTo(0.7)); // reta perfeita: R² = 1
      expect(alert.horizonDays, 0);
    });

    test('não gera alerta com série estável abaixo do limiar', () {
      final ind = IndicatorCatalog.build(
        IndicatorIds.aguaConsumo,
        _linear(start: 150, step: 0),
      );
      final alerts = AlertEngine(thresholds: Thresholds.defaults, now: _now)
          .evaluate([ind]);
      expect(alerts, isEmpty);
    });

    test('limiar mais alto definido pelo gestor elimina o alerta', () {
      final ind = IndicatorCatalog.build(
        IndicatorIds.aguaConsumo,
        _linear(start: 150, step: 1.5),
      );
      final alerts = AlertEngine(
        thresholds: Thresholds.defaults.copyWith(aguaConsumo: 250),
        now: _now,
      ).evaluate([ind]);
      expect(alerts.where((a) => a.method == AlertMethod.regressaoLinear),
          isEmpty);
    });

    test('dados em cache reduzem a confiança', () {
      final ind = IndicatorCatalog.build(
        IndicatorIds.aguaConsumo,
        _linear(start: 150, step: 1.5),
      );
      final online = AlertEngine(thresholds: Thresholds.defaults, now: _now)
          .evaluate([ind]).first;
      final cached = AlertEngine(
              thresholds: Thresholds.defaults, fromCache: true, now: _now)
          .evaluate([ind]).first;
      expect(cached.confidence, lessThan(online.confidence));
      expect(cached.limitations.any((l) => l.contains('sem conexão')), isTrue);
    });
  });

  group('Onda de calor', () {
    test('2 dias seguidos acima do limiar geram alerta', () {
      final ind = IndicatorCatalog.build(IndicatorIds.climaTempMax, [
        ..._linear(start: 27, step: 0, days: 10),
        ..._forecast([29, 33, 34, 28]),
      ]);
      final alerts = AlertEngine(thresholds: Thresholds.defaults, now: _now)
          .evaluate([ind]);
      final heat =
          alerts.firstWhere((a) => a.title == 'Onda de calor prevista');
      expect(heat.horizonDays, 1);
      expect(heat.severity, AlertSeverity.atencao);
    });

    test('um único dia quente não gera alerta', () {
      final ind = IndicatorCatalog.build(IndicatorIds.climaTempMax, [
        ..._linear(start: 27, step: 0, days: 10),
        ..._forecast([29, 35, 28, 27]),
      ]);
      final alerts = AlertEngine(thresholds: Thresholds.defaults, now: _now)
          .evaluate([ind]);
      expect(alerts, isEmpty);
    });
  });

  group('Chuva', () {
    test('chuva acima do limiar gera alerta crítico quando ≥ 1,5× o limiar',
        () {
      final ind = IndicatorCatalog.build(IndicatorIds.climaChuva, [
        ..._linear(start: 0, step: 0, days: 10),
        ..._forecast([0, 2, 65]),
      ]);
      final alerts = AlertEngine(thresholds: Thresholds.defaults, now: _now)
          .evaluate([ind]);
      expect(alerts.single.severity, AlertSeverity.critico);
      expect(alerts.single.horizonDays, 2);
    });
  });

  group('Anomalia', () {
    test(
        'valor muito fora do padrão gera alerta informativo de baixa confiança',
        () {
      final base = _linear(start: 10, step: 0, days: 15);
      final series = [
        for (var i = 0; i < base.length - 1; i++)
          DataPoint(date: base[i].date, value: i.isEven ? 10 : 10.4),
        DataPoint(date: base.last.date, value: 16),
      ];
      final ind = IndicatorCatalog.build(IndicatorIds.energiaConsumo, series);
      final alerts = AlertEngine(thresholds: Thresholds.defaults, now: _now)
          .evaluate([ind]);
      final anomaly = alerts.single;
      expect(anomaly.method, AlertMethod.anomaliaEstatistica);
      expect(anomaly.severity, AlertSeverity.informativo);
      expect(anomaly.confidenceLabel, 'Baixa');
    });
  });

  test('alertas são ordenados por severidade', () {
    final water = IndicatorCatalog.build(
        IndicatorIds.aguaConsumo, _linear(start: 150, step: 1.5));
    final rain = IndicatorCatalog.build(IndicatorIds.climaChuva, [
      ..._linear(start: 0, step: 0, days: 10),
      ..._forecast([0, 45]),
    ]);
    final alerts = AlertEngine(thresholds: Thresholds.defaults, now: _now)
        .evaluate([rain, water]);
    expect(alerts.first.severity.weight,
        greaterThanOrEqualTo(alerts.last.severity.weight));
  });
}

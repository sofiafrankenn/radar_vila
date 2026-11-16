import 'package:flutter_test/flutter_test.dart';

import 'package:radar_vila/domain/statistics.dart';
import 'package:radar_vila/models/data_point.dart';

void main() {
  test('regressão em reta perfeita tem R² = 1', () {
    final reg = Stats.linearRegression([1, 3, 5, 7, 9]);
    expect(reg.slope, closeTo(2, 1e-9));
    expect(reg.intercept, closeTo(1, 1e-9));
    expect(reg.r2, closeTo(1, 1e-9));
  });

  test('média e desvio padrão amostral', () {
    expect(Stats.mean([2, 4, 6]), 4);
    expect(Stats.stdDev([2, 4, 6]), closeTo(2, 1e-9));
  });

  test('variação semanal', () {
    final values = [...List.filled(7, 100.0), ...List.filled(7, 110.0)];
    expect(Stats.weeklyChange(values), closeTo(0.10, 1e-9));
  });

  test('previsão linear projeta a tendência', () {
    final history = List.generate(
      10,
      (i) => DataPoint(date: DateTime(2026, 11, 1 + i), value: 100.0 + i),
    );
    final forecast = Forecaster.linear(history, horizon: 3);
    expect(forecast, hasLength(3));
    expect(forecast.every((p) => p.isForecast), isTrue);
    expect(forecast.first.value, closeTo(110, 1e-6));
    expect(forecast.first.date, DateTime(2026, 11, 11));
  });
}

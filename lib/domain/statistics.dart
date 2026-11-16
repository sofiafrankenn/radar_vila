import 'dart:math' as math;

import 'package:radar_vila/models/data_point.dart';

class RegressionResult {
  const RegressionResult({
    required this.slope,
    required this.intercept,
    required this.r2,
    required this.n,
  });

  final double slope;
  final double intercept;

  /// Coeficiente de determinação (0 a 1): quanto da variação a reta explica.
  final double r2;
  final int n;

  double predict(double x) => intercept + slope * x;
}

/// Estatística básica usada pelo motor de alertas.
class Stats {
  Stats._();

  static double mean(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  /// Desvio padrão amostral.
  static double stdDev(List<double> values) {
    if (values.length < 2) return 0;
    final m = mean(values);
    final sum = values.fold<double>(0, (acc, x) => acc + (x - m) * (x - m));
    return math.sqrt(sum / (values.length - 1));
  }

  static double zScore(double value, List<double> reference) {
    final sd = stdDev(reference);
    if (sd == 0) return 0;
    return (value - mean(reference)) / sd;
  }

  /// Mínimos quadrados com x = 0, 1, 2, ... n-1.
  static RegressionResult linearRegression(List<double> ys) {
    final n = ys.length;
    if (n < 2) {
      return RegressionResult(
        slope: 0,
        intercept: n == 1 ? ys.first : 0,
        r2: 0,
        n: n,
      );
    }
    final mx = (n - 1) / 2;
    final my = mean(ys);
    var sxy = 0.0;
    var sxx = 0.0;
    for (var i = 0; i < n; i++) {
      sxy += (i - mx) * (ys[i] - my);
      sxx += (i - mx) * (i - mx);
    }
    final slope = sxx == 0 ? 0.0 : sxy / sxx;
    final intercept = my - slope * mx;

    var ssRes = 0.0;
    var ssTot = 0.0;
    for (var i = 0; i < n; i++) {
      final pred = intercept + slope * i;
      ssRes += (ys[i] - pred) * (ys[i] - pred);
      ssTot += (ys[i] - my) * (ys[i] - my);
    }
    final r2 = ssTot == 0
        ? (ssRes == 0 ? 1.0 : 0.0)
        : (1 - ssRes / ssTot).clamp(0.0, 1.0).toDouble();

    return RegressionResult(slope: slope, intercept: intercept, r2: r2, n: n);
  }

  /// Variação relativa da média dos últimos 7 dias contra os 7 anteriores.
  static double? weeklyChange(List<double> values) {
    if (values.length < 14) return null;
    final last = mean(values.sublist(values.length - 7));
    final prev = mean(values.sublist(values.length - 14, values.length - 7));
    if (prev == 0) return null;
    return (last - prev) / prev;
  }
}

/// Previsão de curto prazo por tendência linear.
class Forecaster {
  Forecaster._();

  static List<DataPoint> linear(
    List<DataPoint> history, {
    int window = 14,
    int horizon = 3,
    double minValue = 0,
  }) {
    if (history.length < 3) return const [];
    final slice = history.length > window
        ? history.sublist(history.length - window)
        : history;
    final reg = Stats.linearRegression(slice.map((p) => p.value).toList());
    final last = slice.last.date;
    return List<DataPoint>.generate(horizon, (i) {
      final x = (slice.length + i).toDouble();
      final value = math.max(minValue, reg.predict(x));
      return DataPoint(
        date: DateTime(last.year, last.month, last.day + i + 1),
        value: double.parse(value.toStringAsFixed(2)),
        isForecast: true,
      );
    });
  }
}

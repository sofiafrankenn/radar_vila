import 'dart:math' as math;

import 'package:radar_vila/core/constants.dart';
import 'package:radar_vila/domain/statistics.dart';
import 'package:radar_vila/models/indicator.dart';

/// Indicador de benefício social exibido no app.
class SocialImpact {
  const SocialImpact({
    required this.averageConsumption,
    required this.potentialSavingLitersPerWeek,
    required this.peopleSuppliedPerDay,
    required this.reviewedAlerts,
    required this.citizenReports,
  });

  /// Média de consumo dos últimos 7 dias (L/hab/dia); null sem dados.
  final double? averageConsumption;

  /// Litros/semana economizados se o consumo voltasse à meta de 150 L/hab/dia.
  final double potentialSavingLitersPerWeek;

  /// Pessoas que esse volume abasteceria por dia (110 L/pessoa, ONU).
  final double peopleSuppliedPerDay;

  final int reviewedAlerts;
  final int citizenReports;

  bool get hasWaterData => averageConsumption != null;

  bool get withinTarget => hasWaterData && potentialSavingLitersPerWeek <= 0;

  static SocialImpact compute({
    required Indicator? water,
    required int reviewedAlerts,
    required int citizenReports,
    int population = TerritoryInfo.population,
  }) {
    final hist = water?.history ?? const [];
    if (hist.isEmpty) {
      return SocialImpact(
        averageConsumption: null,
        potentialSavingLitersPerWeek: 0,
        peopleSuppliedPerDay: 0,
        reviewedAlerts: reviewedAlerts,
        citizenReports: citizenReports,
      );
    }
    final start = math.max(0, hist.length - 7);
    final avg = Stats.mean(hist.sublist(start).map((p) => p.value).toList());
    final excess = math.max(0.0, avg - ImpactReference.conscientConsumption);
    final dailySaving = excess * population;

    return SocialImpact(
      averageConsumption: avg,
      potentialSavingLitersPerWeek: dailySaving * 7,
      peopleSuppliedPerDay: dailySaving / ImpactReference.unDailyNeed,
      reviewedAlerts: reviewedAlerts,
      citizenReports: citizenReports,
    );
  }
}

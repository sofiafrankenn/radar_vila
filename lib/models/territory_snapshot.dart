import 'package:radar_vila/models/indicator.dart';

/// Retrato dos dados do território em um momento.
class TerritorySnapshot {
  const TerritorySnapshot({
    required this.indicators,
    required this.fetchedAt,
    this.fromCache = false,
    this.warning,
  });

  final List<Indicator> indicators;
  final DateTime fetchedAt;

  /// true quando os dados vêm do armazenamento local (sem conexão).
  final bool fromCache;

  /// Mensagem sobre falhas parciais de atualização.
  final String? warning;

  List<Indicator> indicatorsFor(DashboardType type) =>
      indicators.where((i) => i.dashboard == type).toList(growable: false);

  TerritorySnapshot copyWith({bool? fromCache, String? warning}) =>
      TerritorySnapshot(
        indicators: indicators,
        fetchedAt: fetchedAt,
        fromCache: fromCache ?? this.fromCache,
        warning: warning ?? this.warning,
      );

  Map<String, dynamic> toJson() => {
        'fetchedAt': fetchedAt.toIso8601String(),
        'indicators': [
          for (final i in indicators)
            {
              'id': i.id,
              'series': [for (final p in i.series) p.toJson()],
            },
        ],
      };
}

import 'dart:async';

import 'package:radar_vila/core/constants.dart';
import 'package:radar_vila/core/utils/formatters.dart';
import 'package:radar_vila/data/api_exception.dart';
import 'package:radar_vila/data/indicator_catalog.dart';
import 'package:radar_vila/data/local/local_store.dart';
import 'package:radar_vila/data/services/climate_api_service.dart';
import 'package:radar_vila/data/services/synthetic_data_service.dart';
import 'package:radar_vila/domain/statistics.dart';
import 'package:radar_vila/models/data_point.dart';
import 'package:radar_vila/models/indicator.dart';
import 'package:radar_vila/models/territory_snapshot.dart';

/// Junta as fontes de dados e mantém um cache local para uso offline.
class TerritoryRepository {
  TerritoryRepository({
    required LocalStore store,
    required ClimateApiService climateService,
    required SyntheticDataService syntheticService,
  })  : _store = store,
        _climate = climateService,
        _synthetic = syntheticService;

  final LocalStore _store;
  final ClimateApiService _climate;
  final SyntheticDataService _synthetic;

  Future<TerritorySnapshot> load({bool simulateOffline = false}) async {
    final cached = readCache();

    if (simulateOffline) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (cached == null) {
        throw const ApiException(
            'Sem conexão e nenhum dado salvo no aparelho. Conecte-se para '
            'baixar os dados pela primeira vez.');
      }
      return cached.copyWith(
        fromCache: true,
        warning: 'Modo sem conexão: exibindo dados salvos em '
            '${Fmt.dateTime(cached.fetchedAt)}.',
      );
    }

    final warnings = <String>[];
    var usedCache = false;
    var climateOk = true;
    var consumptionOk = true;

    // Clima — dados reais.
    List<Indicator> climate;
    try {
      final data = await _climate.fetch(
        latitude: TerritoryInfo.latitude,
        longitude: TerritoryInfo.longitude,
      );
      climate = [
        IndicatorCatalog.build(IndicatorIds.climaTempMax, data.temperatureMax),
        IndicatorCatalog.build(IndicatorIds.climaChuva, data.precipitation),
      ];
    } catch (e) {
      climateOk = false;
      warnings.add('clima (${_describe(e)})');
      final fromCache =
          cached?.indicatorsFor(DashboardType.clima) ?? const <Indicator>[];
      usedCache = usedCache || fromCache.isNotEmpty;
      climate = fromCache.isNotEmpty
          ? fromCache
          : [
              IndicatorCatalog.build(IndicatorIds.climaTempMax, const []),
              IndicatorCatalog.build(IndicatorIds.climaChuva, const []),
            ];
    }

    // Consumo — API simulada.
    List<Indicator> consumption;
    try {
      final data = await _synthetic.fetch();
      consumption = [
        for (final entry in data.entries)
          IndicatorCatalog.build(entry.key, _withForecast(entry.value)),
      ];
    } catch (e) {
      consumptionOk = false;
      warnings.add('consumo (${_describe(e)})');
      final fromCache = [
        ...?cached?.indicatorsFor(DashboardType.agua),
        ...?cached?.indicatorsFor(DashboardType.energia),
      ];
      usedCache = usedCache || fromCache.isNotEmpty;
      consumption = fromCache;
    }

    if (!climateOk && !consumptionOk) {
      if (cached == null) {
        throw ApiException(
            'Não foi possível carregar os dados e não há cópia salva no '
            'aparelho. Falhou: ${warnings.join(', ')}.');
      }
      return cached.copyWith(
        fromCache: true,
        warning: 'Sem conexão: exibindo dados salvos em '
            '${Fmt.dateTime(cached.fetchedAt)}.',
      );
    }

    final snapshot = TerritorySnapshot(
      indicators: [...consumption, ...climate],
      fetchedAt: DateTime.now(),
      fromCache: usedCache,
      warning: warnings.isEmpty
          ? null
          : 'Parte dos dados não foi atualizada: ${warnings.join(', ')}.',
    );
    if (warnings.isEmpty) {
      await _store.setJson(StorageKeys.territoryCache, snapshot.toJson());
    }
    return snapshot;
  }

  TerritorySnapshot? readCache() {
    final json = _store.getJson(StorageKeys.territoryCache);
    if (json == null) return null;
    try {
      final indicators = <Indicator>[];
      for (final raw in (json['indicators'] as List)) {
        final map = raw as Map<String, dynamic>;
        final series = [
          for (final p in (map['series'] as List))
            DataPoint.fromJson(p as Map<String, dynamic>),
        ];
        indicators.add(IndicatorCatalog.build(map['id'] as String, series));
      }
      return TerritorySnapshot(
        indicators: indicators,
        fetchedAt: DateTime.parse(json['fetchedAt'] as String),
        fromCache: true,
      );
    } catch (_) {
      return null; // cache corrompido é ignorado
    }
  }

  List<DataPoint> _withForecast(List<DataPoint> history) =>
      [...history, ...Forecaster.linear(history)];

  String _describe(Object e) {
    if (e is ApiException) return e.message;
    if (e is TimeoutException) return 'tempo de resposta esgotado';
    return 'serviço indisponível';
  }
}

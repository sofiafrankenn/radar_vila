import 'package:radar_vila/models/data_point.dart';
import 'package:radar_vila/models/indicator.dart';

/// Metadados de cada indicador (nome, unidade, fonte...).
class IndicatorCatalog {
  IndicatorCatalog._();

  static const String _syntheticSource =
      'Simulação do RadarVila (perfil residencial típico; ordem de grandeza '
      'inspirada em dados públicos do SNIS/ANEEL).';
  static const String _openMeteo =
      'Open-Meteo — API pública de previsão do tempo (open-meteo.com).';

  static const List<String> allIds = [
    IndicatorIds.aguaConsumo,
    IndicatorIds.aguaPerdas,
    IndicatorIds.energiaConsumo,
    IndicatorIds.energiaPico,
    IndicatorIds.climaTempMax,
    IndicatorIds.climaChuva,
  ];

  static Indicator build(String id, List<DataPoint> series) {
    final sorted = [...series]..sort((a, b) => a.date.compareTo(b.date));
    switch (id) {
      case IndicatorIds.aguaConsumo:
        return Indicator(
          id: id,
          name: 'Consumo de água per capita',
          unit: 'L/hab/dia',
          dashboard: DashboardType.agua,
          origin: DataOrigin.sintetico,
          source: _syntheticSource,
          description:
              'Litros de água consumidos por habitante por dia no bairro.',
          series: sorted,
          decimals: 0,
        );
      case IndicatorIds.aguaPerdas:
        return Indicator(
          id: id,
          name: 'Perdas na distribuição',
          unit: '%',
          dashboard: DashboardType.agua,
          origin: DataOrigin.sintetico,
          source: _syntheticSource,
          description:
              'Percentual da água tratada que se perde em vazamentos e '
              'ligações irregulares antes de chegar aos imóveis.',
          series: sorted,
        );
      case IndicatorIds.energiaConsumo:
        return Indicator(
          id: id,
          name: 'Consumo residencial de energia',
          unit: 'kWh/dom/dia',
          dashboard: DashboardType.energia,
          origin: DataOrigin.sintetico,
          source: _syntheticSource,
          description: 'Energia consumida por domicílio por dia.',
          series: sorted,
        );
      case IndicatorIds.energiaPico:
        return Indicator(
          id: id,
          name: 'Pico de demanda na subestação',
          unit: 'MW',
          dashboard: DashboardType.energia,
          origin: DataOrigin.sintetico,
          source: _syntheticSource,
          description: 'Maior demanda diária registrada na subestação que '
              'atende o bairro (capacidade simulada: 48 MW).',
          series: sorted,
        );
      case IndicatorIds.climaTempMax:
        return Indicator(
          id: id,
          name: 'Temperatura máxima',
          unit: '°C',
          dashboard: DashboardType.clima,
          origin: DataOrigin.real,
          source: _openMeteo,
          description: 'Temperatura máxima diária a 2 m do solo — últimos 30 '
              'dias e previsão para 7 dias.',
          series: sorted,
        );
      case IndicatorIds.climaChuva:
        return Indicator(
          id: id,
          name: 'Chuva acumulada no dia',
          unit: 'mm',
          dashboard: DashboardType.clima,
          origin: DataOrigin.real,
          source: _openMeteo,
          description: 'Precipitação total do dia — últimos 30 dias e previsão '
              'para 7 dias.',
          series: sorted,
          preferBars: true,
        );
      default:
        throw ArgumentError('Indicador desconhecido: $id');
    }
  }
}

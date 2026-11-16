import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:radar_vila/data/api_exception.dart';
import 'package:radar_vila/models/data_point.dart';

class ClimateData {
  const ClimateData(
      {required this.temperatureMax, required this.precipitation});

  final List<DataPoint> temperatureMax;
  final List<DataPoint> precipitation;
}

/// Dados meteorológicos REAIS da API pública Open-Meteo (sem chave).
class ClimateApiService {
  ClimateApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Pode ser trocada sem alterar o código:
  /// flutter run --dart-define=CLIMATE_API_URL=https://...
  static const String baseUrl = String.fromEnvironment(
    'CLIMATE_API_URL',
    defaultValue: 'https://api.open-meteo.com/v1/forecast',
  );

  Future<ClimateData> fetch({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse(baseUrl).replace(queryParameters: {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'daily': 'temperature_2m_max,precipitation_sum',
      'past_days': '30',
      'forecast_days': '7',
      'timezone': 'America/Sao_Paulo',
    });

    http.Response response;
    try {
      response = await _client.get(uri).timeout(const Duration(seconds: 12));
    } on TimeoutException {
      throw const ApiException('O serviço de clima demorou para responder.');
    } catch (_) {
      throw const ApiException('Sem conexão com o serviço de clima.');
    }

    if (response.statusCode != 200) {
      throw ApiException(
          'O serviço de clima respondeu com erro ${response.statusCode}.');
    }
    return parse(response.body);
  }

  /// Converte a resposta JSON. Datas a partir de hoje são marcadas como previsão.
  static ClimateData parse(String body, {DateTime? today}) {
    final Object? json;
    try {
      json = jsonDecode(body);
    } catch (_) {
      throw const ApiException('Resposta do serviço de clima ilegível.');
    }
    if (json is! Map<String, dynamic> || json['daily'] is! Map) {
      throw const ApiException(
          'Resposta do serviço de clima em formato inesperado.');
    }

    final daily = json['daily'] as Map;
    final times = (daily['time'] as List?) ?? const [];
    final tmax = (daily['temperature_2m_max'] as List?) ?? const [];
    final rain = (daily['precipitation_sum'] as List?) ?? const [];

    final now = today ?? DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final temps = <DataPoint>[];
    final precs = <DataPoint>[];

    for (var i = 0; i < times.length; i++) {
      final date = DateTime.tryParse(times[i].toString());
      if (date == null) continue;
      final forecast = !date.isBefore(todayDate);
      final t = i < tmax.length ? tmax[i] : null;
      final r = i < rain.length ? rain[i] : null;
      if (t is num) {
        temps.add(
            DataPoint(date: date, value: t.toDouble(), isForecast: forecast));
      }
      if (r is num) {
        precs.add(
            DataPoint(date: date, value: r.toDouble(), isForecast: forecast));
      }
    }
    return ClimateData(temperatureMax: temps, precipitation: precs);
  }
}

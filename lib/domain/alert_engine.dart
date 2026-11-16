import 'dart:math' as math;

import 'package:radar_vila/core/utils/formatters.dart';
import 'package:radar_vila/domain/statistics.dart';
import 'package:radar_vila/models/alert.dart';
import 'package:radar_vila/models/data_point.dart';
import 'package:radar_vila/models/indicator.dart';
import 'package:radar_vila/models/thresholds.dart';

/// Gera alertas a partir de regras e previsões sobre os dados.
///
/// Importante: o motor apenas SUGERE. Nenhuma ação é executada;
/// cada alerta precisa de uma decisão humana registrada no app.
class AlertEngine {
  AlertEngine({
    required this.thresholds,
    this.fromCache = false,
    DateTime? now,
  }) : now = now ?? DateTime.now();

  final Thresholds thresholds;
  final bool fromCache;
  final DateTime now;

  static const int trendWindow = 14;
  static const int trendHorizon = 3;
  static const double anomalyZ = 2.5;

  /// Dados em cache reduzem a confiança em 25%.
  double get _freshness => fromCache ? 0.75 : 1.0;

  List<TerritoryAlert> evaluate(List<Indicator> indicators) {
    final alerts = <TerritoryAlert>[];
    void add(TerritoryAlert? alert) {
      if (alert != null) alerts.add(alert);
    }

    for (final ind in indicators) {
      switch (ind.id) {
        case IndicatorIds.aguaConsumo:
          add(_trendRule(
            ind,
            thresholds.aguaConsumo,
            title: 'Consumo de água pode ultrapassar o limiar',
            suggestedAction:
                'Avaliar campanha de consumo consciente e verificar com a '
                'concessionária o nível dos reservatórios que abastecem o bairro.',
            citizen:
                'O consumo de água no bairro vem subindo e pode passar do nível '
                'considerado seguro nos próximos dias. Evitar desperdício '
                '(banhos longos, lavar calçada com mangueira) ajuda a evitar '
                'falta de água.',
          ));
        case IndicatorIds.energiaPico:
          add(_trendRule(
            ind,
            thresholds.energiaPico,
            title: 'Pico de demanda de energia em alta',
            suggestedAction:
                'Avaliar com a distribuidora o remanejamento de carga e uma '
                'comunicação preventiva aos moradores.',
            citizen:
                'A demanda de energia nos horários de pico está crescendo e '
                'pode chegar perto do limite da rede local. Evitar ligar vários '
                'aparelhos potentes ao mesmo tempo no fim da tarde ajuda a '
                'prevenir quedas.',
          ));
        case IndicatorIds.aguaPerdas:
          add(_averageRule(ind, thresholds.aguaPerdas));
        case IndicatorIds.climaTempMax:
          add(_heatRule(ind, thresholds.calor));
        case IndicatorIds.climaChuva:
          add(_rainRule(ind, thresholds.chuva));
      }
      // Chuva tem muitos dias zerados: z-score não faz sentido nela.
      if (ind.id != IndicatorIds.climaChuva) add(_anomalyRule(ind));
    }

    alerts.sort((a, b) {
      final bySeverity = b.severity.weight.compareTo(a.severity.weight);
      return bySeverity != 0
          ? bySeverity
          : b.confidence.compareTo(a.confidence);
    });
    return alerts;
  }

  // ---------------------------------------------------------------------------
  // Regras
  // ---------------------------------------------------------------------------

  /// Regressão linear nos últimos 14 dias, projetada 3 dias à frente.
  TerritoryAlert? _trendRule(
    Indicator ind,
    double threshold, {
    required String title,
    required String suggestedAction,
    required String citizen,
  }) {
    final hist = ind.history;
    if (hist.length < 7) return null;

    final window = hist.length > trendWindow
        ? hist.sublist(hist.length - trendWindow)
        : hist;
    final values = window.map((p) => p.value).toList();
    final reg = Stats.linearRegression(values);
    final forecasts = List<double>.generate(
      trendHorizon,
      (i) => math.max(0.0, reg.predict((values.length + i).toDouble())),
    );
    final maxForecast = forecasts.reduce(math.max);
    final latest = hist.last.value;

    if (maxForecast < threshold && latest < threshold) return null;

    final firstCross = forecasts.indexWhere((v) => v >= threshold);
    final horizon = latest >= threshold ? 0 : firstCross + 1;
    final critical = latest >= threshold || maxForecast >= threshold * 1.1;
    final coverage = math.min(values.length / 21, 1.0);
    final confidence =
        _clamp((0.15 + 0.55 * reg.r2 + 0.30 * coverage) * _freshness);
    final last7 = _lastValues(hist, 7);

    String f(double v) => _fmt(ind, v);

    return TerritoryAlert(
      id: _id(AlertMethod.regressaoLinear, ind, hist.last.date),
      indicatorId: ind.id,
      indicatorName: ind.name,
      title: title,
      summary: latest >= threshold
          ? 'O valor mais recente (${f(latest)}) já está acima do limiar de '
              '${f(threshold)} e a tendência é de '
              '${reg.slope >= 0 ? 'alta' : 'queda'}.'
          : 'A tendência dos últimos ${values.length} dias projeta até '
              '${f(maxForecast)} nos próximos $trendHorizon dias, acima do '
              'limiar de ${f(threshold)}.',
      severity: critical ? AlertSeverity.critico : AlertSeverity.atencao,
      method: AlertMethod.regressaoLinear,
      confidence: confidence,
      confidenceRationale: 'Combina a qualidade do ajuste da tendência (R² = '
          '${Fmt.number(reg.r2, decimals: 2)}), a quantidade de dias de '
          'histórico (${values.length} de 21 ideais) e a atualidade dos dados'
          '${fromCache ? ' (reduzida porque os dados estão em cache)' : ''}.',
      evidence: [
        Evidence('Último valor (${Fmt.dayMonth(hist.last.date)})', f(latest)),
        Evidence('Média dos últimos 7 dias', f(Stats.mean(last7))),
        Evidence('Tendência (regressão linear)',
            '${Fmt.signed(reg.slope, decimals: 2)} ${ind.unit}/dia'),
        Evidence('Previsão máxima (próx. $trendHorizon dias)', f(maxForecast)),
        Evidence('Limiar definido pelo gestor', f(threshold)),
        Evidence('Qualidade do ajuste (R²)', Fmt.number(reg.r2, decimals: 2)),
        Evidence('Dias de histórico usados', '${values.length}'),
      ],
      limitations: [
        'A regressão linear supõe que a tendência recente continua; feriados, '
            'obras, mudança de tarifa ou chuvas fortes quebram essa hipótese.',
        if (reg.r2 < 0.4)
          'Ajuste fraco (R² abaixo de 0,4): a série oscila muito e esta '
              'previsão é pouco confiável.',
        'Não calculamos previsões além de $trendHorizon dias, pois o erro '
            'cresce rapidamente.',
        ..._baseLimitations(ind),
      ],
      suggestedAction: suggestedAction,
      citizenExplanation: citizen,
      generatedAt: now,
      horizonDays: horizon,
      referenceDate: hist.last.date,
    );
  }

  /// Média de 7 dias acima do limiar (perdas na rede).
  TerritoryAlert? _averageRule(Indicator ind, double threshold) {
    final hist = ind.history;
    if (hist.length < 7) return null;
    final last7 = _lastValues(hist, 7);
    final avg = Stats.mean(last7);
    if (avg < threshold) return null;

    final cv = avg == 0 ? 1.0 : Stats.stdDev(last7) / avg;
    final confidence = _clamp((0.92 - cv * 3) * _freshness);
    String f(double v) => _fmt(ind, v);

    return TerritoryAlert(
      id: _id(AlertMethod.regraLimiar, ind, hist.last.date),
      indicatorId: ind.id,
      indicatorName: ind.name,
      title: 'Perdas na rede de água acima do limiar',
      summary: 'Na última semana, em média ${f(avg)} da água distribuída se '
          'perdeu antes de chegar aos imóveis (limiar: ${f(threshold)}).',
      severity:
          avg >= threshold + 5 ? AlertSeverity.critico : AlertSeverity.atencao,
      method: AlertMethod.regraLimiar,
      confidence: confidence,
      confidenceRationale:
          'Baseada na estabilidade da série: quanto menor a variação diária '
          '(coeficiente de variação = ${Fmt.percent(cv, decimals: 1)}), maior a '
          'confiança de que a média representa a situação real.',
      evidence: [
        Evidence('Média dos últimos 7 dias', f(avg)),
        Evidence('Maior valor da semana', f(last7.reduce(math.max))),
        Evidence('Menor valor da semana', f(last7.reduce(math.min))),
        Evidence('Limiar definido pelo gestor', f(threshold)),
        Evidence('Coeficiente de variação', Fmt.percent(cv, decimals: 1)),
      ],
      limitations: [
        'Perdas incluem vazamentos e ligações irregulares; o indicador não '
            'diferencia as causas.',
        'Erros de macromedição podem inflar ou reduzir o percentual.',
        ..._baseLimitations(ind),
      ],
      suggestedAction:
          'Priorizar vistoria de vazamentos nas sub-regiões com mais '
          'ocorrências cidadãs registradas.',
      citizenExplanation:
          'Uma parte grande da água tratada está se perdendo antes de chegar '
          'às casas, provavelmente em vazamentos. Se você vir água correndo na '
          'rua, registre uma ocorrência no app.',
      generatedAt: now,
      horizonDays: 0,
      referenceDate: hist.last.date,
    );
  }

  /// Onda de calor: 2+ dias seguidos previstos acima do limiar.
  TerritoryAlert? _heatRule(Indicator ind, double threshold) {
    final fc = ind.forecast;
    if (fc.isEmpty) return null;

    var bestStart = -1;
    var bestLen = 0;
    var start = -1;
    var len = 0;
    for (var i = 0; i < fc.length; i++) {
      if (fc[i].value >= threshold) {
        if (len == 0) start = i;
        len++;
        if (len > bestLen) {
          bestLen = len;
          bestStart = start;
        }
      } else {
        len = 0;
      }
    }
    if (bestLen < 2) return null;

    final run = fc.sublist(bestStart, bestStart + bestLen);
    final maxT = run.map((p) => p.value).reduce(math.max);
    final horizon = _daysUntil(run.first.date);
    final confidence = _clamp((0.92 - 0.07 * horizon) * _freshness);
    String f(double v) => _fmt(ind, v);

    return TerritoryAlert(
      id: _id(AlertMethod.previsaoMeteorologica, ind, run.first.date),
      indicatorId: ind.id,
      indicatorName: ind.name,
      title: 'Onda de calor prevista',
      summary: '$bestLen dias seguidos com máxima acima de ${f(threshold)} a '
          'partir de ${Fmt.weekday(run.first.date)}, '
          '${Fmt.dayMonth(run.first.date)} (pico de ${f(maxT)}).',
      severity: bestLen >= 3 || maxT >= threshold + 3
          ? AlertSeverity.critico
          : AlertSeverity.atencao,
      method: AlertMethod.previsaoMeteorologica,
      confidence: confidence,
      confidenceRationale:
          'Previsões meteorológicas perdem precisão a cada dia de antecedência: '
          'este evento começa em $horizon dia(s), por isso a confiança cai '
          '7 pontos por dia.',
      evidence: [
        for (final p in run)
          Evidence(
              'Máxima prevista ${Fmt.weekday(p.date)} ${Fmt.dayMonth(p.date)}',
              f(p.value)),
        Evidence('Limiar definido pelo gestor', f(threshold)),
        Evidence('Dias consecutivos acima do limiar', '$bestLen'),
      ],
      limitations: [
        'Temperatura prevista para um ponto do bairro; ruas sem arborização '
            'podem ficar alguns graus mais quentes.',
        'Previsões com mais de 3 dias de antecedência mudam com frequência.',
        ..._baseLimitations(ind),
      ],
      suggestedAction:
          'Avaliar abertura de pontos de hidratação e reforço de orientação em '
          'UBSs, escolas e para pessoas em situação de rua.',
      citizenExplanation:
          'Os próximos dias devem ser muito quentes. Beba água, procure sombra '
          'e fique atento a idosos, crianças e animais.',
      generatedAt: now,
      horizonDays: horizon,
      referenceDate: run.first.date,
    );
  }

  /// Chuva intensa prevista em algum dos próximos dias.
  TerritoryAlert? _rainRule(Indicator ind, double threshold) {
    final fc = ind.forecast;
    if (fc.isEmpty) return null;
    final idx = fc.indexWhere((p) => p.value >= threshold);
    if (idx < 0) return null;

    final day = fc[idx];
    final total = fc.fold<double>(0, (acc, p) => acc + p.value);
    final horizon = _daysUntil(day.date);
    final confidence = _clamp((0.80 - 0.08 * horizon) * _freshness);
    String f(double v) => _fmt(ind, v);

    return TerritoryAlert(
      id: _id(AlertMethod.previsaoMeteorologica, ind, day.date),
      indicatorId: ind.id,
      indicatorName: ind.name,
      title: 'Risco de alagamento por chuva forte',
      summary: 'Previsão de ${f(day.value)} em '
          '${Fmt.weekday(day.date)}, ${Fmt.dayMonth(day.date)}, acima do '
          'limiar de ${f(threshold)}.',
      severity: day.value >= threshold * 1.5
          ? AlertSeverity.critico
          : AlertSeverity.atencao,
      method: AlertMethod.previsaoMeteorologica,
      confidence: confidence,
      confidenceRationale:
          'Chuva é mais difícil de prever que temperatura; a confiança parte de '
          '80% e cai 8 pontos por dia de antecedência ($horizon dia(s)).',
      evidence: [
        Evidence('Chuva prevista no dia', f(day.value)),
        Evidence('Acumulado previsto (próx. ${fc.length} dias)', f(total)),
        Evidence('Limiar definido pelo gestor', f(threshold)),
      ],
      limitations: [
        'Pancadas de verão são localizadas: pode chover muito em uma rua e '
            'pouco na vizinha.',
        'O risco real depende da limpeza de bueiros e do relevo, que o modelo '
            'não considera.',
        ..._baseLimitations(ind),
      ],
      suggestedAction:
          'Avaliar limpeza preventiva de bueiros e comunicação com a Defesa '
          'Civil.',
      citizenExplanation:
          'Há previsão de chuva forte. Evite áreas que costumam alagar e não '
          'atravesse ruas com água acumulada.',
      generatedAt: now,
      horizonDays: horizon,
      referenceDate: day.date,
    );
  }

  /// Último valor muito diferente dos 14 dias anteriores.
  TerritoryAlert? _anomalyRule(Indicator ind) {
    final hist = ind.history;
    if (hist.length < 11) return null;
    final start = math.max(0, hist.length - 15);
    final reference =
        hist.sublist(start, hist.length - 1).map((p) => p.value).toList();
    final last = hist.last;
    final z = Stats.zScore(last.value, reference);
    if (z.abs() < anomalyZ) return null;

    String f(double v) => _fmt(ind, v);
    final direction = z > 0 ? 'acima' : 'abaixo';

    return TerritoryAlert(
      id: _id(AlertMethod.anomaliaEstatistica, ind, last.date),
      indicatorId: ind.id,
      indicatorName: ind.name,
      title: 'Variação atípica em ${ind.name.toLowerCase()}',
      summary: 'O registro de ${Fmt.dayMonth(last.date)} (${f(last.value)}) '
          'ficou ${Fmt.number(z.abs(), decimals: 1)} desvios padrão $direction '
          'do comportamento recente.',
      severity: AlertSeverity.informativo,
      method: AlertMethod.anomaliaEstatistica,
      confidence: _clamp(0.35 * _freshness),
      confidenceRationale:
          'Anomalias isoladas têm confiança baixa por definição: podem ser erro '
          'de medição ou um evento pontual.',
      evidence: [
        Evidence('Valor registrado', f(last.value)),
        Evidence('Média de referência (${reference.length} dias)',
            f(Stats.mean(reference))),
        Evidence('Desvio padrão de referência', f(Stats.stdDev(reference))),
        Evidence('z-score', Fmt.signed(z, decimals: 2)),
      ],
      limitations: [
        'Um único ponto fora do padrão não indica tendência.',
        'Pode refletir falha do sensor, ajuste de leitura ou evento '
            'excepcional (feriado, festa, obra).',
        ..._baseLimitations(ind),
      ],
      suggestedAction: 'Conferir a medição na fonte antes de qualquer ação.',
      citizenExplanation:
          'O último registro de ${ind.name.toLowerCase()} ficou bem diferente '
          'do normal. Pode ser um problema real ou apenas um erro de medição; '
          'cabe à equipe responsável verificar.',
      generatedAt: now,
      horizonDays: 0,
      referenceDate: last.date,
    );
  }

  // ---------------------------------------------------------------------------
  // Auxiliares
  // ---------------------------------------------------------------------------

  List<String> _baseLimitations(Indicator ind) => [
        if (ind.origin == DataOrigin.sintetico)
          'Dados sintéticos de demonstração: representam um cenário plausível, '
              'não medições reais da concessionária.',
        if (ind.origin == DataOrigin.real)
          'Dados do modelo meteorológico Open-Meteo para um único ponto do '
              'bairro: microclimas não são capturados.',
        if (fromCache)
          'Calculado com dados salvos no aparelho (sem conexão): a situação '
              'atual pode ter mudado.',
      ];

  List<double> _lastValues(List<DataPoint> hist, int n) =>
      hist.sublist(math.max(0, hist.length - n)).map((p) => p.value).toList();

  String _fmt(Indicator ind, double v) =>
      '${Fmt.number(v, decimals: ind.decimals)} ${ind.unit}';

  String _id(AlertMethod method, Indicator ind, DateTime date) =>
      '${method.name}_${ind.id}_${Fmt.dateKey(date)}';

  int _daysUntil(DateTime date) {
    final today = DateTime.utc(now.year, now.month, now.day);
    final target = DateTime.utc(date.year, date.month, date.day);
    return math.max(0, target.difference(today).inDays);
  }

  double _clamp(double v) => v.clamp(0.05, 0.95).toDouble();
}

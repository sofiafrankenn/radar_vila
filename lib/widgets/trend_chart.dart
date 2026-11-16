import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';

import 'package:radar_vila/core/theme/app_spacing.dart';
import 'package:radar_vila/core/theme/theme_context.dart';
import 'package:radar_vila/core/utils/formatters.dart';
import 'package:radar_vila/models/data_point.dart';
import 'package:radar_vila/widgets/state_views.dart';

/// Gráfico de histórico + previsão + linha de limiar.
/// Linha cheia = histórico; tracejado cinza = previsão.
class TrendChart extends StatelessWidget {
  const TrendChart({
    super.key,
    required this.series,
    required this.color,
    required this.unit,
    this.threshold,
    this.decimals = 1,
    this.height = 200,
    this.asBars = false,
  });

  final List<DataPoint> series;
  final Color color;
  final String unit;
  final double? threshold;
  final int decimals;
  final double height;
  final bool asBars;

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty) {
      return SizedBox(
        height: height,
        child: const EmptyView(
          compact: true,
          icon: Icons.show_chart,
          title: 'Sem dados',
          message: 'Não há pontos para exibir neste período.',
        ),
      );
    }

    final values = series.map((p) => p.value).toList();
    var minY = values.reduce(math.min);
    var maxY = values.reduce(math.max);
    final t = threshold;
    if (t != null) {
      minY = math.min(minY, t);
      maxY = math.max(maxY, t);
    }
    final rawSpan = maxY - minY;
    final span =
        rawSpan.abs() < 1e-6 ? math.max(1.0, maxY.abs() * 0.1) : rawSpan;
    minY = asBars ? 0 : minY - span * 0.15;
    if (minY < 0 && values.every((v) => v >= 0)) minY = 0;
    maxY = maxY + span * 0.15;

    final labelEvery = math.max(1, (series.length / 5).ceil());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: _summary(),
          excludeSemantics: true,
          child: SizedBox(
            height: height,
            child: Padding(
              padding: const EdgeInsets.only(
                  top: AppSpacing.sm, right: AppSpacing.sm),
              child: asBars
                  ? _bar(context, minY, maxY, labelEvery)
                  : _line(context, minY, maxY, labelEvery),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _Legend(color: color, hasThreshold: threshold != null, asBars: asBars),
      ],
    );
  }

  String _summary() {
    final hist = series.where((p) => !p.isForecast).toList();
    final fc = series.where((p) => p.isForecast).toList();
    final buffer =
        StringBuffer('Gráfico em $unit com ${hist.length} dias de histórico');
    if (hist.isNotEmpty) {
      buffer.write(
          ', último valor ${Fmt.number(hist.last.value, decimals: decimals)}');
    }
    if (fc.isNotEmpty) {
      final peak = fc.map((p) => p.value).reduce(math.max);
      buffer.write(', previsão de ${fc.length} dias com máximo de '
          '${Fmt.number(peak, decimals: decimals)}');
    }
    if (threshold != null) {
      buffer.write(', limiar em ${Fmt.number(threshold!, decimals: decimals)}');
    }
    return '$buffer.';
  }

  FlTitlesData _titles(BuildContext context, int labelEvery) {
    final style =
        context.textStyles.labelSmall?.copyWith(color: context.palette.muted);
    return FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 42,
          getTitlesWidget: (value, meta) {
            if (value == meta.max || value == meta.min) {
              return const SizedBox.shrink();
            }
            final d = value.abs() >= 100 || decimals == 0 ? 0 : 1;
            return Text(Fmt.number(value, decimals: d), style: style);
          },
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 26,
          interval: 1,
          getTitlesWidget: (value, meta) {
            final i = value.round();
            if ((value - i).abs() > 0.01 || i < 0 || i >= series.length) {
              return const SizedBox.shrink();
            }
            if (i % labelEvery != 0) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(Fmt.dayMonth(series[i].date), style: style),
            );
          },
        ),
      ),
    );
  }

  ExtraLinesData _extraLines(BuildContext context) {
    final t = threshold;
    if (t == null) return const ExtraLinesData();
    final critical = context.palette.critico;
    return ExtraLinesData(horizontalLines: [
      HorizontalLine(
        y: t,
        color: critical,
        strokeWidth: 1.6,
        dashArray: const [4, 4],
        label: HorizontalLineLabel(
          show: true,
          alignment: Alignment.topRight,
          style: TextStyle(
              color: critical, fontSize: 11, fontWeight: FontWeight.w700),
          labelResolver: (_) => 'Limiar ${Fmt.number(t, decimals: decimals)}',
        ),
      ),
    ]);
  }

  FlGridData _grid(BuildContext context) => FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) =>
            FlLine(color: context.palette.border, strokeWidth: 1),
      );

  Widget _line(BuildContext context, double minY, double maxY, int labelEvery) {
    final palette = context.palette;
    final colors = context.colors;

    final histSpots = <FlSpot>[];
    final fcSpots = <FlSpot>[];
    for (var i = 0; i < series.length; i++) {
      final spot = FlSpot(i.toDouble(), series[i].value);
      if (series[i].isForecast) {
        if (fcSpots.isEmpty && histSpots.isNotEmpty) {
          fcSpots.add(histSpots.last);
        }
        fcSpots.add(spot);
      } else {
        histSpots.add(spot);
      }
    }

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: math.max(1, series.length - 1).toDouble(),
        minY: minY,
        maxY: maxY,
        gridData: _grid(context),
        borderData: FlBorderData(show: false),
        titlesData: _titles(context, labelEvery),
        extraLinesData: _extraLines(context),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => colors.inverseSurface,
            getTooltipItems: (spots) => spots.map<LineTooltipItem?>((s) {
              final joinsHistory =
                  histSpots.isNotEmpty && s.barIndex == 1 && s.spotIndex == 0;
              if (joinsHistory) return null;
              final i = s.x.round().clamp(0, series.length - 1).toInt();
              final p = series[i];
              return LineTooltipItem(
                '${Fmt.dayMonth(p.date)}${p.isForecast ? ' (previsão)' : ''}\n'
                '${Fmt.number(p.value, decimals: decimals)} $unit',
                TextStyle(
                  color: colors.onInverseSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          if (histSpots.isNotEmpty)
            LineChartBarData(
              spots: histSpots,
              isCurved: true,
              curveSmoothness: 0.2,
              preventCurveOverShooting: true,
              color: color,
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: true, color: color.withAlpha(36)),
            ),
          if (fcSpots.length > 1 || (histSpots.isEmpty && fcSpots.isNotEmpty))
            LineChartBarData(
              spots: fcSpots,
              color: palette.forecast,
              barWidth: 2.5,
              dashArray: const [6, 4],
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, xPercent, bar, index) =>
                    FlDotCirclePainter(
                  radius: 3,
                  color: palette.forecast,
                  strokeWidth: 0,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _bar(BuildContext context, double minY, double maxY, int labelEvery) {
    final palette = context.palette;
    final colors = context.colors;
    return BarChart(
      BarChartData(
        minY: 0,
        maxY: maxY,
        alignment: BarChartAlignment.spaceBetween,
        gridData: _grid(context),
        borderData: FlBorderData(show: false),
        titlesData: _titles(context, labelEvery),
        extraLinesData: _extraLines(context),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => colors.inverseSurface,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final p = series[group.x];
              return BarTooltipItem(
                '${Fmt.dayMonth(p.date)}${p.isForecast ? ' (previsão)' : ''}\n'
                '${Fmt.number(p.value, decimals: decimals)} $unit',
                TextStyle(
                  color: colors.onInverseSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        barGroups: [
          for (var i = 0; i < series.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: series[i].value,
                  color: series[i].isForecast ? palette.forecast : color,
                  width: series.length > 20 ? 5 : 10,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(3)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend(
      {required this.color, required this.hasThreshold, required this.asBars});

  final Color color;
  final bool hasThreshold;
  final bool asBars;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    Widget item(Color c, String label, {bool dashed = false}) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 18,
              height: asBars && !dashed ? 10 : 3,
              decoration: BoxDecoration(
                color: dashed ? null : c,
                border:
                    dashed ? Border(top: BorderSide(color: c, width: 2)) : null,
              ),
            ),
            const SizedBox(width: 6),
            Text(label, style: context.mutedSmall),
          ],
        );

    return Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.xs,
      children: [
        item(color, 'Histórico'),
        item(palette.forecast, 'Previsão'),
        if (hasThreshold) item(palette.critico, 'Limiar', dashed: true),
      ],
    );
  }
}

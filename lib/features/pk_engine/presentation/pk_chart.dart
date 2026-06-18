import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/config/constants.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/usecases/pk_calculator.dart';

/// Chart widget for the PK simulation. Draws the concentration curve
/// over the simulation window with three coloured therapeutic bands.
/// Bands use the same heuristic multipliers as the original PWA:
/// 0.25× (minimum), 0.4× (low), 1.0× (high), 1.5× (toxic).
class PkChart extends StatelessWidget {
  const PkChart({
    super.key,
    required this.curve,
    required this.doseMg,
    required this.scheduleHours,
    this.thresholdX,
    this.thresholdY,
  });

  final PkCurve curve;
  final double doseMg;
  final List<double> scheduleHours;
  final double? thresholdX;
  final double? thresholdY;

  @override
  Widget build(BuildContext context) {
    if (curve.times.isEmpty) {
      return const SizedBox.shrink();
    }
    final maxY =
        (curve.peakValue * 1.15).clamp(doseMg.toDouble(), double.infinity);

    final minT = doseMg * AppConstants.bandMinMultiplier;
    final lowT = doseMg * AppConstants.bandTherapeuticLow;
    final highT = doseMg * AppConstants.bandTherapeuticHigh;
    final maxT = doseMg * AppConstants.bandToxic;

    final tY = thresholdY;
    final tX = thresholdX;

    return LineChart(
      duration: Duration.zero,
      LineChartData(
        minX: 0,
        maxX: curve.times.last,
        minY: 0,
        maxY: maxY.toDouble(),
        gridData: const FlGridData(show: true, drawVerticalLine: true),
        titlesData: FlTitlesData(
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: (curve.times.last / 5).clamp(1, double.infinity),
              getTitlesWidget: (v, _) => Text(
                '${v.toInt()}h',
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (v, _) => Text(
                v.toStringAsFixed(0),
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
        ),
        rangeAnnotations: RangeAnnotations(
          horizontalRangeAnnotations: [
            HorizontalRangeAnnotation(
              y1: minT,
              y2: lowT,
              color: PkBandColors.safe.withValues(alpha: 0.10),
            ),
            HorizontalRangeAnnotation(
              y1: lowT,
              y2: highT,
              color: PkBandColors.safe.withValues(alpha: 0.18),
            ),
            HorizontalRangeAnnotation(
              y1: highT,
              y2: maxT,
              color: PkBandColors.warn.withValues(alpha: 0.18),
            ),
            HorizontalRangeAnnotation(
              y1: maxT,
              y2: maxY.toDouble(),
              color: PkBandColors.toxic.withValues(alpha: 0.18),
            ),
          ],
        ),
        extraLinesData: ExtraLinesData(
          verticalLines: [
            for (final t in scheduleHours)
              VerticalLine(
                x: t,
                color: Colors.blueAccent.withValues(alpha: 0.35),
                strokeWidth: 1,
                dashArray: const [2, 4],
              ),
            if (tX != null && tX < curve.times.last)
              VerticalLine(
                x: tX,
                color: Colors.orange,
                strokeWidth: 1.8,
                dashArray: const [4, 4],
              ),
          ],
          horizontalLines: [
            if (tY != null && tY > 0)
              HorizontalLine(
                y: tY,
                color: Colors.orange.withValues(alpha: 0.5),
                strokeWidth: 1.4,
                dashArray: const [4, 4],
                label: HorizontalLineLabel(
                  show: true,
                  labelResolver: (_) => '${tY.toStringAsFixed(0)} mg',
                  style: const TextStyle(fontSize: 10, color: Colors.orange),
                ),
              ),
          ],
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < curve.times.length; i++)
                FlSpot(curve.times[i], curve.concentrations[i]),
            ],
            isCurved: true,
            color: const Color(0xFF90CAF9),
            barWidth: 2.4,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF90CAF9).withValues(alpha: 0.08),
            ),
          ),
        ],
      ),
    );
  }
}

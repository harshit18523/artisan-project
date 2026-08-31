import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../l10n/strings.dart';
import '../models/analytics.dart';
import '../theme/palette.dart';
import '../utils/rupees.dart';

/// Weekly earnings area chart built with fl_chart.
class RevenueChart extends StatelessWidget {
  final Language language;

  /// Seven days of earnings, oldest first — see `ShopAnalytics.week`.
  final List<DayEarning> week;

  const RevenueChart({super.key, required this.language, required this.week});

  /// A round axis maximum comfortably above [maxAmount].
  ///
  /// Floors at ₹1,000 so a week with no sales still draws a sensible axis
  /// instead of collapsing every point onto the baseline.
  static double _axisMax(double maxAmount) {
    if (maxAmount <= 0) return 1000;
    final headroom = maxAmount * 1.15;
    // Round up to a tidy step sized to the magnitude of the data.
    final step = headroom <= 1000
        ? 250.0
        : headroom <= 10000
            ? 1000.0
            : 5000.0;
    return (headroom / step).ceil() * step;
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final axisColor = dark ? Colors.white54 : AppColors.ink500;
    final gridColor = dark ? Colors.white10 : AppColors.ink200;

    final maxAmount =
        week.fold<double>(0, (best, d) => d.amount > best ? d.amount : best);
    final maxY = _axisMax(maxAmount);
    final peakIndex = maxAmount <= 0
        ? -1 // no sales this week: don't single out an arbitrary day
        : week.indexWhere((d) => d.amount == maxAmount);

    // Build data spots
    final spots = <FlSpot>[
      for (int i = 0; i < week.length; i++) FlSpot(i.toDouble(), week[i].amount),
    ];

    return SizedBox(
      height: 192,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
            getDrawingHorizontalLine: (_) => FlLine(color: gridColor, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, _) {
                  final i = value.toInt();
                  if (i < 0 || i >= week.length) return const SizedBox.shrink();
                  final day = language == Language.hi
                      ? week[i].dayHi
                      : week[i].dayEn;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(day, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: axisColor)),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => dark ? AppColors.ink950 : AppColors.ink800,
              tooltipRoundedRadius: 12,
              getTooltipItems: (touchedSpots) => touchedSpots.map((s) {
                return LineTooltipItem(
                  formatRupees(s.y.toInt()),
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                );
              }).toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.saffron600,
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, xPercentage, bar, index) {
                  final isPeak = spot.x.toInt() == peakIndex;
                  return FlDotCirclePainter(
                    radius: isPeak ? 7 : 3,
                    color: AppColors.saffron600,
                    strokeWidth: isPeak ? 3 : 0,
                    strokeColor: dark ? AppColors.ink950 : Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.saffron500.withAlpha(115),
                    AppColors.saffron500.withAlpha(5),
                  ],
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 600),
      ),
    );
  }
}

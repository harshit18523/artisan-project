import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/strings.dart';
import '../providers/app_state.dart';
import '../providers/data_provider.dart';
import '../theme/palette.dart';
import '../theme/shadows.dart';
import '../utils/rupees.dart';
import '../widgets/revenue_chart.dart';
import '../widgets/theme_toggle.dart';

class GrowthScreen extends StatelessWidget {
  const GrowthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final data = context.watch<DataProvider>();
    final s = app.strings;
    final dark = Theme.of(context).brightness == Brightness.dark;

    // Every figure on this screen is derived from the orders in SQLite.
    final analytics = data.analytics;
    final peak = analytics.peak;
    final peakDay = app.language == Language.hi ? peak.dayHi : peak.dayEn;
    final trend = analytics.trendPercent;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Header with title + dark mode toggle
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(s.growthTitle, style: TextStyle(
            fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5,
            color: dark ? Colors.white : AppColors.ink900,
          )),
          ThemeToggle(
            isDark: app.isDark,
            onToggle: () => context.read<AppState>().toggleDark(),
          ),
        ]),

        const SizedBox(height: 20),

        // Revenue card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: dark ? AppColors.ink800 : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: dark ? AppColors.ink700 : AppColors.ink200),
            boxShadow: kCardShadow,
          ),
          child: Stack(children: [
            Positioned(right: -40, top: -64, child: Container(
              width: 192, height: 192,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.saffron500.withAlpha(82),
                  AppColors.saffron500.withAlpha(0),
                ]),
              ),
            )),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: AppColors.saffron50, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.account_balance_wallet_rounded, size: 20, color: AppColors.saffron600),
                ),
                const SizedBox(width: 8),
                Text(s.revenueLabel.toUpperCase(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.6, color: AppColors.ink500)),
              ]),
              const SizedBox(height: 12),
              Text(formatRupees(analytics.totalRevenue), style: TextStyle(
                fontSize: 48, fontWeight: FontWeight.w800, letterSpacing: -1,
                color: dark ? Colors.white : AppColors.ink900,
              )),
              // Hidden entirely when there is no prior week to compare against —
              // better than showing an invented percentage.
              if (trend != null) ...[
                const SizedBox(height: 12),
                _TrendPill(trend: trend, label: s.trendLabel),
              ],
            ]),
          ]),
        ),

        const SizedBox(height: 20),

        // Chart card
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          decoration: BoxDecoration(
            color: dark ? AppColors.ink800 : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: dark ? AppColors.ink700 : AppColors.ink200),
            boxShadow: kCardShadow,
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(s.chartTitle, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: dark ? Colors.white : AppColors.ink900)),
                Text('${s.peakLabel}: $peakDay · ${formatRupees(peak.amount.toInt())}',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.saffron700)),
              ]),
            ),
            const SizedBox(height: 8),
            RevenueChart(language: app.language, week: analytics.week),
          ]),
        ),

        const SizedBox(height: 16),

        // Breakdown cards — both derived from orders in SQLite
        Row(children: [
          Expanded(child: _BreakdownTile(Icons.receipt_long_rounded, s.totalOrdersLabel, '${analytics.totalOrders}', dark)),
          const SizedBox(width: 12),
          Expanded(child: _BreakdownTile(Icons.savings_rounded, s.avgOrderLabel, formatRupees(analytics.avgOrderValue), dark)),
        ]),
      ]),
    );
  }
}

/// Week-on-week revenue change. Green and rising, or red and falling.
class _TrendPill extends StatelessWidget {
  final double trend;
  final String label;

  const _TrendPill({required this.trend, required this.label});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final rising = trend >= 0;
    final color = rising ? AppColors.green800 : AppColors.red600;
    final background = rising
        ? (dark ? AppColors.green600.withAlpha(45) : AppColors.green50)
        : AppColors.red600.withAlpha(dark ? 55 : 28);
    final sign = rising ? '+' : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(
          rising ? Icons.arrow_outward_rounded : Icons.south_east_rounded,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          '$sign${trend.toStringAsFixed(1)}% $label',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color),
        ),
      ]),
    );
  }
}

class _BreakdownTile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final bool dark;

  const _BreakdownTile(this.icon, this.label, this.value, this.dark);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? AppColors.ink800 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dark ? AppColors.ink700 : AppColors.ink200),
        boxShadow: kCardShadow,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 20, color: AppColors.ink500),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink500)),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: dark ? Colors.white : AppColors.ink900)),
      ]),
    );
  }
}

import 'order.dart';

class DayEarning {
  final String dayEn;
  final String dayHi;
  final double amount;

  const DayEarning(this.dayEn, this.dayHi, this.amount);
}

/// Weekday labels indexed by `DateTime.weekday - 1` (1 = Monday … 7 = Sunday).
const _weekdayEn = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _weekdayHi = <String>['सोम', 'मंगल', 'बुध', 'गुरु', 'शुक्र', 'शनि', 'रवि'];

/// Sales figures for the Growth tab, derived from real orders.
///
/// Cancelled orders are excluded throughout, matching `DataProvider.todaysSales`.
///
/// Note one deliberate divergence: [totalRevenue], [totalOrders] and
/// [avgOrderValue] count *every* non-cancelled order, while [week] and [peak]
/// can only include orders whose `createdAt` parses and falls inside the last
/// seven days. An order with a blank or malformed `createdAt` therefore counts
/// toward the totals but appears on no bar of the chart.
class ShopAnalytics {
  final int totalRevenue;
  final int totalOrders;
  final int avgOrderValue;

  /// The last seven days, oldest first, ending today.
  final List<DayEarning> week;

  /// Highest-earning day within [week].
  final DayEarning peak;

  /// Change in revenue over the last 7 days versus the 7 before that, as a
  /// percentage.
  ///
  /// Null when the earlier window earned nothing — there is no meaningful
  /// percentage change from zero, and callers should hide the trend rather than
  /// show a fabricated figure.
  final double? trendPercent;

  const ShopAnalytics({
    required this.totalRevenue,
    required this.totalOrders,
    required this.avgOrderValue,
    required this.week,
    required this.peak,
    required this.trendPercent,
  });

  factory ShopAnalytics.fromOrders(List<Order> orders, {DateTime? now}) {
    final active = orders
        .where((o) => o.status.toLowerCase() != 'cancelled')
        .toList();

    final totalRevenue =
        active.fold<int>(0, (sum, o) => sum + o.amountInRupees);
    final totalOrders = active.length;
    final avgOrderValue =
        totalOrders == 0 ? 0 : (totalRevenue / totalOrders).round();

    final today = _dateOnly(now ?? DateTime.now());

    // Bucket each order onto the day it was created. Orders with an unparseable
    // createdAt (the model's '' default) simply never land in a bucket.
    final byDay = <DateTime, int>{};
    for (final o in active) {
      final parsed = DateTime.tryParse(o.createdAt);
      if (parsed == null) continue;
      final day = _dateOnly(parsed);
      byDay[day] = (byDay[day] ?? 0) + o.amountInRupees;
    }

    int sumRange(int startDaysAgo, int endDaysAgo) {
      var total = 0;
      for (var i = startDaysAgo; i >= endDaysAgo; i--) {
        total += byDay[today.subtract(Duration(days: i))] ?? 0;
      }
      return total;
    }

    final week = <DayEarning>[
      for (var i = 6; i >= 0; i--)
        _dayEarning(today.subtract(Duration(days: i)), byDay),
    ];

    final peak = week.reduce((best, d) => d.amount > best.amount ? d : best);

    final thisWeek = sumRange(6, 0);
    final priorWeek = sumRange(13, 7);
    final trendPercent = priorWeek == 0
        ? null
        : ((thisWeek - priorWeek) / priorWeek) * 100;

    return ShopAnalytics(
      totalRevenue: totalRevenue,
      totalOrders: totalOrders,
      avgOrderValue: avgOrderValue,
      week: week,
      peak: peak,
      trendPercent: trendPercent,
    );
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static DayEarning _dayEarning(DateTime day, Map<DateTime, int> byDay) {
    final i = day.weekday - 1;
    return DayEarning(
      _weekdayEn[i],
      _weekdayHi[i],
      (byDay[day] ?? 0).toDouble(),
    );
  }
}

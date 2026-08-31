import 'package:flutter_test/flutter_test.dart';
import 'package:handora/models/analytics.dart';
import 'package:handora/models/order.dart';

/// Fixed "today" so the 7-day window is deterministic. A Wednesday.
final _now = DateTime(2026, 8, 26, 15, 0);

String _stamp(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}'
    '-${d.day.toString().padLeft(2, '0')} 10:00';

Order _order({
  required int amount,
  DateTime? createdAt,
  String status = 'new',
  String id = 'HND-1',
}) {
  return Order(
    id: id,
    quantity: 1,
    productEn: 'Clay Pot',
    productHi: 'मिट्टी का बर्तन',
    amountInRupees: amount,
    placedAt: 'just now',
    thumbnail: 'assets/images/clay_pot.jpg',
    status: status,
    createdAt: createdAt == null ? '' : _stamp(createdAt),
  );
}

void main() {
  group('seedOrders', () {
    test('always lands inside the analytics window, whatever the date', () {
      // The bug this guards: hardcoded createdAt dates fell out of the 7-day
      // window within a week, flattening the Growth chart while the revenue
      // card still showed their total.
      for (final date in [
        DateTime(2026, 8, 31),
        DateTime(2026, 9, 15),
        DateTime(2027, 1, 1),
        DateTime(2030, 6, 30),
      ]) {
        final analytics =
            ShopAnalytics.fromOrders(seedOrders(now: date), now: date);

        expect(analytics.totalRevenue, 2050);
        expect(analytics.totalOrders, 3);
        expect(
          analytics.week.fold<double>(0, (sum, d) => sum + d.amount),
          2050,
          reason: 'every seeded order must appear on the chart for $date',
        );
      }
    });

    test('produces timestamps the analytics window can parse', () {
      for (final o in seedOrders(now: _now)) {
        expect(DateTime.tryParse(o.createdAt), isNotNull,
            reason: '${o.id} has an unparseable createdAt: "${o.createdAt}"');
      }
    });
  });

  group('ShopAnalytics.fromOrders', () {
    test('an empty order list produces zeros, not a crash or NaN', () {
      final a = ShopAnalytics.fromOrders(const [], now: _now);

      expect(a.totalRevenue, 0);
      expect(a.totalOrders, 0);
      expect(a.avgOrderValue, 0, reason: 'must not divide by zero');
      expect(a.week, hasLength(7));
      expect(a.week.every((d) => d.amount == 0), isTrue);
      expect(a.trendPercent, isNull);
    });

    test('totals and average come from non-cancelled orders', () {
      final a = ShopAnalytics.fromOrders([
        _order(amount: 850, createdAt: _now),
        _order(amount: 900, createdAt: _now),
        _order(amount: 300, createdAt: _now),
      ], now: _now);

      expect(a.totalRevenue, 2050);
      expect(a.totalOrders, 3);
      expect(a.avgOrderValue, 683); // 2050 / 3 rounded
    });

    test('cancelled orders are excluded entirely', () {
      final a = ShopAnalytics.fromOrders([
        _order(amount: 850, createdAt: _now),
        _order(amount: 5000, createdAt: _now, status: 'cancelled'),
        _order(amount: 5000, createdAt: _now, status: 'CANCELLED'),
      ], now: _now);

      expect(a.totalRevenue, 850);
      expect(a.totalOrders, 1);
      expect(a.week.last.amount, 850);
    });

    test('every order cancelled behaves like no orders at all', () {
      final a = ShopAnalytics.fromOrders([
        _order(amount: 850, createdAt: _now, status: 'cancelled'),
      ], now: _now);

      expect(a.totalRevenue, 0);
      expect(a.totalOrders, 0);
      expect(a.avgOrderValue, 0);
      expect(a.trendPercent, isNull);
    });

    test('orders land on the right day and are summed per day', () {
      final a = ShopAnalytics.fromOrders([
        _order(amount: 100, createdAt: _now),
        _order(amount: 50, createdAt: _now),
        _order(amount: 700, createdAt: _now.subtract(const Duration(days: 2))),
      ], now: _now);

      expect(a.week.last.amount, 150, reason: 'today is the final bar');
      expect(a.week[4].amount, 700, reason: 'two days ago');
      expect(a.peak.amount, 700);
    });

    test('the week is labelled by weekday, oldest first', () {
      final a = ShopAnalytics.fromOrders(const [], now: _now);

      // _now is a Wednesday, so the window runs Thu..Wed.
      expect(a.week.map((d) => d.dayEn).toList(),
          ['Thu', 'Fri', 'Sat', 'Sun', 'Mon', 'Tue', 'Wed']);
      expect(a.week.last.dayHi, 'बुध');
    });

    test('orders outside the 7-day window count toward totals but not the chart',
        () {
      final a = ShopAnalytics.fromOrders([
        _order(amount: 400, createdAt: _now.subtract(const Duration(days: 30))),
      ], now: _now);

      expect(a.totalRevenue, 400);
      expect(a.week.every((d) => d.amount == 0), isTrue);
    });

    test('an unparseable createdAt counts toward totals but not the chart', () {
      final a = ShopAnalytics.fromOrders([
        _order(amount: 250), // createdAt defaults to ''
      ], now: _now);

      expect(a.totalRevenue, 250);
      expect(a.totalOrders, 1);
      expect(a.week.every((d) => d.amount == 0), isTrue);
    });

    group('trendPercent', () {
      test('is null when the prior week earned nothing', () {
        final a = ShopAnalytics.fromOrders([
          _order(amount: 1000, createdAt: _now),
        ], now: _now);

        expect(a.trendPercent, isNull,
            reason: 'no honest percentage change from zero');
      });

      test('is positive when this week beats the last', () {
        final a = ShopAnalytics.fromOrders([
          _order(amount: 200, createdAt: _now.subtract(const Duration(days: 8))),
          _order(amount: 300, createdAt: _now),
        ], now: _now);

        expect(a.trendPercent, closeTo(50, 0.001)); // 200 -> 300
      });

      test('is negative when this week falls behind', () {
        final a = ShopAnalytics.fromOrders([
          _order(amount: 400, createdAt: _now.subtract(const Duration(days: 8))),
          _order(amount: 300, createdAt: _now),
        ], now: _now);

        expect(a.trendPercent, closeTo(-25, 0.001)); // 400 -> 300
      });
    });
  });
}

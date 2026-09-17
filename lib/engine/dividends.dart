/// lib/engine/dividends.dart
/// 分红每秒累加 + 5 秒结算一次的实现。
library;

import '../models/holding.dart';
import '../models/stock.dart';

/// 一次性累加 1 秒的分红到 pot；返回该秒累加的金额（用于飘字）。
double accrueOneSecond({
  required Map<String, Holding> holdings,
  required Map<String, LiveStock> stocks,
  required List<StockSeed> seeds,
  required double dividendMult,
}) {
  double add = 0.0;
  for (final StockSeed seed in seeds) {
    final Holding? h = holdings[seed.code];
    if (h == null || h.shares <= 0) continue;
    final LiveStock? live = stocks[seed.code];
    if (live == null || live.price <= 0) continue;
    add += h.shares * live.price * seed.dailyDivRate / 86400.0 * dividendMult;
  }
  return add;
}

/// 离线 (T 秒) 累计分红 (基于 savedPrices)。
double offlineDividend({
  required Map<String, Holding> holdings,
  required Map<String, double> savedPrices,
  required List<StockSeed> seeds,
  required double dividendMult,
  required Duration elapsed,
}) {
  if (elapsed <= Duration.zero) return 0.0;
  final double secs = elapsed.inMilliseconds / 1000.0;
  double total = 0.0;
  for (final StockSeed seed in seeds) {
    final Holding? h = holdings[seed.code];
    if (h == null || h.shares <= 0) continue;
    final double price = savedPrices[seed.code] ?? 0.0;
    if (price <= 0) continue;
    total += h.shares * price * seed.dailyDivRate / 86400.0 * dividendMult * secs;
  }
  return total;
}
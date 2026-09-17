/// lib/engine/events.dart
/// 随机事件触发、标题选择。
library;

import 'dart:math' as math;

import '../core/constants.dart';
import '../models/market_event.dart';
import '../models/stock.dart';

class EventEngine {
  EventEngine({required math.Random rng}) : _rng = rng;
  final math.Random _rng;

  /// 返回下一次延迟 (秒)。
  int rollNextDelay() {
    return kEventMinSeconds +
        _rng.nextInt(kEventMaxSeconds - kEventMinSeconds + 1);
  }

  /// 在已解锁股票里选一只触发。返回 null 表示无可选。
  MarketEvent? maybeTrigger({
    required List<StockSeed> seeds,
    required Set<String> unlockedCodes,
    required Map<String, int> lastEventCodeMs,
    required int nowMs,
  }) {
    final List<StockSeed> candidates = seeds
        .where((StockSeed s) => unlockedCodes.contains(s.code))
        .toList(growable: false);
    if (candidates.isEmpty) return null;
    final StockSeed chosen = candidates[_rng.nextInt(candidates.length)];

    // 5 分钟内不重复
    final int lastMs = lastEventCodeMs[chosen.code] ?? 0;
    if (nowMs - lastMs < 5 * 60 * 1000) {
      return null;
    }

    final bool positive = _rng.nextBool();
    final double magnitude = 0.08 + _rng.nextDouble() * 0.10; // 0.08~0.18
    final double effect = positive ? magnitude : -magnitude;
    final int durSec = kEventDurationMin +
        _rng.nextInt(kEventDurationMax - kEventDurationMin + 1);
    final int startMs = nowMs;
    final int endMs = startMs + durSec * 1000;

    final List<String> pool =
        positive ? kPositiveHeadlines : kNegativeHeadlines;
    final String raw = pool[_rng.nextInt(pool.length)];
    final String headline = raw.replaceAll('{name}', chosen.name);

    lastEventCodeMs[chosen.code] = startMs;

    return MarketEvent(
      code: chosen.code,
      name: chosen.name,
      headline: headline,
      effect: effect,
      startMs: startMs,
      endMs: endMs,
    );
  }
}
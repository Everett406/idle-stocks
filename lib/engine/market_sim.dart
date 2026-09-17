/// lib/engine/market_sim.dart
/// 单只股票的价格 tick：先按当前 mu / sigma GBM，再叠加事件 boost 与夜盘效果。
library;

import '../core/gbm.dart';
import '../models/market_event.dart';
import '../models/stock.dart';

/// 给定 seed + 当前夜盘状态，得到有效 mu / sigma (per sec)。
({double muPerSec, double sigmaPerSec}) effectiveParams({
  required StockSeed seed,
  required double driftBonusMul, // 转生加成
  required double volBonusMul, // 夜盘 ×2 等
}) {
  // 转生加成：每日漂移 += 5% / 级（叠加乘法）
  final double mu = seed.dailyDrift * driftBonusMul;
  final double sigma = seed.dailyVol * volBonusMul;
  return (
    muPerSec: muPerSecFromDaily(mu),
    sigmaPerSec: sigmaPerSecFromDaily(sigma),
  );
}

/// 单只股票 tick。
class MarketTicker {
  MarketTicker({required NormalRandom normal}) : _normal = normal;
  final NormalRandom _normal;

  double tickOne({
    required StockSeed seed,
    required LiveStock live,
    required double driftBonusMul,
    required double volBonusMul,
    required MarketEvent? activeEvent,
    required int nowMs,
  }) {
    final ({double muPerSec, double sigmaPerSec}) p = effectiveParams(
      seed: seed,
      driftBonusMul: driftBonusMul,
      volBonusMul: volBonusMul,
    );
    double newPrice = gbmStep(
      price: live.price,
      muPerSec: p.muPerSec,
      sigmaPerSec: p.sigmaPerSec,
      dtSec: 1.0,
      normal: _normal,
    );
    // 事件叠加：1 + effect * decay
    if (activeEvent != null && activeEvent.code == seed.code && nowMs < activeEvent.endMs) {
      final double t = (nowMs - activeEvent.startMs) /
          (activeEvent.endMs - activeEvent.startMs).clamp(1, 1 << 30);
      final double decay = (1.0 - t).clamp(0.0, 1.0);
      newPrice *= (1.0 + activeEvent.effect * decay);
    }
    // 事件结束后把 boost 归位
    if (nowMs >= live.eventUntilMs) {
      live.eventBoost = 1.0;
    }
    if (newPrice.isNaN || newPrice.isInfinite || newPrice <= 0) {
      return live.price;
    }
    return newPrice;
  }
}
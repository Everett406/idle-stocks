/// lib/core/gbm.dart
/// 几何布朗运动 (GBM) 单步推进 + 标准正态 Box-Muller 实现。
library;

import 'dart:math' as math;

/// 标准正态采样 (Box-Muller)。每次调用返回一对，用一个存一个备用。
class NormalRandom {
  NormalRandom(this._rng);
  final math.Random _rng;
  double? _spare;

  /// 返回一个 N(0,1) 样本。
  double next() {
    final double? s = _spare;
    if (s != null) {
      _spare = null;
      return s;
    }
    double u1;
    double u2;
    do {
      u1 = _rng.nextDouble();
      u2 = _rng.nextDouble();
    } while (u1 <= 1e-12);
    final double mag = math.sqrt(-2.0 * math.log(u1));
    final double z0 = mag * math.cos(2 * math.pi * u2);
    final double z1 = mag * math.sin(2 * math.pi * u2);
    _spare = z1;
    return z0;
  }
}

/// 单步 GBM：
///   S' = S * exp((mu - 0.5*sigma^2) * dt + sigma * sqrt(dt) * Z)
/// `dt` 单位：秒。
double gbmStep({
  required double price,
  required double muPerSec,
  required double sigmaPerSec,
  required double dtSec,
  required NormalRandom normal,
}) {
  if (price <= 0) return price;
  final double z = normal.next();
  final double drift = (muPerSec - 0.5 * sigmaPerSec * sigmaPerSec) * dtSec;
  final double diffusion = sigmaPerSec * math.sqrt(dtSec) * z;
  final double newPrice = price * math.exp(drift + diffusion);
  if (newPrice.isNaN || newPrice.isInfinite || newPrice <= 0) {
    return price;
  }
  return newPrice;
}

/// 把"日参数"换算成"秒参数"。
double muPerSecFromDaily(double dailyDrift) => dailyDrift / 86400.0;
double sigmaPerSecFromDaily(double dailyVol) => dailyVol / math.sqrt(86400.0);
/// lib/engine/prestige.dart
/// 转生：阈值判断、执行重置、永久加成。
library;

import '../core/constants.dart';

class Prestige {
  static double thresholdFor(int managerLevel) {
    return kPrestigeBaseThreshold * (managerLevel + 1) * (managerLevel + 1);
  }

  /// 是否可触发转生。
  static bool canPrestige({
    required double totalAssets,
    required int managerLevel,
  }) {
    return totalAssets >= thresholdFor(managerLevel);
  }

  /// 执行转生后的永久加成。
  /// 返回一个 (dividendMultMul, driftBonusMul) 数值。
  static (double dividendMul, double driftMul) bonusesFor(int managerLevel) {
    final int lv = managerLevel;
    final double div = 1.0 + 0.15 * lv;
    final double drift = 1.0 + 0.05 * lv;
    return (div, drift);
  }
}
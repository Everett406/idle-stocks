/// lib/models/upgrade.dart
/// 升级项定义（静态）+ 升级 ID 枚举。
library;

enum UpgradeId {
  fee,
  div,
  bot,
  stop,
  news;

  String get label {
    switch (this) {
      case UpgradeId.fee:
        return '佣金折扣';
      case UpgradeId.div:
        return '分红倍率';
      case UpgradeId.bot:
        return '自动交易机器人';
      case UpgradeId.stop:
        return '止损保险';
      case UpgradeId.news:
        return '新闻推送';
    }
  }

  String get desc {
    switch (this) {
      case UpgradeId.fee:
        return '降低交易手续费，买卖更划算。';
      case UpgradeId.div:
        return '提升所有持仓的分红倍率。';
      case UpgradeId.bot:
        return '按规则自动对自选股低买高卖。';
      case UpgradeId.stop:
        return '持仓亏损过大时自动减仓止损。';
      case UpgradeId.news:
        return '提前 30 秒预告即将发生的事件。';
    }
  }
}

/// 给定升级 ID 和当前等级，得到下一级价格。
/// 不暴露给 UI 计算错误——所有升级成本都走这里。
double upgradeNextCost(UpgradeId id, int currentLevel) {
  switch (id) {
    case UpgradeId.fee:
      return _costFee(currentLevel);
    case UpgradeId.div:
      return _costDiv(currentLevel);
    case UpgradeId.bot:
      return _costBot(currentLevel);
    case UpgradeId.stop:
      return _costStop(currentLevel);
    case UpgradeId.news:
      return currentLevel >= 1 ? double.infinity : 30000.0;
  }
}

int upgradeMaxLevel(UpgradeId id) {
  switch (id) {
    case UpgradeId.fee:
      return 5;
    case UpgradeId.div:
      return 8;
    case UpgradeId.bot:
      return 3;
    case UpgradeId.stop:
      return 3;
    case UpgradeId.news:
      return 1;
  }
}

double _costFee(int lv) {
  // 5000 * 3^lv
  return 5000.0 * _powInt(3, lv);
}

double _costDiv(int lv) {
  // 4000 * 2.5^lv
  return 4000.0 * _powDouble(2.5, lv);
}

double _costBot(int lv) {
  // 25000 * 4^lv
  return 25000.0 * _powInt(4, lv);
}

double _costStop(int lv) {
  // 15000 * 3^lv
  return 15000.0 * _powInt(3, lv);
}

int _powInt(int base, int exp) {
  int r = 1;
  for (int i = 0; i < exp; i++) {
    r *= base;
  }
  return r;
}

double _powDouble(double base, int exp) {
  double r = 1.0;
  for (int i = 0; i < exp; i++) {
    r *= base;
  }
  return r;
}

/// 当前等级下的"效果摘要"。
String upgradeEffectLine(UpgradeId id, int level) {
  switch (id) {
    case UpgradeId.fee:
      // 0.20% 起步，每级 -0.03%，最低 0.05%
      final double fee = 0.0020 - 0.0003 * level;
      final double shown = fee * 100;
      return '当前手续费 ${shown.toStringAsFixed(2)}%';
    case UpgradeId.div:
      // 1.0 + 0.25/级，上限 x3.0
      final double m = 1.0 + 0.25 * level;
      return '当前分红倍率 ×${m.toStringAsFixed(2)}';
    case UpgradeId.bot:
      final String s = switch (level) {
        0 => '未启用',
        1 => '自选股自动低买 / 高卖 (10 股)',
        2 => '自选股自动低买 / 高卖 (30 股)',
        _ => '自选股自动低买 / 高卖 (100 股)',
      };
      return s;
    case UpgradeId.stop:
      final String t = switch (level) {
        0 => '未启用',
        1 => '亏损 8% 自动减仓',
        2 => '亏损 6% 自动减仓',
        _ => '亏损 4% 自动减仓',
      };
      return t;
    case UpgradeId.news:
      return level >= 1 ? '事件预告已开启 (30 秒)' : '未开启';
  }
}
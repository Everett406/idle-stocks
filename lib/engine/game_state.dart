/// lib/engine/game_state.dart
/// 中央 ChangeNotifier：持有所有可变状态、驱动 1s + 5s Timer、
/// 编排 market sim / events / dividends / tasks / save。
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/gbm.dart';
import '../models/holding.dart';
import '../models/market_event.dart';
import '../models/stock.dart';
import '../models/task.dart';
import '../models/upgrade.dart';
import '../services/sound_service.dart';
import 'dividends.dart';
import 'events.dart';
import 'market_sim.dart';
import 'prestige.dart';
import 'save_service.dart';
import 'task_system.dart';

/// UI 一次性消费的事件（GameState 入队，UI 拉走）。
sealed class UiEvent {
  const UiEvent();
}

class UiOfflineReport extends UiEvent {
  UiOfflineReport(this.seconds, this.amount);
  final int seconds;
  final double amount;
}

class UiUnlockToast extends UiEvent {
  UiUnlockToast(this.code, this.name);
  final String code;
  final String name;
}

class UiEventBanner extends UiEvent {
  UiEventBanner(this.event);
  final MarketEvent event;
}

class UiPrestigeComplete extends UiEvent {
  UiPrestigeComplete(this.newLevel);
  final int newLevel;
}

class UiTradeToast extends UiEvent {
  UiTradeToast({required this.buy, required this.shares, required this.amount});
  final bool buy;
  final int shares;
  final double amount;
}

class GameState extends ChangeNotifier {
  GameState({required this.soundService});

  final SoundService soundService;

  // ───── 状态切片 ─────
  final List<StockSeed> _seeds = kStockSeeds;
  final Map<String, StockSeed> _seedByCode = <String, StockSeed>{
    for (final StockSeed s in kStockSeeds) s.code: s,
  };

  late Map<String, LiveStock> _stocks;
  late Map<String, Holding> _holdings;
  late Map<UpgradeId, int> _upgrades;
  late int _managerLevel;
  late Set<String> _favorites;
  late List<DailyTask> _tasks;
  late String _taskDayKey;
  late double _cash;
  late double _dividendPot;
  late Map<String, double> _baselineForDay;
  late ThemeMode _themeMode;
  late int _lastSaveMs;
  // 上次事件触发时间戳
  int _nextEventInSec = 120;
  int _secondsSinceEventCheck = 0;
  // 上次 bot 检查时间戳 (毫秒)
  int _lastBotCheckMs = 0;
  // 每只股票最近一次事件开始 ms (避免 5 分钟内重复)
  final Map<String, int> _lastEventCodeMs = <String, int>{};
  // 当前正在播放的事件 (单只)
  MarketEvent? _activeEvent;
  // 当前显示的预告 (若升级了 news_push)
  MarketEvent? _previewEvent;
  int _previewEventTriggerMs = 0;

  // ───── 子引擎 ─────
  late NormalRandom _normal;
  late MarketTicker _ticker;
  late EventEngine _eventEngine;
  late TaskSystem _taskSystem;
  // RNG 单独维护存档 seed
  late math.Random _rng;

  // ───── 计时器 ─────
  Timer? _tickTimer;
  Timer? _divTimer;

  // ───── UI 事件队列 ─────
  final List<UiEvent> _uiEvents = <UiEvent>[];

  // ───── 公开 getter (只读视图) ─────
  List<StockSeed> get seeds => _seeds;
  Map<String, LiveStock> get stocks => _stocks;
  Map<String, Holding> get holdings => _holdings;
  Map<UpgradeId, int> get upgrades => _upgrades;
  int get managerLevel => _managerLevel;
  Set<String> get favorites => Set<String>.unmodifiable(_favorites);
  List<DailyTask> get tasks => List<DailyTask>.unmodifiable(_tasks);
  String get taskDayKey => _taskDayKey;
  double get cash => _cash;
  double get dividendPot => _dividendPot;
  Map<String, double> get baselineForDay => Map.unmodifiable(_baselineForDay);
  ThemeMode get themeMode => _themeMode;
  MarketEvent? get activeEvent => _activeEvent;
  MarketEvent? get previewEvent =>
      _previewEventTriggerMs > 0 &&
              DateTime.now().millisecondsSinceEpoch < _previewEventTriggerMs
          ? _previewEvent
          : null;
  String appVersion = const String.fromEnvironment('APP_VERSION', defaultValue: 'dev');

  // ───── 派生数据 ─────
  bool isUnlocked(String code) {
    final StockSeed? s = _seedByCode[code];
    if (s == null) return false;
    return totalAssets >= s.unlockAt;
  }

  double get totalAssets {
    double v = _cash;
    for (final StockSeed s in _seeds) {
      final Holding? h = _holdings[s.code];
      final LiveStock? live = _stocks[s.code];
      if (h == null || live == null) continue;
      v += h.shares * live.price;
    }
    return v;
  }

  /// 今日盈亏：相对 _baselineForDay 的差值。
  double get dayPnL {
    double v = 0.0;
    for (final StockSeed s in _seeds) {
      final Holding? h = _holdings[s.code];
      final LiveStock? live = _stocks[s.code];
      if (h == null || live == null) continue;
      final double base = _baselineForDay[s.code] ?? live.price;
      v += h.shares * (live.price - base);
    }
    return v;
  }

  double get dividendMult {
    final double base = 1.0 + 0.25 * (_upgrades[UpgradeId.div] ?? 0);
    final (double divMul, _) = Prestige.bonusesFor(_managerLevel);
    // 分红加倍卡时效：mvp 简化版本里用一个固定时长，叠加乘 2
    final double cardMul = _doubleCardRemaining.inSeconds > 0 ? 2.0 : 1.0;
    return base * divMul * cardMul;
  }

  Duration _doubleCardRemaining = Duration.zero;

  double get driftBonusMul {
    final (_, double drift) = Prestige.bonusesFor(_managerLevel);
    return drift;
  }

  double get commissionRate {
    final int lv = _upgrades[UpgradeId.fee] ?? 0;
    final double fee = 0.0020 - 0.0003 * lv;
    return fee < 0.0005 ? 0.0005 : fee;
  }

  bool isNightSession() {
    final DateTime now = DateTime.now();
    final int h = now.hour;
    return h >= kNightStartHour && h < kNightEndHour;
  }

  // ───── 初始化 ─────
  Future<OfflineBootstrap> bootstrap() async {
    _normal = NormalRandom(math.Random());
    _rng = math.Random();
    _ticker = MarketTicker(normal: _normal);
    _eventEngine = EventEngine(rng: _rng);
    _taskSystem = TaskSystem();

    _upgrades = <UpgradeId, int>{
      for (final UpgradeId id in UpgradeId.values) id: 0,
    };
    _holdings = <String, Holding>{};
    _favorites = <String>{_seeds.first.code};
    _managerLevel = 0;
    _cash = kStartingCash;
    _dividendPot = 0.0;
    _baselineForDay = <String, double>{};
    _lastSaveMs = DateTime.now().millisecondsSinceEpoch;
    _stocks = <String, LiveStock>{
      for (final StockSeed s in _seeds)
        s.code: LiveStock(
          code: s.code,
          initialPrice: s.initialPrice,
          price: s.initialPrice,
          history: <double>[s.initialPrice],
          eventBoost: 1.0,
          eventUntilMs: 0,
        ),
    };
    _baselineForDay = <String, double>{
      for (final StockSeed s in _seeds) s.code: s.initialPrice,
    };
    _taskDayKey = dateKeyOf(DateTime.now());
    _tasks = _taskSystem.ensureDailyTasks(
      existing: const <DailyTask>[],
      currentDayKey: _taskDayKey,
    );
    _themeMode = ThemeMode.system;

    // 读档
    final Map<String, dynamic>? saved = await SaveService.instance.load();
    if (saved != null) {
      _applyLoadedSave(saved);
    }

    // 离线结算
    final OfflineBootstrap offline = _settleOffline();

    // 跨天则重生今日任务 & 重置基准价
    final String todayKey = dateKeyOf(DateTime.now());
    if (todayKey != _taskDayKey) {
      _taskDayKey = todayKey;
      _tasks = _taskSystem.ensureDailyTasks(
        existing: _tasks,
        currentDayKey: todayKey,
      );
      _baselineForDay = <String, double>{
        for (final StockSeed s in _seeds) s.code: _stocks[s.code]?.price ?? s.initialPrice,
      };
    }

    // 合成历史填充 (只对已解锁股票)
    _fillSyntheticHistory();

    return offline;
  }

  void _applyLoadedSave(Map<String, dynamic> data) {
    _cash = (data['cash'] as num?)?.toDouble() ?? kStartingCash;
    _dividendPot = (data['dividendPot'] as num?)?.toDouble() ?? 0.0;
    _managerLevel = (data['managerLevel'] as num?)?.toInt() ?? 0;
    _lastSaveMs = (data['lastSaveMs'] as num?)?.toInt() ??
        DateTime.now().millisecondsSinceEpoch;
    _taskDayKey = (data['taskDayKey'] as String?) ?? dateKeyOf(DateTime.now());

    final dynamic rawHoldings = data['holdings'];
    _holdings = <String, Holding>{};
    if (rawHoldings is Map) {
      rawHoldings.forEach((dynamic k, dynamic v) {
        if (k is String && v is Map<String, dynamic>) {
          _holdings[k] = Holding.fromJson(v);
        }
      });
    }

    final dynamic rawUpgrades = data['upgrades'];
    if (rawUpgrades is Map) {
      rawUpgrades.forEach((dynamic k, dynamic v) {
        final UpgradeId? id = _upgradeIdByName(k as String);
        if (id != null && v is num) {
          _upgrades[id] = v.toInt().clamp(0, upgradeMaxLevel(id));
        }
      });
    }

    final dynamic rawFav = data['favorites'];
    if (rawFav is List) {
      _favorites = rawFav
          .whereType<String>()
          .where((String c) => _seedByCode.containsKey(c))
          .toSet();
      if (_favorites.isEmpty) _favorites.add(_seeds.first.code);
    }

    final dynamic rawStocks = data['stocks'];
    if (rawStocks is Map) {
      rawStocks.forEach((dynamic k, dynamic v) {
        if (k is String && v is Map<String, dynamic>) {
          final StockSeed? seed = _seedByCode[k];
          if (seed != null) {
            _stocks[k] = LiveStock.fromJson(k, seed.initialPrice, v);
          }
        }
      });
    }

    final dynamic rawBaseline = data['baselineForDayP'];
    if (rawBaseline is Map) {
      rawBaseline.forEach((dynamic k, dynamic v) {
        if (k is String && v is num) {
          _baselineForDay[k] = v.toDouble();
        }
      });
    }

    final dynamic rawTasks = data['tasks'];
    if (rawTasks is List) {
      _tasks = rawTasks
          .whereType<Map<String, dynamic>>()
          .map(DailyTask.fromJson)
          .toList();
    }
    _tasks = _taskSystem.ensureDailyTasks(
      existing: _tasks,
      currentDayKey: _taskDayKey,
    );

    final dynamic rawTheme = data['themeMode'];
    if (rawTheme is String) {
      switch (rawTheme) {
        case 'light':
          _themeMode = ThemeMode.light;
          break;
        case 'dark':
          _themeMode = ThemeMode.dark;
          break;
        default:
          _themeMode = ThemeMode.system;
      }
    }
  }

  UpgradeId? _upgradeIdByName(String name) {
    for (final UpgradeId id in UpgradeId.values) {
      if (id.name == name) return id;
    }
    return null;
  }

  /// 根据 lastSave 与当前时间，计算离线秒数和分红。
  OfflineBootstrap _settleOffline() {
    final int nowMs = DateTime.now().millisecondsSinceEpoch;
    final int deltaMs = nowMs - _lastSaveMs;
    if (deltaMs < kOfflineThreshold.inMilliseconds) {
      return OfflineBootstrap.empty();
    }
    final Duration elapsed = Duration(milliseconds: deltaMs);
    final Duration cap = elapsed > kOfflineCap ? kOfflineCap : elapsed;
    final Map<String, double> savedPrices = <String, double>{
      for (final StockSeed s in _seeds) s.code: _stocks[s.code]?.price ?? s.initialPrice,
    };
    final double amount = offlineDividend(
      holdings: _holdings,
      savedPrices: savedPrices,
      seeds: _seeds,
      dividendMult: dividendMult,
      elapsed: cap,
    );
    if (amount > 0) {
      _cash += amount;
    }
    return OfflineBootstrap(seconds: cap.inSeconds, amount: amount);
  }

  /// 为已解锁股票填充合成历史 (按 mu 反推)。
  void _fillSyntheticHistory() {
    for (final StockSeed s in _seeds) {
      final LiveStock? live = _stocks[s.code];
      if (live == null) continue;
      if (live.history.length >= kCardHistoryLen) continue;
      // 当前价 → 反推
      final int need = kCardHistoryLen - live.history.length;
      double p = live.price;
      final List<double> synth = <double>[p];
      for (int i = 0; i < need; i++) {
        final double mu = muPerSecFromDaily(s.dailyDrift);
        final double sigma = sigmaPerSecFromDaily(s.dailyVol);
        final double dt = kHistoryFillStep.inSeconds.toDouble();
        final double drift = (mu - 0.5 * sigma * sigma) * dt;
        final double diffusion = sigma * math.sqrt(dt) * _normal.next();
        final double next = p * math.exp(-(drift + diffusion));
        if (next.isNaN || next.isInfinite || next <= 0) {
          synth.add(p);
        } else {
          synth.add(next);
          p = next;
        }
      }
      // synth: 当前 → 过去
      synth.removeLast();
      synth.addAll(live.history);
      // 取最新 120
      if (synth.length > kCardHistoryLen) {
        synth.removeRange(0, synth.length - kCardHistoryLen);
      }
      live.history = synth;
    }
  }

  // ───── 启动 / 停止 ─────
  void start() {
    _tickTimer?.cancel();
    _divTimer?.cancel();
    _tickTimer = Timer.periodic(kTickInterval, (_) => _tick());
    _divTimer = Timer.periodic(kDividendInterval, (_) => _settleDividends());
  }

  void stop() {
    _tickTimer?.cancel();
    _divTimer?.cancel();
    _tickTimer = null;
    _divTimer = null;
  }

  Future<void> onAppPaused() async {
    await _save();
    stop();
  }

  Future<void> onAppResumed() async {
    final OfflineBootstrap offline = _settleOffline();
    if (offline.amount > 0) {
      _uiEvents.add(UiOfflineReport(offline.seconds, offline.amount));
    }
    start();
    notifyListeners();
  }

  // ───── 主循环 ─────
  int _tickCounter = 0;
  void _tick() {
    _tickCounter++;
    final int nowMs = DateTime.now().millisecondsSinceEpoch;

    // 1. 推所有股票
    final double volMul = isNightSession() ? 2.0 : 1.0;
    for (final StockSeed s in _seeds) {
      final LiveStock? live = _stocks[s.code];
      if (live == null) continue;
      live.price = _ticker.tickOne(
        seed: s,
        live: live,
        driftBonusMul: driftBonusMul,
        volBonusMul: volMul,
        activeEvent: _activeEvent,
        nowMs: nowMs,
      );
      live.pushPrice(live.price, maxLen: kCardHistoryLen);
    }

    // 2. 事件结束
    if (_activeEvent != null && nowMs >= _activeEvent!.endMs) {
      final LiveStock? live = _stocks[_activeEvent!.code];
      if (live != null) live.eventBoost = 1.0;
      _activeEvent = null;
      _previewEventTriggerMs = 0;
    }

    // 3. 事件触发
    _secondsSinceEventCheck++;
    if (_activeEvent == null &&
        _secondsSinceEventCheck >= _nextEventInSec) {
      _secondsSinceEventCheck = 0;
      _nextEventInSec = _eventEngine.rollNextDelay();
      final Set<String> unlocked = <String>{
        for (final StockSeed s in _seeds)
          if (totalAssets >= s.unlockAt) s.code,
      };
      final MarketEvent? ev = _eventEngine.maybeTrigger(
        seeds: _seeds,
        unlockedCodes: unlocked,
        lastEventCodeMs: _lastEventCodeMs,
        nowMs: nowMs,
      );
      if (ev != null) {
        _activeEvent = ev;
        final LiveStock? live = _stocks[ev.code];
        if (live != null) {
          live.eventBoost = 1.0 + ev.effect;
          live.eventUntilMs = ev.endMs;
        }
        _uiEvents.add(UiEventBanner(ev));
        soundService.play(Sfx.news);
        // 新闻推送预告
        if ((_upgrades[UpgradeId.news] ?? 0) >= 1) {
          // 这里简化为：事件触发当下同时显示预告 (逻辑保留供以后扩展)
          _previewEvent = null;
          _previewEventTriggerMs = 0;
        }
      }
    }

    // 4. 分红累加
    _dividendPot += accrueOneSecond(
      holdings: _holdings,
      stocks: _stocks,
      seeds: _seeds,
      dividendMult: dividendMult,
    );

    // 5. 解锁检查
    final Set<String> prevUnlocked = _currentlyUnlocked();
    for (final StockSeed s in _seeds) {
      final bool nowU = totalAssets >= s.unlockAt;
      final bool wasU = prevUnlocked.contains(s.code);
      if (nowU && !wasU) {
        _uiEvents.add(UiUnlockToast(s.code, s.name));
        soundService.play(Sfx.unlock);
      }
    }

    // 7. 自动机器人
    if (nowMs - _lastBotCheckMs >= kBotInterval.inMilliseconds) {
      _lastBotCheckMs = nowMs;
      _runBotIfReady();
    }

    // 8. 止损保险
    _runStopLossIfReady();

    // 9. 任务进度推进 (pnl/holdRising 在 tick 里评估)
    _updateTimedTaskProgress();

    // 10. 分红加倍卡倒计时
    if (_doubleCardRemaining > Duration.zero) {
      _doubleCardRemaining -= kTickInterval;
      if (_doubleCardRemaining.isNegative) {
        _doubleCardRemaining = Duration.zero;
      }
    }

    // 11. 自动存档
    if (_tickCounter % kSaveInterval.inSeconds == 0) {
      // 异步保存不影响 tick 节奏
      unawaited(_save());
    }

    notifyListeners();
  }

  double _realizedDayPnL() {
    // 今日盈亏 = dayPnL + 已实现 (卖出时 avgCost 差)
    return dayPnL;
  }

  void _updateTimedTaskProgress() {
    final double pnl = dayPnL;
    final int pnlInt = pnl > 0 ? pnl.floor() : 0;
    final double maxToday = pnlInt.toDouble();
    bool anyRising = false;
    for (final StockSeed s in _seeds) {
      final LiveStock? live = _stocks[s.code];
      if (live == null) continue;
      final double base = _baselineForDay[s.code] ?? live.price;
      final double ratio = base > 0 ? (live.price - base) / base : 0.0;
      if (ratio >= 0.02) {
        anyRising = true;
        break;
      }
    }
    for (final DailyTask t in _tasks) {
      if (t.state != TaskState.active) continue;
      switch (t.kind) {
        case TaskKind.pnl:
          // 用当前 P&L 作为进度（只增不减，方便 UI 显示）
          if (pnlInt > t.progress) t.progress = pnlInt.clamp(0, t.target);
          break;
        case TaskKind.holdRising:
          if (anyRising) t.progress = t.target;
          break;
        default:
          break;
      }
    }
    maxToday; // (silence lints)
  }

  Set<String> _currentlyUnlocked() {
    return <String>{
      for (final StockSeed s in _seeds)
        if (totalAssets >= s.unlockAt) s.code,
    };
  }

  // ───── 5 秒结算分红 ─────
  double _lastSettledAmount = 0.0;
  void _settleDividends() {
    if (_dividendPot <= 0) return;
    final double amt = _dividendPot;
    _cash += amt;
    _dividendPot = 0.0;
    _lastSettledAmount = amt;
    _bumpTask(TaskKind.dividend, amt.floor());
    soundService.play(Sfx.coin);
    notifyListeners();
  }

  double get lastSettledAmount => _lastSettledAmount;

  // ───── 自动机器人 ─────
  void _runBotIfReady() {
    final int lv = _upgrades[UpgradeId.bot] ?? 0;
    if (lv <= 0) return;
    final int qty = switch (lv) {
      1 => 10,
      2 => 30,
      _ => 100,
    };
    final double buyTh = switch (lv) {
      1 => 0.95,
      2 => 0.93,
      _ => 0.90,
    };
    final double sellTh = switch (lv) {
      1 => 1.05,
      2 => 1.07,
      _ => 1.10,
    };
    for (final String code in _favorites) {
      final Holding? h = _holdings[code];
      final LiveStock? live = _stocks[code];
      if (h == null || live == null) continue;
      if (!isUnlocked(code)) continue;
      // 买入：当前 < 持仓均价 * buyTh 且现金够
      if (h.avgCost > 0 &&
          live.price <= h.avgCost * buyTh &&
          _cash >= live.price * qty * (1 + commissionRate)) {
        buyInternal(code, qty, silent: true);
        continue;
      }
      // 卖出：当前 > 持仓均价 * sellTh 且有持仓
      if (h.avgCost > 0 &&
          live.price >= h.avgCost * sellTh &&
          h.shares > 0) {
        final int sellQty = (h.shares ~/ 2).clamp(1, h.shares);
        sellInternal(code, sellQty, silent: true);
      }
    }
  }

  // ───── 止损保险 ─────
  void _runStopLossIfReady() {
    final int lv = _upgrades[UpgradeId.stop] ?? 0;
    if (lv <= 0) return;
    final double threshold = switch (lv) {
      1 => -0.08,
      2 => -0.06,
      _ => -0.04,
    };
    for (final String code in _holdings.keys.toList()) {
      final Holding? h = _holdings[code];
      final LiveStock? live = _stocks[code];
      if (h == null || live == null || h.shares <= 0 || h.avgCost <= 0) continue;
      final double pnl = (live.price - h.avgCost) / h.avgCost;
      if (pnl <= threshold) {
        final int sellQty = (h.shares ~/ 2).clamp(1, h.shares);
        sellInternal(code, sellQty, silent: true);
        _uiEvents.add(UiTradeToast(buy: false, shares: sellQty, amount: sellQty * live.price));
      }
    }
  }

  // ───── 交易 (公开 API) ─────
  /// 公开买入入口；校验现金、扣费、写持仓。
  /// 返回 true=成交；false=失败。
  bool buy(String code, int shares) {
    if (shares <= 0) return false;
    final ok = buyInternal(code, shares, silent: false);
    if (ok) {
      _bumpTask(TaskKind.tradeCount, 1);
    }
    return ok;
  }

  bool sell(String code, int shares) {
    if (shares <= 0) return false;
    final ok = sellInternal(code, shares, silent: false);
    if (ok) {
      _bumpTask(TaskKind.tradeCount, 1);
    }
    return ok;
  }

  bool buyInternal(String code, int shares, {required bool silent}) {
    final StockSeed? s = _seedByCode[code];
    final LiveStock? live = _stocks[code];
    if (s == null || live == null) return false;
    if (!isUnlocked(code)) return false;
    final double fee = commissionRate;
    final double gross = shares * live.price;
    final double cost = gross * (1 + fee);
    if (_cash < cost) return false;
    _cash -= cost;
    final Holding cur = _holdings[code] ?? Holding.empty();
    final int newShares = cur.shares + shares;
    cur.avgCost = newShares == 0
        ? 0
        : (cur.shares * cur.avgCost + shares * live.price) / newShares;
    cur.shares = newShares;
    _holdings[code] = cur;
    if (!silent) {
      soundService.play(Sfx.trade);
      _uiEvents.add(UiTradeToast(buy: true, shares: shares, amount: gross));
    }
    notifyListeners();
    return true;
  }

  bool sellInternal(String code, int shares, {required bool silent}) {
    final StockSeed? s = _seedByCode[code];
    final LiveStock? live = _stocks[code];
    if (s == null || live == null) return false;
    final Holding? cur = _holdings[code];
    if (cur == null || cur.shares < shares) return false;
    final double fee = commissionRate;
    final double gross = shares * live.price;
    final double net = gross * (1 - fee);
    _cash += net;
    cur.shares -= shares;
    if (cur.shares == 0) cur.avgCost = 0;
    _holdings[code] = cur;
    if (!silent) {
      soundService.play(Sfx.trade);
      _uiEvents.add(UiTradeToast(buy: false, shares: shares, amount: net));
    }
    notifyListeners();
    return true;
  }

  // ───── 升级 / 转生 / 任务 ─────
  bool purchaseUpgrade(UpgradeId id) {
    final int cur = _upgrades[id] ?? 0;
    final int maxLv = upgradeMaxLevel(id);
    if (cur >= maxLv) return false;
    final double cost = upgradeNextCost(id, cur);
    if (_cash < cost) return false;
    _cash -= cost;
    _upgrades[id] = cur + 1;
    notifyListeners();
    return true;
  }

  bool claimTask(int index) {
    if (index < 0 || index >= _tasks.length) return false;
    final DailyTask t = _tasks[index];
    if (t.state != TaskState.active || !t.isComplete) return false;
    t.state = TaskState.claimed;
    if (t.rewardDoubleCard) {
      _doubleCardRemaining += const Duration(minutes: 10);
    } else if (t.rewardCash > 0) {
      _cash += t.rewardCash;
    }
    notifyListeners();
    return true;
  }

  bool canPrestigeNow() {
    return Prestige.canPrestige(
      totalAssets: totalAssets,
      managerLevel: _managerLevel,
    );
  }

  void doPrestige() {
    if (!canPrestigeNow()) return;
    final int newLevel = _managerLevel + 1;
    soundService.play(Sfx.prestige);
    _cash = kStartingCash;
    _holdings.clear();
    _upgrades = <UpgradeId, int>{
      for (final UpgradeId id in UpgradeId.values) id: 0,
    };
    _dividendPot = 0.0;
    _stocks = <String, LiveStock>{
      for (final StockSeed s in _seeds)
        s.code: LiveStock(
          code: s.code,
          initialPrice: s.initialPrice,
          price: s.initialPrice,
          history: <double>[s.initialPrice],
          eventBoost: 1.0,
          eventUntilMs: 0,
        ),
    };
    _baselineForDay = <String, double>{
      for (final StockSeed s in _seeds) s.code: s.initialPrice,
    };
    _favorites = <String>{_seeds.first.code};
    _taskDayKey = dateKeyOf(DateTime.now());
    _tasks = _taskSystem.ensureDailyTasks(
      existing: const <DailyTask>[],
      currentDayKey: _taskDayKey,
    );
    _activeEvent = null;
    _managerLevel = newLevel;
    _uiEvents.add(UiPrestigeComplete(newLevel));
    notifyListeners();
  }

  void toggleFavorite(String code) {
    if (!_seedByCode.containsKey(code)) return;
    if (_favorites.contains(code)) {
      _favorites.remove(code);
    } else {
      _favorites.add(code);
    }
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
    unawaited(_save());
  }

  // ───── 任务进度累加 ─────
  void _bumpTask(TaskKind kind, int delta) {
    for (final DailyTask t in _tasks) {
      if (t.state != TaskState.active) continue;
      if (t.kind == kind) {
        t.progress = (t.progress + delta).clamp(0, t.target);
      }
    }
  }

  // ───── UI 事件队列 ─────
  List<UiEvent> drainUiEvents() {
    final List<UiEvent> out = List<UiEvent>.from(_uiEvents);
    _uiEvents.clear();
    return out;
  }

  // ───── 存档 ─────
  Future<void> _save() async {
    final Map<String, dynamic> data = <String, dynamic>{
      'cash': _cash,
      'dividendPot': _dividendPot,
      'managerLevel': _managerLevel,
      'lastSaveMs': DateTime.now().millisecondsSinceEpoch,
      'taskDayKey': _taskDayKey,
      'holdings': <String, dynamic>{
        for (final MapEntry<String, Holding> e in _holdings.entries) e.key: e.value.toJson(),
      },
      'upgrades': <String, dynamic>{
        for (final UpgradeId id in UpgradeId.values) id.name: _upgrades[id] ?? 0,
      },
      'favorites': _favorites.toList(),
      'stocks': <String, dynamic>{
        for (final MapEntry<String, LiveStock> e in _stocks.entries) e.key: e.value.toJson(historyTail: kSaveHistoryLen),
      },
      'baselineForDayP': _baselineForDay,
      'tasks': _tasks.map((DailyTask t) => t.toJson()).toList(),
      'themeMode': _themeMode.name,
    };
    _lastSaveMs = data['lastSaveMs'] as int;
    await SaveService.instance.save(data);
  }

  Future<void> saveNow() => _save();

  // ───── 测试/调试 ─────
  @visibleForTesting
  void debugForceTick() => _tick();

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}

/// 离线结算结果。
class OfflineBootstrap {
  OfflineBootstrap.empty()
      : seconds = 0,
        amount = 0;
  OfflineBootstrap({required this.seconds, required this.amount});
  final int seconds;
  final double amount;
}
/// lib/ui/market_page.dart
/// 市场 Tab：顶部跑马灯 + 股票卡列表（迷你走势图 + 持仓/自选呼吸描边）。
library;

import 'package:flutter/material.dart';

import '../core/format.dart';
import '../engine/game_state.dart';
import '../models/market_event.dart';
import '../models/stock.dart';
import 'app.dart';
import 'stock_detail_page.dart';
import 'widgets/event_banner.dart';
import 'widgets/sparkline.dart';

class MarketPage extends StatefulWidget {
  const MarketPage({super.key, required this.game});
  final GameState game;

  @override
  State<MarketPage> createState() => _MarketPageState();
}

class _MarketPageState extends State<MarketPage> {
  MarketEvent? _activeEvent;
  bool _showEventBanner = false;

  @override
  void initState() {
    super.initState();
    widget.game.addListener(_drainEvents);
  }

  @override
  void dispose() {
    widget.game.removeListener(_drainEvents);
    super.dispose();
  }

  void _drainEvents() {
    final List<UiEvent> evs = widget.game.drainUiEvents();
    bool changed = false;
    for (final UiEvent e in evs) {
      if (e is UiEventBanner) {
        _activeEvent = e.event;
        _showEventBanner = true;
        changed = true;
      } else if (e is UiUnlockToast) {
        changed = true;
      }
    }
    if (changed && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final MarketColors m = context.market;
    return Column(
      children: <Widget>[
        _TopBar(game: widget.game, accent: m.up),
        if (_showEventBanner && _activeEvent != null)
          EventBanner(
            event: _activeEvent!,
            visible: true,
            upColor: m.up,
            downColor: m.down,
          ),
        Expanded(
          child: AnimatedBuilder(
            animation: widget.game,
            builder: (BuildContext context, Widget? _) {
              final List<Widget> cards = <Widget>[];
              for (final StockSeed seed in widget.game.seeds) {
                final bool unlocked = widget.game.isUnlocked(seed.code);
                cards.add(_StockCard(
                  game: widget.game,
                  seed: seed,
                  unlocked: unlocked,
                  onTap: unlocked
                      ? () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (BuildContext c) =>
                                  StockDetailPage(game: widget.game, code: seed.code),
                            ),
                          );
                        }
                      : null,
                ));
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: cards.length,
                itemBuilder: (BuildContext c, int i) => cards[i],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.game, required this.accent});
  final GameState game;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('股海大亨', style: Theme.of(context).textTheme.titleLarge),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => game.saveNow(),
                  tooltip: '手动存档',
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // 跑马灯区域用一个 TweenAnimationBuilder 展示动态背景微变。
          _BackgroundTint(game: game, accent: accent),
        ],
      ),
    );
  }
}

class _BackgroundTint extends StatelessWidget {
  const _BackgroundTint({required this.game, required this.accent});
  final GameState game;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 36,
      child: Stack(
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Color.lerp(const Color(0xFF0E1A30), const Color(0xFF1B1A12), _bias(game))
                  : Color.lerp(const Color(0xFFF7F8FA), const Color(0xFFF0F4F1), _bias(game)),
            ),
          ),
          TickerTape(game: game),
        ],
      ),
    );
  }

  double _bias(GameState g) {
    // 平均 drift 加权映射到 [0,1]
    double weighted = 0;
    double total = 0;
    for (final StockSeed s in g.seeds) {
      if (!g.isUnlocked(s.code)) continue;
      weighted += s.dailyDrift;
      total += 1;
    }
    if (total == 0) return 0.5;
    final double avg = weighted / total; // 通常 -0.001 ~ 0.006
    return (0.5 + avg * 60).clamp(0.0, 1.0);
  }
}

class _StockCard extends StatefulWidget {
  const _StockCard({required this.game, required this.seed, required this.unlocked, required this.onTap});
  final GameState game;
  final StockSeed seed;
  final bool unlocked;
  final VoidCallback? onTap;

  @override
  State<_StockCard> createState() => _StockCardState();
}

class _StockCardState extends State<_StockCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _borderCtl;

  @override
  void initState() {
    super.initState();
    _borderCtl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _borderCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final MarketColors m = context.market;
    final LiveStock? live = widget.game.stocks[widget.seed.code];
    final bool held = (widget.game.holdings[widget.seed.code]?.shares ?? 0) > 0;
    final bool fav = widget.game.favorites.contains(widget.seed.code);
    final bool accent = held || fav;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: AnimatedBuilder(
        animation: _borderCtl,
        builder: (BuildContext context, Widget? _) {
          final double a = accent ? (0.6 + 0.4 * _borderCtl.value) : 0.0;
          final double upDown = (live?.dayChangeRatio ?? 0);
          final Color borderColor = !widget.unlocked
              ? Theme.of(context).dividerColor
              : (upDown >= 0 ? m.up : m.down);
          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: widget.onTap,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: borderColor.withOpacity(a == 0 ? 0.3 : a),
                  width: a == 0 ? 1 : 1.4,
                ),
              ),
              child: !widget.unlocked
                  ? _Locked(seed: widget.seed)
                  : _Unlocked(
                      seed: widget.seed,
                      live: live!,
                      m: m,
                    ),
            ),
          );
        },
      ),
    );
  }
}

class _Locked extends StatelessWidget {
  const _Locked({required this.seed});
  final StockSeed seed;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const Icon(Icons.lock, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('${seed.name}  ${seed.code}', style: Theme.of(context).textTheme.titleSmall),
              Text(
                '总资产达 ${formatMoney(seed.unlockAt)} 解锁 · ${seed.sector}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Unlocked extends StatelessWidget {
  const _Unlocked({required this.seed, required this.live, required this.m});
  final StockSeed seed;
  final LiveStock live;
  final MarketColors m;
  @override
  Widget build(BuildContext context) {
    final double r = live.dayChangeRatio;
    final List<double> full = live.history;
    final int n = full.length;
    final int from = n > 120 ? n - 120 : 0;
    final List<double> h = full.sublist(from);
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text(seed.name, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(width: 6),
                  Text(seed.code, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Theme.of(context).dividerColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(seed.sector,
                        style: const TextStyle(fontSize: 10)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: <Widget>[
                  Text(
                    formatPrice(live.price),
                    style: priceStyle(
                      upColor: m.up,
                      downColor: m.down,
                      neutralColor: m.neutral,
                      ratio: r,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formatPercent(r),
                    style: priceStyle(
                      upColor: m.up,
                      downColor: m.down,
                      neutralColor: m.neutral,
                      ratio: r,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(
          width: 80,
          height: 40,
          child: Sparkline(values: h, height: 40),
        ),
      ],
    );
  }
}
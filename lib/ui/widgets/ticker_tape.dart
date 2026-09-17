/// lib/ui/widgets/ticker_tape.dart
/// 顶部跑马灯：使用两段 ListView 拼接 + 持续滚动动画。
library;

import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../engine/game_state.dart';
import '../app.dart';

class TickerTape extends StatefulWidget {
  const TickerTape({super.key, required this.game});
  final GameState game;

  @override
  State<TickerTape> createState() => _TickerTapeState();
}

class _TickerTapeState extends State<TickerTape>
    with SingleTickerProviderStateMixin {
  late final ScrollController _ctlA;
  late final ScrollController _ctlB;
  late final AnimationController _auto;

  @override
  void initState() {
    super.initState();
    _ctlA = ScrollController();
    _ctlB = ScrollController();
    _auto = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
  }

  @override
  void dispose() {
    _ctlA.dispose();
    _ctlB.dispose();
    _auto.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.game,
      builder: (BuildContext context, Widget? _) {
        final MarketColors m = context.market;
        // 渲染一组 (name price ratio)
        final List<_TickerItem> items = <_TickerItem>[];
        for (final seed in widget.game.seeds) {
          if (!widget.game.isUnlocked(seed.code)) continue;
          final live = widget.game.stocks[seed.code];
          if (live == null) continue;
          final ratio = seed.initialPrice > 0
              ? (live.price - seed.initialPrice) / seed.initialPrice
              : 0.0;
          items.add(_TickerItem(seed.name, live.price, ratio));
        }
        // 跑马灯：用 ListView 双段拼接，让它们各自滚但循环
        return SizedBox(
          height: 36,
          child: Row(
            children: <Widget>[
              Expanded(
                child: AnimatedBuilder(
                  animation: _auto,
                  builder: (BuildContext context, Widget? _) {
                    // 持续把 A 滚到底；同时反向把 B 滚到顶，模拟接续。
                    final double total = _estimateWidth(items);
                    final double aOff = -(_auto.value * total);
                    final double bOff = aOff + total;
                    return ClipRect(
                      child: Stack(
                        children: <Widget>[
                          _Row(items: items, offsetX: aOff, m: m),
                          _Row(items: items, offsetX: bOff, m: m),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  double _estimateWidth(List<_TickerItem> items) {
    // 每个 item 约 200 px；用于跑马灯拼接距离
    return items.length * 200.0;
  }
}

class _TickerItem {
  _TickerItem(this.name, this.price, this.ratio);
  final String name;
  final double price;
  final double ratio;
}

class _Row extends StatelessWidget {
  const _Row({required this.items, required this.offsetX, required this.m});
  final List<_TickerItem> items;
  final double offsetX;
  final MarketColors m;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(offsetX, 0),
      child: Row(
        children: <Widget>[
          for (final _TickerItem it in items)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: <Widget>[
                  Text(
                    it.name,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    formatPrice(it.price),
                    style: priceStyle(
                      upColor: m.up,
                      downColor: m.down,
                      neutralColor: m.neutral,
                      ratio: it.ratio,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    formatPercent(it.ratio),
                    style: priceStyle(
                      upColor: m.up,
                      downColor: m.down,
                      neutralColor: m.neutral,
                      ratio: it.ratio,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 1,
                    height: 16,
                    color: Theme.of(context).dividerColor,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
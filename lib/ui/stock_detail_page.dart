/// lib/ui/stock_detail_page.dart
/// 股票详情：实时折线 + 买卖面板 + 收藏按钮 + 事件标记。
library;

import 'package:flutter/material.dart';

import '../core/format.dart';
import '../engine/game_state.dart';
import '../models/market_event.dart';
import '../models/stock.dart';
import 'app.dart';
import 'widgets/trading_panel.dart';

class StockDetailPage extends StatefulWidget {
  const StockDetailPage({super.key, required this.game, required this.code});
  final GameState game;
  final String code;

  @override
  State<StockDetailPage> createState() => _StockDetailPageState();
}

class _StockDetailPageState extends State<StockDetailPage> {
  @override
  Widget build(BuildContext context) {
    final MarketColors m = context.market;
    final StockSeed? seed = widget.game.seeds
        .where((StockSeed s) => s.code == widget.code)
        .firstOrNull;
    if (seed == null) {
      return const Scaffold(body: Center(child: Text('未找到该股票')));
    }
    final LiveStock? live = widget.game.stocks[widget.code];
    final h = widget.game.holdings[widget.code];
    return AnimatedBuilder(
      animation: widget.game,
      builder: (BuildContext context, Widget? _) {
        if (live == null) return const SizedBox.shrink();
        final double dayR = live.dayChangeRatio;
        final MarketEvent? activeEvent = widget.game.activeEvent?.code == widget.code
            ? widget.game.activeEvent
            : null;
        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: <Widget>[
                Text(seed.name),
                const SizedBox(width: 8),
                Text(seed.code, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            actions: <Widget>[
              IconButton(
                icon: Icon(
                  widget.game.favorites.contains(widget.code)
                      ? Icons.favorite
                      : Icons.favorite_border,
                ),
                color: widget.game.favorites.contains(widget.code) ? m.up : null,
                onPressed: () => widget.game.toggleFavorite(widget.code),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              formatPrice(live.price),
                              style: priceStyle(
                                upColor: m.up,
                                downColor: m.down,
                                neutralColor: m.neutral,
                                ratio: dayR,
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: <Widget>[
                                Text(
                                  '今日 ${formatPercent(dayR)}',
                                  style: priceStyle(
                                    upColor: m.up,
                                    downColor: m.down,
                                    neutralColor: m.neutral,
                                    ratio: dayR,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).dividerColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(seed.sector, style: const TextStyle(fontSize: 11)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '日漂移 ${formatPercent(seed.dailyDrift)} · 日波动 ${formatPercent(seed.dailyVol)} · 日分红 ${formatPercent(seed.dailyDivRate)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _DetailChart(
                      values: _extendedHistory(live, activeEvent),
                      upColor: m.up,
                      downColor: m.down,
                      neutral: m.neutral,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text('现价', style: Theme.of(context).textTheme.bodySmall),
                      Text('持仓 ${h?.shares ?? 0} 股', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                TradingPanel(
                  seed: seed,
                  price: live.price,
                  cash: widget.game.cash,
                  holdingShares: h?.shares ?? 0,
                  commissionRate: widget.game.commissionRate,
                  upColor: m.up,
                  downColor: m.down,
                  onBuy: (int sh) => widget.game.buy(widget.code, sh),
                  onSell: (int sh) => widget.game.sell(widget.code, sh),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<double> _extendedHistory(LiveStock live, MarketEvent? ev) {
    final List<double> base = live.history;
    if (base.length < 2) return base;
    return base;
  }
}

class _DetailChart extends StatelessWidget {
  const _DetailChart({required this.values, required this.upColor, required this.downColor, required this.neutral});
  final List<double> values;
  final Color upColor;
  final Color downColor;
  final Color neutral;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: CustomPaint(
        painter: _DetailPainter(
          values: values,
          upColor: upColor,
          downColor: downColor,
          neutral: neutral,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _DetailPainter extends CustomPainter {
  _DetailPainter({required this.values, required this.upColor, required this.downColor, required this.neutral});
  final List<double> values;
  final Color upColor;
  final Color downColor;
  final Color neutral;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    double minV = values.first;
    double maxV = values.first;
    for (final double v in values) {
      if (v < minV) minV = v;
      if (v > maxV) maxV = v;
    }
    final double span = (maxV - minV).abs();
    final double scale = span < 1e-6 ? 0.0 : 1.0 / span;
    final double pad = 16;
    final double w = size.width - pad * 2;
    final double h = size.height - pad * 2;
    // 网格线
    final Paint grid = Paint()
      ..color = neutral.withOpacity(0.08)
      ..strokeWidth = 1;
    for (int i = 1; i < 4; i++) {
      final double y = pad + h * i / 4;
      canvas.drawLine(Offset(pad, y), Offset(pad + w, y), grid);
    }
    final Path line = Path();
    final int n = values.length;
    for (int i = 0; i < n; i++) {
      final double x = pad + (i / (n - 1)) * w;
      final double y = pad + (1.0 - (values[i] - minV) * scale) * h;
      if (i == 0) {
        line.moveTo(x, y);
      } else {
        line.lineTo(x, y);
      }
    }
    // 渐变填充
    final Color lineColor = values.last >= values.first ? upColor : downColor;
    final Path fill = Path.from(line)
      ..lineTo(pad + w, pad + h)
      ..lineTo(pad, pad + h)
      ..close();
    final Paint fp = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[lineColor.withOpacity(0.30), lineColor.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fill, fp);
    final Paint lp = Paint()
      ..color = lineColor
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(line, lp);
  }

  @override
  bool shouldRepaint(covariant _DetailPainter old) {
    if (old.values.length != values.length) return true;
    for (int i = 0; i < values.length; i++) {
      if ((old.values[i] - values[i]).abs() > 1e-4) return true;
    }
    return false;
  }
}
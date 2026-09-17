/// lib/ui/portfolio_page.dart
/// 持仓 Tab：资产总览 + 持仓列表 + 主题切换入口。
library;

import 'package:flutter/material.dart';

import '../core/format.dart';
import '../engine/game_state.dart';
import '../models/stock.dart';
import 'app.dart';
import 'stock_detail_page.dart';
import 'widgets/countup_text.dart';
import 'widgets/sparkline.dart';

class PortfolioPage extends StatelessWidget {
  const PortfolioPage({super.key, required this.game});
  final GameState game;

  @override
  Widget build(BuildContext context) {
    final MarketColors m = context.market;
    return AnimatedBuilder(
      animation: game,
      builder: (BuildContext context, Widget? _) {
        final double assets = game.totalAssets;
        final double pnl = game.dayPnL;
        return Column(
          children: <Widget>[
            _Header(game: game, totalAssets: assets, pnl: pnl),
            const Divider(height: 1),
            Expanded(
              child: _buildList(context, game, m),
            ),
          ],
        );
      },
    );
  }

  Widget _buildList(BuildContext context, GameState game, MarketColors m) {
    final List<StockSeed> ownedSeeds = <StockSeed>[];
    for (final StockSeed s in game.seeds) {
      if ((game.holdings[s.code]?.shares ?? 0) > 0) ownedSeeds.add(s);
    }
    if (ownedSeeds.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(Icons.shopping_bag_outlined, size: 56),
              const SizedBox(height: 12),
              Text('暂无持仓', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(
                '去市场 Tab 挑一只看好的票买入。',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: ownedSeeds.length,
      itemBuilder: (BuildContext c, int i) {
        final StockSeed s = ownedSeeds[i];
        return _HoldingCard(game: game, seed: s, m: m);
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.game, required this.totalAssets, required this.pnl});
  final GameState game;
  final double totalAssets;
  final double pnl;

  @override
  Widget build(BuildContext context) {
    final MarketColors m = context.market;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('总资产', style: Theme.of(context).textTheme.bodyMedium),
                IconButton(
                  icon: const Icon(Icons.settings),
                  tooltip: '设置',
                  onPressed: () => _showSettings(context),
                ),
              ],
            ),
            const SizedBox(height: 4),
            CountUpText(
              value: totalAssets,
              upColor: m.up,
              downColor: m.down,
              neutralColor: Theme.of(context).textTheme.titleLarge?.color ?? m.neutral,
              formatter: formatMoney,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: _StatBlock(
                    label: '现金',
                    valueWidget: CountUpText(
                      value: game.cash,
                      upColor: m.up,
                      downColor: m.down,
                      neutralColor: Theme.of(context).textTheme.titleSmall?.color ?? m.neutral,
                      formatter: formatMoney,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ),
                Expanded(
                  child: _StatBlock(
                    label: '今日盈亏',
                    valueWidget: CountUpText(
                      value: pnl,
                      upColor: m.up,
                      downColor: m.down,
                      neutralColor: Theme.of(context).textTheme.titleSmall?.color ?? m.neutral,
                      formatter: formatMoney,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ),
                Expanded(
                  child: _StatBlock(
                    label: '经理',
                    valueWidget: Text(
                      'Lv.${game.managerLevel}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      builder: (BuildContext c) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text('设置', style: Theme.of(c).textTheme.titleLarge),
                const SizedBox(height: 12),
                Text('主题', style: Theme.of(c).textTheme.bodyMedium),
                const SizedBox(height: 8),
                SegmentedButton<ThemeMode>(
                  segments: const <ButtonSegment<ThemeMode>>[
                    ButtonSegment<ThemeMode>(value: ThemeMode.system, label: Text('跟随')),
                    ButtonSegment<ThemeMode>(value: ThemeMode.light, label: Text('浅色')),
                    ButtonSegment<ThemeMode>(value: ThemeMode.dark, label: Text('深色')),
                  ],
                  selected: <ThemeMode>{game.themeMode},
                  onSelectionChanged: (Set<ThemeMode> s) {
                    game.setThemeMode(s.first);
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('版本'),
                  subtitle: Text(game.appVersion),
                ),
                ListTile(
                  leading: const Icon(Icons.save_outlined),
                  title: const Text('立即存档'),
                  onTap: () async {
                    await game.saveNow();
                    if (c.mounted) {
                      ScaffoldMessenger.of(c).showSnackBar(
                        const SnackBar(content: Text('已保存')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({required this.label, required this.valueWidget});
  final String label;
  final Widget valueWidget;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        valueWidget,
      ],
    );
  }
}

class _HoldingCard extends StatelessWidget {
  const _HoldingCard({required this.game, required this.seed, required this.m});
  final GameState game;
  final StockSeed seed;
  final MarketColors m;

  @override
  Widget build(BuildContext context) {
    final h = game.holdings[seed.code];
    final live = game.stocks[seed.code];
    if (h == null || live == null) return const SizedBox.shrink();
    final double mv = h.shares * live.price;
    final double unrealized = h.shares * (live.price - h.avgCost);
    final double unrealizedRatio = h.avgCost > 0 ? (live.price - h.avgCost) / h.avgCost : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (BuildContext c) => StockDetailPage(game: game, code: seed.code),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text('${seed.name}  ${seed.code}', style: Theme.of(context).textTheme.titleSmall),
                  ),
                  Text(
                    formatMoney(mv),
                    style: monoStyle(
                      color: Theme.of(context).textTheme.titleSmall?.color,
                      fontWeight: FontWeight.w700,
                      base: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: <Widget>[
                  Text(
                    '${h.shares} 股',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 8),
                  Text('均价 ${formatPrice(h.avgCost)}', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(width: 8),
                  Text(
                    formatMoney(unrealized),
                    style: priceStyle(
                      upColor: m.up,
                      downColor: m.down,
                      neutralColor: m.neutral,
                      ratio: unrealizedRatio,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SizedBox(height: 36, child: Sparkline(values: live.history, height: 36)),
              const SizedBox(height: 6),
              Row(
                children: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.favorite, size: 20),
                    color: game.favorites.contains(seed.code) ? m.up : null,
                    onPressed: () => game.toggleFavorite(seed.code),
                    tooltip: '自选',
                  ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: h.shares <= 0
                        ? null
                        : () {
                            game.sell(seed.code, (h.shares / 2).ceil().clamp(1, h.shares));
                          },
                    child: const Text('卖一半'),
                  ),
                  const SizedBox(width: 6),
                  OutlinedButton(
                    onPressed: h.shares <= 0
                        ? null
                        : () => game.sell(seed.code, h.shares),
                    child: const Text('全卖'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
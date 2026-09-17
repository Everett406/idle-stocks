/// lib/ui/growth_page.dart
/// 成长 Tab：升级 + 每日任务 + 夜盘提示 + 转生。
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants.dart';
import '../core/format.dart';
import '../engine/game_state.dart';
import '../engine/prestige.dart';
import '../models/task.dart';
import '../models/upgrade.dart';
import 'app.dart';
import 'widgets/countup_text.dart';

class GrowthPage extends StatelessWidget {
  const GrowthPage({super.key, required this.game});
  final GameState game;

  @override
  Widget build(BuildContext context) {
    final MarketColors m = context.market;
    return AnimatedBuilder(
      animation: game,
      builder: (BuildContext context, Widget? _) {
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          children: <Widget>[
            _NightSessionCard(active: game.isNightSession()),
            const SizedBox(height: 12),
            _SectionTitle(title: '升级'),
            for (final UpgradeId id in UpgradeId.values)
              _UpgradeRow(game: game, id: id),
            const SizedBox(height: 16),
            _SectionTitle(title: '今日任务'),
            for (int i = 0; i < game.tasks.length; i++)
              _TaskRow(game: game, index: i, task: game.tasks[i]),
            const SizedBox(height: 16),
            _PrestigeCard(game: game),
          ],
        );
      },
    );
  }
}

class _NightSessionCard extends StatelessWidget {
  const _NightSessionCard({required this.active});
  final bool active;
  @override
  Widget build(BuildContext context) {
    final MarketColors m = context.market;
    final Color c = active ? m.up : Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c, width: 1.2),
      ),
      child: Row(
        children: <Widget>[
          Icon(active ? Icons.flash_on : Icons.nightlight_round, color: c),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  active ? '夜盘激战进行中' : '夜盘激战 21:00–22:00',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  active
                      ? '波动 ×2，分红 ×1.5'
                      : '到点自动开启：波动翻倍、分红 ×1.5',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _UpgradeRow extends StatelessWidget {
  const _UpgradeRow({required this.game, required this.id});
  final GameState game;
  final UpgradeId id;
  @override
  Widget build(BuildContext context) {
    final int lv = game.upgrades[id] ?? 0;
    final int max = upgradeMaxLevel(id);
    final bool maxed = lv >= max;
    final double cost = upgradeNextCost(id, lv);
    final bool canBuy = !maxed && game.cash >= cost;
    final MarketColors m = context.market;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(id.label, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).dividerColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('Lv.$lv / $max', style: const TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
                Text(id.desc, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(upgradeEffectLine(id, lv), style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: canBuy ? () {
              if (game.purchaseUpgrade(id)) {
                HapticFeedback.selectionClick();
              }
            } : null,
            style: FilledButton.styleFrom(
              backgroundColor: maxed ? Theme.of(context).disabledColor : null,
            ),
            child: Text(maxed ? '已满级' : formatMoney(cost)),
          ),
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.game, required this.index, required this.task});
  final GameState game;
  final int index;
  final DailyTask task;
  @override
  Widget build(BuildContext context) {
    final MarketColors m = context.market;
    final bool done = task.isComplete;
    final bool claimed = task.state == TaskState.claimed;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            claimed ? Icons.check_circle : (done ? Icons.radio_button_unchecked : Icons.radio_button_unchecked),
            color: claimed ? Theme.of(context).colorScheme.primary : (done ? m.up : null),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(task.label, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                LinearProgressIndicator(value: task.progressRatio),
                const SizedBox(height: 4),
                Text(
                  claimed
                      ? '已领取'
                      : '进度 ${task.progress}/${task.target}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: (done && !claimed) ? () {
              game.claimTask(index);
            } : null,
            child: Text(
              claimed
                  ? '已领'
                  : (task.rewardDoubleCard ? '领取 ×2 卡' : '领取 ${formatMoney(task.rewardCash)}'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrestigeCard extends StatelessWidget {
  const _PrestigeCard({required this.game});
  final GameState game;

  @override
  Widget build(BuildContext context) {
    final MarketColors m = context.market;
    final double threshold = Prestige.thresholdFor(game.managerLevel);
    final double progress = (game.totalAssets / threshold).clamp(0.0, 1.0);
    final bool can = game.canPrestigeNow();
    final (double div, double drift) = Prestige.bonusesFor(game.managerLevel + 1);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: can ? m.up : Theme.of(context).dividerColor,
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.workspace_premium, color: can ? m.up : null),
              const SizedBox(width: 8),
              Text('转生', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Text('经理 Lv.${game.managerLevel}', style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
          const SizedBox(height: 8),
          Text('总资产达 ${formatMoney(threshold)} 可转生', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          LinearProgressIndicator(value: progress),
          const SizedBox(height: 6),
          CountUpText(
            value: game.totalAssets,
            upColor: m.up,
            downColor: m.down,
            neutralColor: Theme.of(context).textTheme.bodyMedium?.color ?? m.neutral,
            formatter: formatMoney,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Text(
            '下一级永久加成：分红 ×${div.toStringAsFixed(2)}，漂移 ×${drift.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: can ? () {
              HapticFeedback.heavyImpact();
              game.doPrestige();
            } : null,
            style: FilledButton.styleFrom(backgroundColor: can ? m.up : null),
            child: const Text('转生'),
          ),
        ],
      ),
    );
  }
}
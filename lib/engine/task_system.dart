/// lib/engine/task_system.dart
/// 每日任务：跨天重置、用日期种子选 3 个模板。
library;

import 'dart:math' as math;

import '../core/constants.dart';
import '../models/task.dart';

class TaskSystem {
  TaskSystem();

  /// 若跨天或首次启动，生成 3 个新任务。
  List<DailyTask> ensureDailyTasks({
    required List<DailyTask> existing,
    required String currentDayKey,
  }) {
    final bool sameDay = existing.isNotEmpty &&
        existing.first.id.contains(currentDayKey);
    if (sameDay) return existing;

    final List<DailyTask> next = <DailyTask>[];
    final int seed = hashDateKey(DateTime.parse(currentDayKey));
    final math.Random dayRng = math.Random(seed);
    final List<TaskTemplate> pool = List<TaskTemplate>.from(kTaskTemplates);
    pool.shuffle(dayRng);
    final List<TaskTemplate> picks = pool.take(3).toList(growable: false);

    for (int i = 0; i < picks.length; i++) {
      final TaskTemplate t = picks[i];
      final String label = t.label
          .replaceAll('{n}', NumberFormatFixed.format(t.target));
      // 简单奖励：现金 500~3000 或分红加倍卡
      final bool card = dayRng.nextDouble() < 0.25;
      next.add(DailyTask(
        id: '${t.id}_${currentDayKey}_$i',
        templateId: t.id,
        label: label,
        target: t.target,
        kind: t.kind,
        progress: 0,
        state: TaskState.active,
        rewardCash: card ? 0 : (500 + dayRng.nextInt(2501)).toDouble(),
        rewardDoubleCard: card,
      ));
    }
    return next;
  }

  /// 任务进度推进：在 GameState 每 tick 调用一次。
  void updateProgress({
    required List<DailyTask> tasks,
    required Map<TaskKind, int> deltas,
  }) {
    for (final DailyTask t in tasks) {
      if (t.state != TaskState.active) continue;
      final int? d = deltas[t.kind];
      if (d == null || d == 0) continue;
      t.progress = (t.progress + d).clamp(0, t.target);
    }
  }
}

/// 极简数字格式化（避免再 import intl）
class NumberFormatFixed {
  static String format(int v) => v.toString();
}
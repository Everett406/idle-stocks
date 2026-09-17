/// lib/models/task.dart
/// 每日任务实例。
library;

import '../core/constants.dart';

enum TaskState { active, claimed, expired }

class DailyTask {
  DailyTask({
    required this.id,
    required this.templateId,
    required this.label,
    required this.target,
    required this.kind,
    required this.progress,
    required this.state,
    required this.rewardCash,
    required this.rewardDoubleCard,
  });

  /// 内部唯一 id：templateId + 当日种子后缀（避免跨天撞 id）。
  final String id;
  final String templateId;
  final String label;
  final int target;
  final TaskKind kind;
  int progress;
  TaskState state;
  final double rewardCash;
  final bool rewardDoubleCard;

  double get progressRatio => target == 0 ? 0 : (progress / target).clamp(0.0, 1.0);
  bool get isComplete => progress >= target;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'templateId': templateId,
        'label': label,
        'target': target,
        'kind': kind.index,
        'progress': progress,
        'state': state.index,
        'rewardCash': rewardCash,
        'rewardDoubleCard': rewardDoubleCard,
      };

  static DailyTask fromJson(Map<String, dynamic> json) {
    final int kindIdx = (json['kind'] as num?)?.toInt() ?? 0;
    final int stateIdx = (json['state'] as num?)?.toInt() ?? 0;
    return DailyTask(
      id: json['id'] as String,
      templateId: json['templateId'] as String,
      label: json['label'] as String,
      target: (json['target'] as num).toInt(),
      kind: kindIdx >= 0 && kindIdx < TaskKind.values.length
          ? TaskKind.values[kindIdx]
          : TaskKind.tradeCount,
      progress: (json['progress'] as num).toInt(),
      state: stateIdx >= 0 && stateIdx < TaskState.values.length
          ? TaskState.values[stateIdx]
          : TaskState.active,
      rewardCash: (json['rewardCash'] as num?)?.toDouble() ?? 0,
      rewardDoubleCard: json['rewardDoubleCard'] as bool? ?? false,
    );
  }
}
/// lib/ui/widgets/offline_report_sheet.dart
/// 离线收益报告：从底部滑入，逐项数字累加展示，最后总资产金光闪烁大跳。
library;

import 'package:flutter/material.dart';

import '../../core/format.dart';

class OfflineReportSheet extends StatefulWidget {
  const OfflineReportSheet({super.key, required this.seconds, required this.amount, required this.totalAssets, required this.themeUpColor, required this.themeGoldColor});
  final int seconds;
  final double amount;
  final double totalAssets;
  final Color themeUpColor;
  final Color themeGoldColor;

  static Future<void> show({
    required BuildContext context,
    required int seconds,
    required double amount,
    required double totalAssets,
    required Color themeUpColor,
    required Color themeGoldColor,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext c) => OfflineReportSheet(
        seconds: seconds,
        amount: amount,
        totalAssets: totalAssets,
        themeUpColor: themeUpColor,
        themeGoldColor: themeGoldColor,
      ),
    );
  }

  @override
  State<OfflineReportSheet> createState() => _OfflineReportSheetState();
}

class _OfflineReportSheetState extends State<OfflineReportSheet>
    with TickerProviderStateMixin {
  late final AnimationController _ctl;
  late final Animation<double> _itemsAnim;
  late final Animation<double> _totalAnim;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _itemsAnim = CurvedAnimation(parent: _ctl, curve: const Interval(0.0, 0.7, curve: Curves.easeOut));
    _totalAnim = CurvedAnimation(parent: _ctl, curve: const Interval(0.55, 1.0, curve: Curves.easeOutBack));
    _ctl.forward();
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctl,
      builder: (BuildContext context, Widget? _) {
        final double p = _itemsAnim.value;
        final double t = _totalAnim.value;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '欢迎回来，经理',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              _Item(
                label: '离线时长',
                value: _durationString(widget.seconds),
                progress: p,
              ),
              _Item(
                label: '离线分红',
                value: formatMoney(widget.amount),
                valueColor: widget.themeGoldColor,
                progress: p,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                decoration: BoxDecoration(
                  color: widget.themeGoldColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: widget.themeGoldColor, width: 1.2),
                ),
                child: Column(
                  children: <Widget>[
                    Text(
                      '当前总资产',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    Transform.scale(
                      scale: 0.8 + 0.2 * t,
                      child: Text(
                        formatMoney(widget.totalAssets),
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                          color: widget.themeGoldColor,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          shadows: <Shadow>[
                            Shadow(
                              color: widget.themeGoldColor.withOpacity(0.55),
                              blurRadius: 18 * t,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('继续经营'),
              ),
              SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
            ],
          ),
        );
      },
    );
  }

  String _durationString(int seconds) {
    if (seconds < 60) return '${seconds}秒';
    if (seconds < 3600) return '${(seconds / 60).floor()} 分 ${seconds % 60} 秒';
    final int h = seconds ~/ 3600;
    final int m = (seconds % 3600) ~/ 60;
    return '$h 小时 $m 分';
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.label, required this.value, required this.progress, this.valueColor});
  final String label;
  final String value;
  final double progress;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final double shown = progress.clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Opacity(
            opacity: shown,
            child: Transform.translate(
              offset: Offset(0, (1 - shown) * 8),
              child: Text(
                value,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                  fontWeight: FontWeight.w700,
                  color: valueColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
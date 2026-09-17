/// lib/ui/widgets/event_banner.dart
/// 顶部滑入的事件 BREAKING 横幅。
library;

import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../models/market_event.dart';

class EventBanner extends StatefulWidget {
  const EventBanner({
    super.key,
    required this.event,
    required this.visible,
    required this.upColor,
    required this.downColor,
  });
  final MarketEvent event;
  final bool visible;
  final Color upColor;
  final Color downColor;

  @override
  State<EventBanner> createState() => _EventBannerState();
}

class _EventBannerState extends State<EventBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    if (widget.visible) _ctl.forward();
  }

  @override
  void didUpdateWidget(covariant EventBanner old) {
    super.didUpdateWidget(old);
    if (widget.visible && !old.visible) {
      _ctl.forward(from: 0);
    } else if (!widget.visible && old.visible) {
      _ctl.reverse();
    }
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool positive = widget.event.isPositive;
    final Color c = positive ? widget.upColor : widget.downColor;
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, -1),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: _ctl, curve: Curves.easeOutCubic)),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: c.withOpacity(0.18),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: c, width: 1.4),
        ),
        child: Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: c,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                positive ? 'BREAKING ▲' : 'BREAKING ▼',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    widget.event.headline,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.event.name} · ${formatPercent(widget.event.effect)} · ${(widget.event.duration.inSeconds / 60).toStringAsFixed(1)} 分钟',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
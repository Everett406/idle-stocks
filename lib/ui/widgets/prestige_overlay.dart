/// lib/ui/widgets/prestige_overlay.dart
/// 转生：全屏光效遮罩，总资产数字倒流归零，经理徽章金光旋转出现。
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/format.dart';

class PrestigeOverlay extends StatefulWidget {
  const PrestigeOverlay({super.key, required this.beforeAssets, required this.newLevel, required this.accentColor, required this.onDismiss});

  final double beforeAssets;
  final int newLevel;
  final Color accentColor;
  final VoidCallback onDismiss;

  static OverlayEntry? _entry;

  static void show({required BuildContext context, required double beforeAssets, required int newLevel, required Color accentColor, required VoidCallback onDismiss}) {
    _entry?.remove();
    final OverlayEntry entry = OverlayEntry(
      builder: (BuildContext c) => PrestigeOverlay(
        beforeAssets: beforeAssets,
        newLevel: newLevel,
        accentColor: accentColor,
        onDismiss: onDismiss,
      ),
    );
    _entry = entry;
    Overlay.of(context).insert(entry);
  }

  @override
  State<PrestigeOverlay> createState() => _PrestigeOverlayState();
}

class _PrestigeOverlayState extends State<PrestigeOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..addListener(() {
      if (mounted) setState(() {});
    });
    _ctl.forward();
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  void _dismiss() {
    _ctl.reverse().then((_) {
      if (mounted) {
        PrestigeOverlay._entry?.remove();
        PrestigeOverlay._entry = null;
        widget.onDismiss();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final double t = _ctl.value;
    // 倒流归零 (0 -> 0.6)，徽章 (0.5 -> 1.0)
    final double reverse = (1.0 - t / 0.6).clamp(0.0, 1.0);
    final double shown = (reverse * widget.beforeAssets);
    final double badge = ((t - 0.5) / 0.5).clamp(0.0, 1.0);
    final double spin = badge * 2 * math.pi;
    return GestureDetector(
      onTap: _dismiss,
      child: Container(
        color: widget.accentColor.withOpacity(0.18 + 0.6 * t),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (t < 0.6)
                Text(
                  formatMoney(shown),
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withOpacity(1 - t / 0.6),
                  ),
                ),
              if (badge > 0)
                Transform.rotate(
                  angle: spin,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: <Color>[
                          widget.accentColor,
                          widget.accentColor.withOpacity(0.1),
                        ],
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: widget.accentColor.withOpacity(0.6 * badge),
                          blurRadius: 30 * badge,
                          spreadRadius: 8 * badge,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(Icons.workspace_premium,
                              size: 56, color: Colors.black.withOpacity(0.7)),
                          Text(
                            '经理 Lv.${widget.newLevel}',
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
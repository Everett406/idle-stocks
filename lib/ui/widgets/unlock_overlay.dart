/// lib/ui/widgets/unlock_overlay.dart
/// 解锁新股票：Overlay 全屏"锁链破碎" + 闪光。
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/stock.dart';

class UnlockOverlay extends StatefulWidget {
  const UnlockOverlay({super.key, required this.seed, required this.accentColor, required this.onDismiss});

  final StockSeed seed;
  final Color accentColor;
  final VoidCallback onDismiss;

  static OverlayEntry? _entry;

  static void show({required BuildContext context, required StockSeed seed, required Color accentColor, required VoidCallback onDismiss}) {
    _entry?.remove();
    final OverlayEntry entry = OverlayEntry(
      builder: (BuildContext c) => UnlockOverlay(seed: seed, accentColor: accentColor, onDismiss: onDismiss),
    );
    _entry = entry;
    Overlay.of(context).insert(entry);
  }

  @override
  State<UnlockOverlay> createState() => _UnlockOverlayState();
}

class _UnlockOverlayState extends State<UnlockOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
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
        UnlockOverlay._entry?.remove();
        UnlockOverlay._entry = null;
        widget.onDismiss();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final double t = _ctl.value;
    final double fade = t < 0.7 ? 1.0 : (1.0 - (t - 0.7) / 0.3).clamp(0.0, 1.0);
    return GestureDetector(
      onTap: _dismiss,
      child: Container(
        color: Colors.black.withOpacity(0.55 * fade),
        child: Center(
          child: CustomPaint(
            painter: _ChainBreakPainter(
              progress: t,
              accent: widget.accentColor,
              seed: widget.seed,
            ),
            child: SizedBox(
              width: 280,
              height: 280,
              child: Center(
                child: Opacity(
                  opacity: t < 0.7 ? t / 0.7 : (1 - (t - 0.7) / 0.3).clamp(0.0, 1.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(Icons.lock_open, color: widget.accentColor, size: 56),
                      const SizedBox(height: 12),
                      Text(
                        '解锁！',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      Text(widget.seed.name, style: Theme.of(context).textTheme.titleMedium),
                      Text(widget.seed.code, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChainBreakPainter extends CustomPainter {
  _ChainBreakPainter({required this.progress, required this.accent, required this.seed});
  final double progress;
  final Color accent;
  final StockSeed seed;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = Offset(size.width / 2, size.height / 2);
    final double radius = math.min(size.width, size.height) / 2 - 8;
    final Paint ringPaint = Paint()
      ..color = accent.withOpacity(0.4 + 0.6 * progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    // 闪光圈
    canvas.drawCircle(c, radius + (1 - progress) * 16, ringPaint);
    final Paint fillPaint = Paint()
      ..color = accent.withOpacity(0.18 * (1 - progress));
    canvas.drawCircle(c, radius - 8, fillPaint);
    // 链节碎裂粒子
    final math.Random rng = math.Random(seed.code.hashCode);
    final Paint dot = Paint()..color = accent;
    final int n = 18;
    for (int i = 0; i < n; i++) {
      final double a = (i / n) * 2 * math.pi + rng.nextDouble() * 0.3;
      final double r = radius * (0.4 + 0.6 * progress);
      final double dx = c.dx + math.cos(a) * r;
      final double dy = c.dy + math.sin(a) * r;
      dot.color = accent.withOpacity((1 - progress).clamp(0.0, 1.0));
      canvas.drawCircle(Offset(dx, dy), 2 + progress * 2, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _ChainBreakPainter old) => old.progress != progress;
}
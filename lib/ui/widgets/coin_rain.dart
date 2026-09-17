/// lib/ui/widgets/coin_rain.dart
/// 分红结算时的金币粒子 + "+¥xx" 飘字上浮渐隐。
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/format.dart';

class CoinRain extends StatefulWidget {
  const CoinRain({
    super.key,
    required this.amount,
    required this.upColor,
    required this.accentColor,
    this.height = 220,
  });

  final double amount;
  final Color upColor;
  final Color accentColor;
  final double height;

  @override
  State<CoinRain> createState() => _CoinRainState();
}

class _CoinRainState extends State<CoinRain>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;
  final List<_Particle> _particles = <_Particle>[];
  final math.Random _rng = math.Random();
  int _seq = 0;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..addListener(_onTick);
  }

  @override
  void didUpdateWidget(covariant CoinRain old) {
    super.didUpdateWidget(old);
    if ((widget.amount - old.amount).abs() > 0.01 && widget.amount > 0) {
      _emit(widget.amount);
      _ctl.forward(from: 0);
    }
  }

  void _emit(double amount) {
    final int n = math.min(40, 12 + (amount ~/ 50));
    for (int i = 0; i < n; i++) {
      _particles.add(_Particle(
        id: _seq++,
        x: _rng.nextDouble(),
        startY: _rng.nextDouble() * 0.3,
        endY: 1.0 + _rng.nextDouble() * 0.4,
        size: 6 + _rng.nextDouble() * 8,
        spin: (0.4 + _rng.nextDouble() * 1.2) * (_rng.nextBool() ? 1 : -1),
        delay: _rng.nextDouble() * 0.2,
        color: _rng.nextBool() ? widget.accentColor : widget.upColor,
      ));
    }
    // 飘字
    _floats.add(_Floating(
      id: _seq++,
      text: '+${formatMoney(amount)}',
      x: 0.5 + (_rng.nextDouble() - 0.5) * 0.3,
      color: widget.accentColor,
    ));
  }

  final List<_Floating> _floats = <_Floating>[];

  void _onTick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: CustomPaint(
          painter: _RainPainter(
            particles: _particles,
            floats: _floats,
            progress: _ctl.value,
          ),
        ),
      ),
    );
  }
}

class _Particle {
  _Particle({
    required this.id,
    required this.x,
    required this.startY,
    required this.endY,
    required this.size,
    required this.spin,
    required this.delay,
    required this.color,
  });
  final int id;
  final double x;
  final double startY;
  final double endY;
  final double size;
  final double spin;
  final double delay;
  final Color color;
}

class _Floating {
  _Floating({
    required this.id,
    required this.text,
    required this.x,
    required this.color,
  });
  final int id;
  final String text;
  final double x;
  final Color color;
}

class _RainPainter extends CustomPainter {
  _RainPainter({
    required this.particles,
    required this.floats,
    required this.progress,
  });
  final List<_Particle> particles;
  final List<_Floating> floats;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    for (final _Particle p in particles) {
      final double t = ((progress - p.delay) / (1.0 - p.delay)).clamp(0.0, 1.0);
      if (t <= 0) continue;
      final double y = p.startY + (p.endY - p.startY) * t;
      final Offset c = Offset(p.x * size.width, y * size.height);
      final double rot = p.spin * t * 6.28;
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(rot);
      final Paint pnt = Paint()..color = p.color;
      canvas.drawCircle(Offset.zero, p.size / 2, pnt);
      final Paint ring = Paint()
        ..color = Colors.white.withOpacity(0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawCircle(Offset.zero, p.size / 2 - 1, ring);
      canvas.restore();
    }
    for (final _Floating f in floats) {
      final double t = (progress / 1.0).clamp(0.0, 1.0);
      final double y = 0.55 - 0.4 * t;
      final double op = (1.0 - t).clamp(0.0, 1.0);
      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: f.text,
          style: TextStyle(
            color: f.color.withOpacity(op),
            fontSize: 22,
            fontWeight: FontWeight.w800,
            fontFamily: 'monospace',
            fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(f.x * size.width - tp.width / 2, y * size.height));
    }
  }

  @override
  bool shouldRepaint(covariant _RainPainter old) =>
      old.progress != progress ||
      old.particles.length != particles.length ||
      old.floats.length != floats.length;
}
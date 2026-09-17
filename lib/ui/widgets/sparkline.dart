/// lib/ui/widgets/sparkline.dart
/// 迷你走势图 CustomPainter：复用一份 Canvas，根据 ratio 着色。
library;

import 'package:flutter/material.dart';

import '../app.dart';

class Sparkline extends StatelessWidget {
  const Sparkline({
    super.key,
    required this.values,
    required this.height,
    this.lineWidth = 1.6,
    this.fill = true,
  });

  final List<double> values;
  final double height;
  final double lineWidth;
  final bool fill;

  @override
  Widget build(BuildContext context) {
    if (values.length < 2) {
      return SizedBox(height: height);
    }
    final MarketColors m = context.market;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _SparkPainter(
          values: values,
          lineColor: m.up,
          fillTopColor: m.up.withOpacity(0.22),
          fillBottomColor: m.up.withOpacity(0.0),
          lineWidth: lineWidth,
          fill: fill,
        ),
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter({
    required this.values,
    required this.lineColor,
    required this.fillTopColor,
    required this.fillBottomColor,
    required this.lineWidth,
    required this.fill,
  });

  final List<double> values;
  final Color lineColor;
  final Color fillTopColor;
  final Color fillBottomColor;
  final double lineWidth;
  final bool fill;

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
    final double pad = lineWidth;
    final double w = size.width - pad * 2;
    final double h = size.height - pad * 2;
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
    if (fill) {
      final Path f = Path.from(line)
        ..lineTo(pad + w, pad + h)
        ..lineTo(pad, pad + h)
        ..close();
      final Paint fp = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[fillTopColor, fillBottomColor],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawPath(f, fp);
    }
    final Paint p = Paint()
      ..color = lineColor
      ..strokeWidth = lineWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(line, p);
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) {
    if (old.values.length != values.length) return true;
    for (int i = 0; i < values.length; i++) {
      if ((old.values[i] - values[i]).abs() > 1e-4) return true;
    }
    return old.lineColor != lineColor ||
        old.fill != fill ||
        old.lineWidth != lineWidth;
  }
}
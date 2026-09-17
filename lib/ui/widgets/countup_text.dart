/// lib/ui/widgets/countup_text.dart
/// 数字滚动：从旧值平滑过渡到新值；带红涨绿跌着色。
library;

import 'package:flutter/material.dart';

import '../../core/format.dart';

/// 显示 double / int 的滚动文本。
/// - value：当前目标值
/// - duration：滚动时长
/// - upColor / downColor / neutralColor：颜色三态
/// - prevValue：可选；缺省时每次新值变化都从上一帧目标值过渡
class CountUpText extends StatefulWidget {
  const CountUpText({
    super.key,
    required this.value,
    this.duration = const Duration(milliseconds: 400),
    this.upColor = const Color(0xFFF04A4A),
    this.downColor = const Color(0xFF2FBF8F),
    this.neutralColor = const Color(0xFFE6E9F0),
    this.style,
    this.formatter = formatMoney,
    this.fractionDigits = 2,
  });

  final double value;
  final Duration duration;
  final Color upColor;
  final Color downColor;
  final Color neutralColor;
  final TextStyle? style;
  final String Function(num) formatter;
  final int fractionDigits;

  @override
  State<CountUpText> createState() => _CountUpTextState();
}

class _CountUpTextState extends State<CountUpText>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctl;
  late double _from;
  late double _to;

  @override
  void initState() {
    super.initState();
    _from = widget.value;
    _to = widget.value;
    _ctl = AnimationController(vsync: this, duration: widget.duration)
      ..addListener(() {
        if (mounted) setState(() {});
      });
  }

  @override
  void didUpdateWidget(covariant CountUpText old) {
    super.didUpdateWidget(old);
    if ((old.value - widget.value).abs() > 0.005) {
      _from = _current();
      _to = widget.value;
      _ctl
        ..stop()
        ..duration = widget.duration
        ..forward(from: 0);
    }
  }

  double _current() {
    final double t = _ctl.value;
    return _from + (_to - _from) * t;
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double v = _current();
    final double delta = _to - _from;
    final Color c = delta > 0.0001
        ? widget.upColor
        : (delta < -0.0001 ? widget.downColor : widget.neutralColor);
    final TextStyle base = widget.style ??
            Theme.of(context).textTheme.bodyLarge ??
            const TextStyle();
    return Text(
      widget.formatter(v),
      style: monoStyle(
        color: c,
        fontSize: base.fontSize,
        fontWeight: base.fontWeight,
        base: base,
      ),
    );
  }
}
/// lib/models/market_event.dart
/// 一次性事件 (engine 内部生成)，不影响存档；UI 用其展示横幅。
library;

class MarketEvent {
  MarketEvent({
    required this.code,
    required this.name,
    required this.headline,
    required this.effect,
    required this.startMs,
    required this.endMs,
  });

  final String code;
  final String name;
  final String headline;
  final double effect; // ±0.08 ~ ±0.18
  final int startMs;
  final int endMs;

  bool get isPositive => effect > 0;
  Duration get duration => Duration(milliseconds: endMs - startMs);
}
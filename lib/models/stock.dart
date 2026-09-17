/// lib/models/stock.dart
/// 股票数据：常量定义 (StockSeed) + 运行时可变状态 (LiveStock)。
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';

@immutable
class StockSeed {
  const StockSeed({
    required this.code,
    required this.name,
    required this.sector,
    required this.initialPrice,
    required this.dailyDrift,
    required this.dailyVol,
    required this.dailyDivRate,
    required this.unlockAt,
  });

  final String code;
  final String name;
  final String sector;
  final double initialPrice;
  final double dailyDrift;
  final double dailyVol;
  final double dailyDivRate;
  final double unlockAt;
}

/// 单只股票运行时状态 (内存中可变)。
class LiveStock {
  LiveStock({
    required this.code,
    required this.initialPrice,
    required this.price,
    required this.history,
    required this.eventBoost,
    required this.eventUntilMs,
  });

  final String code;
  final double initialPrice;
  double price;
  List<double> history; // 旧 → 新
  double eventBoost; // 1.0 为无事件；>1 利好；<1 利空
  int eventUntilMs;

  /// 价格日变化率（基于 initialPrice）。
  double get dayChangeRatio =>
      initialPrice > 0 ? (price - initialPrice) / initialPrice : 0.0;

  /// 追加一个价格点；保留最新 maxLen 个。
  void pushPrice(double p, {int maxLen = 120}) {
    history.add(p);
    if (history.length > maxLen) {
      history = history.sublist(history.length - maxLen);
    }
  }

  Map<String, dynamic> toJson({int historyTail = 96}) {
    final List<double> tail = history.length <= historyTail
        ? history
        : history.sublist(history.length - historyTail);
    return <String, dynamic>{
      'price': price,
      'history': tail,
      'eventBoost': eventBoost,
      'eventUntilMs': eventUntilMs,
    };
  }

  static LiveStock fromJson(String code, double initialPrice, Map<String, dynamic> json) {
    final dynamic rawHist = json['history'];
    final List<double> h = <double>[];
    if (rawHist is List) {
      for (final dynamic v in rawHist) {
        if (v is num) h.add(v.toDouble());
      }
    }
    return LiveStock(
      code: code,
      initialPrice: initialPrice,
      price: (json['price'] as num).toDouble(),
      history: h,
      eventBoost: (json['eventBoost'] as num?)?.toDouble() ?? 1.0,
      eventUntilMs: (json['eventUntilMs'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  String toString() => jsonEncode(toJson());
}
/// lib/core/format.dart
/// 金额、百分比、价格格式化；等宽数字 textStyle。
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final NumberFormat _moneyFmt = NumberFormat.decimalPattern('zh_CN')
  ..minimumFractionDigits = 2
  ..maximumFractionDigits = 2;

final NumberFormat _percentFmt = NumberFormat.decimalPattern('zh_CN')
  ..minimumFractionDigits = 2
  ..maximumFractionDigits = 2;

final NumberFormat _qtyFmt = NumberFormat.decimalPattern('zh_CN');

String formatMoney(num v) {
  final double d = v.toDouble();
  if (d.abs() >= 1e8) {
    return '¥${(d / 1e8).toStringAsFixed(2)}亿';
  }
  if (d.abs() >= 1e4) {
    return '¥${(d / 1e4).toStringAsFixed(2)}万';
  }
  return '¥${_moneyFmt.format(d)}';
}

String formatMoneyExact(num v) {
  return '¥${_moneyFmt.format(v.toDouble())}';
}

String formatPrice(num v) {
  return '¥${_moneyFmt.format(v.toDouble())}';
}

String formatPercent(num ratio) {
  // ratio: 0.0123 表示 +1.23%
  final double r = ratio.toDouble() * 100;
  final String sign = r >= 0 ? '+' : '';
  return '$sign${_percentFmt.format(r)}%';
}

String formatPercentSigned(num ratio, {bool withSign = true}) {
  final double r = ratio.toDouble() * 100;
  if (withSign) {
    final String s = r >= 0 ? '+' : '';
    return '$s${_percentFmt.format(r)}%';
  }
  return '${_percentFmt.format(r)}%';
}

String formatQty(num v) => _qtyFmt.format(v.toDouble());

String formatDuration(Duration d) {
  if (d.inSeconds < 60) return '${d.inSeconds}秒';
  if (d.inMinutes < 60) return '${d.inMinutes}分${d.inSeconds % 60}秒';
  if (d.inHours < 24) return '${d.inHours}小时${d.inMinutes % 60}分';
  return '${d.inDays}天${d.inHours % 24}小时';
}

/// 红涨绿跌（中国习惯）的等宽数字样式
TextStyle moneyStyle({
  required TextStyle? base,
  required Color upColor,
  required Color downColor,
  required Color neutralColor,
  required bool isUp,
  required bool isDown,
  double? fontSize,
  FontWeight? fontWeight,
}) {
  final TextStyle b = base ?? const TextStyle();
  final Color color = isUp
      ? upColor
      : (isDown ? downColor : neutralColor);
  return b.copyWith(
    fontFamily: 'monospace',
    fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    color: color,
    fontSize: fontSize,
    fontWeight: fontWeight,
  );
}

/// 中性数字样式（用于价格标签本身，按方向染色）
TextStyle priceStyle({
  required Color upColor,
  required Color downColor,
  required Color neutralColor,
  required double ratio, // 当前相对基准的涨跌幅
  double? fontSize,
  FontWeight? fontWeight,
}) {
  final Color c = ratio > 0.0001
      ? upColor
      : (ratio < -0.0001 ? downColor : neutralColor);
  return TextStyle(
    fontFamily: 'monospace',
    fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    color: c,
    fontSize: fontSize,
    fontWeight: fontWeight,
  );
}

/// 通用等宽数字样式
TextStyle monoStyle({
  Color? color,
  double? fontSize,
  FontWeight? fontWeight,
  TextStyle? base,
}) {
  return (base ?? const TextStyle()).copyWith(
    fontFamily: 'monospace',
    fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    color: color,
    fontSize: fontSize,
    fontWeight: fontWeight,
  );
}
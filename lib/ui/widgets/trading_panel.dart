/// lib/ui/widgets/trading_panel.dart
/// 股票详情页买卖面板：股数输入 + 快捷 + 红买绿卖大按钮。
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/format.dart';
import '../../models/stock.dart';
import '../app.dart';

class TradingPanel extends StatefulWidget {
  const TradingPanel({
    super.key,
    required this.seed,
    required this.price,
    required this.cash,
    required this.holdingShares,
    required this.commissionRate,
    required this.onBuy,
    required this.onSell,
    required this.upColor,
    required this.downColor,
  });

  final StockSeed seed;
  final double price;
  final double cash;
  final int holdingShares;
  final double commissionRate;
  final bool Function(int shares) onBuy;
  final bool Function(int shares) onSell;
  final Color upColor;
  final Color downColor;

  @override
  State<TradingPanel> createState() => _TradingPanelState();
}

class _TradingPanelState extends State<TradingPanel> {
  final TextEditingController _ctl = TextEditingController(text: '10');
  int get _shares => int.tryParse(_ctl.text) ?? 0;

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  void _setQty(int q) {
    _ctl.text = q.toString();
    _ctl.selection = TextSelection.collapsed(offset: _ctl.text.length);
  }

  int? _maxBuyQty() {
    final double fee = widget.commissionRate;
    final double p = widget.price;
    if (p <= 0) return 0;
    final double maxCash = widget.cash / (p * (1 + fee));
    return maxCash.floor();
  }

  @override
  Widget build(BuildContext context) {
    final int sh = _shares;
    final double gross = sh * widget.price;
    final double fee = widget.commissionRate;
    final double cost = gross * (1 + fee);
    final double proceeds = gross * (1 - fee);
    final int? maxBuy = _maxBuyQty();
    final MarketColors m = context.market;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _ctl,
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                    labelText: '股数',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              Wrap(
                spacing: 6,
                children: <Widget>[
                  _Chip(label: '1', onTap: () => _setQty(1)),
                  _Chip(label: '10', onTap: () => _setQty(10)),
                  _Chip(label: '100', onTap: () => _setQty(100)),
                  _Chip(
                    label: '全部',
                    onTap: () {
                      if (maxBuy != null && maxBuy > 0) _setQty(maxBuy);
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              _kv(context, '参考价', formatPrice(widget.price)),
              _kv(context, '手续费', '${(fee * 100).toStringAsFixed(2)}%'),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              _kv(context, '预估金额', formatMoney(gross)),
              _kv(context, sh >= 0 ? '买入花费' : '', formatMoney(cost)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: widget.upColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: sh <= 0
                      ? null
                      : () {
                          if (widget.onBuy(sh)) {
                            HapticFeedback.selectionClick();
                          }
                        },
                  child: Text('买入 $sh 股', style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: widget.downColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: sh <= 0 || sh > widget.holdingShares
                      ? null
                      : () {
                          if (widget.onSell(sh)) {
                            HapticFeedback.selectionClick();
                          }
                        },
                  child: Text('卖出 $sh 股', style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '现金 ${formatMoney(widget.cash)} · 持仓 $sh/${widget.holdingShares} 股 · 卖出可得 ${formatMoney(proceeds)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: m.neutral),
          ),
        ],
      ),
    );
  }

  Widget _kv(BuildContext context, String k, String v) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(k, style: Theme.of(context).textTheme.bodySmall),
        Text(
          v,
          style: monoStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color,
            fontWeight: FontWeight.w700,
            base: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
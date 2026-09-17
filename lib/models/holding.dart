/// lib/models/holding.dart
/// 单只股票的持仓：股数 + 平均成本。
library;

class Holding {
  Holding({required this.shares, required this.avgCost});
  int shares;
  double avgCost;

  double marketValue(double price) => shares * price;

  double unrealizedPnL(double price) {
    if (shares <= 0) return 0.0;
    return shares * (price - avgCost);
  }

  double unrealizedPnLRatio(double price) {
    if (shares <= 0 || avgCost <= 0) return 0.0;
    return (price - avgCost) / avgCost;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'shares': shares,
        'avgCost': avgCost,
      };

  static Holding fromJson(Map<String, dynamic> json) => Holding(
        shares: (json['shares'] as num).toInt(),
        avgCost: (json['avgCost'] as num).toDouble(),
      );

  static Holding empty() => Holding(shares: 0, avgCost: 0);
}
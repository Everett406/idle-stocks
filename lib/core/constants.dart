/// lib/core/constants.dart
/// 游戏全部数值常量、颜色、模板——集中可调。
library;

import 'package:flutter/material.dart';

// ───────────────────────── 时间 / 节奏 ─────────────────────────
const Duration kTickInterval = Duration(seconds: 1);
const Duration kDividendInterval = Duration(seconds: 5);
const Duration kSaveInterval = Duration(seconds: 10);
const Duration kBotInterval = Duration(seconds: 30);
const Duration kOfflineCap = Duration(hours: 8);
const Duration kOfflineThreshold = Duration(seconds: 60);

// 事件触发窗口（秒）
const int kEventMinSeconds = 90;
const int kEventMaxSeconds = 240;

// 事件时长窗口（秒）
const int kEventDurationMin = 180; // 3 分钟
const int kEventDurationMax = 480; // 8 分钟

// 历史曲线保留长度
const int kCardHistoryLen = 600; // 单只票最大历史点数 (卡片只用后 120)
const int kSaveHistoryLen = 96;
const Duration kHistoryFillStep = Duration(minutes: 5);

// 夜盘激战 (本地时间)
const int kNightStartHour = 21;
const int kNightEndHour = 22;

// ───────────────────────── 颜色 (双主题) ─────────────────────────
class AppColors {
  // Dark — 金融终端
  static const Color darkScaffold = Color(0xFF0B1220);
  static const Color darkCard = Color(0xFF131C2E);
  static const Color darkCardElevated = Color(0xFF1B2540);
  static const Color darkDivider = Color(0x33FFFFFF); // 20% white
  static const Color darkGold = Color(0xFFD4AF37);
  static const Color darkTeal = Color(0xFF2DD4BF);
  static const Color darkUp = Color(0xFFF04A4A); // 红涨
  static const Color darkDown = Color(0xFF2FBF8F); // 绿跌
  static const Color darkTextPrimary = Color(0xFFE6E9F0);
  static const Color darkTextSecondary = Color(0xFF9AA4B8);

  // Light — 干净白底炒股 App
  static const Color lightScaffold = Color(0xFFF7F8FA);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardElevated = Color(0xFFF2F4F8);
  static const Color lightDivider = Color(0x1F000000);
  static const Color lightPrimary = Color(0xFFD93026); // 证券红
  static const Color lightSecondary = Color(0xFF0B7A55);
  static const Color lightUp = Color(0xFFD93026);
  static const Color lightDown = Color(0xFF0B7A55);
  static const Color lightTextPrimary = Color(0xFF111418);
  static const Color lightTextSecondary = Color(0xFF5F6770);
}

// ───────────────────────── 股票参数表 ─────────────────────────
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
  final double dailyDrift; // 例 0.0015 = 0.15%
  final double dailyVol; // 例 0.012 = 1.2%
  final double dailyDivRate; // 例 0.0025 = 0.25%/天
  final double unlockAt; // 总资产阈值
}

const List<StockSeed> kStockSeeds = <StockSeed>[
  StockSeed(code: 'XCBK', name: '星辰银行', sector: '金融', initialPrice: 12.50, dailyDrift: 0.0015, dailyVol: 0.012, dailyDivRate: 0.0025, unlockAt: 0),
  StockSeed(code: 'NSDL', name: '南山电力', sector: '公用', initialPrice: 8.20,  dailyDrift: 0.0010, dailyVol: 0.009, dailyDivRate: 0.0030, unlockAt: 0),
  StockSeed(code: 'BYSP', name: '白鹿食品', sector: '消费', initialPrice: 22.00, dailyDrift: 0.0020, dailyVol: 0.015, dailyDivRate: 0.0020, unlockAt: 50000),
  StockSeed(code: 'QYHK', name: '青云航空', sector: '军工', initialPrice: 35.00, dailyDrift: 0.0025, dailyVol: 0.022, dailyDivRate: 0.0012, unlockAt: 120000),
  StockSeed(code: 'TMZG', name: '铁马重工', sector: '制造', initialPrice: 58.00, dailyDrift: 0.0030, dailyVol: 0.024, dailyDivRate: 0.0012, unlockAt: 250000),
  StockSeed(code: 'LWDC', name: '蓝湾地产', sector: '地产', initialPrice: 16.00, dailyDrift: -0.0010, dailyVol: 0.020, dailyDivRate: 0.0050, unlockAt: 250000),
  StockSeed(code: 'WLKJ', name: '未来科技', sector: '科技', initialPrice: 120.00, dailyDrift: 0.0050, dailyVol: 0.032, dailyDivRate: 0.0008, unlockAt: 500000),
  StockSeed(code: 'HHNY', name: '浩瀚能源', sector: '能源', initialPrice: 75.00, dailyDrift: 0.0035, dailyVol: 0.026, dailyDivRate: 0.0015, unlockAt: 800000),
  StockSeed(code: 'LXSW', name: '灵犀生物', sector: '医药', initialPrice: 150.00, dailyDrift: 0.0045, dailyVol: 0.030, dailyDivRate: 0.0010, unlockAt: 1200000),
  StockSeed(code: 'TMGX', name: '天马微芯', sector: '半导体', initialPrice: 300.00, dailyDrift: 0.0060, dailyVol: 0.038, dailyDivRate: 0.0006, unlockAt: 2000000),
];

// ───────────────────────── 新闻标题模板 ─────────────────────────
const List<String> kPositiveHeadlines = <String>[
  '{name}发布革命性新品，市场沸腾',
  '{name}斩获超级大单，业绩可期',
  '{name}宣布大额回购，股价应声大涨',
  '{name}核心技术取得重大突破',
  '政策利好叠加，{name}估值有望重估',
  '机构大举买入{name}，持仓创新高',
  '{name}海外扩张提速，新市场打开',
  '{name}季报超预期，现金流大幅改善',
  '{name}获国家级奖项，品牌价值飙升',
  '{name}签订战略合作协议，未来想象空间打开',
];

const List<String> kNegativeHeadlines = <String>[
  '{name}陷入财务造假传闻，股价承压',
  '{name}核心产品遭监管调查',
  '{name}高管大幅减持，市场信心动摇',
  '{name}主要客户流失，业绩预警',
  '{name}供应链中断，产能受限',
  '{name}海外业务遇阻，损失或扩大',
  '{name}诉讼缠身，或面临巨额赔偿',
  '行业政策转向，{name}估值承压',
  '{name}技术路线被质疑，市场份额下滑',
  '{name}季报大幅低于预期，机构下调评级',
];

// ───────────────────────── 升级价格公式 ─────────────────────────
// 实际公式实现见 lib/models/upgrade.dart，避免重复实现导致分叉。
// 等级上限也见 upgrade.dart。

// ───────────────────────── 初始 / 阈值 ─────────────────────────

// ───────────────────────── 初始 / 阈值 ─────────────────────────
const double kStartingCash = 100000.0;
const double kPrestigeBaseThreshold = 500000.0;
const int kSaveSchemaVersion = 1;
const String kSaveKey = 'save_v1';

// ───────────────────────── 任务模板 ─────────────────────────
enum TaskKind {
  tradeCount,
  pnl,
  dividend,
  holdRising,
}

class TaskTemplate {
  const TaskTemplate({
    required this.id,
    required this.label,
    required this.target,
    required this.kind,
  });
  final String id;
  final String label;
  final int target;
  final TaskKind kind;
}

const List<TaskTemplate> kTaskTemplates = <TaskTemplate>[
  TaskTemplate(id: 'trade_2',   label: '完成 {n} 笔交易', target: 2,  kind: TaskKind.tradeCount),
  TaskTemplate(id: 'trade_3',   label: '完成 {n} 笔交易', target: 3,  kind: TaskKind.tradeCount),
  TaskTemplate(id: 'pnl_3000',  label: '今日盈利 ≥ ¥{n}', target: 3000, kind: TaskKind.pnl),
  TaskTemplate(id: 'pnl_8000',  label: '今日盈利 ≥ ¥{n}', target: 8000, kind: TaskKind.pnl),
  TaskTemplate(id: 'div_500',   label: '累计分红 ≥ ¥{n}',  target: 500,  kind: TaskKind.dividend),
  TaskTemplate(id: 'div_1500',  label: '累计分红 ≥ ¥{n}',  target: 1500, kind: TaskKind.dividend),
  TaskTemplate(id: 'rise_2',    label: '持有今日涨幅 ≥ 2% 的股票', target: 1, kind: TaskKind.holdRising),
  TaskTemplate(id: 'rise_5',    label: '持有今日涨幅 ≥ 5% 的股票', target: 1, kind: TaskKind.holdRising),
];

// ───────────────────────── 工具 ─────────────────────────
int hashDateKey(DateTime d) {
  // 把日期映射到一个稳定种子
  return d.year * 10000 + d.month * 100 + d.day;
}

String dateKeyOf(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year}-${two(d.month)}-${two(d.day)}';
}
/// lib/ui/app.dart
/// 根 MaterialApp + 自定义双主题 + 底部导航三 Tab + 全局事件分发。
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants.dart';
import '../engine/game_state.dart';
import 'growth_page.dart';
import 'market_page.dart';
import 'portfolio_page.dart';
import 'widgets/offline_report_sheet.dart';
import 'widgets/prestige_overlay.dart';
import 'widgets/unlock_overlay.dart';

class StockTycoonApp extends StatelessWidget {
  const StockTycoonApp({
    super.key,
    required this.game,
    required this.offline,
  });
  final GameState game;
  final OfflineBootstrap offline;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: game,
      builder: (BuildContext context, Widget? _) {
        final ThemeMode mode = game.themeMode;
        return MaterialApp(
          title: '股海大亨',
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          home: HomeShell(game: game, offline: offline),
        );
      },
    );
  }
}

class AppTheme {
  static ThemeData dark() {
    const Color upRed = AppColors.darkUp;
    const Color downGreen = AppColors.darkDown;
    const Color gold = AppColors.darkGold;
    final ColorScheme cs = ColorScheme.fromSeed(
      seedColor: gold,
      brightness: Brightness.dark,
      primary: gold,
      secondary: AppColors.darkTeal,
      surface: AppColors.darkCard,
      onSurface: AppColors.darkTextPrimary,
      error: upRed,
    ).copyWith(
      surfaceContainerHighest: AppColors.darkCardElevated,
    );
    const TextTheme baseText = TextTheme();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkScaffold,
      colorScheme: cs,
      cardColor: AppColors.darkCard,
      dividerColor: AppColors.darkDivider,
      canvasColor: AppColors.darkCard,
      textTheme: baseText.apply(
        bodyColor: AppColors.darkTextPrimary,
        displayColor: AppColors.darkTextPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkScaffold,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.darkCard,
        indicatorColor: gold.withOpacity(0.18),
        labelTextStyle: const WidgetStatePropertyAll<TextStyle>(
          TextStyle(
            fontSize: 12,
            color: AppColors.darkTextSecondary,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      extensions: <ThemeExtension<dynamic>>[
        const MarketColors(
          up: upRed,
          down: downGreen,
          neutral: AppColors.darkTextPrimary,
        ),
      ],
    );
  }

  static ThemeData light() {
    const Color upRed = AppColors.lightUp;
    const Color downGreen = AppColors.lightDown;
    const Color primaryRed = AppColors.lightPrimary;
    final ColorScheme cs = ColorScheme.fromSeed(
      seedColor: primaryRed,
      brightness: Brightness.light,
      primary: primaryRed,
      secondary: AppColors.lightSecondary,
      surface: AppColors.lightCard,
      onSurface: AppColors.lightTextPrimary,
      error: upRed,
    ).copyWith(
      surfaceContainerHighest: AppColors.lightCardElevated,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightScaffold,
      colorScheme: cs,
      cardColor: AppColors.lightCard,
      dividerColor: AppColors.lightDivider,
      canvasColor: AppColors.lightCard,
      textTheme: const TextTheme().apply(
        bodyColor: AppColors.lightTextPrimary,
        displayColor: AppColors.lightTextPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightScaffold,
        foregroundColor: AppColors.lightTextPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.lightCard,
        indicatorColor: primaryRed.withOpacity(0.15),
        labelTextStyle: const WidgetStatePropertyAll<TextStyle>(
          TextStyle(fontSize: 12, color: AppColors.lightTextSecondary),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      extensions: <ThemeExtension<dynamic>>[
        const MarketColors(
          up: upRed,
          down: downGreen,
          neutral: AppColors.lightTextPrimary,
        ),
      ],
    );
  }
}

class MarketColors extends ThemeExtension<MarketColors> {
  const MarketColors({
    required this.up,
    required this.down,
    required this.neutral,
  });
  final Color up; // 红涨
  final Color down; // 绿跌
  final Color neutral;

  @override
  MarketColors copyWith({Color? up, Color? down, Color? neutral}) =>
      MarketColors(
        up: up ?? this.up,
        down: down ?? this.down,
        neutral: neutral ?? this.neutral,
      );

  @override
  MarketColors lerp(ThemeExtension<MarketColors>? other, double t) {
    if (other is! MarketColors) return this;
    return MarketColors(
      up: Color.lerp(up, other.up, t) ?? up,
      down: Color.lerp(down, other.down, t) ?? down,
      neutral: Color.lerp(neutral, other.neutral, t) ?? neutral,
    );
  }
}

extension MarketColorsX on BuildContext {
  MarketColors get market =>
      Theme.of(this).extension<MarketColors>() ??
      const MarketColors(
        up: AppColors.darkUp,
        down: AppColors.darkDown,
        neutral: AppColors.darkTextPrimary,
      );
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.game, required this.offline});
  final GameState game;
  final OfflineBootstrap offline;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  int _index = 0;
  bool _offlineShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.game.addListener(_drainGlobalEvents);
    WidgetsBinding.instance.addPostFrameCallback((_) => _showOfflineIfAny());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.game.removeListener(_drainGlobalEvents);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        widget.game.onAppPaused();
        break;
      case AppLifecycleState.resumed:
        widget.game.onAppResumed();
        break;
    }
  }

  void _showOfflineIfAny() {
    if (_offlineShown) return;
    if (widget.offline.amount > 0) {
      _offlineShown = true;
      final MarketColors m = Theme.of(context).extension<MarketColors>()!;
      OfflineReportSheet.show(
        context: context,
        seconds: widget.offline.seconds,
        amount: widget.offline.amount,
        totalAssets: widget.game.totalAssets,
        themeUpColor: m.up,
        themeGoldColor: m.up == AppColors.darkUp
            ? AppColors.darkGold
            : AppColors.lightPrimary,
      );
    } else {
      _offlineShown = true;
    }
  }

  void _drainGlobalEvents() {
    final List<UiEvent> evs = widget.game.drainUiEvents();
    if (evs.isEmpty) return;
    final MarketColors m = Theme.of(context).extension<MarketColors>()!;
    final Color gold = m.up == AppColors.darkUp
        ? AppColors.darkGold
        : AppColors.lightPrimary;
    for (final UiEvent e in evs) {
      if (e is UiUnlockToast) {
        final seed = widget.game.seeds
            .where((s) => s.code == e.code)
            .firstOrNull;
        if (seed == null) continue;
        HapticFeedback.heavyImpact();
        UnlockOverlay.show(
          context: context,
          seed: seed,
          accentColor: gold,
          onDismiss: () {},
        );
      } else if (e is UiPrestigeComplete) {
        HapticFeedback.heavyImpact();
        PrestigeOverlay.show(
          context: context,
          beforeAssets: 0,
          newLevel: e.newLevel,
          accentColor: gold,
          onDismiss: () {},
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      MarketPage(game: widget.game),
      PortfolioPage(game: widget.game),
      GrowthPage(game: widget.game),
    ];
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: _index, children: pages)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (int i) => setState(() => _index = i),
        destinations: const <NavigationDestination>[
          NavigationDestination(icon: Icon(Icons.show_chart), label: '市场'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet), label: '持仓'),
          NavigationDestination(icon: Icon(Icons.trending_up), label: '成长'),
        ],
      ),
    );
  }
}
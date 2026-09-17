/// lib/main.dart
/// 入口：初始化 SoundService + GameState，读档与离线结算，启动 timers。
library;

import 'package:flutter/material.dart';

import 'engine/game_state.dart';
import 'services/sound_service.dart';
import 'ui/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final SoundService sound = SoundService();
  final GameState game = GameState(soundService: sound);
  final OfflineBootstrap offline = await game.bootstrap();
  game.start();
  runApp(StockTycoonApp(game: game, offline: offline));
}
/// lib/services/sound_service.dart
/// 音效播放：每个音效独立 AudioPlayer 实例，避免互相打断。
library;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

enum Sfx { trade, coin, news, unlock, prestige }

class SoundService {
  SoundService();

  bool muted = false;
  final Map<Sfx, AudioPlayer> _players = <Sfx, AudioPlayer>{};

  AudioPlayer _ensure(Sfx sfx) {
    return _players.putIfAbsent(
      sfx,
      () => AudioPlayer(playerId: 'sfx_${sfx.name}'),
    );
  }

  Future<void> play(Sfx sfx) async {
    if (muted) return;
    try {
      final AudioPlayer p = _ensure(sfx);
      await p.stop();
      await p.play(AssetSource('sounds/${sfx.name}.wav'));
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('sound play failed ($sfx): $e\n$st');
      }
    }
  }

  Future<void> dispose() async {
    for (final AudioPlayer p in _players.values) {
      try {
        await p.dispose();
      } catch (_) {/* ignore */}
    }
    _players.clear();
  }
}
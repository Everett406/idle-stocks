/// lib/engine/save_service.dart
/// shared_preferences JSON 读写。格式参见 docs/GDD.md §11。
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';

class SaveService {
  SaveService._();
  static final SaveService instance = SaveService._();

  Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  Future<Map<String, dynamic>?> load() async {
    try {
      final SharedPreferences p = await _prefs();
      final String? raw = p.getString(kSaveKey);
      if (raw == null || raw.isEmpty) return null;
      final dynamic decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return decoded;
    } catch (_) {
      return null;
    }
  }

  Future<void> save(Map<String, dynamic> data) async {
    try {
      final SharedPreferences p = await _prefs();
      final String raw = jsonEncode(data);
      await p.setString(kSaveKey, raw);
    } catch (_) {
      // 存档失败不致命——下次再试。
    }
  }

  Future<void> clear() async {
    try {
      final SharedPreferences p = await _prefs();
      await p.remove(kSaveKey);
    } catch (_) {/* ignore */}
  }
}
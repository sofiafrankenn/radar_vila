import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Chaves do armazenamento local.
class StorageKeys {
  StorageKeys._();

  static const consent = 'consent_given';
  static const consentDate = 'consent_date';
  static const shareAggregated = 'share_aggregated';
  static const themeMode = 'theme_mode';
  static const highContrast = 'high_contrast';
  static const textScale = 'text_scale';
  static const thresholds = 'thresholds';
  static const territoryCache = 'territory_cache_v1';
  static const alertDecisions = 'alert_decisions';
  static const occurrences = 'occurrences';
}

/// Fachada sobre o SharedPreferences (facilita testes e troca de backend).
class LocalStore {
  LocalStore(this._prefs);

  final SharedPreferences _prefs;

  static Future<LocalStore> create() async =>
      LocalStore(await SharedPreferences.getInstance());

  bool? getBool(String key) => _prefs.getBool(key);
  Future<void> setBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  String? getString(String key) => _prefs.getString(key);
  Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  double? getDouble(String key) => _prefs.getDouble(key);
  Future<void> setDouble(String key, double value) async {
    await _prefs.setDouble(key, value);
  }

  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }

  Map<String, dynamic>? getJson(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  List<dynamic>? getJsonList(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is List ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> setJson(String key, Object value) async {
    await _prefs.setString(key, jsonEncode(value));
  }
}

import 'package:material_ui/material_ui.dart';

import 'package:radar_vila/data/local/local_store.dart';
import 'package:radar_vila/models/thresholds.dart';

/// Estado GLOBAL de preferências, consentimento e limiares (persistidos).
class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._store) {
    _load();
  }

  final LocalStore _store;

  bool _consentGiven = false;
  DateTime? _consentDate;
  bool _shareAggregated = false;
  ThemeMode _themeMode = ThemeMode.system;
  bool _highContrast = false;
  double _textScale = 1.0;
  Thresholds _thresholds = Thresholds.defaults;
  bool _simulateOffline = false;

  bool get consentGiven => _consentGiven;
  DateTime? get consentDate => _consentDate;
  bool get shareAggregated => _shareAggregated;
  ThemeMode get themeMode => _themeMode;
  bool get highContrast => _highContrast;
  double get textScale => _textScale;
  Thresholds get thresholds => _thresholds;

  /// Modo de demonstração (não persiste entre aberturas do app).
  bool get simulateOffline => _simulateOffline;

  void _load() {
    _consentGiven = _store.getBool(StorageKeys.consent) ?? false;
    final date = _store.getString(StorageKeys.consentDate);
    _consentDate = date == null ? null : DateTime.tryParse(date);
    _shareAggregated = _store.getBool(StorageKeys.shareAggregated) ?? false;
    final mode = _store.getString(StorageKeys.themeMode);
    _themeMode = ThemeMode.values.firstWhere(
      (m) => m.name == mode,
      orElse: () => ThemeMode.system,
    );
    _highContrast = _store.getBool(StorageKeys.highContrast) ?? false;
    _textScale = _store.getDouble(StorageKeys.textScale) ?? 1.0;
    final json = _store.getJson(StorageKeys.thresholds);
    if (json != null) {
      try {
        _thresholds = Thresholds.fromJson(json);
      } catch (_) {
        _thresholds = Thresholds.defaults;
      }
    }
  }

  Future<void> giveConsent({required bool shareAggregated}) async {
    _consentGiven = true;
    _consentDate = DateTime.now();
    _shareAggregated = shareAggregated;
    notifyListeners();
    await _store.setBool(StorageKeys.consent, true);
    await _store.setString(
        StorageKeys.consentDate, _consentDate!.toIso8601String());
    await _store.setBool(StorageKeys.shareAggregated, shareAggregated);
  }

  Future<void> revokeConsent() async {
    _consentGiven = false;
    _consentDate = null;
    _shareAggregated = false;
    notifyListeners();
    await _store.remove(StorageKeys.consent);
    await _store.remove(StorageKeys.consentDate);
    await _store.remove(StorageKeys.shareAggregated);
  }

  Future<void> setShareAggregated(bool value) async {
    _shareAggregated = value;
    notifyListeners();
    await _store.setBool(StorageKeys.shareAggregated, value);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await _store.setString(StorageKeys.themeMode, mode.name);
  }

  Future<void> setHighContrast(bool value) async {
    _highContrast = value;
    notifyListeners();
    await _store.setBool(StorageKeys.highContrast, value);
  }

  Future<void> setTextScale(double value) async {
    _textScale = value;
    notifyListeners();
    await _store.setDouble(StorageKeys.textScale, value);
  }

  Future<void> saveThresholds(Thresholds value) async {
    _thresholds = value;
    notifyListeners();
    await _store.setJson(StorageKeys.thresholds, value.toJson());
  }

  Future<void> resetThresholds() => saveThresholds(Thresholds.defaults);

  void setSimulateOffline(bool value) {
    _simulateOffline = value;
    notifyListeners();
  }
}

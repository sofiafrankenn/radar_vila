import 'package:flutter/foundation.dart';

import 'package:radar_vila/data/api_exception.dart';
import 'package:radar_vila/data/local/local_store.dart';
import 'package:radar_vila/data/repositories/territory_repository.dart';
import 'package:radar_vila/domain/alert_engine.dart';
import 'package:radar_vila/models/alert.dart';
import 'package:radar_vila/models/indicator.dart';
import 'package:radar_vila/models/territory_snapshot.dart';
import 'package:radar_vila/models/thresholds.dart';
import 'package:radar_vila/providers/load_status.dart';
import 'package:radar_vila/providers/settings_provider.dart';

/// Estado GLOBAL dos dados do território, alertas e decisões humanas.
/// Compartilhado por visão geral, dashboards, detalhe e lista de alertas.
class TerritoryProvider extends ChangeNotifier {
  TerritoryProvider({
    required TerritoryRepository repository,
    required LocalStore store,
    required SettingsProvider settings,
  })  : _repository = repository,
        _store = store,
        _settings = settings {
    _decisions = _readDecisions();
    _lastThresholds = settings.thresholds;
    _lastSimulateOffline = settings.simulateOffline;
    settings.addListener(_onSettingsChanged);
  }

  final TerritoryRepository _repository;
  final LocalStore _store;
  final SettingsProvider _settings;

  late Map<String, AlertDecisionRecord> _decisions;
  late Thresholds _lastThresholds;
  late bool _lastSimulateOffline;

  LoadStatus _status = LoadStatus.initial;
  String? _errorMessage;
  TerritorySnapshot? _snapshot;
  List<TerritoryAlert> _alerts = const [];

  LoadStatus get status => _status;
  String? get errorMessage => _errorMessage;
  TerritorySnapshot? get snapshot => _snapshot;
  bool get hasData => _snapshot != null;
  bool get isLoading => _status == LoadStatus.loading;
  List<TerritoryAlert> get alerts => _alerts;

  int get pendingAlertsCount =>
      _alerts.where((a) => decisionFor(a.id) == HumanDecision.pendente).length;

  int get reviewedAlertsCount => _decisions.values
      .where((d) => d.decision != HumanDecision.pendente)
      .length;

  Future<void> load() async {
    if (_status == LoadStatus.loading) return;
    _status = LoadStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      _snapshot = await _repository.load(
        simulateOffline: _settings.simulateOffline,
      );
      _status = LoadStatus.success;
      _recompute();
    } on ApiException catch (e) {
      _status = LoadStatus.error;
      _errorMessage = e.message;
    } catch (e) {
      _status = LoadStatus.error;
      _errorMessage = 'Erro inesperado ao carregar os dados.';
      debugPrint('TerritoryProvider.load: $e');
    }
    notifyListeners();
  }

  Indicator? indicatorById(String id) {
    final list = _snapshot?.indicators ?? const <Indicator>[];
    for (final i in list) {
      if (i.id == id) return i;
    }
    return null;
  }

  List<Indicator> indicatorsFor(DashboardType type) =>
      _snapshot?.indicatorsFor(type) ?? const [];

  TerritoryAlert? alertById(String id) {
    for (final a in _alerts) {
      if (a.id == id) return a;
    }
    return null;
  }

  List<TerritoryAlert> alertsForIndicator(String indicatorId) =>
      _alerts.where((a) => a.indicatorId == indicatorId).toList();

  List<TerritoryAlert> alertsForDashboard(DashboardType type) => _alerts
      .where((a) => indicatorById(a.indicatorId)?.dashboard == type)
      .toList();

  HumanDecision decisionFor(String alertId) =>
      _decisions[alertId]?.decision ?? HumanDecision.pendente;

  AlertDecisionRecord? decisionRecordFor(String alertId) => _decisions[alertId];

  /// Única forma de mudar o status de um alerta: ação explícita de uma pessoa.
  Future<void> setDecision(
    String alertId,
    HumanDecision decision,
    String note,
  ) async {
    if (decision == HumanDecision.pendente) {
      _decisions.remove(alertId);
    } else {
      _decisions[alertId] = AlertDecisionRecord(
        decision: decision,
        note: note,
        decidedAt: DateTime.now(),
      );
    }
    notifyListeners();
    await _store.setJson(StorageKeys.alertDecisions, {
      for (final e in _decisions.entries) e.key: e.value.toJson(),
    });
  }

  void _recompute() {
    final snap = _snapshot;
    if (snap == null) {
      _alerts = const [];
      return;
    }
    _alerts = AlertEngine(
      thresholds: _settings.thresholds,
      fromCache: snap.fromCache,
    ).evaluate(snap.indicators);
  }

  void _onSettingsChanged() {
    final thresholds = _settings.thresholds;
    final offline = _settings.simulateOffline;
    if (offline != _lastSimulateOffline) {
      _lastSimulateOffline = offline;
      load();
    }
    if (thresholds != _lastThresholds) {
      _lastThresholds = thresholds;
      _recompute();
      notifyListeners();
    }
  }

  Map<String, AlertDecisionRecord> _readDecisions() {
    final json = _store.getJson(StorageKeys.alertDecisions) ?? const {};
    final result = <String, AlertDecisionRecord>{};
    json.forEach((key, value) {
      try {
        result[key] =
            AlertDecisionRecord.fromJson(value as Map<String, dynamic>);
      } catch (_) {
        // registro inválido ignorado
      }
    });
    return result;
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    super.dispose();
  }
}

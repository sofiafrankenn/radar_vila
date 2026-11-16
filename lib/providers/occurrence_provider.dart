import 'package:flutter/foundation.dart';

import 'package:radar_vila/data/repositories/occurrence_repository.dart';
import 'package:radar_vila/models/occurrence.dart';
import 'package:radar_vila/providers/load_status.dart';

/// Estado GLOBAL das ocorrências cidadãs (persistidas localmente).
class OccurrenceProvider extends ChangeNotifier {
  OccurrenceProvider(this._repository);

  final OccurrenceRepository _repository;

  LoadStatus _status = LoadStatus.initial;
  String? _errorMessage;
  List<Occurrence> _items = const [];

  LoadStatus get status => _status;
  String? get errorMessage => _errorMessage;
  List<Occurrence> get items => _items;
  bool get isLoading => _status == LoadStatus.loading;

  Map<OccurrenceCategory, int> get countByCategory {
    final counts = <OccurrenceCategory, int>{};
    for (final o in _items) {
      counts[o.category] = (counts[o.category] ?? 0) + 1;
    }
    return counts;
  }

  /// Ocorrências agrupadas por sub-região (usado no mapa).
  Map<String, List<Occurrence>> get byRegion {
    final groups = <String, List<Occurrence>>{};
    for (final o in _items) {
      groups.putIfAbsent(o.region, () => []).add(o);
    }
    return groups;
  }

  Future<void> load() async {
    _status = LoadStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      _items = await _repository.loadAll();
      _status = LoadStatus.success;
    } catch (e) {
      _status = LoadStatus.error;
      _errorMessage = 'Não foi possível ler as ocorrências salvas.';
    }
    notifyListeners();
  }

  Future<void> add(Occurrence occurrence) async {
    final previous = _items;
    _items = [occurrence, ..._items];
    notifyListeners();
    try {
      await _repository.saveAll(_items);
    } catch (_) {
      _items = previous;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> remove(String id) async {
    _items = _items.where((o) => o.id != id).toList();
    notifyListeners();
    await _repository.saveAll(_items);
  }

  Future<void> clear() async {
    _items = const [];
    notifyListeners();
    await _repository.clear();
  }
}

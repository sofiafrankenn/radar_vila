import 'package:radar_vila/data/local/local_store.dart';
import 'package:radar_vila/models/occurrence.dart';

/// Ocorrências ficam somente no aparelho (nada é enviado a servidores).
class OccurrenceRepository {
  OccurrenceRepository(
    this._store, {
    this.latency = const Duration(milliseconds: 300),
  });

  final LocalStore _store;
  final Duration latency;

  Future<List<Occurrence>> loadAll() async {
    await Future<void>.delayed(latency);
    final raw = _store.getJsonList(StorageKeys.occurrences) ?? const [];
    final items = <Occurrence>[];
    for (final entry in raw) {
      try {
        items.add(Occurrence.fromJson(entry as Map<String, dynamic>));
      } catch (_) {
        // registro corrompido é descartado
      }
    }
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  Future<void> saveAll(List<Occurrence> items) => _store.setJson(
        StorageKeys.occurrences,
        [for (final o in items) o.toJson()],
      );

  Future<void> clear() => _store.remove(StorageKeys.occurrences);
}

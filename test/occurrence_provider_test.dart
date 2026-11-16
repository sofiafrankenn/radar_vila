import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:radar_vila/core/constants.dart';
import 'package:radar_vila/data/local/local_store.dart';
import 'package:radar_vila/data/repositories/occurrence_repository.dart';
import 'package:radar_vila/models/occurrence.dart';
import 'package:radar_vila/providers/occurrence_provider.dart';

Occurrence _occ(String id, String region, OccurrenceCategory category) =>
    Occurrence(
      id: id,
      category: category,
      region: region,
      description: 'Teste',
      date: DateTime(2026, 11, 10),
      reporterAlias: 'Cidadão #TEST',
      createdAt: DateTime(2026, 11, 10),
    );

void main() {
  test('Ocorrências são persistidas e agrupadas por sub-região', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await LocalStore.create();
    final repo = OccurrenceRepository(store, latency: Duration.zero);
    final provider = OccurrenceProvider(repo);

    final paraiso = TerritoryInfo.regions[2];
    final klabin = TerritoryInfo.regions[3];
    await provider.add(_occ('1', paraiso, OccurrenceCategory.vazamento));
    await provider.add(_occ('2', paraiso, OccurrenceCategory.alagamento));
    await provider.add(_occ('3', klabin, OccurrenceCategory.faltaAgua));

    expect(provider.byRegion[paraiso], hasLength(2));
    expect(provider.byRegion[klabin], hasLength(1));
    expect(provider.byRegion.containsKey(TerritoryInfo.regions.first), isFalse);

    // Um novo provider lê o que foi salvo no aparelho (funciona offline).
    final reloaded = OccurrenceProvider(repo);
    await reloaded.load();
    expect(reloaded.items, hasLength(3));
  });

  test('Toda sub-região do formulário tem posição no mapa', () {
    for (final region in TerritoryInfo.regions) {
      expect(TerritoryInfo.regionCenters, contains(region));
    }
  });
}

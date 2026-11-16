import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:radar_vila/app.dart';
import 'package:radar_vila/core/theme/app_theme.dart';
import 'package:radar_vila/data/indicator_catalog.dart';
import 'package:radar_vila/data/local/local_store.dart';
import 'package:radar_vila/data/repositories/occurrence_repository.dart';
import 'package:radar_vila/data/repositories/territory_repository.dart';
import 'package:radar_vila/data/services/climate_api_service.dart';
import 'package:radar_vila/data/services/synthetic_data_service.dart';
import 'package:radar_vila/models/alert.dart';
import 'package:radar_vila/models/territory_snapshot.dart';
import 'package:radar_vila/widgets/banners.dart';
import 'package:radar_vila/widgets/pills.dart';

/// Repositório falso: sem rede, dados sintéticos imediatos.
class _FakeTerritoryRepository extends TerritoryRepository {
  _FakeTerritoryRepository(LocalStore store)
      : super(
          store: store,
          climateService: ClimateApiService(),
          syntheticService: SyntheticDataService(latency: Duration.zero),
        );

  @override
  Future<TerritorySnapshot> load({bool simulateOffline = false}) async {
    final data = SyntheticDataService.generate(today: DateTime.now());
    return TerritorySnapshot(
      indicators: [
        for (final e in data.entries) IndicatorCatalog.build(e.key, e.value),
      ],
      fetchedAt: DateTime.now(),
    );
  }
}

void main() {
  testWidgets('Aviso de decisão humana é exibido', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(body: HumanDecisionBanner()),
    ));
    expect(find.text('A decisão final é sempre humana'), findsOneWidget);
  });

  testWidgets('Severidade mostra texto, não só cor', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.highContrastLight,
      home: const Scaffold(body: SeverityChip(severity: AlertSeverity.critico)),
    ));
    expect(find.text('Crítico'), findsOneWidget);
  });

  testWidgets('Consentimento libera o app', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = await LocalStore.create();

    await tester.pumpWidget(RadarVilaApp(
      store: store,
      territoryRepository: _FakeTerritoryRepository(store),
      occurrenceRepository: OccurrenceRepository(store, latency: Duration.zero),
    ));
    await tester.pump();

    // A tela usa ListView (construção preguiçosa): rola até o botão.
    final button = find.text('Concordo e quero continuar');
    await tester.scrollUntilVisible(
      button,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(button, findsOneWidget);

    final checkbox = find.byType(CheckboxListTile).first;
    await tester.ensureVisible(checkbox);
    await tester.tap(checkbox);
    await tester.pump();
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Painéis do território'), findsOneWidget);
  });
}

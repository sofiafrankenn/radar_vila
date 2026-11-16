import 'package:material_ui/material_ui.dart';
import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:provider/provider.dart';

import 'package:radar_vila/core/theme/app_theme.dart';
import 'package:radar_vila/data/local/local_store.dart';
import 'package:radar_vila/data/repositories/occurrence_repository.dart';
import 'package:radar_vila/data/repositories/territory_repository.dart';
import 'package:radar_vila/data/services/climate_api_service.dart';
import 'package:radar_vila/data/services/synthetic_data_service.dart';
import 'package:radar_vila/providers/occurrence_provider.dart';
import 'package:radar_vila/providers/settings_provider.dart';
import 'package:radar_vila/providers/territory_provider.dart';
import 'package:radar_vila/routes/app_router.dart';
import 'package:radar_vila/screens/app_gate.dart';

class RadarVilaApp extends StatelessWidget {
  const RadarVilaApp({
    super.key,
    required this.store,
    this.territoryRepository,
    this.occurrenceRepository,
  });

  final LocalStore store;

  /// Permitem injetar implementações falsas nos testes.
  final TerritoryRepository? territoryRepository;
  final OccurrenceRepository? occurrenceRepository;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>(
          create: (_) => SettingsProvider(store),
        ),
        ChangeNotifierProvider<TerritoryProvider>(
          lazy: false,
          create: (ctx) {
            final provider = TerritoryProvider(
              repository: territoryRepository ??
                  TerritoryRepository(
                    store: store,
                    climateService: ClimateApiService(),
                    syntheticService: SyntheticDataService(),
                  ),
              store: store,
              settings: ctx.read<SettingsProvider>(),
            );
            Future.microtask(provider.load);
            return provider;
          },
        ),
        ChangeNotifierProvider<OccurrenceProvider>(
          lazy: false,
          create: (_) {
            final provider = OccurrenceProvider(
              occurrenceRepository ?? OccurrenceRepository(store),
            );
            Future.microtask(provider.load);
            return provider;
          },
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'RadarVila',
            debugShowCheckedModeBanner: false,
            theme: settings.highContrast
                ? AppTheme.highContrastLight
                : AppTheme.light,
            darkTheme: settings.highContrast
                ? AppTheme.highContrastDark
                : AppTheme.dark,
            themeMode: settings.themeMode,
            locale: const Locale('pt', 'BR'),
            supportedLocales: const [Locale('pt', 'BR')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const AppGate(),
            onGenerateRoute: AppRouter.onGenerateRoute,
            builder: (context, child) {
              // Respeita a fonte do sistema e soma o ajuste feito no app.
              final mq = MediaQuery.of(context);
              final systemFactor = mq.textScaler.scale(16) / 16;
              final factor = (systemFactor * settings.textScale)
                  .clamp(0.85, 2.4)
                  .toDouble();
              return MediaQuery(
                data: mq.copyWith(textScaler: TextScaler.linear(factor)),
                child: child ?? const SizedBox.shrink(),
              );
            },
          );
        },
      ),
    );
  }
}

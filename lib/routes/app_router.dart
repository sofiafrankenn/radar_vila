import 'package:material_ui/material_ui.dart';

import 'package:radar_vila/models/indicator.dart';
import 'package:radar_vila/routes/app_routes.dart';
import 'package:radar_vila/screens/about/about_data_screen.dart';
import 'package:radar_vila/screens/alerts/alert_detail_screen.dart';
import 'package:radar_vila/screens/dashboard/dashboard_screen.dart';
import 'package:radar_vila/screens/indicator/indicator_detail_screen.dart';
import 'package:radar_vila/screens/map/territory_map_screen.dart';
import 'package:radar_vila/screens/not_found_screen.dart';
import 'package:radar_vila/screens/occurrences/occurrence_form_screen.dart';
import 'package:radar_vila/screens/settings/thresholds_screen.dart';

/// Gera as rotas e valida os parâmetros recebidos.
class AppRouter {
  AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final args = settings.arguments;
    final Widget page;
    switch (settings.name) {
      case AppRoutes.dashboard:
        page = args is DashboardType
            ? DashboardScreen(type: args)
            : const NotFoundScreen();
      case AppRoutes.indicator:
        page = args is String
            ? IndicatorDetailScreen(indicatorId: args)
            : const NotFoundScreen();
      case AppRoutes.alertDetail:
        page = args is String
            ? AlertDetailScreen(alertId: args)
            : const NotFoundScreen();
      case AppRoutes.occurrenceForm:
        page = const OccurrenceFormScreen();
      case AppRoutes.thresholds:
        page = const ThresholdsScreen();
      case AppRoutes.about:
        page = const AboutDataScreen();
      case AppRoutes.map:
        page = const TerritoryMapScreen();
      default:
        page = const NotFoundScreen();
    }
    return MaterialPageRoute<void>(settings: settings, builder: (_) => page);
  }
}

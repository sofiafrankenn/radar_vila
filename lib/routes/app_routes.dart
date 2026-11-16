/// Rotas nomeadas do app.
class AppRoutes {
  AppRoutes._();

  static const String home = '/';
  static const String dashboard = '/dashboard'; // argumento: DashboardType
  static const String indicator = '/indicador'; // argumento: id (String)
  static const String alertDetail = '/alerta'; // argumento: id (String)
  static const String occurrenceForm = '/ocorrencias/nova';
  static const String thresholds = '/limiares';
  static const String about = '/sobre';
  static const String map = '/mapa';
}

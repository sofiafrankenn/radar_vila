/// Informações fixas do território monitorado.
class TerritoryInfo {
  TerritoryInfo._();

  static const String name = 'Vila Mariana';
  static const String city = 'São Paulo/SP';
  static const double latitude = -23.5891;
  static const double longitude = -46.6346;

  /// População do distrito (Censo IBGE 2010), usada como referência aproximada.
  static const int population = 130484;
  static const String populationNote =
      'População do distrito (Censo IBGE 2010), usada como referência aproximada.';

  /// Sub-regiões usadas no registro de ocorrências (sem endereço exato).
  static const List<String> regions = [
    'Vila Mariana (centro)',
    'Vila Clementino',
    'Paraíso',
    'Chácara Klabin',
    'Jardim Vila Mariana',
  ];
}

/// Referências usadas no indicador de benefício social.
class ImpactReference {
  ImpactReference._();

  /// Meta de consumo consciente adotada no app (L/hab/dia).
  static const double conscientConsumption = 150;

  /// Volume diário que a ONU considera suficiente por pessoa (L/dia).
  static const double unDailyNeed = 110;
}

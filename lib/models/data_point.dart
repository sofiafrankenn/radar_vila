/// Um valor diário de um indicador (histórico ou previsão).
class DataPoint {
  const DataPoint({
    required this.date,
    required this.value,
    this.isForecast = false,
  });

  final DateTime date;
  final double value;
  final bool isForecast;

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'value': value,
        'isForecast': isForecast,
      };

  factory DataPoint.fromJson(Map<String, dynamic> json) => DataPoint(
        date: DateTime.parse(json['date'] as String),
        value: (json['value'] as num).toDouble(),
        isForecast: json['isForecast'] as bool? ?? false,
      );
}

class TideLevel {
  final String stationId;
  final String stationName;
  final String value;
  final DateTime date;

  TideLevel({
    required this.stationId,
    required this.stationName,
    required this.value,
    required this.date,
  });

  factory TideLevel.fromJson(Map<String, dynamic> json) {
    return TideLevel(
      stationId: json['ID_stazione'] ?? '',
      stationName: json['stazione'] ?? '',
      value: json['valore'] ?? '0 m',
      date: DateTime.parse(json['data']),
    );
  }

  double get valueInCm {
    final cleanValue = value.replaceAll(' m', '').trim();
    return (double.tryParse(cleanValue) ?? 0.0) * 100;
  }
}

class TideForecast {
  final DateTime forecastDate;
  final DateTime extremeDate;
  final String type; // min or max
  final int value;
  final String title;

  TideForecast({
    required this.forecastDate,
    required this.extremeDate,
    required this.type,
    required this.value,
    required this.title,
  });

  factory TideForecast.fromJson(Map<String, dynamic> json) {
    final valueStr = json['VALORE']?.toString() ?? '';
    final parsedValue = double.tryParse(valueStr)?.round() ?? 0;
    return TideForecast(
      forecastDate: DateTime.parse(json['DATA_PREVISIONE']),
      extremeDate: DateTime.parse(json['DATA_ESTREMALE']),
      type: json['TIPO_ESTREMALE'] ?? '',
      value: parsedValue,
      title: json['TITOLO'] ?? '',
    );
  }
}

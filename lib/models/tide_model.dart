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
      stationId: json['ID_stazione']?.toString() ?? '',
      stationName: json['stazione']?.toString() ?? '',
      value: json['valore']?.toString() ?? '0 m',
      date: DateTime.tryParse(json['data']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  double get valueInCm {
    final cleanValue = value.replaceAll(' m', '').replaceAll('m', '').replaceAll(',', '.').trim();
    final parsed = double.tryParse(cleanValue);
    if (parsed == null || parsed <= -900) {
      // -999 indicates missing sensor data in CPSM
      return 0.0;
    }
    return parsed * 100;
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
    final parsedValue = double.tryParse(valueStr.replaceAll(',', '.'))?.round() ?? 0;
    return TideForecast(
      forecastDate: DateTime.tryParse(json['DATA_PREVISIONE']?.toString() ?? '') ?? DateTime.now(),
      extremeDate: DateTime.tryParse(json['DATA_ESTREMALE']?.toString() ?? '') ?? DateTime.now(),
      type: json['TIPO_ESTREMALE']?.toString() ?? '',
      value: parsedValue,
      title: json['TITOLO']?.toString() ?? '',
    );
  }
}

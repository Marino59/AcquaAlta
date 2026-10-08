import 'package:flutter_test/flutter_test.dart';
import 'package:venice_tide/models/tide_model.dart';

void main() {
  group('TideForecast', () {
    test('fromJson correctly parses double string to int', () {
      final json = {
        'DATA_PREVISIONE': '2026-06-25 17:00:00',
        'DATA_ESTREMALE': '2026-06-25 20:25:00',
        'TIPO_ESTREMALE': 'max',
        'VALORE': '65.0',
        'TITOLO': 'Marea percepita per l\'estremale del 25/06 alle 20:25',
      };

      final forecast = TideForecast.fromJson(json);

      expect(forecast.value, equals(65));
      expect(forecast.type, equals('max'));
      expect(forecast.title, equals('Marea percepita per l\'estremale del 25/06 alle 20:25'));
    });

    test('fromJson handles empty or missing VALORE', () {
      final json = {
        'DATA_PREVISIONE': '2026-06-25 17:00:00',
        'DATA_ESTREMALE': '2026-06-25 20:25:00',
        'TIPO_ESTREMALE': 'max',
        'TITOLO': 'Test',
      };

      final forecast = TideForecast.fromJson(json);

      expect(forecast.value, equals(0));
    });
  });

  group('TideLevel', () {
    test('fromJson correctly parses standard station data', () {
      final json = {
        'ID_stazione': '1025',
        'stazione': 'Punta Salute Canal Grande',
        'valore': '0.88 m',
        'data': '2026-10-08 09:00:00',
      };

      final level = TideLevel.fromJson(json);

      expect(level.stationId, equals('1025'));
      expect(level.stationName, equals('Punta Salute Canal Grande'));
      expect(level.valueInCm, equals(88.0));
    });

    test('fromJson handles comma decimals and no space before m', () {
      final json = {
        'ID_stazione': 1025,
        'stazione': 'Punta Salute',
        'valore': '0,95m',
        'data': '2026-10-08 09:00:00',
      };

      final level = TideLevel.fromJson(json);

      expect(level.stationId, equals('1025'));
      expect(level.valueInCm, equals(95.0));
    });

    test('fromJson handles -999 missing sensor value by returning 0.0', () {
      final json = {
        'ID_stazione': '1025',
        'stazione': 'Punta Salute',
        'valore': '-999',
        'data': '2026-10-08 09:00:00',
      };

      final level = TideLevel.fromJson(json);
      expect(level.valueInCm, equals(0.0));
    });
  });
}


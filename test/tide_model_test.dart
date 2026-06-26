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
}

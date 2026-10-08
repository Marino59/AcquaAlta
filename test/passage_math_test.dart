import 'package:flutter_test/flutter_test.dart';
import 'package:venice_tide/models/tide_model.dart';
import 'package:venice_tide/utils/tide_math.dart';

void main() {
  group('TideMath', () {
    test('generateCurve produces smooth points between forecasts', () {
      final now = DateTime.now();
      final forecasts = [
        TideForecast(
          forecastDate: now,
          extremeDate: now,
          type: 'max',
          value: 90,
          title: 'Alta',
        ),
        TideForecast(
          forecastDate: now,
          extremeDate: now.add(const Duration(hours: 6)),
          type: 'min',
          value: 20,
          title: 'Bassa',
        ),
      ];

      final points = TideMath.generateCurve(forecasts);
      expect(points.isNotEmpty, isTrue);
      expect(points.first.value, closeTo(90, 0.1));
      expect(points.last.value, closeTo(20, 0.1));
    });

    test('findSafeWindows correctly identifies periods below threshold', () {
      final base = DateTime(2026, 10, 8, 12, 0);
      final forecasts = [
        TideForecast(forecastDate: base, extremeDate: base, type: 'max', value: 95, title: 'Alta'),
        TideForecast(forecastDate: base, extremeDate: base.add(const Duration(hours: 6)), type: 'min', value: 30, title: 'Bassa'),
        TideForecast(forecastDate: base, extremeDate: base.add(const Duration(hours: 12)), type: 'max', value: 100, title: 'Alta'),
      ];

      final windows = TideMath.findSafeWindows(forecasts, 80.0);
      expect(windows.isNotEmpty, isTrue);
      // Safe window should start around 2-3 hours after the high tide and end before the next
      final firstWindow = windows.first;
      expect(firstWindow.first.isAfter(base), isTrue);
      expect(firstWindow.last.isBefore(base.add(const Duration(hours: 12))), isTrue);
    });
  });
}

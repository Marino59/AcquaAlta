import 'package:flutter_test/flutter_test.dart';
import 'package:venice_tide/utils/italian_date_helper.dart';

void main() {
  group('ItalianDateHelper', () {
    test('natural day names for today, tomorrow, and weekdays', () {
      final now = DateTime(2026, 10, 8, 12, 0); // Thursday (Giovedì)
      expect(ItalianDateHelper.getDayNameNatural(now, now), equals('oggi'));
      expect(ItalianDateHelper.getDayNameNatural(now.add(const Duration(days: 1)), now), equals('domani'));
      expect(ItalianDateHelper.getDayNameNatural(now.add(const Duration(days: 2)), now), equals('sabato'));
      expect(ItalianDateHelper.getDayNameNatural(now.add(const Duration(days: 3)), now), equals('domenica'));
      expect(ItalianDateHelper.getDayNameNatural(now.add(const Duration(days: 4)), now), equals('lunedì'));
    });

    test('natural time format', () {
      expect(ItalianDateHelper.formatTimeNatural(DateTime(2026, 10, 8, 12, 10)), equals('12 e 10'));
      expect(ItalianDateHelper.formatTimeNatural(DateTime(2026, 10, 8, 0, 5)), equals('0 e 05'));
    });

    test('chip labels', () {
      final now = DateTime(2026, 10, 8, 12, 0);
      expect(ItalianDateHelper.getDayChipLabel(now, now), equals('Oggi'));
      expect(ItalianDateHelper.getDayChipLabel(now.add(const Duration(days: 1)), now), equals('Domani'));
      expect(ItalianDateHelper.getDayChipLabel(now.add(const Duration(days: 2)), now), equals('Sabato 10'));
    });
  });
}

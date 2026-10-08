/// Rock-solid Italian date and time formatting without intl locale dependencies.
/// Guarantees zero LocaleDataException crashes across web, desktop, and mobile.
class ItalianDateHelper {
  static const List<String> daysCapitalized = [
    'Lunedì',
    'Martedì',
    'Mercoledì',
    'Giovedì',
    'Venerdì',
    'Sabato',
    'Domenica'
  ];

  static const List<String> daysLower = [
    'lunedì',
    'martedì',
    'mercoledì',
    'giovedì',
    'venerdì',
    'sabato',
    'domenica'
  ];

  static const List<String> daysShort = [
    'Lun',
    'Mar',
    'Mer',
    'Gio',
    'Ven',
    'Sab',
    'Dom'
  ];

  static const List<String> monthsShort = [
    'Gen',
    'Feb',
    'Mar',
    'Apr',
    'Mag',
    'Giu',
    'Lug',
    'Ago',
    'Set',
    'Ott',
    'Nov',
    'Dic'
  ];

  /// Returns natural relative day: "oggi", "domani", or day name in Italian (e.g. "sabato")
  static String getDayNameNatural(DateTime date, DateTime now) {
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return "oggi";
    }
    final tomorrow = now.add(const Duration(days: 1));
    if (date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day) {
      return "domani";
    }
    final idx = (date.weekday - 1).clamp(0, 6);
    return daysLower[idx];
  }

  /// Returns capitalized relative day for chips and tiles: "Oggi", "Domani", or "Sabato 10"
  static String getDayChipLabel(DateTime date, DateTime now) {
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return "Oggi";
    }
    final tomorrow = now.add(const Duration(days: 1));
    if (date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day) {
      return "Domani";
    }
    final idx = (date.weekday - 1).clamp(0, 6);
    return "${daysCapitalized[idx]} ${date.day}";
  }

  /// Capitalizes first letter of string safely
  static String capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  /// Natural Italian time representation: e.g. "12 e 10" or "0 e 40"
  static String formatTimeNatural(DateTime t) {
    final h = t.hour;
    final mStr = t.minute.toString().padLeft(2, '0');
    return "$h e $mStr";
  }

  /// Standard clock time: e.g. "12:10"
  static String formatClockTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return "$h:$m";
  }

  /// Short forecast date format: e.g. "Gio 8 Ott"
  static String formatForecastDate(DateTime t) {
    final dayName = daysShort[(t.weekday - 1).clamp(0, 6)];
    final monthName = monthsShort[(t.month - 1).clamp(0, 11)];
    return "$dayName ${t.day} $monthName";
  }

  /// Axis format: e.g. "Gio 12:00"
  static String formatGraphAxisDate(DateTime t) {
    final dayName = daysShort[(t.weekday - 1).clamp(0, 6)];
    final time = formatClockTime(t);
    return "$dayName $time";
  }

  /// Tooltip format: e.g. "Gio 8 Ott 12:00"
  static String formatTooltipDate(DateTime t) {
    final dateStr = formatForecastDate(t);
    final time = formatClockTime(t);
    return "$dateStr $time";
  }
}

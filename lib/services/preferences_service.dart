import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _keyMaxHeight = 'max_safe_height';

  Future<void> setMaxSafeHeight(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyMaxHeight, value);
  }

  Future<double> getMaxSafeHeight() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyMaxHeight) ?? 80.0;
  }
}

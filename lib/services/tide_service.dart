import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/tide_model.dart';

class TideService {
  static const String _levelUrl = 'https://dati.venezia.it/sites/default/files/dataset/opendata/livello.json';
  static const String _forecastUrl = 'https://dati.venezia.it/sites/default/files/dataset/opendata/previsione.json';

  Future<TideLevel?> getCurrentTide() async {
    try {
      final response = await http.get(Uri.parse(_getUrl(_levelUrl)));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        // Punta Salute is usually the reference (ID 1025 or similar)
        // From previous verification, ID_stazione 1025 is Punta Salute Canal Grande
        final stationData = data.firstWhere(
          (element) => element['ID_stazione'] == '1025',
          orElse: () => null,
        );
        
        if (stationData != null) {
          return TideLevel.fromJson(stationData);
        }
      }
    } catch (e) {
      debugPrint('Error fetching current tide: $e');
    }
    return null;
  }

  Future<List<TideForecast>> getForecast() async {
    try {
      final response = await http.get(Uri.parse(_getUrl(_forecastUrl)));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => TideForecast.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching forecast: $e');
    }
    return [];
  }

  String _getUrl(String url) {
    if (kIsWeb) {
      // api.allorigins.win returned 500 errors. Switching to corsproxy.io.
      return 'https://corsproxy.io/?$url';
    }
    return url;
  }
}

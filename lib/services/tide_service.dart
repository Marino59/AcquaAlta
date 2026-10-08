import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/tide_model.dart';

class TideService {
  static const String _levelUrl = 'https://dati.venezia.it/sites/default/files/dataset/opendata/livello.json';
  static const String _forecastUrl = 'https://dati.venezia.it/sites/default/files/dataset/opendata/previsione.json';

  Future<String?> _fetchData(String originalUrl) async {
    if (!kIsWeb) {
      try {
        final response = await http.get(Uri.parse(originalUrl)).timeout(const Duration(seconds: 10));
        if (response.statusCode == 200) {
          return response.body;
        }
      } catch (e) {
        debugPrint('Direct fetch failed ($originalUrl): $e');
      }
      return null;
    }

    // On Web, use high-speed Cloudflare Worker CORS proxies with fallback.
    // Ensure URL is encoded with Uri.encodeComponent to avoid proxy parsing errors.
    final encoded = Uri.encodeComponent(originalUrl);
    final proxyUrls = [
      'https://cors-anywhere.pulkitpareekofficial.workers.dev/?url=$encoded',
      'https://dry-surf-6b16.joshua-ed.workers.dev/?url=$encoded',
      'https://api.allorigins.win/raw?url=$encoded',
      'https://api.cors.lol/?url=$encoded',
    ];

    for (final proxy in proxyUrls) {
      try {
        final response = await http.get(Uri.parse(proxy)).timeout(const Duration(seconds: 8));
        final body = response.body.trim();
        if (response.statusCode == 200 && (body.startsWith('[') || body.startsWith('{'))) {
          return body;
        }
      } catch (e) {
        debugPrint('Proxy fetch failed ($proxy): $e');
      }
    }

    // Last resort fallback: direct fetch in case CORS headers or extension are available
    try {
      final response = await http.get(Uri.parse(originalUrl)).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        return response.body;
      }
    } catch (_) {}

    return null;
  }

  static TideLevel? _cachedLevel;
  static List<TideForecast> _cachedForecast = [];

  Future<TideLevel?> getCurrentTide() async {
    try {
      final body = await _fetchData(_levelUrl);
      if (body != null) {
        final List<dynamic> data = json.decode(body);
        
        bool isValidStation(dynamic el) {
          if (el == null) return false;
          final val = el['valore']?.toString() ?? '';
          return val.isNotEmpty && !val.contains('-999');
        }

        // Priority 1: Punta Salute Canal Grande (1025)
        var stationData = data.firstWhere(
          (element) => element['ID_stazione']?.toString() == '1025' && isValidStation(element),
          orElse: () => null,
        );

        // Priority 2: Punta Salute Canale Giudecca (1045)
        stationData ??= data.firstWhere(
          (element) => element['ID_stazione']?.toString() == '1045' && isValidStation(element),
          orElse: () => null,
        );

        // Priority 3: Venezia Misericordia (1029) or San Geremia (1001)
        stationData ??= data.firstWhere(
          (element) => ['1029', '1001'].contains(element['ID_stazione']?.toString()) && isValidStation(element),
          orElse: () => null,
        );

        // Priority 4: Any first valid station in Venice lagoon
        stationData ??= data.firstWhere(
          (element) => isValidStation(element),
          orElse: () => null,
        );

        // Fallback: if all stations have strange values, take 1025 anyway
        stationData ??= data.firstWhere(
          (element) => element['ID_stazione']?.toString() == '1025',
          orElse: () => null,
        );

        if (stationData != null) {
          final level = TideLevel.fromJson(stationData);
          _cachedLevel = level;
          return level;
        }
      }
    } catch (e) {
      debugPrint('Error fetching current tide: $e');
    }
    return _cachedLevel;
  }

  Future<List<TideForecast>> getForecast() async {
    try {
      final body = await _fetchData(_forecastUrl);
      if (body != null) {
        final List<dynamic> data = json.decode(body);
        final list = data.map((e) => TideForecast.fromJson(e)).toList();
        list.sort((a, b) => a.extremeDate.compareTo(b.extremeDate));
        if (list.isNotEmpty) {
          _cachedForecast = list;
          return list;
        }
      }
    } catch (e) {
      debugPrint('Error fetching forecast: $e');
    }
    return _cachedForecast;
  }
}


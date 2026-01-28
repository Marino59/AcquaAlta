import 'dart:math';
import '../models/tide_model.dart';

class TideMath {
  /// Estimates the tide level at a specific [time] using cosine interpolation
  static double estimateTideLevel(DateTime time, TideForecast prev, TideForecast next) {
    if (time.isBefore(prev.extremeDate)) return prev.value.toDouble();
    if (time.isAfter(next.extremeDate)) return next.value.toDouble();

    final totalDuration = next.extremeDate.difference(prev.extremeDate).inMinutes;
    final elapsed = time.difference(prev.extremeDate).inMinutes;
    
    // Normalize time t from 0 to 1
    final t = elapsed / totalDuration;

    // Cosine interpolation: 
    final ease = (1 - cos(t * pi)) / 2;
    return prev.value + (next.value - prev.value) * ease;
  }

  /// Calculates points for the graph
  static List<MapEntry<DateTime, double>> generateCurve(List<TideForecast> forecasts) {
    if (forecasts.length < 2) return [];

    List<MapEntry<DateTime, double>> points = [];
    
    // Sort just in case
    forecasts.sort((a, b) => a.extremeDate.compareTo(b.extremeDate));

    for (int i = 0; i < forecasts.length - 1; i++) {
        final start = forecasts[i];
        final end = forecasts[i+1];
        
        // Generate points every 15 mins for better precision
        var current = start.extremeDate;
        while (current.isBefore(end.extremeDate)) {
           points.add(MapEntry(current, estimateTideLevel(current, start, end)));
           current = current.add(const Duration(minutes: 15));
        }
    }
    // Add the last point
    points.add(MapEntry(forecasts.last.extremeDate, forecasts.last.value.toDouble()));
    
    return points;
  }

  /// Returns the DATE/TIME when the status will change.
  /// If [isCurrentlySafe] is true, returns the first time the tide goes ABOVE [maxHeight].
  /// If [isCurrentlySafe] is false, returns the first time the tide goes BELOW [maxHeight].
  static DateTime? findNextCrossing(List<TideForecast> forecasts, double maxHeight, bool isCurrentlySafe) {
     final curve = generateCurve(forecasts);
     final now = DateTime.now();

     // Only look at points in the future
     final futurePoints = curve.where((p) => p.key.isAfter(now)).toList();
     
     if (futurePoints.isEmpty) return null;

     for (var point in futurePoints) {
       final level = point.value;
       
       if (isCurrentlySafe) {
         // Look for when it becomes UNSAFE
         if (level > maxHeight) {
           return point.key;
         }
       } else {
         // Look for when it becomes SAFE
         if (level <= maxHeight) {
           return point.key;
         }
       }
     }
     return null;
  }

  /// Finds time windows where tide is BELOW [maxHeight].
  static List<List<DateTime>> findSafeWindows(List<TideForecast> forecasts, double maxHeight) {
     final curve = generateCurve(forecasts);
     List<List<DateTime>> windows = [];
     List<DateTime>? currentWindow;

     for (var point in curve) {
       final time = point.key;
       final level = point.value;
       
       if (level <= maxHeight) {
         if (currentWindow == null) {
           currentWindow = [time];
         }
       } else {
         if (currentWindow != null) {
           currentWindow.add(time);
           windows.add(currentWindow);
           currentWindow = null;
         }
       }
     }

     if (currentWindow != null) {
        currentWindow.add(curve.last.key);
        windows.add(currentWindow);
     }
     
     return windows;
  }

  /// Returns 1 if rising, -1 if falling, 0 if stable (or unknown)
  /// Uses the CURRENT REAL-TIME value and compares with near-future forecast
  static int getTrend(double currentValue, List<TideForecast> forecasts) {
     final now = DateTime.now();
     // Look 15 minutes ahead to get a reliable trend
     final futureVal = estimateTideLevelFromList(now.add(const Duration(minutes: 15)), forecasts);
     
     // Add a small threshold to avoid flickering (e.g. 1 cm change)
     final diff = futureVal - currentValue;
     if (diff > 1.0) return 1;  // Rising
     if (diff < -1.0) return -1; // Falling
     return 0; // Stable
  }



  static double estimateTideLevelFromList(DateTime time, List<TideForecast> forecasts, {double? currentTide}) {
    
    if (forecasts.isEmpty) return currentTide ?? 0.0;
    
    // Ensure sorted
    forecasts.sort((a, b) => a.extremeDate.compareTo(b.extremeDate));
    
    // 1. Time is BEFORE first forecast point
    if (time.isBefore(forecasts.first.extremeDate)) {
      if (currentTide != null) {
        // Interpolate between NOW (currentTide) and FIRST FORECAST
        final now = DateTime.now();
        
        // If time is also before NOW (past), just return currentTide (approximation)
        if (time.isBefore(now)) return currentTide;

        // Create a synthetic "current" forecast point
        // Actually, let's just use estimateTideLevel directly manually
        // We need 'prev' and 'next' as TideForecast objects or just logic
        // Let's create a fake 'prev' object for NOW
        final prevData = TideForecast(
            forecastDate: now,
            extremeDate: now,
            type: "current",
            value: currentTide.round(), // int cm
            title: "Data Attuale"
        );
        
        final nextData = forecasts.first;
        
        return estimateTideLevel(time, prevData, nextData);
      } else {
        // No current tide available, fallback to first forecast value
        return forecasts.first.value.toDouble();
      }
    }

    // 2. Standard Interpolation
    TideForecast? prev;
    TideForecast? next;

    for (int i = 0; i < forecasts.length - 1; i++) {
      if (time.compareTo(forecasts[i].extremeDate) >= 0 && 
          time.compareTo(forecasts[i+1].extremeDate) <= 0) {
        prev = forecasts[i];
        next = forecasts[i+1];
        break;
      }
    }
    
    // 3. Boundary: After last forecast
    if (prev == null || next == null) {
       if (time.isAfter(forecasts.last.extremeDate)) {
         return forecasts.last.value.toDouble();
       }
       return 0.0; 
    }

    return estimateTideLevel(time, prev, next);
  }
}

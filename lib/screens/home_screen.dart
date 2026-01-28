import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/tide_model.dart';
import '../services/tide_service.dart';
import '../services/preferences_service.dart';
import '../utils/tide_math.dart';
import 'graph_screen.dart';
import 'forecast_screen.dart';
import 'official_graph_screen.dart';
import 'map_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TideService _service = TideService();
  final PreferencesService _prefs = PreferencesService();
  
  TideLevel? _currentLevel;
  List<TideForecast> _forecast = [];
  bool _loading = true;
  double _maxSafeHeight = 80.0;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    debugPrint("LOADING DATA...");
    setState(() => _loading = true);
    try {
      final current = await _service.getCurrentTide();
      debugPrint("Current Tide: ${current?.valueInCm}");
      
      final forecast = await _service.getForecast();
      debugPrint("Forecast items: ${forecast.length}");
      
      final mh = await _prefs.getMaxSafeHeight();

      if (mounted) {
        setState(() {
          _currentLevel = current;
          _forecast = forecast;
          // Ensure forecast is sorted for TideMath
          _forecast.sort((a, b) => a.extremeDate.compareTo(b.extremeDate));
          _maxSafeHeight = mh;
          _loading = false;
        });
        debugPrint("DATA LOADED. Loading state set to false.");
      }
    } catch (e, stack) {
      debugPrint("ERROR LOADING DATA: $e");
      debugPrint(stack.toString());
    }
  }

  Future<void> _updateMaxHeight(double newVal) async {
    await _prefs.setMaxSafeHeight(newVal);
    setState(() {
      _maxSafeHeight = newVal;
    });
  }

  void _showSettingsDialog() {
    double tempHeight = _maxSafeHeight;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Impostazioni Barca", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Altezza massima di passaggio: ${tempHeight.round()} cm"),
                Slider(
                  value: tempHeight,
                  min: 40,
                  max: 160,
                  divisions: 24,
                  label: "${tempHeight.round()} cm",
                  onChanged: (val) {
                    setDialogState(() => tempHeight = val);
                  },
                ),
                const Text("Modifica questo valore se usi una barca diversa o se cambia il livello di sicurezza del ponte."),
              ],
            );
          }
        ),
        actions: [
          TextButton(
             onPressed: () => Navigator.pop(context),
             child: const Text("Annulla"),
          ),
          ElevatedButton(
            onPressed: () {
              _updateMaxHeight(tempHeight);
              Navigator.pop(context);
            },
            child: const Text("Salva"),
          )
        ],
      ),
    );
  }

  void _showPredictionTimer() async {
    final now = DateTime.now();
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFF2E7D32),
              onPrimary: Colors.white,
              onSurface: Colors.grey.shade900,
            ),
          ),
          child: child!,
        );
      },
    );

    if (time != null) {
      // Construct DateTime for today/tomorrow based on time
      var target = DateTime(now.year, now.month, now.day, time.hour, time.minute);
      if (target.isBefore(now.subtract(const Duration(minutes: 15)))) {
        // Assume tomorrow if time is significantly in the past
        target = target.add(const Duration(days: 1));
      }



      final predictedVal = TideMath.estimateTideLevelFromList(
        target, 
        _forecast,
        currentTide: _currentLevel?.valueInCm
      );
      
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Previsione Marea", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Alle ore ${time.format(context)}", 
                style: GoogleFonts.outfit(fontSize: 18, color: Colors.grey.shade700)
              ),
              const SizedBox(height: 10),
              Text(
                "${predictedVal.toStringAsFixed(0)} cm", 
                style: GoogleFonts.outfit(fontSize: 48, fontWeight: FontWeight.bold, color: const Color(0xFF2E7D32))
              ),
              const SizedBox(height: 10),
              Text(
                _getDayName(target) == 'oggi' ? "Oggi" : "Domani",
                style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey),
              )
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text("OK")
            )
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final pages = [
      _buildPassageStatusScreen(),
      MapScreen(tideLevel: _currentLevel?.valueInCm ?? 0.0),
      ForecastScreen(forecast: _forecast),
      const OfficialGraphScreen(),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.directions_boat), label: "Passaggio"),
          NavigationDestination(icon: Icon(Icons.map), label: "Mappa"),
          NavigationDestination(icon: Icon(Icons.list), label: "Previsioni"),
          NavigationDestination(icon: Icon(Icons.public), label: "Ufficiale"),
        ],
      ),
    );
  }

  Widget _buildPassageStatusScreen() {
    final currentVal = _currentLevel?.valueInCm ?? 0.0;
    
    // IMPORTANT: Prioritize REAL TIME sensor data for "Current State"
    final isCurrentlySafe = currentVal <= _maxSafeHeight;

    // Trend Calculation - Use REAL-TIME sensor value
    final trend = TideMath.getTrend(currentVal, _forecast);
    IconData trendIcon;
    Color trendColor = Colors.grey;
    if (trend > 0) {
      trendIcon = Icons.arrow_upward_rounded;
      trendColor = Colors.orange.shade800;
    } else if (trend < 0) {
      trendIcon = Icons.arrow_downward_rounded;
      trendColor = Colors.blue.shade800;
    } else {
      trendIcon = Icons.horizontal_rule_rounded;
    }
    
    // Theme Colors
    final bgColor = isCurrentlySafe ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE); 
    final mainColor = isCurrentlySafe ? const Color(0xFF2E7D32) : const Color(0xFFC62828); 
    
    // Calculate Windows (for the list)
    final allWindows = TideMath.findSafeWindows(_forecast, _maxSafeHeight);
    final now = DateTime.now();
    var windowsToShow = allWindows.where((w) => w.last.isAfter(now)).toList();
    
    String mainMessage = "";
    String subMessage = "";

    // Calculate "Until When" using the math model scanning forward from NOW
    final nextEventTime = TideMath.findNextCrossing(_forecast, _maxSafeHeight, isCurrentlySafe);
    
    // --- LIST MERGING LOGIC ---
    // If currently safe, ensure the list starts with "NOW"
    if (isCurrentlySafe) {
      final effectiveEndTime = nextEventTime ?? now.add(const Duration(hours: 24));
      
      if (windowsToShow.isEmpty) {
        windowsToShow.add([now, effectiveEndTime]);
      } else {
        final firstWin = windowsToShow.first;
        // Merge logic
        if (firstWin.first.isBefore(effectiveEndTime) || firstWin.first.difference(now).inMinutes < 30) {
            if (effectiveEndTime.isAfter(firstWin.first)) {
              final mergedEnd = firstWin.last.isAfter(effectiveEndTime) ? firstWin.last : effectiveEndTime;
              windowsToShow[0] = [now, mergedEnd];
            } else {
              windowsToShow.insert(0, [now, effectiveEndTime]);
            }
        } else {
           windowsToShow.insert(0, [now, effectiveEndTime]);
        }
      }
    }
    // ---------------------------
    
    // Flatten split windows by day for natural language
    final List<Map<String, dynamic>> dailySegments = _flattenAndGroupWindows(windowsToShow, now);

    if (isCurrentlySafe) {
      mainMessage = "VIA LIBERA";
      if (nextEventTime != null) {
         if (nextEventTime.difference(now).inHours > 24) {
             subMessage = "Nessun problema per le prossime 24h+";
         } else {
             subMessage = "fino alle ${_formatTimeNatural(nextEventTime)} di ${_getDayName(nextEventTime)}";
         }
      } else {
         subMessage = "Nessun rialzo critico previsto.";
      }
    } else {
      mainMessage = "NON PASSI";
      if (nextEventTime != null) {
          subMessage = "fino alle ${_formatTimeNatural(nextEventTime)} di ${_getDayName(nextEventTime)}";
      } else {
          subMessage = "Marea troppo alta per le prossime ore.";
      }
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.access_time_rounded), 
            color: Colors.black54,
            tooltip: "Vedi previsione",
            onPressed: _showPredictionTimer
          ),
          IconButton(
            icon: const Icon(Icons.refresh), 
            color: Colors.black54,
            tooltip: "Aggiorna dati",
            onPressed: _loadData
          ),
          IconButton(icon: Icon(Icons.settings, color: mainColor), onPressed: _showSettingsDialog)
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                 child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Section
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                           Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: mainColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isCurrentlySafe ? Icons.directions_boat : Icons.no_transfer,
                              size: 50,
                              color: mainColor,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            mainMessage,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 40, 
                              fontWeight: FontWeight.w900,
                              color: mainColor,
                              height: 1.0
                            ),
                          ),
                          const SizedBox(height: 10),
                           Text(
                            subMessage,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87
                            ),
                          ),
                           const SizedBox(height: 20),
                           Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "${currentVal.toStringAsFixed(0)} cm",
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold, 
                                    fontSize: 32,
                                    color: Colors.black87
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(trendIcon, color: trendColor, size: 32),
                              ],
                            ),
                           )
                        ],
                      ),
                    ),
                    
                    // Bottom Section
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))]
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
                            child: Text(
                              "Prossimi orari di passaggio",
                              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: dailySegments.length,
                            itemBuilder: (context, index) {
                              final item = dailySegments[index];
                              final dayName = item['day'] as String;
                              final desc = item['desc'] as String;
                              
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F8E9), 
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.green.shade200)
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 16, color: Colors.green),
                                    const SizedBox(width: 10),
                                    Text(dayName, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                                    const Spacer(),
                                    Text(desc, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 40), // Bottom padding
                        ],
                      ),
                    )
                  ],
                 ),
              ),
            );
          }
        ),
      ),
    );
  }

  // --- Natural Language Helpers ---

  String _formatTimeNatural(DateTime t) {
    // "1 e 45" instead of "1:45"
    final h = t.hour; // 0-23
    final m = t.minute;
    final mStr = m.toString().padLeft(2, '0');
    return "$h e $mStr"; // Simple: 13 e 10
  }

  List<Map<String, dynamic>> _flattenAndGroupWindows(List<List<DateTime>> windows, DateTime now) {
    List<Map<String, dynamic>> result = [];
    
    // We need to split windows across midnights to group by day properly
    // e.g. Mon 22:00 -> Tue 02:00 becomes:
    // Mon: dalle 22 e 00
    // Tue: fino alle 2 e 00
    
    // 1. Flatten into daily chunks
    List<_DailyChunk> chunks = [];
    
    for (var w in windows) {
      DateTime start = w.first;
      DateTime end = w.last;
      
      // If start is before now (merged current window), clap to now
      if (start.isBefore(now)) start = now;
      if (end.isBefore(start)) continue; // Safety check

      while (!isSameDay(start, end)) {
        // Chunk ends at midnight of the next day
        final nextMidnight = DateTime(start.year, start.month, start.day + 1);
        chunks.add(_DailyChunk(start, nextMidnight.subtract(const Duration(seconds: 1)))); // 23:59:59
        start = nextMidnight; // Start next chunk at 00:00
      }
      // Add remainder
      chunks.add(_DailyChunk(start, end));
    }

    // 2. Group by Day String
    final Map<String, List<_DailyChunk>> grouped = {};
    for (var chunk in chunks) {
      final key = _getDayName(chunk.start); // "Oggi", "Lunedi", etc.
      grouped.putIfAbsent(key, () => []).add(chunk);
    }
    
    // 3. Format strings per day
    // Possible cases per day:
    // A. Starts at 00:00 (or Now for Today) AND Ends at 23:59 -> "Sempre"
    // B. Starts at 00:00 (or Now) AND Ends at X -> "fino alle X"
    // C. Starts at X AND Ends at 23:59 -> "dalle X"
    // D. Starts at X AND Ends at Y -> "dalle X alle Y"
    
    // Note: A day might have multiple chunks (e.g. 00-02 and 22-24).
    // We iterate grouped keys in order implicitly? Ideally sort by date.
    
    // Let's rely on the original list order which is chronological.
    // We need to iterate the linked hash map keys in insertion order?
    // Map iterates keys in insertion order in Dart.
    
    final sortedKeys = grouped.keys.toList(); // Should be roughly ordered
    debugPrint("Sorted Keys: $sortedKeys");
    
    for (var day in sortedKeys) {
      final dayChunks = grouped[day];
      if (dayChunks == null) {
         debugPrint("ERROR: grouped[$day] is null!");
         continue;
      }
      for (var chunk in dayChunks) {
         String desc = "";
         final isStartOfDay = (chunk.start.hour == 0 && chunk.start.minute == 0) || (day == "oggi" && chunk.start.difference(now).inMinutes.abs() < 5);
         final isEndOfDay = (chunk.end.hour == 23 && chunk.end.minute >= 59);

         if (isStartOfDay && isEndOfDay) {
           desc = "Sempre";
         } else if (isStartOfDay) {
           desc = "fino alle ${_formatTimeNatural(chunk.end)}";
         } else if (isEndOfDay) {
           desc = "dalle ${_formatTimeNatural(chunk.start)}";
         } else {
           desc = "dalle ${_formatTimeNatural(chunk.start)} alle ${_formatTimeNatural(chunk.end)}";
         }
         
         result.add({
           'day': capitalize(day),
           'desc': desc
         });
      }
    }

    return result;
  }
  
  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  String _getDayName(DateTime date) {
    final now = DateTime.now();
    if (date.day == now.day && date.month == now.month) return "oggi";
    if (date.day == now.add(const Duration(days: 1)).day) return "domani";
    return DateFormat('EEEE', 'it_IT').format(date);
  }
}

class _DailyChunk {
  final DateTime start;
  final DateTime end;
  _DailyChunk(this.start, this.end);
}

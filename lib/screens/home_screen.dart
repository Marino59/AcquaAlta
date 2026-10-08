import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/tide_model.dart';
import '../services/tide_service.dart';
import '../services/preferences_service.dart';
import '../utils/tide_math.dart';
import '../utils/italian_date_helper.dart';
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
  DateTime? _selectedGraphDate;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    debugPrint("LOADING DATA...");
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _service.getCurrentTide(),
        _service.getForecast(),
      ]);
      final current = results[0] as TideLevel?;
      final forecast = results[1] as List<TideForecast>;
      debugPrint("Current Tide: ${current?.valueInCm}");
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
      if (mounted) {
        setState(() => _loading = false);
      }
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
                ItalianDateHelper.getDayNameNatural(target, now) == 'oggi' ? "Oggi" : "Domani",
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
      GraphScreen(
        forecast: _forecast,
        initialSelectedDate: _selectedGraphDate,
        onDateSelected: (date) {
          setState(() {
            _selectedGraphDate = date;
          });
        },
      ),
      MapScreen(tideLevel: _currentLevel?.valueInCm ?? (_forecast.isNotEmpty ? TideMath.estimateTideLevelFromList(DateTime.now(), _forecast) : 0.0)),
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
          NavigationDestination(icon: Icon(Icons.show_chart), label: "Grafico"),
          NavigationDestination(icon: Icon(Icons.map), label: "Mappa"),
          NavigationDestination(icon: Icon(Icons.list), label: "Previsioni"),
          NavigationDestination(icon: Icon(Icons.public), label: "Ufficiale"),
        ],
      ),
    );
  }

  Widget _buildPassageStatusScreen() {
    final bool hasSensor = _currentLevel != null;
    final double? sensorVal = _currentLevel?.valueInCm;
    final double? estimatedVal = _forecast.isNotEmpty
        ? TideMath.estimateTideLevelFromList(DateTime.now(), _forecast)
        : null;
    final double currentVal = sensorVal ?? estimatedVal ?? 0.0;
    final bool isDataAvailable = sensorVal != null || estimatedVal != null;
    
    // IMPORTANT: Prioritize REAL TIME sensor data for "Current State"
    final isCurrentlySafe = currentVal <= _maxSafeHeight;

    // Trend Calculation - Use REAL-TIME sensor value
    final trend = isDataAvailable ? TideMath.getTrend(currentVal, _forecast) : 0;
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
    final bgColor = !isDataAvailable
        ? Colors.grey.shade200
        : (isCurrentlySafe ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE)); 
    final mainColor = !isDataAvailable
        ? Colors.grey.shade700
        : (isCurrentlySafe ? const Color(0xFF2E7D32) : const Color(0xFFC62828)); 
    
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
    List<Map<String, dynamic>> dailySegments = [];
    try {
      dailySegments = _flattenAndGroupWindows(windowsToShow, now);
    } catch (e, stack) {
      debugPrint("Error in _flattenAndGroupWindows: $e\n$stack");
    }
    final uniqueDays = dailySegments.map((e) => e['day'] as String).toSet().toList();

    if (!isDataAvailable) {
      mainMessage = "DATI NON DISPONIBILI";
      subMessage = "Impossibile recuperare i dati dal Centro Maree.";
    } else if (isCurrentlySafe) {
      mainMessage = "VIA LIBERA";
      if (nextEventTime != null) {
         if (nextEventTime.difference(now).inHours > 24) {
             subMessage = "Nessun problema per le prossime 24h+";
         } else {
             subMessage = "fino alle ${ItalianDateHelper.formatTimeNatural(nextEventTime)} di ${ItalianDateHelper.getDayNameNatural(nextEventTime, now)}";
         }
      } else {
         subMessage = "Nessun rialzo critico previsto.";
      }
    } else {
      mainMessage = "NON PASSI";
      if (nextEventTime != null) {
          subMessage = "fino alle ${ItalianDateHelper.formatTimeNatural(nextEventTime)} di ${ItalianDateHelper.getDayNameNatural(nextEventTime, now)}";
      } else {
          subMessage = "Marea troppo alta per le prossime ore.";
      }
    }

    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.size.width > mediaQuery.size.height;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: isLandscape ? 40 : 48,
        title: isLandscape 
            ? Text("Passaggio Barca", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87))
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.access_time_rounded), 
            color: Colors.black54,
            tooltip: "Vedi previsione ad un'ora specifica",
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
        child: isLandscape
            ? _buildLandscapePassageLayout(
                mainColor: mainColor,
                isCurrentlySafe: isCurrentlySafe,
                mainMessage: mainMessage,
                subMessage: subMessage,
                isDataAvailable: isDataAvailable,
                currentVal: currentVal,
                trendIcon: trendIcon,
                trendColor: trendColor,
                hasSensor: hasSensor,
                estimatedVal: estimatedVal,
                dailySegments: dailySegments,
                uniqueDays: uniqueDays,
              )
            : _buildPortraitPassageLayout(
                mainColor: mainColor,
                isCurrentlySafe: isCurrentlySafe,
                mainMessage: mainMessage,
                subMessage: subMessage,
                isDataAvailable: isDataAvailable,
                currentVal: currentVal,
                trendIcon: trendIcon,
                trendColor: trendColor,
                hasSensor: hasSensor,
                estimatedVal: estimatedVal,
                dailySegments: dailySegments,
                uniqueDays: uniqueDays,
              ),
      ),
    );
  }

  Widget _buildLandscapePassageLayout({
    required Color mainColor,
    required bool isCurrentlySafe,
    required String mainMessage,
    required String subMessage,
    required bool isDataAvailable,
    required double currentVal,
    required IconData trendIcon,
    required Color trendColor,
    required bool hasSensor,
    required double? estimatedVal,
    required List<Map<String, dynamic>> dailySegments,
    required List<String> uniqueDays,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left column: Status Card (~45%)
        Expanded(
          flex: 5,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 66,
                    height: 66,
                    decoration: BoxDecoration(
                      color: mainColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isCurrentlySafe ? Icons.directions_boat : Icons.no_transfer,
                      size: 36,
                      color: mainColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    mainMessage,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 30, 
                      fontWeight: FontWeight.w900,
                      color: mainColor,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subMessage,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isDataAvailable ? "${currentVal.toStringAsFixed(0)} cm" : "-- cm",
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold, 
                                fontSize: 24,
                                color: Colors.black87,
                              ),
                            ),
                            if (isDataAvailable) ...[
                              const SizedBox(width: 6),
                              Icon(trendIcon, color: trendColor, size: 24),
                            ],
                          ],
                        ),
                        if (isDataAvailable && !hasSensor && estimatedVal != null)
                          Text(
                            "(stima da previsione)",
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Right column: "Prossimi orari di passaggio" Card (~55%)
        Expanded(
          flex: 6,
          child: Container(
            margin: const EdgeInsets.fromLTRB(0, 4, 12, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 2))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      const Icon(Icons.schedule, size: 18, color: Colors.black87),
                      const SizedBox(width: 8),
                      Text(
                        "Prossimi orari di passaggio",
                        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                Expanded(
                  child: dailySegments.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              isDataAvailable
                                  ? "Nessun passaggio sicuro previsto per ${_maxSafeHeight.round()} cm nelle prossime ore."
                                  : "In attesa dei dati di previsione...",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 13),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          itemCount: dailySegments.length,
                          itemBuilder: (context, index) => _buildPassageTile(dailySegments[index], uniqueDays),
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPortraitPassageLayout({
    required Color mainColor,
    required bool isCurrentlySafe,
    required String mainMessage,
    required String subMessage,
    required bool isDataAvailable,
    required double currentVal,
    required IconData trendIcon,
    required Color trendColor,
    required bool hasSensor,
    required double? estimatedVal,
    required List<Map<String, dynamic>> dailySegments,
    required List<String> uniqueDays,
  }) {
    return Column(
      children: [
        // Top Section: Status
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
          child: Column(
            children: [
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  color: mainColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCurrentlySafe ? Icons.directions_boat : Icons.no_transfer,
                  size: 40,
                  color: mainColor,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                mainMessage,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 34, 
                  fontWeight: FontWeight.w900,
                  color: mainColor,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subMessage,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isDataAvailable ? "${currentVal.toStringAsFixed(0)} cm" : "-- cm",
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold, 
                            fontSize: 28,
                            color: Colors.black87,
                          ),
                        ),
                        if (isDataAvailable) ...[
                          const SizedBox(width: 8),
                          Icon(trendIcon, color: trendColor, size: 28),
                        ],
                      ],
                    ),
                    if (isDataAvailable && !hasSensor && estimatedVal != null)
                      Text(
                        "(stima da previsione)",
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Bottom Section: Expand to remaining screen height!
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                  child: Row(
                    children: [
                      const Icon(Icons.schedule, size: 20, color: Colors.black87),
                      const SizedBox(width: 8),
                      Text(
                        "Prossimi orari di passaggio",
                        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, indent: 20, endIndent: 20),
                Expanded(
                  child: dailySegments.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Text(
                              isDataAvailable
                                  ? "Nessun passaggio sicuro previsto per ${_maxSafeHeight.round()} cm nelle prossime ore.\nPuoi modificare l'altezza limite barca nelle impostazioni in alto."
                                  : "In attesa dei dati di previsione...",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 14),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          itemCount: dailySegments.length,
                          itemBuilder: (context, index) => _buildPassageTile(dailySegments[index], uniqueDays),
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPassageTile(Map<String, dynamic> item, List<String> uniqueDays) {
    final dayName = item['day'] as String;
    final desc = item['desc'] as String;
    
    final dayIndex = uniqueDays.indexOf(dayName);
    final colorIndex = dayIndex != -1 ? dayIndex % 4 : 0;
    
    final bgColors = [
      Colors.pink.withOpacity(0.12),
      Colors.amber.withOpacity(0.15),
      Colors.green.withOpacity(0.12),
      Colors.lightBlue.withOpacity(0.12),
    ];
    
    final borderColors = [
      Colors.pink.withOpacity(0.35),
      Colors.amber.withOpacity(0.40),
      Colors.green.withOpacity(0.35),
      Colors.lightBlue.withOpacity(0.35),
    ];
    
    final textColors = [
      Colors.pink.shade900,
      Colors.amber.shade900,
      Colors.green.shade900,
      Colors.lightBlue.shade900,
    ];
    
    final iconColors = [
      Colors.pink,
      Colors.amber.shade800,
      Colors.green,
      Colors.lightBlue,
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: bgColors[colorIndex], 
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColors[colorIndex])
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedGraphDate = item['date'] as DateTime?;
              _currentIndex = 1; // Switches to "Grafico" tab
            });
          },
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: iconColors[colorIndex]),
                const SizedBox(width: 8),
                Text(
                  dayName, 
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold, 
                    fontSize: 15,
                    color: textColors[colorIndex]
                  )
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    desc, 
                    textAlign: TextAlign.end,
                    style: GoogleFonts.outfit(
                      fontSize: 15, 
                      fontWeight: FontWeight.bold, 
                      color: Colors.black87
                    )
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Natural Language Helpers ---

  List<Map<String, dynamic>> _flattenAndGroupWindows(List<List<DateTime>> windows, DateTime now) {
    List<Map<String, dynamic>> result = [];
    List<_DailyChunk> chunks = [];
    
    for (var w in windows) {
      DateTime start = w.first;
      DateTime end = w.last;
      
      if (start.isBefore(now)) start = now;
      if (end.isBefore(start)) continue;

      while (!isSameDay(start, end)) {
        final nextMidnight = DateTime(start.year, start.month, start.day + 1);
        chunks.add(_DailyChunk(start, nextMidnight.subtract(const Duration(seconds: 1))));
        start = nextMidnight;
      }
      chunks.add(_DailyChunk(start, end));
    }

    final Map<String, List<_DailyChunk>> grouped = {};
    for (var chunk in chunks) {
      final key = ItalianDateHelper.getDayNameNatural(chunk.start, now);
      grouped.putIfAbsent(key, () => []).add(chunk);
    }
    
    final sortedKeys = grouped.keys.toList();
    for (var day in sortedKeys) {
      final dayChunks = grouped[day];
      if (dayChunks == null) continue;
      for (var chunk in dayChunks) {
         String desc = "";
         final isStartOfDay = (chunk.start.hour == 0 && chunk.start.minute == 0) || (day == "oggi" && chunk.start.difference(now).inMinutes.abs() < 5);
         final isEndOfDay = (chunk.end.hour == 23 && chunk.end.minute >= 59);

         if (isStartOfDay && isEndOfDay) {
           desc = "Sempre";
         } else if (isStartOfDay) {
           desc = "fino alle ${ItalianDateHelper.formatTimeNatural(chunk.end)}";
         } else if (isEndOfDay) {
           desc = "dalle ${ItalianDateHelper.formatTimeNatural(chunk.start)}";
         } else {
           desc = "dalle ${ItalianDateHelper.formatTimeNatural(chunk.start)} alle ${ItalianDateHelper.formatTimeNatural(chunk.end)}";
         }
         
         result.add({
           'day': ItalianDateHelper.capitalize(day),
           'desc': desc,
           'date': chunk.start,
         });
      }
    }

    return result;
  }
  
  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _DailyChunk {
  final DateTime start;
  final DateTime end;
  _DailyChunk(this.start, this.end);
}

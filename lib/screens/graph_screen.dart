import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/tide_model.dart';
import '../utils/tide_math.dart';
import '../services/preferences_service.dart';


class GraphScreen extends StatefulWidget {
  final List<TideForecast> forecast;

  const GraphScreen({super.key, required this.forecast});

  @override
  State<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen> {
  final PreferencesService _prefs = PreferencesService();
  double _maxSafeHeight = 80.0;
  List<MapEntry<DateTime, double>> _points = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _points = TideMath.generateCurve(widget.forecast);
  }

  Future<void> _loadSettings() async {
    final h = await _prefs.getMaxSafeHeight();
    setState(() {
      _maxSafeHeight = h;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_points.isEmpty) {
      return const Center(child: Text("Dati insufficienti per il grafico"));
    }

    final minX = _points.first.key.millisecondsSinceEpoch.toDouble();
    final maxX = _points.last.key.millisecondsSinceEpoch.toDouble();
    // Y Axis Padding
    final minY = _points.map((e) => e.value).reduce((a, b) => a < b ? a : b) - 10;
    final maxY = _points.map((e) => e.value).reduce((a, b) => a > b ? a : b) + 10;
    
    // Ensure threshold is visible
    final absoluteMaxY = _maxSafeHeight > maxY ? _maxSafeHeight + 10 : maxY;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Text(
                "Andamento Marea",
                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Chip(
                label: Text("Limite: ${_maxSafeHeight.toStringAsFixed(0)} cm"),
                backgroundColor: Colors.red.shade100,
                labelStyle: const TextStyle(color: Colors.red),
              )
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                minX: minX,
                maxX: maxX,
                minY: minY,
                maxY: absoluteMaxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withOpacity(0.1),
                    strokeWidth: 1,
                  ),
                   getDrawingVerticalLine: (value) => FlLine(
                    color: Colors.grey.withOpacity(0.1),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          "${value.toInt()}",
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1000 * 60 * 60 * 6, // 6 hours
                      getTitlesWidget: (value, meta) {
                        final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            DateFormat('HH:mm').format(date),
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  // Actual Tide Curve
                  LineChartBarData(
                    spots: _points.map((e) => FlSpot(
                      e.key.millisecondsSinceEpoch.toDouble(), 
                      e.value
                    )).toList(),
                    isCurved: true,
                    color: Colors.blueAccent,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true, 
                      color: Colors.blueAccent.withOpacity(0.1)
                    ),
                  ),
                  // Limit Line (Not supported directly as a line, using a constant line)
                ],
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: _maxSafeHeight,
                      color: Colors.red,
                      strokeWidth: 2,
                      dashArray: [5, 5],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        padding: const EdgeInsets.only(right: 5, bottom: 5),
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        labelResolver: (line) => "LIMIT",
                      ),
                    ),
                  ],
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    // tooltipBgColor: Colors.blueGrey, older versions
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final date = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
                        return LineTooltipItem(
                          "${DateFormat('HH:mm').format(date)}\n${spot.y.toStringAsFixed(1)} cm",
                          const TextStyle(color: Colors.white),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

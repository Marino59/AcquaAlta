import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/tide_model.dart';


class ForecastScreen extends StatelessWidget {
  final List<TideForecast> forecast;

  const ForecastScreen({super.key, required this.forecast});

  @override
  Widget build(BuildContext context) {
    if (forecast.isEmpty) {
      return const Center(child: Text("Nessuna previsione disponibile"));
    }

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          title: Text("Previsioni", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.black87)),
          backgroundColor: Colors.white,
          elevation: 0,
          floating: true,
          centerTitle: true,
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              return _buildForecastItem(forecast[index]);
            },
            childCount: forecast.length,
          ),
        ),
      ],
    );
  }

  Widget _buildForecastItem(TideForecast item) {
    final isMax = item.type == 'max';
    final dateStr = DateFormat('EEE d MMM', 'it_IT').format(item.extremeDate);
    final timeStr = DateFormat('HH:mm').format(item.extremeDate);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border(left: BorderSide(
          color: isMax ? Colors.redAccent : Colors.green,
          width: 4
        ))
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateStr.toUpperCase(),
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                timeStr,
                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Icon(
                    isMax ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                    color: isMax ? Colors.redAccent : Colors.green,
                    size: 20,
                  ),
                   Text(
                    "${item.value} cm",
                    style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.black87),
                  ),
                ],
              ),
              Text(
                isMax ? "Massima" : "Minima",
                style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
              )
            ],
          )
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.2, end: 0);
  }
}

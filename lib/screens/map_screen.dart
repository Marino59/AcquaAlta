import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';

class MapScreen extends StatefulWidget {
  final double tideLevel;
  const MapScreen({super.key, this.tideLevel = 0.0});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Center of Venice
  final LatLng _center = const LatLng(45.4340, 12.3385);
  final MapController _mapController = MapController();

  // HARDCODED DEMO DATA FOR PASSERELLE (Safe Routes)
  final List<LatLng> _demoSafeRoute1 = [
    const LatLng(45.4310, 12.3280), // Zattere
    const LatLng(45.4312, 12.3285),
    const LatLng(45.4315, 12.3290),
  ];

  // SAN MARCO POLYGON (Approximate)
  final List<LatLng> _sanMarcoPolygon = [
    const LatLng(45.4342, 12.3385),
    const LatLng(45.4335, 12.3380),
    const LatLng(45.4332, 12.3395),
    const LatLng(45.4338, 12.3400),
  ];
  
  // RIALTO POLYGON (Approximate - Market Area)
  final List<LatLng> _rialtoPolygon = [
    const LatLng(45.4382, 12.3355),
    const LatLng(45.4385, 12.3360),
    const LatLng(45.4380, 12.3365),
    const LatLng(45.4375, 12.3360),
  ];

  // FERROVIA/P.LE ROMA (Approximate)
  final List<LatLng> _ferroviaPolygon = [
    const LatLng(45.4410, 12.3210),
    const LatLng(45.4415, 12.3215),
    const LatLng(45.4410, 12.3225),
    const LatLng(45.4405, 12.3220),
  ];

  // ZATTERE (Approximate - Waterfront)
  final List<LatLng> _zatterePolygon = [
    const LatLng(45.4295, 12.3250),
    const LatLng(45.4298, 12.3290),
    const LatLng(45.4292, 12.3290),
    const LatLng(45.4290, 12.3250),
  ];

  @override
  Widget build(BuildContext context) {
    // Flood Thresholds (approximate logic)
    bool isSanMarcoFlooded = widget.tideLevel >= 80;
    bool isRialtoFlooded = widget.tideLevel >= 105;
    bool isZattereFlooded = widget.tideLevel >= 110;
    bool isFerroviaFlooded = widget.tideLevel >= 120;
    
    // Check if ANY flooding is occurring for alert
    bool anyFlood = isSanMarcoFlooded || isRialtoFlooded || isZattereFlooded || isFerroviaFlooded;
    List<String> floodedAreas = [];
    if (isSanMarcoFlooded) floodedAreas.add("San Marco");
    if (isRialtoFlooded) floodedAreas.add("Rialto");
    if (isZattereFlooded) floodedAreas.add("Zattere");
    if (isFerroviaFlooded) floodedAreas.add("Ferrovia");

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 15.0,
              minZoom: 13.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.venice_tide',
              ),
              // FLOOD ZONES
              PolygonLayer(
                polygons: [
                  if (isSanMarcoFlooded)
                    Polygon(
                      points: _sanMarcoPolygon,
                      color: Colors.red.withOpacity(0.4),
                      borderColor: Colors.red,
                      borderStrokeWidth: 2,
                      label: "Piazza San Marco",
                      labelStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
                    ),
                  if (isRialtoFlooded)
                    Polygon(
                      points: _rialtoPolygon,
                      color: Colors.red.withOpacity(0.4),
                      borderColor: Colors.red,
                      borderStrokeWidth: 2,
                      label: "Rialto",
                      labelStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
                    ),
                   if (isFerroviaFlooded)
                    Polygon(
                      points: _ferroviaPolygon,
                      color: Colors.red.withOpacity(0.4),
                      borderColor: Colors.red,
                      borderStrokeWidth: 2,
                      label: "Ferrovia",
                      labelStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
                    ),
                   if (isZattereFlooded)
                    Polygon(
                      points: _zatterePolygon,
                      color: Colors.red.withOpacity(0.4),
                      borderColor: Colors.red,
                      borderStrokeWidth: 2,
                      label: "Zattere",
                      labelStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
                    ),
                ],
              ),
              // SAFE ROUTES
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _demoSafeRoute1,
                    strokeWidth: 4.0,
                    color: Colors.green, // "Safe" color
                  ),
                ],
              ),
              // Marker for User Location (Mock)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _center,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.location_on, color: Colors.blue, size: 40),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Column(
              children: [
                 Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 4))
                    ]
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12, height: 12, 
                        decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Text("Passerelle", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 20),
                       Container(
                        width: 12, height: 12, 
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Text("Zone Allagate", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                if (anyFlood)
                 Padding(
                   padding: const EdgeInsets.only(top: 10),
                   child: Container(
                     padding: const EdgeInsets.all(12),
                     decoration: BoxDecoration(
                       color: Colors.red.shade100,
                       borderRadius: BorderRadius.circular(16)
                     ),
                     child: Text(
                        "Zone a rischio: ${floodedAreas.join(", ")}",
                        style: GoogleFonts.outfit(color: Colors.red.shade900, fontSize: 13, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                     ),
                   ),
                 )
              ],
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _mapController.move(_center, 16.0);
        },
        child: const Icon(Icons.my_location),
      ),
    );
  }
}

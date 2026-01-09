import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';

class MapPicker extends StatefulWidget {
  final LatLng initialPosition;
  const MapPicker({super.key, required this.initialPosition});

  @override
  State<MapPicker> createState() => _MapPickerState();
}

class _MapPickerState extends State<MapPicker> {
  late MapController _mapController;
  String _address = "Fetching address...";
  String _subAddress = "Point the pin at a location";
  String _coordsDisplay = "";

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _fetchAddress(widget.initialPosition);
  }

  Future<void> _fetchAddress(LatLng pos) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];

        setState(() {
          // 1. FILTER PLUS CODES: If street contains '+', use a descriptive area name instead
          String street = place.street ?? "";
          if (street.contains('+') || street.toLowerCase().contains('unnamed')) {
            _address = place.thoroughfare?.isNotEmpty == true
                ? place.thoroughfare!
                : (place.subLocality?.isNotEmpty == true ? place.subLocality! : "Specific Location");
          } else {
            _address = street;
          }

          // 2. BUILD SUB-ADDRESS: More detailed context
          _subAddress = "${place.subLocality ?? ''}, ${place.locality ?? ''}, ${place.postalCode ?? ''}".trim();

          // 3. COORDINATES: The absolute backup for accuracy
          _coordsDisplay = "${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}";
        });
      }
    } catch (e) {
      setState(() => _address = "Unknown Location");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Set Precise Location", style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initialPosition,
              initialZoom: 18.0, // Closer zoom for better identification
              onMapEvent: (event) {
                if (event is MapEventMoveEnd) {
                  _fetchAddress(_mapController.camera.center);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.adar',
              ),
            ],
          ),

          // THE PIN
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Icon(Icons.location_on, size: 50, color: Colors.red[800]),
            ),
          ),

          // PROFESSIONAL DETAILS CARD
          Positioned(
            bottom: 20, left: 15, right: 15,
            child: Card(
              elevation: 10,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // GPS BADGE: Shows the user we have the exact coordinates
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "GPS: $_coordsDisplay",
                        style: const TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.location_city, color: Colors.blue, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(_address,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, letterSpacing: -0.5),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(_subAddress, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    const Divider(height: 30),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[900],
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        // Returns both the address and coordinates for the report
                        Navigator.pop(context, "$_address ($_coordsDisplay)");
                      },
                      child: const Text("Confirm Incident Spot",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
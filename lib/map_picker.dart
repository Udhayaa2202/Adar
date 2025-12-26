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
  String _address = "Move map to target location...";
  LatLng? _selectedCoords;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _selectedCoords = widget.initialPosition;
  }

  // Logic: Converts the map center coordinates into a Street Address
  Future<void> _fetchAddress(LatLng pos) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _address = "${place.street}, ${place.locality}";
          _selectedCoords = pos;
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
        title: const Text("Set Incident Location"),
        backgroundColor: const Color(0xFF0D1B2A),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initialPosition,
              initialZoom: 16,
              // WHY: This updates the address whenever the user stops moving the map
              onMapEvent: (event) {
                if (event is MapEventMoveEnd) {
                  _fetchAddress(_mapController.camera.center);
                }
              },
            ),
            children: [
              TileLayer(
                // DARK MODE TILES: Using CartoDB Dark Matter (Free & No Key needed)
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
              ),
            ],
          ),

          // THE FIXED RED PIN: Stays in the center while the map moves behind it
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 40), // Adjust icon to point exactly at center
              child: Icon(Icons.location_on, size: 50, color: Colors.redAccent),
            ),
          ),

          // CONFIRMATION PANEL
          Positioned(
            bottom: 30, left: 20, right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1B2A),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 10)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("INCIDENT AREA", style: TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(_address, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 14)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: () {
                      // RETURNS: Sends the address back to the Report Screen
                      Navigator.pop(context, _address);
                    },
                    child: const Text("Confirm Location", style: TextStyle(color: Colors.white)),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart'; // Required for the LatLng class
import 'package:adar/map_picker.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  // Variables to hold user selections
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  String _locationText = "Tap to get location";
  bool _isLoadingLocation = false;

  // --- LOGIC SECTION: Why and What ---

  // What: Fetches coordinates and turns them into a readable address.
  // Why: To provide specific incident location without the user typing it manually.
  Future<void> _getCurrentLocation() async {
    // What: Handles the flow from tapping the button to getting a confirmed address from the map.
    // Why: To ensure we have GPS permission before opening the Map Picker.
    Future<void> _getCurrentLocation() async {
      setState(() => _isLoadingLocation = true);

      try {
        // 1. Check if location services (GPS toggle) are enabled
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          setState(() {
            _locationText = "GPS is turned off";
            _isLoadingLocation = false;
          });
          return;
        }

        // 2. Check and Request Permissions
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            setState(() {
              _locationText = "Permission denied";
              _isLoadingLocation = false;
            });
            return;
          }
        }

        // 3. Get the initial position to center the map
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high
        );

        // 4. Open the MapPicker screen and WAIT for the user to confirm a spot
        // Make sure you have imported your MapPicker file at the top!
        final String? confirmedAddress = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MapPicker(
              initialPosition: LatLng(position.latitude, position.longitude),
            ),
          ),
        );

        // 5. Update UI with the result from the Map
        setState(() {
          if (confirmedAddress != null) {
            _locationText = confirmedAddress;
          }
          _isLoadingLocation = false;
        });

      } catch (e) {
        debugPrint("Location Error: $e");
        setState(() {
          _locationText = "Error getting location";
          _isLoadingLocation = false;
        });
      }
    }
  }

  // What: Opens the System Calendar.
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != selectedDate) {
      setState(() => selectedDate = picked);
    }
  }

  // What: Opens the System Clock.
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && picked != selectedTime) {
      setState(() => selectedTime = picked);
    }
  }

  // --- UI SECTION ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        title: const Text("Submit Report"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Description Field
            const TextField(
              maxLines: 4,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Describe the activity...",
                hintStyle: TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 2. Date and Time Row (Uses Expanded to sit 50/50)
            Row(
              children: [
                Expanded(
                  child: _buildPickerBox(
                    label: "Date of Event",
                    value: selectedDate == null
                        ? "Select Date"
                        : DateFormat('dd/MM/yyyy').format(selectedDate!),
                    iconColor: Colors.blue,
                    onTap: () => _selectDate(context),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildPickerBox(
                    label: "Time of Event",
                    value: selectedTime == null
                        ? "Select Time"
                        : selectedTime!.format(context),
                    iconColor: Colors.blue,
                    onTap: () => _selectTime(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 3. Functional Location Selector
            // Why: Wrapped in InkWell so it responds to a tap.
            InkWell(
              onTap: _isLoadingLocation ? null : _getCurrentLocation,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    Icon(
                        _isLoadingLocation ? Icons.hourglass_top : Icons.location_on,
                        color: Colors.blue
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _isLoadingLocation ? "Fetching GPS..." : _locationText,
                        style: const TextStyle(color: Colors.white70),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white70),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            const Text("Add Evidence:", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),

            // 4. Evidence Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildEvidenceButton(Icons.camera_alt, "Photo", Colors.blue),
                _buildEvidenceButton(Icons.videocam, "Video", Colors.blueGrey),
                _buildEvidenceButton(Icons.mic, "Voice", Colors.redAccent),
              ],
            ),
            const SizedBox(height: 30),

            // 5. AI Tip Section
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Ai Tip", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 18)),
                  SizedBox(height: 5),
                  Text(
                    "Multiple reports indicate drug deals happening near this location. Be specific about what you saw.",
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // 6. Submit Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0056D2),
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              onPressed: () {
                // Future: Send all data to backend
              },
              child: const Text("Submit Report", style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Widget for Date/Time Boxes
  Widget _buildPickerBox({required String label, required String value, required Color iconColor, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: iconColor, fontSize: 12)),
            const SizedBox(height: 5),
            Text(value, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  // Helper Widget for circular evidence icons
  Widget _buildEvidenceButton(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          height: 60,
          width: 80,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
      ],
    );
  }
}
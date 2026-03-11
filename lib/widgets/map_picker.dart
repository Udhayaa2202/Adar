import 'dart:async';
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

  // --- SEARCH STATE ---
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  List<Location> _searchResults = [];
  bool _isSearching = false;
  bool _showResults = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _fetchAddress(widget.initialPosition);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _showResults = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 600), () {
      _searchLocation(query.trim());
    });
  }

  Future<void> _searchLocation(String query) async {
    setState(() => _isSearching = true);
    try {
      List<Location> locations = await locationFromAddress(query);
      if (mounted) {
        setState(() {
          _searchResults = locations;
          _showResults = locations.isNotEmpty;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _showResults = true;
          _isSearching = false;
        });
      }
    }
  }

  void _selectSearchResult(Location location) {
    final newPos = LatLng(location.latitude, location.longitude);
    _mapController.move(newPos, 17.0);
    _fetchAddress(newPos);
    setState(() {
      _showResults = false;
      _searchResults = [];
    });
    _searchFocus.unfocus();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _showResults = false;
    });
  }

  Future<void> _fetchAddress(LatLng pos) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(pos.latitude, pos.longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];

        setState(() {
          String street = place.street ?? "";
          if (street.contains('+') ||
              street.toLowerCase().contains('unnamed')) {
            _address = place.thoroughfare?.isNotEmpty == true
                ? place.thoroughfare!
                : (place.subLocality?.isNotEmpty == true
                    ? place.subLocality!
                    : "Specific Location");
          } else {
            _address = street;
          }

          _subAddress =
              "${place.subLocality ?? ''}, ${place.locality ?? ''}, ${place.postalCode ?? ''}"
                  .trim();
          _coordsDisplay =
              "${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}";
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
        title: const Text("Set Precise Location",
            style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Stack(
        children: [
          // --- MAP ---
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initialPosition,
              initialZoom: 18.0,
              onMapEvent: (event) {
                if (event is MapEventMoveEnd) {
                  _fetchAddress(_mapController.camera.center);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://mt1.google.com/vt/lyrs=r&x={x}&y={y}&z={z}',
                userAgentPackageName: 'com.example.adar',
              ),
            ],
          ),

          // --- CENTER PIN ---
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child:
                  Icon(Icons.location_on, size: 50, color: Colors.red[800]),
            ),
          ),

          // --- SEARCH BAR ---
          Positioned(
            top: 10,
            left: 15,
            right: 15,
            child: Column(
              children: [
                Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(12),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocus,
                    onChanged: _onSearchChanged,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (q) {
                      if (q.trim().isNotEmpty) _searchLocation(q.trim());
                    },
                    decoration: InputDecoration(
                      hintText: "Search location by name...",
                      hintStyle: TextStyle(
                          color: Colors.grey[500], fontSize: 14),
                      prefixIcon: const Icon(Icons.search,
                          color: Colors.blueGrey),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close,
                                  color: Colors.grey, size: 20),
                              onPressed: _clearSearch,
                            )
                          : (_isSearching
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2)),
                                )
                              : null),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                // --- SEARCH RESULTS DROPDOWN ---
                if (_showResults)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    constraints: const BoxConstraints(maxHeight: 220),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromRGBO(0, 0, 0, 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _searchResults.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(Icons.search_off,
                                    color: Colors.grey, size: 20),
                                SizedBox(width: 10),
                                Text("No results found",
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 14)),
                              ],
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            itemCount: _searchResults.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final loc = _searchResults[index];
                              return ListTile(
                                dense: true,
                                leading: Icon(Icons.place,
                                    color: Colors.red[700], size: 22),
                                title: Text(
                                  _searchController.text,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14),
                                ),
                                subtitle: Text(
                                  "${loc.latitude.toStringAsFixed(5)}, ${loc.longitude.toStringAsFixed(5)}",
                                  style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12),
                                ),
                                onTap: () => _selectSearchResult(loc),
                              );
                            },
                          ),
                  ),
              ],
            ),
          ),

          // --- DETAILS CARD ---
          Positioned(
            bottom: 20,
            left: 15,
            right: 15,
            child: Card(
              elevation: 10,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // GPS BADGE
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(33, 150, 243, 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "GPS: $_coordsDisplay",
                        style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.location_city,
                            color: Colors.blue, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(_address,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                  letterSpacing: -0.5),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(_subAddress,
                        style: TextStyle(
                            color: Colors.grey[600], fontSize: 13)),
                    const Divider(height: 30),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[900],
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.pop(context, {
                          'address': _address,
                          'latitude': _mapController.camera.center.latitude,
                          'longitude': _mapController.camera.center.longitude,
                        });
                      },
                      child: const Text("Confirm Incident Spot",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
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
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:adar/l10n/app_localizations.dart';

import 'package:adar/widgets/map_picker.dart';
import 'package:adar/screens/intelligent_reporter_chat.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _locationText;
  double? _incidentLat;
  double? _incidentLon;
  bool _isLoadingLocation = false;

  // --- TRUST SCORE TRACKERS ---
  bool _isFromGallery = false;
  bool _isMockLocation = false;

  File? _selectedImage;
  File? _selectedVideo;
  Map<String, double>? _capturedGps;

  final ImagePicker _picker = ImagePicker();
  VideoPlayerController? _videoController;
  final TextEditingController _descController = TextEditingController();

  @override
  void dispose() {
    _videoController?.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _dismissKeyboard() {
    FocusScopeNode currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus) {
      currentFocus.unfocus();
    }
  }

  /// Handles GPS capture and checks for Mock Location (Fake GPS)
  Future<void> _getCurrentLocation() async {
    _dismissKeyboard();
    setState(() => _isLoadingLocation = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // --- SCORING CHECK: DETECTION OF FAKE GPS ---
      setState(() {
        _isMockLocation = position.isMocked;
      });

      if (_isMockLocation) {
        _showSnackBar("Security Note: Automated location verification flagged.", isError: true);
      }

      if (!mounted) return;

      final dynamic result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MapPicker(
            initialPosition: LatLng(position.latitude, position.longitude),
          ),
        ),
      );

      if (result != null && result is Map<String, dynamic>) {
        setState(() {
          _locationText = result['address'];
          _incidentLat = result['latitude'];
          _incidentLon = result['longitude'];
        });
      }
    } catch (e) {
      _showSnackBar(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  /// Navigates to the AI Chat screen, passing all captured data and trust signals
  void _navigateToChat() {
    _dismissKeyboard();

    final locText = _locationText ?? AppLocalizations.of(context)!.tapToGetLocation;
    final isLocationSet = _locationText != null;

    final bool isValid = _descController.text.trim().isNotEmpty &&
        (_selectedImage != null || _selectedVideo != null) &&
        isLocationSet;

    if (!isValid) {
      _showSnackBar(AppLocalizations.of(context)!.fillAllFieldsError, isError: true);
      return;
    }

    if (_isFuture(_selectedDate, _selectedTime)) {
      _showSnackBar(AppLocalizations.of(context)!.futureDateError, isError: true);
      return;
    }

    // --- INTEGRATION: PASSING TRUST SIGNALS TO THE NEXT STAGE ---
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IntelligentReporterChat(
          description: _descController.text.trim(),
          location: locText,
          incidentDate: _selectedDate,
          incidentTime: _selectedTime,
          imageFile: _selectedImage,
          videoFile: _selectedVideo,
          isFromGallery: _isFromGallery,
          isMocked: _isMockLocation,
          capturedGps: _capturedGps,
          incidentLat: _incidentLat,
          incidentLon: _incidentLon,
        ),
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.blueAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _dismissKeyboard,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D1B2A),
          title: Text(AppLocalizations.of(context)!.submitReportTitle, style: const TextStyle(color: Colors.white)),
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(AppLocalizations.of(context)!.descriptionLabel),
              const SizedBox(height: 8),
              _buildDescriptionField(),
              const SizedBox(height: 20),
              _buildDateTimeSection(),
              const SizedBox(height: 20),
              _buildLocationRow(),
              const SizedBox(height: 30),
              _buildSectionHeader(AppLocalizations.of(context)!.evidenceLabel, color: Colors.white),
              const SizedBox(height: 15),
              _buildEvidenceButtons(),
              if (_selectedImage != null) _buildImagePreview(),
              if (_selectedVideo != null) _buildVideoPreview(),
              const SizedBox(height: 40),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {Color color = Colors.blue}) {
    return Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold));
  }

  Widget _buildDescriptionField() {
    return TextField(
      controller: _descController,
      maxLines: 4,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _dismissKeyboard(),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context)!.descriptionHint,
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
        helperText: AppLocalizations.of(context)!.descriptionHelper,
        helperStyle: const TextStyle(color: Colors.blueGrey, fontSize: 11),
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildDateTimeSection() {
    return Row(
      children: [
        Expanded(
          child: _buildPickerBox(
            label: AppLocalizations.of(context)!.dateLabel,
            value: _selectedDate == null ? "Select" : DateFormat('dd/MM/yy').format(_selectedDate!),
            onTap: () => _selectDate(context),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildPickerBox(
            label: AppLocalizations.of(context)!.timeLabel,
            value: _selectedTime == null ? "Select" : _selectedTime!.format(context),
            onTap: () => _selectTime(context),
          ),
        ),
      ],
    );
  }

  Widget _buildEvidenceButtons() {
    return Row(
      children: [
        _buildEvidenceButton(Icons.camera_alt, AppLocalizations.of(context)!.photoButton, Colors.blue, () => _showPicker("Photo", _pickPhoto)),
        const SizedBox(width: 20),
        _buildEvidenceButton(Icons.videocam, AppLocalizations.of(context)!.videoButton, Colors.blueGrey, () => _showPicker("Video", _pickVideo)),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0056D2),
        minimumSize: const Size(double.infinity, 60),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      onPressed: _navigateToChat,
      child: Text(AppLocalizations.of(context)!.continueToAssistant, style: const TextStyle(fontSize: 18, color: Colors.white)),
    );
  }

  Future<void> _pickPhoto(ImageSource source) async {
    _isFromGallery = (source == ImageSource.gallery);

    final XFile? file = await _picker.pickImage(
      source: source,
    );
    if (file != null) {
      // CAPTURE DEVICE SIGNATURE (TIMESTAMPED GPS)
      try {
        Position pos = await Geolocator.getCurrentPosition();
        _capturedGps = {'latitude': pos.latitude, 'longitude': pos.longitude};
      } catch (e) {
        _capturedGps = null;
      }
      setState(() => _selectedImage = File(file.path));
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    // TRACK SOURCE FOR TRUST SCORING
    _isFromGallery = (source == ImageSource.gallery);

    final XFile? file = await _picker.pickVideo(source: source);
    if (file != null) {
      // CAPTURE DEVICE SIGNATURE (TIMESTAMPED GPS)
      try {
        Position pos = await Geolocator.getCurrentPosition();
        _capturedGps = {'latitude': pos.latitude, 'longitude': pos.longitude};
      } catch (e) {
        _capturedGps = null;
      }
      _selectedVideo = File(file.path);
      _videoController = VideoPlayerController.file(_selectedVideo!)
        ..initialize().then((_) => setState(() {}));
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        if (_isFuture(_selectedDate, _selectedTime)) {
          _selectedTime = null;
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      if (_isFuture(_selectedDate ?? DateTime.now(), picked)) {
        _showSnackBar(AppLocalizations.of(context)!.futureDateError, isError: true);
        return;
      }
      setState(() => _selectedTime = picked);
    }
  }

  bool _isFuture(DateTime? date, TimeOfDay? time) {
    if (date == null || time == null) return false;
    final now = DateTime.now();
    final selectedDateTime = DateTime(
      date.year, date.month, date.day,
      time.hour, time.minute,
    );
    return selectedDateTime.isAfter(now);
  }

  void _showPicker(String title, Function(ImageSource) onPick) {
    showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF0D1B2A),
        builder: (context) => Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
              leading: const Icon(Icons.camera, color: Colors.blue),
              title: Text("Take $title", style: const TextStyle(color: Colors.white)),
              onTap: () { Navigator.pop(context); onPick(ImageSource.camera); }
          ),
          ListTile(
              leading: const Icon(Icons.image, color: Colors.blue),
              title: Text("From Gallery", style: const TextStyle(color: Colors.white)),
              onTap: () { Navigator.pop(context); onPick(ImageSource.gallery); }
          ),
        ])
    );
  }

  void _viewImage() {
    if (_selectedImage == null) return;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.file(_selectedImage!),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _viewVideo() {
    if (_selectedVideo == null || _videoController == null) return;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: Colors.black,
            insetPadding: EdgeInsets.zero,
            child: Stack(
              children: [
                Center(
                  child: AspectRatio(
                    aspectRatio: _videoController!.value.aspectRatio,
                    child: VideoPlayer(_videoController!),
                  ),
                ),
                Positioned(
                  top: 40,
                  right: 20,
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 50,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: CircleAvatar(
                      backgroundColor: Colors.blueAccent.withValues(alpha: 0.8),
                      radius: 30,
                      child: IconButton(
                        iconSize: 35,
                        icon: Icon(
                          _videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            _videoController!.value.isPlaying
                                ? _videoController!.pause()
                                : _videoController!.play();
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _previewWrapper({required String label, required Widget child, required VoidCallback onDelete, required VoidCallback onView}) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: const TextStyle(color: Colors.blueAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    GestureDetector(
                      onTap: onView,
                      child: const Icon(Icons.visibility_outlined, color: Colors.blueAccent, size: 20),
                    ),
                    const SizedBox(width: 15),
                    GestureDetector(
                      onTap: onDelete,
                      child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
            child: GestureDetector(
              onTap: onView,
              child: SizedBox(
                height: 250,
                width: double.infinity,
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() => _previewWrapper(label: "Photo Proof", onDelete: () => setState(() => _selectedImage = null), onView: _viewImage, child: Image.file(_selectedImage!, fit: BoxFit.cover));

  Widget _buildVideoPreview() => _previewWrapper(label: "Video Proof", onDelete: () { _videoController?.pause(); setState(() { _selectedVideo = null; _videoController = null; }); }, onView: _viewVideo,
      child: _videoController != null && _videoController!.value.isInitialized ? VideoPlayer(_videoController!) : const Center(child: CircularProgressIndicator())
  );

  Widget _buildPickerBox({required String label, required String value, required VoidCallback onTap}) {
    return InkWell(onTap: onTap, child: Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white24)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: Colors.blue, fontSize: 12)), const SizedBox(height: 5), Text(value, style: const TextStyle(color: Colors.white))])));
  }

  Widget _buildEvidenceButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return Column(children: [InkWell(onTap: onTap, child: Container(height: 60, width: 80, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: Colors.white))), const SizedBox(height: 5), Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70))]);
  }

  Widget _buildLocationRow() {
    return InkWell(onTap: _isLoadingLocation ? null : _getCurrentLocation, child: Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
        child: Row(children: [Icon(_isLoadingLocation ? Icons.hourglass_top : Icons.location_on, color: Colors.blue), const SizedBox(width: 10), Expanded(child: Text(_locationText ?? AppLocalizations.of(context)!.tapToGetLocation, style: const TextStyle(color: Colors.white70), overflow: TextOverflow.ellipsis)), const Icon(Icons.chevron_right, color: Colors.white70)])));
  }
}
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

// Internal Project Imports - Ensure these match your folder structure
import 'package:adar/widgets/map_picker.dart';
import 'package:adar/screens/intelligent_reporter_chat.dart';

/// Screen responsible for capturing initial incident intelligence.
class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  // --- State Management ---
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _locationText = "Tap to get location";
  bool _isLoadingLocation = false;

  File? _selectedImage;
  File? _selectedVideo;

  final ImagePicker _picker = ImagePicker();
  VideoPlayerController? _videoController;
  final TextEditingController _descController = TextEditingController();

  @override
  void dispose() {
    _videoController?.dispose();
    _descController.dispose();
    super.dispose();
  }

  // --- Logic Layer ---

  void _dismissKeyboard() {
    FocusScopeNode currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus) {
      currentFocus.unfocus();
    }
  }

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

      if (!mounted) return;

      final String? result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MapPicker(
            initialPosition: LatLng(position.latitude, position.longitude),
          ),
        ),
      );

      if (result != null) setState(() => _locationText = result);
    } catch (e) {
      _showSnackBar(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  void _navigateToChat() {
    _dismissKeyboard();

    final bool isValid = _descController.text.trim().isNotEmpty &&
        (_selectedImage != null || _selectedVideo != null) &&
        _locationText != "Tap to get location";

    if (!isValid) {
      _showSnackBar("Please provide Description, Evidence, and Location.", isError: true);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IntelligentReporterChat(
          description: _descController.text.trim(),
          location: _locationText,
          incidentDate: _selectedDate,
          incidentTime: _selectedTime,
          imageFile: _selectedImage,
          videoFile: _selectedVideo,
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

  // --- UI Components ---

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _dismissKeyboard,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D1B2A),
          title: const Text("Submit Report", style: TextStyle(color: Colors.white)),
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader("Description *"),
              const SizedBox(height: 8),
              _buildDescriptionField(),
              const SizedBox(height: 20),
              _buildDateTimeSection(),
              const SizedBox(height: 20),
              _buildLocationRow(),
              const SizedBox(height: 30),
              _buildSectionHeader("Evidence *", color: Colors.white),
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
      // This ensures the "Done" button appears on the keyboard
      textInputAction: TextInputAction.done,
      // This hides the keyboard automatically when "Done" is pressed
      onSubmitted: (_) => _dismissKeyboard(),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: "What did you see? (e.g., Person hiding a package...)",
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
        helperText: "Tip: Include clothing, physical features, or specific actions.",
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
            label: "Date",
            value: _selectedDate == null ? "Select" : DateFormat('dd/MM/yy').format(_selectedDate!),
            onTap: () => _selectDate(context),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildPickerBox(
            label: "Time",
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
        _buildEvidenceButton(Icons.camera_alt, "Photo", Colors.blue, () => _showPicker("Photo", _pickPhoto)),
        const SizedBox(width: 20),
        _buildEvidenceButton(Icons.videocam, "Video", Colors.blueGrey, () => _showPicker("Video", _pickVideo)),
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
      child: const Text("Continue to Assistant", style: TextStyle(fontSize: 18, color: Colors.white)),
    );
  }

  // --- Helper UI & Pickers (Condensed) ---

  Future<void> _pickPhoto(ImageSource source) async {
    final XFile? file = await _picker.pickImage(source: source, imageQuality: 70);
    if (file != null) setState(() => _selectedImage = File(file.path));
  }

  Future<void> _pickVideo(ImageSource source) async {
    final XFile? file = await _picker.pickVideo(source: source);
    if (file != null) {
      _selectedVideo = File(file.path);
      _videoController = VideoPlayerController.file(_selectedVideo!)
        ..initialize().then((_) => setState(() {}));
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2024), lastDate: DateTime(2030));
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) setState(() => _selectedTime = picked);
  }

  void _showPicker(String title, Function(ImageSource) onPick) {
    showModalBottomSheet(context: context, backgroundColor: const Color(0xFF0D1B2A), builder: (context) => Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(leading: const Icon(Icons.camera, color: Colors.blue), title: Text("Take $title", style: const TextStyle(color: Colors.white)), onTap: () { Navigator.pop(context); onPick(ImageSource.camera); }),
      ListTile(leading: const Icon(Icons.image, color: Colors.blue), title: Text("From Gallery", style: const TextStyle(color: Colors.white)), onTap: () { Navigator.pop(context); onPick(ImageSource.gallery); }),
    ]));
  }

  // --- Wrapper Widgets for Previews ---
  Widget _buildImagePreview() => _previewWrapper(label: "Photo Proof", onDelete: () => setState(() => _selectedImage = null), child: Image.file(_selectedImage!, fit: BoxFit.cover));

  Widget _buildVideoPreview() => _previewWrapper(label: "Video Proof", onDelete: () { _videoController?.pause(); setState(() { _selectedVideo = null; _videoController = null; }); },
      child: _videoController != null && _videoController!.value.isInitialized ? VideoPlayer(_videoController!) : const Center(child: CircularProgressIndicator())
  );

  Widget _previewWrapper({required String label, required Widget child, required VoidCallback onDelete}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(top: 20, bottom: 8), child: Text(label, style: const TextStyle(color: Colors.blue, fontSize: 12))),
      Stack(children: [
        Container(height: 200, width: double.infinity, decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), color: Colors.white10), child: ClipRRect(borderRadius: BorderRadius.circular(15), child: child)),
        Positioned(right: 10, top: 10, child: GestureDetector(onTap: onDelete, child: const CircleAvatar(backgroundColor: Colors.black54, radius: 15, child: Icon(Icons.close, color: Colors.white, size: 18))))
      ])
    ]);
  }

  Widget _buildPickerBox({required String label, required String value, required VoidCallback onTap}) {
    return InkWell(onTap: onTap, child: Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white24)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: Colors.blue, fontSize: 12)), const SizedBox(height: 5), Text(value, style: const TextStyle(color: Colors.white))])));
  }

  Widget _buildEvidenceButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return Column(children: [InkWell(onTap: onTap, child: Container(height: 60, width: 80, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: Colors.white))), const SizedBox(height: 5), Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70))]);
  }

  Widget _buildLocationRow() {
    return InkWell(onTap: _isLoadingLocation ? null : _getCurrentLocation, child: Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
        child: Row(children: [Icon(_isLoadingLocation ? Icons.hourglass_top : Icons.location_on, color: Colors.blue), const SizedBox(width: 10), Expanded(child: Text(_locationText, style: const TextStyle(color: Colors.white70), overflow: TextOverflow.ellipsis)), const Icon(Icons.chevron_right, color: Colors.white70)])));
  }
}
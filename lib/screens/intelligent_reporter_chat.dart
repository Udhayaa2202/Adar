import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:adar/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'report_success_screen.dart';

class IntelligentReporterChat extends StatefulWidget {
  final String description;
  final String location;
  final DateTime? incidentDate;
  final TimeOfDay? incidentTime;
  final File? imageFile;
  final File? videoFile;

  const IntelligentReporterChat({
    super.key,
    required this.description,
    required this.location,
    this.incidentDate,
    this.incidentTime,
    this.imageFile,
    this.videoFile,
  });

  @override
  State<IntelligentReporterChat> createState() => _IntelligentReporterChatState();
}

class _IntelligentReporterChatState extends State<IntelligentReporterChat> {
  final List<Map<String, dynamic>> _messages = [];
  final Map<String, String> _answers = {};
  bool _isTyping = false;
  bool _isFinalized = false;
  bool _isUploading = false;
  int _currentQuestionIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startChat();
    });
  }

  void _startChat() async {
    _addAssistantMessage(AppLocalizations.of(context)!.assistantIntro);
    await Future.delayed(const Duration(seconds: 1));
    _askNextQuestion();
  }

  void _addAssistantMessage(String text) {
    if (mounted) setState(() => _messages.add({"isUser": false, "text": text}));
  }

  void _askNextQuestion() {
    final List<Map<String, dynamic>> questions = [
      {
        "id": "frequency",
        "text": AppLocalizations.of(context)!.q_frequency,
        "options": [
          AppLocalizations.of(context)!.q_frequency_opt1,
          AppLocalizations.of(context)!.q_frequency_opt2,
          AppLocalizations.of(context)!.q_frequency_opt3
        ]
      },
      {
        "id": "sensitive_area",
        "text": AppLocalizations.of(context)!.q_sensitive_area,
        "options": [
          AppLocalizations.of(context)!.q_sensitive_area_opt1,
          AppLocalizations.of(context)!.q_sensitive_area_opt2
        ]
      },
      {
        "id": "activity_type",
        "text": AppLocalizations.of(context)!.q_activity_type,
        "options": [
          AppLocalizations.of(context)!.q_activity_type_opt1,
          AppLocalizations.of(context)!.q_activity_type_opt2,
          AppLocalizations.of(context)!.q_activity_type_opt3
        ]
      },
      {
        "id": "vehicles",
        "text": AppLocalizations.of(context)!.q_vehicles,
        "options": [
          AppLocalizations.of(context)!.q_vehicles_opt1,
          AppLocalizations.of(context)!.q_vehicles_opt2,
          AppLocalizations.of(context)!.q_vehicles_opt3
        ]
      },
      {
        "id": "people_count",
        "text": AppLocalizations.of(context)!.q_people_count,
        "options": [
          AppLocalizations.of(context)!.q_people_count_opt1,
          AppLocalizations.of(context)!.q_people_count_opt2,
          AppLocalizations.of(context)!.q_people_count_opt3
        ]
      },
    ];

    if (_currentQuestionIndex < questions.length) {
      setState(() => _isTyping = true);
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _isTyping = false;
            _messages.add({
              "isUser": false,
              "text": questions[_currentQuestionIndex]["text"],
              "options": questions[_currentQuestionIndex]["options"],
              "id": questions[_currentQuestionIndex]["id"]
            });
          });
        }
      });
    } else {
      setState(() => _isFinalized = true);
      _addAssistantMessage(AppLocalizations.of(context)!.assistantThanks);
    }
  }

  void _handleUserAnswer(String questionId, String answer) {
    setState(() {
      _answers[questionId] = answer;
      _messages.add({"isUser": true, "text": answer});
      if (_messages.length >= 2) _messages[_messages.length - 2].remove("options");
      _currentQuestionIndex++;
    });
    _askNextQuestion();
  }

  Future<void> _submitEverything() async {
    setState(() => _isUploading = true);
    final supabase = Supabase.instance.client;

    try {
      final String reportId = "ADAR-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";
      final prefs = await SharedPreferences.getInstance();
      final String userId = prefs.getString('anon_id') ?? "Unknown";
      Map<String, String> evidenceUrls = {};

      // --- 1. UPLOAD IMAGE TO SUPABASE ---
      if (widget.imageFile != null) {
        final path = 'evidence/$reportId/img_${DateTime.now().millisecondsSinceEpoch}.jpg';
        debugPrint("LOG: Attempting upload to app_evidence bucket...");

        try {
          final bytes = await widget.imageFile!.readAsBytes();

          await supabase.storage
              .from('app_evidence')
              .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          )
              .timeout(const Duration(seconds: 120));

          final String publicUrl = supabase.storage.from('app_evidence').getPublicUrl(path);
          evidenceUrls['image'] = publicUrl;
          debugPrint("LOG: Supabase Upload Successful: $publicUrl");
        } on TimeoutException {
          debugPrint("LOG ERROR: Supabase upload timed out after 120 seconds.");
          // We continue to Firestore so the text report isn't lost
        } catch (uploadError) {
          debugPrint("LOG ERROR: Supabase upload failed: $uploadError");
        }
      }

      // --- 2. SAVE METADATA TO FIREBASE ---
      debugPrint("LOG: Saving to Firestore...");
      await FirebaseFirestore.instance.collection('reports').doc(reportId).set({
        'reportId': reportId,
        'userId': userId,
        'description': widget.description,
        'location': widget.location,
        'incidentDate': widget.incidentDate != null ? DateFormat('yyyy-MM-dd').format(widget.incidentDate!) : null,
        'incidentTime': widget.incidentTime?.format(context),
        ..._answers,
        'evidenceUrls': evidenceUrls,
        'status': 'Under Review',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      _navigateToSuccess(reportId);
    } catch (e) {
      debugPrint("LOG CRITICAL ERROR: $e");
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Submission Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _navigateToSuccess(String id) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => ReportSuccessScreen(reportId: id)),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        title: Text(AppLocalizations.of(context)!.assistantTitle, style: const TextStyle(fontSize: 18)),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) return _buildTypingIndicator();
                return _buildChatBubble(_messages[index]);
              },
            ),
          ),
          if (_isFinalized) _buildSubmitSection(),
        ],
      ),
    );
  }

  Widget _buildSubmitSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[800],
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        onPressed: _isUploading ? null : _submitEverything,
        child: _isUploading
            ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
        )
            : Text(AppLocalizations.of(context)!.finalizeSubmit, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  Widget _buildChatBubble(Map<String, dynamic> msg) {
    bool isUser = msg["isUser"];
    return Column(
      crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.all(15),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          decoration: BoxDecoration(
            color: isUser ? Colors.blue[900] : Colors.white10,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(15),
              topRight: const Radius.circular(15),
              bottomLeft: Radius.circular(isUser ? 15 : 0),
              bottomRight: Radius.circular(isUser ? 0 : 15),
            ),
          ),
          child: Text(msg["text"], style: const TextStyle(color: Colors.white)),
        ),
        if (msg.containsKey("options"))
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 15),
            child: Wrap(
              spacing: 8,
              children: (msg["options"] as List<String>).map((opt) {
                return ChoiceChip(
                  label: Text(opt, style: const TextStyle(color: Colors.white, fontSize: 12)),
                  selected: false,
                  onSelected: (_) => _handleUserAnswer(msg["id"], opt),
                  backgroundColor: Colors.blue.withOpacity(0.2),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(15)),
        child: Text(AppLocalizations.of(context)!.assistantTyping, style: const TextStyle(color: Colors.white38, fontSize: 12, fontStyle: FontStyle.italic)),
      ),
    );
  }
}
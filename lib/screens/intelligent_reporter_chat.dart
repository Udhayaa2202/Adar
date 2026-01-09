import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
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

  final List<Map<String, dynamic>> _questions = [
    {"id": "frequency", "text": "How often have you noticed this happening?", "options": ["Daily", "Weekly", "Just once"]},
    {"id": "sensitive_area", "text": "Is this near a sensitive area like a school or park?", "options": ["Yes, very close", "No, far away"]},
    {"id": "activity_type", "text": "What best describes the activity you saw?", "options": ["Dealing/Exchange", "Stash/Drop-off", "Usage"]},
    {"id": "vehicles", "text": "Were there any vehicles involved in the scene?", "options": ["Parked car/bike", "Moving vehicle", "None"]},
    {"id": "people_count", "text": "Approximate number of people involved?", "options": ["1-2 people", "Small group (3-5)", "Large crowd"]},
  ];

  @override
  void initState() {
    super.initState();
    _startChat();
  }

  void _startChat() async {
    _addAssistantMessage("Hello. I've analyzed your initial report. I need 5 quick details to help the authorities prioritize this.");
    await Future.delayed(const Duration(seconds: 1));
    _askNextQuestion();
  }

  void _addAssistantMessage(String text) {
    if (mounted) setState(() => _messages.add({"isUser": false, "text": text}));
  }

  void _askNextQuestion() {
    if (_currentQuestionIndex < _questions.length) {
      setState(() => _isTyping = true);
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _isTyping = false;
            _messages.add({
              "isUser": false,
              "text": _questions[_currentQuestionIndex]["text"],
              "options": _questions[_currentQuestionIndex]["options"],
              "id": _questions[_currentQuestionIndex]["id"]
            });
          });
        }
      });
    } else {
      setState(() => _isFinalized = true);
      _addAssistantMessage("Thank you. I have all the intelligence needed. Your report is ready for secure transmission.");
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
    try {
      final String reportId = "ADAR-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";
      Map<String, String> evidenceUrls = {};
      final supabase = Supabase.instance.client;

      if (widget.imageFile != null) {
        final path = 'evidence/$reportId/img_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await supabase.storage.from('reports').upload(path, widget.imageFile!);
        evidenceUrls['image'] = supabase.storage.from('reports').getPublicUrl(path);
      }

      await FirebaseFirestore.instance.collection('reports').doc(reportId).set({
        'reportId': reportId,
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
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
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
        title: const Text("Intelligence Assistant", style: TextStyle(fontSize: 18)),
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
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text("FINALIZE & SUBMIT REPORT", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
        child: const Text("Assistant is analyzing...", style: TextStyle(color: Colors.white38, fontSize: 12, fontStyle: FontStyle.italic)),
      ),
    );
  }
}
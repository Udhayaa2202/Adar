import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:adar/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:adar/services/media_service.dart';
import 'report_success_screen.dart';

class IntelligentReporterChat extends StatefulWidget {
  final String description;
  final String location;
  final DateTime? incidentDate;
  final TimeOfDay? incidentTime;
  final File? imageFile;
  final File? videoFile;
  final bool isFromGallery;
  final bool isMocked;
  final Map<String, double>? capturedGps;
  final double? incidentLat;
  final double? incidentLon;

  const IntelligentReporterChat({
    super.key,
    required this.description,
    required this.location,
    this.incidentDate,
    this.incidentTime,
    this.imageFile,
    this.videoFile,
    required this.isFromGallery,
    required this.isMocked,
    this.capturedGps,
    this.incidentLat,
    this.incidentLon,
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

      // --- 1. UPLOAD IMAGE & CAPTURE METADATA ---
      Map<String, double>? photoMetadata;
      String? photoLocationSource;
      if (widget.imageFile != null) {
        final path = 'evidence/$reportId/img_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final result = await MediaService.processImage(widget.imageFile!, fallbackGps: widget.capturedGps);
        if (result != null) {
          final File processedFile = result['file'] as File;
          photoMetadata = result['metadata'] as Map<String, double>?;
          photoLocationSource = result['source'] as String?;
          
          final bytes = await processedFile.readAsBytes();
          await supabase.storage.from('app_evidence').uploadBinary(path, bytes,
              fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true));
          evidenceUrls['image'] = supabase.storage.from('app_evidence').getPublicUrl(path);
        }
      }

      // --- 2. UPLOAD VIDEO ---
      if (widget.videoFile != null) {
        final path = 'evidence/$reportId/vid_${DateTime.now().millisecondsSinceEpoch}.mp4';
        final processedVideo = await MediaService.processVideo(widget.videoFile!);
        if (processedVideo != null) {
          final bytes = await processedVideo.readAsBytes();
          await supabase.storage.from('app_evidence').uploadBinary(path, bytes,
              fileOptions: const FileOptions(contentType: 'video/mp4', upsert: true));
          evidenceUrls['video'] = supabase.storage.from('app_evidence').getPublicUrl(path);
        }
      }

      // --- 3. CALCULATE TRUST SCORE ---
      final Map<String, dynamic> trustResult = _calculateTrustScore();
      final int trustScore = trustResult['score'] as int;
      final Map<String, dynamic> trustBreakdown = trustResult['breakdown'] as Map<String, dynamic>;

      // --- 4. SAVE TO FIREBASE ---
      await FirebaseFirestore.instance.collection('reports').doc(reportId).set({
        'reportId': reportId,
        'userId': userId,
        'description': widget.description,
        'location': widget.location,
        'incidentDate': widget.incidentDate != null ? DateFormat('yyyy-MM-dd').format(widget.incidentDate!) : null,
        'incidentTime': widget.incidentTime?.format(context),
        'incidentLat': widget.incidentLat,
        'incidentLon': widget.incidentLon,
        'trustScore': trustScore,
        'trustBreakdown': trustBreakdown,
        'isFromGallery': widget.isFromGallery,
        'isMocked': widget.isMocked,
        'photoLocation': photoMetadata != null ? "${photoMetadata!['latitude']}, ${photoMetadata!['longitude']}" : null,
        'photoLocationSource': photoLocationSource,
        ..._answers,
        'evidenceUrls': evidenceUrls,
        'status': trustScore < 40 ? 'Flagged' : 'Under Review',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // --- 5. UPDATE LOCAL PREFS (For Dashboard) ---
      await prefs.setDouble('trust_score', trustScore.toDouble());

      if (!mounted) return;
      _navigateToSuccess(reportId);
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Submission Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      MediaService.dispose();
    }
  }

  /// Comprehensive trust scoring with breakdown for transparency
  Map<String, dynamic> _calculateTrustScore() {
    int score = 100;
    Map<String, dynamic> breakdown = {};

    // ============================================
    // 1. GPS INTEGRITY (Critical — highest penalty)
    // ============================================
    if (widget.isMocked) {
      score -= 30;
      breakdown['mockGps'] = -30;
    }

    // ============================================
    // 2. EVIDENCE SOURCE CHECK
    // ============================================
    if (widget.isFromGallery) {
      score -= 10;
      breakdown['gallerySource'] = -10;
    }

    // ============================================
    // 3. EVIDENCE QUALITY — penalize missing pieces
    // ============================================
    if (widget.imageFile == null && widget.videoFile == null) {
      // No evidence at all — should never happen due to validation, but handle it
      score -= 15;
      breakdown['noEvidence'] = -15;
    } else if (widget.imageFile == null || widget.videoFile == null) {
      // Only one type provided
      score -= 5;
      breakdown['partialEvidence'] = -5;
    } else {
      // Both photo + video = bonus for completeness
      score += 5;
      breakdown['fullEvidence'] = 5;
    }

    // ============================================
    // 4. DESCRIPTION DEPTH — tiered analysis
    // ============================================
    final int descLen = widget.description.trim().length;
    final int wordCount = widget.description.trim().split(RegExp(r'\s+')).length;

    if (descLen < 15 || wordCount < 3) {
      // Extremely short / likely spam
      score -= 15;
      breakdown['descriptionDepth'] = -15;
    } else if (descLen < 30 || wordCount < 6) {
      // Very brief
      score -= 10;
      breakdown['descriptionDepth'] = -10;
    } else if (descLen < 60) {
      // Acceptable but not detailed
      score -= 5;
      breakdown['descriptionDepth'] = -5;
    } else {
      // Good detail — reward
      score += 5;
      breakdown['descriptionDepth'] = 5;
    }

    // ============================================
    // 5. DATE/TIME STALENESS CHECK
    // ============================================
    if (widget.incidentDate == null) {
      // No date provided at all
      score -= 10;
      breakdown['noDate'] = -10;
    } else {
      final now = DateTime.now();
      final daysDiff = now.difference(widget.incidentDate!).inDays;

      if (widget.incidentTime == null) {
        // Date provided but no time
        score -= 5;
        breakdown['noTime'] = -5;
      }

      if (daysDiff > 30) {
        // Very old incident — high staleness
        score -= 15;
        breakdown['staleness'] = -15;
      } else if (daysDiff > 7) {
        // Somewhat old
        score -= 10;
        breakdown['staleness'] = -10;
      } else if (daysDiff > 3) {
        // Slightly delayed
        score -= 5;
        breakdown['staleness'] = -5;
      }
      // 0-3 days = fresh, no penalty
    }

    // ============================================
    // 6. CHAT ANSWER ANALYSIS — detail & consistency
    // ============================================
    int answeredCount = _answers.length;

    if (answeredCount < 5) {
      // User skipped or didn't answer all questions (shouldn't happen in normal flow)
      score -= 5;
      breakdown['incompleteAnswers'] = -5;
    }

    // Cross-check: High detail answers boost score
    int detailSignals = 0;

    // Frequency: recurring incidents are more credible patterns
    final freq = _answers['frequency'] ?? '';
    if (freq.contains('Daily') || freq.contains('தினசரி')) {
      detailSignals += 2;
    } else if (freq.contains('Weekly') || freq.contains('வாராந்திரம்')) {
      detailSignals += 1;
    }

    // Sensitive area: reports near schools/parks carry more weight
    final sensitive = _answers['sensitive_area'] ?? '';
    if (sensitive.contains('Yes') || sensitive.contains('மிக அருகில்')) {
      detailSignals += 1;
    }

    // People count: more people = harder to fabricate
    final people = _answers['people_count'] ?? '';
    if (people.contains('group') || people.contains('crowd') ||
        people.contains('குழு') || people.contains('கூட்டம்')) {
      detailSignals += 1;
    }

    // Vehicles: vehicle involvement adds specificity
    final vehicles = _answers['vehicles'] ?? '';
    if (!vehicles.contains('None') && !vehicles.contains('இல்லை') && vehicles.isNotEmpty) {
      detailSignals += 1;
    }

    // Award bonus for high detail (max +5)
    if (detailSignals >= 4) {
      score += 5;
      breakdown['detailBonus'] = 5;
    } else if (detailSignals >= 2) {
      score += 3;
      breakdown['detailBonus'] = 3;
    }

    // ============================================
    // 7. LOCATION VALIDATION
    // ============================================
    final loc = widget.location;
    if (loc.isEmpty || loc == 'Tap to get location' || loc == 'Unknown Location') {
      score -= 10;
      breakdown['invalidLocation'] = -10;
    }

    // ============================================
    // 8. CONSISTENCY CROSS-CHECK
    //    If gallery + mock GPS = likely fabricated
    // ============================================
    if (widget.isFromGallery && widget.isMocked) {
      score -= 10;
      breakdown['fabricationFlag'] = -10;
    }

    // Clamp to valid range
    score = score.clamp(0, 100);
    breakdown['finalScore'] = score;

    return {'score': score, 'breakdown': breakdown};
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
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
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
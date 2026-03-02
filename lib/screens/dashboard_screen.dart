import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:adar/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _anonymousId = "";
  String _trustScore = "100.0";
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;
  StreamSubscription? _reportsSub;

  @override
  void initState() {
    super.initState();
    _fetchData();

    _searchFocusNode.addListener(() {
      setState(() {
        _isSearching = _searchFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _reportsSub?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('anon_id') ?? "Unknown";

    if (mounted) {
      setState(() => _anonymousId = userId);
    }

    // Listen to the user's reports in real-time so trust score
    // updates instantly when an admin changes a report status.
    _reportsSub?.cancel();
    _reportsSub = FirebaseFirestore.instance
        .collection('reports')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      _computeLiveTrustScore(snapshot.docs);
    });
  }

  /// Dynamically computes user trust score from ALL their reports.
  /// If an admin rejects a report, the score drops automatically.
  void _computeLiveTrustScore(List<QueryDocumentSnapshot> docs) {
    if (docs.isEmpty) {
      setState(() => _trustScore = "100.0");
      return;
    }

    double totalScore = 0;
    int count = 0;

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      double reportScore = (data['trustScore'] ?? 100).toDouble();
      final String status = (data['status'] ?? '').toString().toLowerCase();

      // --- ADMIN REJECTION PENALTY ---
      // If admin rejected this report (e.g. fake Google images),
      // apply a heavy penalty to that report's score.
      if (status == 'rejected') {
        reportScore = (reportScore - 25).clamp(0, 100).toDouble();
      }
      // Flagged reports also get a smaller penalty
      else if (status == 'flagged') {
        reportScore = (reportScore - 10).clamp(0, 100).toDouble();
      }
      // Verified reports get a small boost
      else if (status == 'verified') {
        reportScore = (reportScore + 5).clamp(0, 100).toDouble();
      }

      totalScore += reportScore;
      count++;
    }

    final double avgScore = totalScore / count;

    if (mounted) {
      setState(() => _trustScore = avgScore.toStringAsFixed(1));
      // Persist for offline access
      SharedPreferences.getInstance().then((prefs) {
        prefs.setDouble('trust_score', avgScore);
      });
    }
  }

  void _handleGlobalSearch() async {
    String input = _searchController.text.trim();
    if (input.isEmpty) return;

    final String fullId = input.toUpperCase().startsWith("ADAR-")
        ? input.toUpperCase()
        : "ADAR-$input";

    _dismissKeyboard();

    try {
      final doc = await FirebaseFirestore.instance
          .collection('reports')
          .doc(fullId)
          .get();

      if (doc.exists && mounted) {
        _showReportDetails(doc.data() as Map<String, dynamic>);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Report $fullId not found."),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Search error: $e"), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.dashboardTitle.toUpperCase(),
            style: const TextStyle(letterSpacing: 2, fontSize: 13, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0D1B2A),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            _buildIdentityCard(),
            const SizedBox(height: 20),
            _buildSearchBar(),
            const SizedBox(height: 25),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(AppLocalizations.of(context)!.yourReports.toUpperCase(),
                  style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1)),
            ),
            const SizedBox(height: 15),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _anonymousId.isNotEmpty
                    ? FirebaseFirestore.instance
                    .collection('reports')
                    .where('userId', isEqualTo: _anonymousId)
                    .snapshots()
                    : null,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text("No history found.",
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.2))),
                    );
                  }

                  var docs = snapshot.data!.docs;

                  docs.sort((a, b) {
                    final aTime = (a.data() as Map)['createdAt'] as Timestamp?;
                    final bTime = (b.data() as Map)['createdAt'] as Timestamp?;
                    if (aTime == null || bTime == null) return 0;
                    return bTime.compareTo(aTime);
                  });

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final report = docs[index].data() as Map<String, dynamic>;
                      return _buildReportItem(report);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            _buildMainActionButton(),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildIdentityCard() {
    double scoreValue = double.tryParse(_trustScore) ?? 100.0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("ID: $_anonymousId",
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text("${AppLocalizations.of(context)!.trustScore}: $_trustScore%",
                  style: TextStyle(
                      color: scoreValue < 50 ? Colors.redAccent : Colors.amber,
                      fontSize: 18,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _showTrustScoreInfo,
                child: Row(
                  children: const [
                    Icon(Icons.info_outline, color: Colors.blue, size: 14),
                    SizedBox(width: 5),
                    Text(
                      "About Trust Score",
                      style: TextStyle(color: Colors.blue, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Icon(Icons.verified_user, color: Colors.blueAccent, size: 50),
        ],
      ),
    );
  }

  void _showTrustScoreInfo() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0D1B2A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(25, 25, 25, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("TRUST SCORE ANALYSIS",
                style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 14)),
            const SizedBox(height: 20),

            _buildSectionHeader("NEGATIVE FACTORS", Colors.redAccent),
            _buildImpactRow(Icons.location_disabled, "Fake GPS / Mock Location", "-30%", Colors.redAccent),
            _buildImpactRow(Icons.collections, "Gallery uploads (Non-live)", "-10%", Colors.redAccent),
            _buildImpactRow(Icons.hide_image, "No evidence provided", "-15%", Colors.redAccent),
            _buildImpactRow(Icons.image_not_supported, "Only photo or video (not both)", "-5%", Colors.redAccent),
            _buildImpactRow(Icons.short_text, "Very short description", "up to -15%", Colors.redAccent),
            _buildImpactRow(Icons.calendar_today, "No date/time provided", "-10%", Colors.redAccent),
            _buildImpactRow(Icons.history, "Stale incident (>3 days old)", "up to -15%", Colors.redAccent),
            _buildImpactRow(Icons.location_off, "Invalid/missing location", "-10%", Colors.redAccent),
            _buildImpactRow(Icons.dangerous, "Gallery + Fake GPS combined", "-10%", Colors.redAccent),

            const SizedBox(height: 20),

            _buildSectionHeader("POSITIVE FACTORS", Colors.greenAccent),
            _buildImpactRow(Icons.camera_alt, "Direct Camera Capture", "Verified", Colors.greenAccent),
            _buildImpactRow(Icons.my_location, "Real-time GPS Verification", "Verified", Colors.greenAccent),
            _buildImpactRow(Icons.photo_library, "Both photo + video provided", "+5%", Colors.greenAccent),
            _buildImpactRow(Icons.article, "Detailed description (60+ chars)", "+5%", Colors.greenAccent),
            _buildImpactRow(Icons.quiz, "High-detail chat answers", "up to +5%", Colors.greenAccent),

            const SizedBox(height: 25),

            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(255, 193, 7, 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color.fromRGBO(255, 193, 7, 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 16),
                      SizedBox(width: 8),
                      Text("IMPORTANT NOTE",
                          style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Low trust scores (below 40%) may result in reports being automatically flagged for manual review or hidden from public visibility to prevent misinformation.",
                    style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text("I UNDERSTAND", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title,
          style: TextStyle(color: Color.fromRGBO(color.r.toInt(), color.g.toInt(), color.b.toInt(), 0.8), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
    );
  }

  Widget _buildImpactRow(IconData icon, String text, String impact, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.white24, size: 18),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13))),
          Text(impact, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      focusNode: _searchFocusNode,
      onChanged: (val) => setState(() {}),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF0D1B2A),
        hintText: "Enter ID (e.g. 123456)",
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
        prefixIcon: _isSearching || _searchController.text.isNotEmpty
            ? const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
          child: Text("ADAR-",
              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
        )
            : const Icon(Icons.search, color: Colors.white24),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
            icon: const Icon(Icons.close, color: Colors.blue),
            onPressed: () {
              _searchController.clear();
              _dismissKeyboard();
              setState(() {});
            })
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildReportItem(Map<String, dynamic> report) {
    final String rId = report['reportId'] ?? "N/A";
    final String status = report['status'] ?? "PENDING";
    final bool isRejected = status.toUpperCase() == 'REJECTED';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: isRejected
            ? const Color.fromRGBO(244, 67, 54, 0.08)
            : const Color.fromRGBO(255, 255, 255, 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isRejected ? const Color.fromRGBO(244, 67, 54, 0.3) : Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rId, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.circle, size: 6, color: _getStatusColor(status)),
                    const SizedBox(width: 8),
                    Text(status.toUpperCase(),
                        style: TextStyle(
                            color: _getStatusColor(status),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5)),
                    if (isRejected) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(244, 67, 54, 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text("-25 pts",
                            style: TextStyle(color: Colors.redAccent, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                if (isRejected && report['rejectionReason'] != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    report['rejectionReason'],
                    style: const TextStyle(color: Colors.white38, fontSize: 11, fontStyle: FontStyle.italic),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showReportDetails(report),
            icon: const Icon(Icons.chevron_right, color: Colors.blueGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildMainActionButton() {
    bool hasSearchText = _searchController.text.isNotEmpty;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: hasSearchText ? Colors.blue : const Color(0xFF0056D2),
        minimumSize: const Size(double.infinity, 60),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      onPressed: hasSearchText ? _handleGlobalSearch : () => Navigator.pushNamed(context, '/report'),
      child: Text(
        hasSearchText ? "SEARCH DATABASE" : "SUBMIT NEW REPORT",
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'VERIFIED': return Colors.greenAccent;
      case 'UNDER REVIEW': return Colors.lightBlueAccent;
      case 'FLAGGED': return Colors.redAccent;
      case 'REJECTED': return Colors.redAccent;
      default: return Colors.orangeAccent;
    }
  }

  void _showReportDetails(Map<String, dynamic> report) {
    final String status = (report['status'] ?? '').toString();
    final bool isRejected = status.toUpperCase() == 'REJECTED';
    final int originalScore = (report['trustScore'] ?? 100) as int;
    final int effectiveScore = isRejected ? (originalScore - 25).clamp(0, 100) : originalScore;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF0D1B2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("REPORT DETAILS",
                  style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 12)),
              const Divider(color: Colors.white10, height: 30),
              _buildDetailRow("ID", report['reportId'] ?? "N/A"),
              _buildDetailRow("Status", report['status'] ?? "PENDING", color: _getStatusColor(report['status'] ?? "")),

              // --- REJECTION CARD ---
              if (isRejected)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 5, bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(244, 67, 54, 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color.fromRGBO(244, 67, 54, 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.gpp_bad, color: Colors.redAccent, size: 18),
                          SizedBox(width: 8),
                          Text("REPORT REJECTED",
                              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.8)),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Rejection Reason
                      const Text("REASON", style: TextStyle(color: Colors.white30, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      const SizedBox(height: 4),
                      Text(
                        report['rejectionReason'] ?? "No reason provided by admin.",
                        style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                      ),

                      const Divider(color: Colors.white10, height: 20),

                      // Score Impact
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("SCORE IMPACT", style: TextStyle(color: Colors.white30, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color.fromRGBO(244, 67, 54, 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text("-25 PENALTY",
                                style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text("$originalScore%",
                              style: const TextStyle(color: Colors.white38, fontSize: 14, decoration: TextDecoration.lineThrough)),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, color: Colors.redAccent, size: 14),
                          const SizedBox(width: 8),
                          Text("$effectiveScore%",
                              style: const TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),

              if (!isRejected && report['trustScore'] != null)
                _buildDetailRow("Calculated Trust", "${report['trustScore']}%", color: Colors.amber),

              _buildDetailRow("Incident Location", report['location'] ?? "Not provided"),
              _buildDetailRow("AI Description", report['description'] ?? "No description"),

              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("CLOSE", style: TextStyle(color: Colors.white54)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color color = Colors.white70}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:adar/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardScreen extends StatefulWidget {
  final Map<String, dynamic>? newReport;

  const DashboardScreen({super.key, this.newReport});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _anonymousId = "";
  String _trustScore = "0.0";
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;

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
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _anonymousId = prefs.getString('anon_id') ?? "Unknown";
        double currentScore = prefs.getDouble('trust_score') ?? 0.0;

        if (currentScore >= 4.0) {
          currentScore = 0.0;
          prefs.setDouble('trust_score', currentScore);
        }
        _trustScore = currentScore.toStringAsFixed(1);
      });
    }
  }

  // Global Search: Search ALL reports, not just the user's local list
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
              content: Text(AppLocalizations.of(context)!.reportNotFound(fullId)),
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
        title: Text(AppLocalizations.of(context)!.dashboardTitle,
            style: const TextStyle(letterSpacing: 2, fontSize: 16)),
        backgroundColor: const Color(0xFF0D1B2A),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          children: [
            // Trust Score & ID Card
            _buildIdentityCard(),
            const SizedBox(height: 20),

            _buildSearchBar(),
            const SizedBox(height: 30),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(AppLocalizations.of(context)!.yourReports,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2)),
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
                      child: Text("No reports submitted yet.",
                          style: TextStyle(color: Colors.white.withOpacity(0.3))),
                    );
                  }

                  var docs = snapshot.data!.docs;
                  if (_searchController.text.isNotEmpty) {
                    final query = _searchController.text.toLowerCase();
                    docs = docs.where((d) {
                      final data = d.data() as Map<String, dynamic>;
                      return (data['reportId'] ?? '').toString().toLowerCase().contains(query);
                    }).toList();
                  }

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

            // Action Button (Dynamic: Search or New Report)
            _buildMainActionButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildIdentityCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("ID: $_anonymousId",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text("${AppLocalizations.of(context)!.trustScore}: $_trustScore",
                  style: const TextStyle(
                      color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const Icon(Icons.shield, color: Colors.blue, size: 40),
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
        hintText: AppLocalizations.of(context)!.searchHint,
        hintStyle: const TextStyle(color: Colors.white54),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(rId, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.circle, size: 8, color: _getStatusColor(status)),
                  const SizedBox(width: 6),
                  Text(status,
                      style: TextStyle(
                          color: _getStatusColor(status),
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          TextButton(
            onPressed: () => _showReportDetails(report),
            child: Text(AppLocalizations.of(context)!.viewReport,
                style: const TextStyle(color: Colors.blue)),
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
        minimumSize: const Size(double.infinity, 65),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      onPressed: hasSearchText ? _handleGlobalSearch : () => Navigator.pushNamed(context, '/report'),
      child: Text(
        hasSearchText
            ? AppLocalizations.of(context)!.searchButton
            : AppLocalizations.of(context)!.startNewReport,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'VERIFIED': return Colors.greenAccent;
      case 'UNDER REVIEW': return Colors.lightBlueAccent;
      case 'REJECTED': return Colors.redAccent;
      default: return Colors.orangeAccent;
    }
  }

  void _showReportDetails(Map<String, dynamic> report) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF0D1B2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context)!.reportDetails,
                  style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const Divider(color: Colors.white10),
              _buildDetailRow("ID", report['reportId'] ?? "N/A"),
              _buildDetailRow("Status", report['status'] ?? "PENDING", color: _getStatusColor(report['status'] ?? "")),
              _buildDetailRow("Location", report['location'] ?? "Not provided"),
              _buildDetailRow("Description", report['description'] ?? "No description provided"),

              if (report['evidenceUrls'] != null && report['evidenceUrls']['image'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(report['evidenceUrls']['image'], height: 150, width: double.infinity, fit: BoxFit.cover),
                  ),
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Center(child: Text("Close")),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color color = Colors.white70}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
          Text(value, style: TextStyle(color: color, fontSize: 14)),
        ],
      ),
    );
  }
}
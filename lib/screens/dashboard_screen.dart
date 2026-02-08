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
  String _trustScore = "";
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _searchController.addListener(() {
      setState(() {});
    });
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
        if (currentScore == 4.0) {
          currentScore = 0.0;
          prefs.setDouble('trust_score', currentScore);
        }
        _trustScore = currentScore.toStringAsFixed(1);
      });
    }
  }

  void _handleSearch() async {
    final String reportId = _searchController.text.trim();
    if (reportId.length == 6) {
      final fullId = "ADAR-$reportId";
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
            SnackBar(
              content: Text("Error searching: $e"),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.validIdError)),
      );
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
        title: Text(
            AppLocalizations.of(context)!.dashboardTitle, style: const TextStyle(letterSpacing: 2, fontSize: 16)),
        backgroundColor: const Color(0xFF0D1B2A),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
               Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          children: [
            // Trust Score & ID Card
            Container(
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
                          style: const TextStyle(color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text("${AppLocalizations.of(context)!.trustScore}: $_trustScore",
                          style: const TextStyle(color: Colors.amber,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Icon(Icons.shield, color: Colors.blue, size: 40),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Search Bar
            TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              keyboardType: TextInputType.number,
              maxLength: 6,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF0D1B2A),
                hintText: AppLocalizations.of(context)!.searchHint,
                hintStyle: const TextStyle(color: Colors.white54, fontSize: 16),
                prefixIcon: (_isSearching || _searchController.text.isNotEmpty)
                    ? Container(
                        width: 60,
                        alignment: Alignment.center,
                        margin: const EdgeInsets.only(left: 10),
                        child: const Text("ADAR-",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                      )
                    : null,
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, color: Colors.blue),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                counterText: "",

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 15, horizontal: 20),
              ),
            ),
            const SizedBox(height: 30),

            // Your Reports Section
             Align(
              alignment: Alignment.centerLeft,
              child: Text(AppLocalizations.of(context)!.yourReports,
                  style: const TextStyle(color: Colors.white,
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
                  if (_anonymousId.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error loading reports: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        "No reports found for this ID.",
                        style: TextStyle(color: Colors.white.withOpacity(0.5)),
                      ),
                    );
                  }

                  var reports = snapshot.data!.docs;

                  if (_searchController.text.isNotEmpty) {
                    final query = _searchController.text.trim().toUpperCase();
                    reports = reports.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final id = (data['reportId'] ?? data['id'] ?? '').toString().toUpperCase();
                      return id.contains(query) || id.replaceAll('ADAR-', '').contains(query);
                    }).toList();
                  }

                  reports.sort((a, b) {
                    final aData = a.data() as Map<String, dynamic>;
                    final bData = b.data() as Map<String, dynamic>;

                    dynamic getTimestamp(Map<String, dynamic> data) {
                       if (data['createdAt'] is Timestamp) {
                         return (data['createdAt'] as Timestamp).toDate();
                       }
                       return DateTime.now(); 
                    }

                    final aTime = getTimestamp(aData);
                    final bTime = getTimestamp(bData);
                    
                    return bTime.compareTo(aTime);
                  });

                  return ListView.builder(
                    itemCount: reports.length,
                    itemBuilder: (context, index) {
                      final reportData = reports[index].data() as Map<String, dynamic>;
                      final String reportId = reportData['reportId'] ?? reportData['id'] ?? 'Unknown ID';
                      final String status = reportData['status'] ?? 'PENDING';
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 15),
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
                                Text(reportId,
                                    style: const TextStyle(color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    Icon(Icons.circle, size: 8,
                                        color: _getStatusColor(status)),
                                    const SizedBox(width: 5),
                                    Text(status,
                                        style: TextStyle(color: _getStatusColor(status),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.withOpacity(0.2),
                                foregroundColor: Colors.blue,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () => _showReportDetails(reportData),
                              child: Text(AppLocalizations.of(context)!.viewReport),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0056D2),
                minimumSize: const Size(double.infinity, 65),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: _searchController.text.isNotEmpty
                  ? _handleSearch
                  : () {
                      _searchFocusNode.unfocus();
                      Navigator.pushNamed(context, '/report');
                    },
              child: Text(
                  _searchController.text.isNotEmpty
                      ? AppLocalizations.of(context)!.searchButton
                      : AppLocalizations.of(context)!.startNewReport,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    final s = status.toUpperCase();
    if (s == 'VERIFIED') return Colors.greenAccent;
    if (s == 'PENDING') return Colors.orangeAccent;
    if (s == 'UNDER REVIEW') return Colors.lightBlueAccent;
    if (s == 'REJECTED') return Colors.redAccent;
    return Colors.grey;
  }

  void _showReportDetails(Map<String, dynamic> report) {
    // Safely handle missing fields
    final String rId = report['reportId'] ?? report['id'] ?? 'N/A';
    final String rStatus = report['status'] ?? 'Unknown';
    final String rDate = report['incidentDate'] ?? report['date'] ?? 'N/A';
    final String rLocation = report['location'] ?? 'Unknown Location';
    final String rDesc = report['description'] ?? 'No Description';

    showDialog(
      context: context,
      builder: (context) =>
          Dialog(
            backgroundColor: const Color(0xFF0D1B2A),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                       Text(AppLocalizations.of(context)!.reportDetails, style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5)),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 15),
                  _buildDetailRow("ID", rId),
                  _buildDetailRow(AppLocalizations.of(context)!.statusStatus, rStatus,
                      color: _getStatusColor(rStatus)),
                  _buildDetailRow(AppLocalizations.of(context)!.dateDate, rDate),
                  _buildDetailRow(AppLocalizations.of(context)!.locationLocation, rLocation),
                  const SizedBox(height: 15),
                   Text(AppLocalizations.of(context)!.descriptionDescription, style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text(rDesc, style: const TextStyle(
                      color: Colors.white70, height: 1.4)),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildDetailRow(String label, String value,
      {Color color = Colors.white}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

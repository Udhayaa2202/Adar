import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

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
    setState(() {
      _anonymousId = prefs.getString('anon_id') ?? "Unknown";
      _trustScore = (prefs.getDouble('trust_score') ?? 4.0).toStringAsFixed(1);
    });
  }

  void _handleSearch() {
    final String reportId = _searchController.text.trim();
    if (reportId.length == 6) {
      // Ready to fetch report logic here
      print("Fetching report: ADAR-$reportId");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Searching for ADAR-$reportId...")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid 6-digit Report ID")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("DASHBOARD", style: TextStyle(letterSpacing: 2, fontSize: 16)),
        backgroundColor: const Color(0xFF0D1B2A),
        automaticallyImplyLeading: false,
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
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text("TRUST SCORE: $_trustScore",
                          style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
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
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF0D1B2A),
                hintText: "Enter Your Report-ID",
                hintStyle: const TextStyle(color: Colors.white54),
                prefixText: "ADAR-",
                prefixStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search, color: Colors.blue),
                  onPressed: _handleSearch,
                ),
                counterText: "", // Hides the character counter
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              ),
            ),
            const Spacer(),

            Text(_isSearching ? "Enter ID to search" : "Ready to report activity?",
                style: const TextStyle(color: Colors.white60)),
            const SizedBox(height: 20),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0056D2),
                minimumSize: const Size(double.infinity, 65),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: _isSearching
                  ? _handleSearch
                  : () => Navigator.pushNamed(context, '/report'),
              child: Text(
                  _isSearching ? "SEARCH" : "START NEW REPORT",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

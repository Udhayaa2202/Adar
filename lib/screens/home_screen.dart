import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _anonymousId = "Loading...";
  String _trustScore = "4.0";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Logic to get or create unique user data
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();

    // Check if ID already exists
    String? savedId = prefs.getString('anon_id');
    double? savedScore = prefs.getDouble('trust_score');

    if (savedId == null) {
      // First time user: Create a random ID like ABX7K5F2
      const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ123456789';
      savedId = List.generate(8, (i) => chars[Random().nextInt(chars.length)]).join();
      savedScore = 4.0; // Default starting score

      await prefs.setString('anon_id', savedId);
      await prefs.setDouble('trust_score', savedScore);
    }

    setState(() {
      _anonymousId = savedId!;
      _trustScore = savedScore!.toStringAsFixed(1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D1B2A), Colors.black],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_outline, color: Colors.white, size: 100),
            const Text(
              "ADAR",
              style: TextStyle(
                color: Colors.white,
                fontSize: 42,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
            const Text(
              "Anonymous Drug Activity Reporter",
              style: TextStyle(color: Colors.blueGrey, fontSize: 14),
            ),
            const SizedBox(height: 60),
            const Text(
              "Report Drug Activity\nAnonymously",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0056D2),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/report');
                },
                child: const Text(
                  "Start Reporting",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // 4. Dynamic Trust Score Section
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  Text(
                    "You are Anonymous ID: $_anonymousId",
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 5),
                  RichText(
                    text: TextSpan(
                      text: "Trust Score: ",
                      style: const TextStyle(color: Colors.white70),
                      children: [
                        TextSpan(
                          text: _trustScore,
                          style: const TextStyle(
                              color: Colors.amber, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
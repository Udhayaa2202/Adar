import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;

  Future<void> _handleStart() async {
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();

    // Logic to ensure user data exists before moving to dashboard
    if (prefs.getString('anon_id') == null) {
      const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ123456789';
      String newId = List.generate(8, (i) => chars[Random().nextInt(chars.length)]).join();
      await prefs.setString('anon_id', newId);
      await prefs.setDouble('trust_score', 4.0);
    }

    // Brief delay to show the "Secure Connection" loading effect
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      // Navigate to the Dashboard (We will define this route in main.dart)
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
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
            const SizedBox(height: 40),

            // Loading Bar or Button
            _isLoading
                ? const Column(
              children: [
                CircularProgressIndicator(color: Color(0xFF0056D2)),
                SizedBox(height: 20),
                Text("Establishing Secure Grid...",
                    style: TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            )
                : Padding(
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
                onPressed: _handleStart,
                child: const Text(
                  "Start Reporting",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
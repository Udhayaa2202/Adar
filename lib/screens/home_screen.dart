import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'package:provider/provider.dart';
import 'package:adar/providers/language_provider.dart';
import 'package:adar/l10n/app_localizations.dart';

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

  void _showLanguageSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D1B2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
               Text(
                AppLocalizations.of(context)!.selectLanguage,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Text("🇺🇸", style: TextStyle(fontSize: 24)),
                title: Text(AppLocalizations.of(context)!.english, style: const TextStyle(color: Colors.white)),
                onTap: () {
                  Provider.of<LanguageProvider>(context, listen: false)
                      .changeLanguage(const Locale('en'));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Text("🇮🇳", style: TextStyle(fontSize: 24)),
                title: Text(AppLocalizations.of(context)!.tamil, style: const TextStyle(color: Colors.white)),
                onTap: () {
                  Provider.of<LanguageProvider>(context, listen: false)
                      .changeLanguage(const Locale('ta'));
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
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
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const Icon(Icons.person_outline, color: Colors.white, size: 100),
              Text(
                AppLocalizations.of(context)!.appName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  AppLocalizations.of(context)!.appSubtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.blueGrey, fontSize: 14),
                ),
              ),
              const SizedBox(height: 60),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  AppLocalizations.of(context)!.reportTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 40),
          
              // Loading Bar or Button
              _isLoading
                  ? Column(
                children: [
                   const CircularProgressIndicator(color: Color(0xFF0056D2)),
                   const SizedBox(height: 20),
                   Text(AppLocalizations.of(context)!.establishingConnection,
                      style: const TextStyle(color: Colors.white38, fontSize: 12)),
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
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      AppLocalizations.of(context)!.startReporting,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _showLanguageSelector(context),
                icon: const Icon(Icons.language, color: Colors.white54, size: 16),
                label: Text(
                  AppLocalizations.of(context)!.selectLanguage,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
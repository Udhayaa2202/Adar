import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';

// Import your screens (ensure these paths match your project structure)
import 'screens/report_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Load the environment file
  await dotenv.load(fileName: ".env");

  // 2. Initialize Firebase
  await Firebase.initializeApp();

  // 3. Initialize Supabase using the hidden keys from .env
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  runApp(const AdarApp());
}

class AdarApp extends StatelessWidget {
  const AdarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ADAR Reporter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
      ),
      // This is where your app actually starts
      home: const ReportScreen(),
    );
  }
}
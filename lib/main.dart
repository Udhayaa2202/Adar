import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/report_screen.dart';

void main() {
  runApp(const ADARApp());
}

class ADARApp extends StatelessWidget {
  const ADARApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.dark),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/report': (context) => const ReportScreen(), // Define the route
      },
    );
  }
}
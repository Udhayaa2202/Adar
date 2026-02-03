import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:adar/l10n/app_localizations.dart';

// Import your screens (ensure these paths match your project structure)
import 'screens/report_screen.dart';
import 'screens/home_screen.dart';
import 'screens/dashboard_screen.dart';
import 'providers/language_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  // 2. Initialize Firebase
  await Firebase.initializeApp();

  // 3. Initialize Supabase using the hidden keys from .env
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => LanguageProvider(),
      child: const AdarApp(),
    ),
  );
}

class AdarApp extends StatelessWidget {
  const AdarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return MaterialApp(
          title: 'ADAR Reporter',
          debugShowCheckedModeBanner: false,
          locale: languageProvider.currentLocale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'), // English
            Locale('ta'), // Tamil
          ],
          theme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.blue,
          ),
          // 1. Change home to HomeScreen
          home: const HomeScreen(),

          routes: {
              '/dashboard': (context) => const DashboardScreen(),
              '/report': (context) => const ReportScreen(),
          },
        );
      },
    );
  }
}
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/persona_selection_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/profile_screen.dart';
import 'services/notification_service.dart'; // IMPORT THIS

import 'package:flutter/foundation.dart';
import 'package:sqlite_inspector/sqlite_inspector.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (kDebugMode) {
    // Starts the local server on port 7111 by default
    await SqliteInspector.start();
  }

  // Initialize and schedule notifications on startup
  await NotificationService.init();
  await NotificationService.requestPermissions();
  await NotificationService.scheduleDailyReminders();
  
  final prefs = await SharedPreferences.getInstance();
  final int? dailyGoal = prefs.getInt('daily_goal');

  // Decide initial route: if daily_goal is set, go to dashboard, else login
  String initialRoute = '/login';
  if (dailyGoal != null && dailyGoal > 0) {
    initialRoute = '/dashboard';
  }

  runApp(H2OTrackerApp(initialRoute: initialRoute));
}

class H2OTrackerApp extends StatelessWidget {
  final String initialRoute;

  const H2OTrackerApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'H2O Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1E313B),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E5FF),
          secondary: Color(0xFF1DE9B6),
          surface: Color(0xFF24363F),
        ),
      ),
      initialRoute: initialRoute,
      routes: {
        '/login': (context) => const LoginScreen(),
        '/persona': (context) => const PersonaSelectionScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:cancelbuddy/app_settings.dart';
import 'package:cancelbuddy/notification_service.dart';
import 'package:cancelbuddy/savings.dart';
import 'package:cancelbuddy/screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  await Hive.openBox('subscriptions');
  await Hive.openBox('settings');
  await Hive.openBox(SavingsStore.boxName);

  await NotificationService.instance.initialize();

  runApp(const CancelBuddyApp());
}

// ============================================================
// APP
// ============================================================

class CancelBuddyApp extends StatefulWidget {
  const CancelBuddyApp({super.key});

  @override
  State<CancelBuddyApp> createState() =>
      _CancelBuddyAppState();
}

class _CancelBuddyAppState
    extends State<CancelBuddyApp> {
  bool isDark = AppSettings.darkMode;

  void toggle() {
    setState(() {
      isDark = !isDark;
    });

    AppSettings.box.put(
      AppSettings.darkModeKey,
      isDark,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CancelBuddy',
      themeMode:
          isDark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        colorSchemeSeed:
            const Color(0xFF5E6AD2),
        scaffoldBackgroundColor:
            const Color(0xFFF7F8FC),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),
        ),
        inputDecorationTheme:
            InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(16),
            borderSide:
                const BorderSide(
              color: Color(0xFF5E6AD2),
              width: 1.5,
            ),
          ),
          contentPadding:
              const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 17,
          ),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorSchemeSeed:
            const Color(0xFF7C83E8),
        scaffoldBackgroundColor:
            const Color(0xFF101116),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),
        ),
        inputDecorationTheme:
            InputDecorationTheme(
          filled: true,
          fillColor:
              const Color(0xFF191A21),
          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(16),
            borderSide:
                const BorderSide(
              color: Color(0xFF7C83E8),
              width: 1.5,
            ),
          ),
          contentPadding:
              const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 17,
          ),
        ),
      ),
      home: HomeScreen(
        isDarkMode: isDark,
        onThemeToggle: toggle,
      ),
    );
  }
}

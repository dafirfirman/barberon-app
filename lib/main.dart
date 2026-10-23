// lib/main.dart
import 'package:apkbarberon/page/home_page.dart';
import 'package:apkbarberon/auth/welcome_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';

// Tema BarberGo
import 'package:apkbarberon/Thema/theme.dart';
// Controller tema global
import 'package:apkbarberon/services/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase masih diinisialisasi (untuk fitur lain bila ada). Login kini
  // memakai OTP WhatsApp, bukan Firebase.
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  // Muat tema tersimpan
  await themeController.load();

  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({Key? key, required this.isLoggedIn}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Bangun ulang MaterialApp setiap kali tema berubah
    return AnimatedBuilder(
      animation: themeController,
      builder: (context, _) {
        return MaterialApp(
          title: 'BarberGo',
          debugShowCheckedModeBanner: false,
          theme: BarberGoTheme.light(),
          darkTheme: BarberGoTheme.dark(),
          themeMode: themeController.mode,
          home: isLoggedIn
              ? HomePage(updateThemeMode: themeController.setMode)
              : const WelcomePage(),
        );
      },
    );
  }
}
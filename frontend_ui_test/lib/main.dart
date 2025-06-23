import 'package:flutter/material.dart';
import 'pages/auth_page.dart';
import 'pages/home_page.dart';
import 'pages/barcode_page.dart';
import 'pages/ocr_page.dart';
import 'pages/profile_screen.dart';
import 'pages/history_screen.dart';
import 'pages/feedback_page.dart';
import 'services/app_colors.dart';

void main() {
  runApp(const GroceryGuardianApp());
}

class GroceryGuardianApp extends StatelessWidget {
  const GroceryGuardianApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grocery Guardian',
      theme: ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        useMaterial3: false,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthPage(),
        '/home': (context) => const HomePage(),
        '/barcode': (context) => const BarcodePage(),
        '/ocr': (context) => const OCRPage(),
        '/profile': (context) => const ProfileScreen(),
        '/history': (context) => const HistoryScreen(),
        '/feedback': (context) => const FeedbackPage(),
      },
    );
  }
}

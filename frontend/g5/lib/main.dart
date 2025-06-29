import 'package:flutter/material.dart';
import 'presentation/screens/SignInPage.dart';
import 'presentation/screens/SignUpPage.dart';
import 'presentation/screens/welcome_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/history/history_record_page.dart';
import 'presentation/screens/sugar_tracking/sugar_tracking_page.dart';
import 'presentation/screens/monthly_overview/monthly_overview_screen.dart';
import 'presentation/theme/app_colors.dart';
import 'presentation/theme/app_styles.dart';
import 'services/user_service.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grocery Guardian',
      theme: ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Poppins',
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 0,
          titleTextStyle: AppStyles.h2.copyWith(color: AppColors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            textStyle: AppStyles.buttonText,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          background: AppColors.background,
        ),
      ),
      home: FutureBuilder<bool>(
        future: UserService.instance.isLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          
          final isLoggedIn = snapshot.data ?? false;
          return isLoggedIn ? const HomeScreen() : WelcomeScreen();
        },
      ),
      routes: <String, WidgetBuilder> {
        '/signin': (BuildContext context) => SignInPage(),
        '/signup': (BuildContext context) => SignUpPage(),
        '/main': (BuildContext context) => const HomeScreen(),
        '/history': (BuildContext context) => HistoryRecordPage(),
        '/sugar-tracking': (BuildContext context) => SugarTrackingPage(),
        '/monthly-overview': (BuildContext context) => MonthlyOverviewScreen(),
      },
    );
  }

}
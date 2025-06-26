import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'domain/entities/user.dart';
import 'presentation/screens/SignInPage.dart';
import 'presentation/screens/SignUpPage.dart';
import 'presentation/screens/welcome_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/theme/app_colors.dart';
import 'presentation/theme/app_styles.dart';

class UserProvider extends ChangeNotifier {
  User? _user;
  User? get user => _user;
  void setUser(User? user) {
    _user = user;
    notifyListeners();
  }
}

void main() => runApp(
  ChangeNotifierProvider(
    create: (_) => UserProvider(),
    child: const MyApp(),
  ),
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    // Temporary boolean to control initial screen
    bool isLoggedIn = false;
    
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
      home: isLoggedIn ? const HomeScreen() : WelcomeScreen(),
      routes: <String, WidgetBuilder> {
        '/signin': (BuildContext context) => SignInPage(),
        '/signup': (BuildContext context) => SignUpPage(),
        '/main': (BuildContext context) => const HomeScreen(),
      },
    );
  }
}
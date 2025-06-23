import 'package:flutter/material.dart';
import '../services/app_colors.dart';
import '../services/app_styles.dart';
import '../services/buttons.dart';
import '../services/input_fields.dart';
import 'package:page_transition/page_transition.dart';
import 'home_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isLogin = true;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  void toggleForm() {
    setState(() {
      isLogin = !isLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isLogin ? 'Login' : 'Register',
                style: AppStyles.headingStyle,
              ),
              const SizedBox(height: 32),
              StyledInputField(
                controller: emailController,
                hintText: 'Email',
              ),
              const SizedBox(height: 16),
              StyledInputField(
                controller: passwordController,
                hintText: 'Password',
                obscureText: true,
              ),
              if (!isLogin) ...[
                const SizedBox(height: 16),
                StyledInputField(
                  controller: confirmPasswordController,
                  hintText: 'Confirm Password',
                  obscureText: true,
                ),
              ],
              const SizedBox(height: 24),
              PrimaryButton(
                text: isLogin ? 'Login' : 'Register',
                onPressed: () {
                      final email = emailController.text.trim();
                      final password = passwordController.text.trim();
                      final confirmPassword = confirmPasswordController.text.trim();

                      if (email.isEmpty || password.isEmpty || (!isLogin && confirmPassword.isEmpty)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please fill in all fields')),
                        );
                        return;
                      }

                      if (!isLogin && password != confirmPassword) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Passwords do not match')),
                        );
                        return;
                      }

                      // Simulate success (replace with actual backend/auth logic)
                      Navigator.pushReplacement(
                        context,
                        PageTransition(
                          type: PageTransitionType.rightToLeft,
                          child: const HomePage(),
                        ),
                      );
                },
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: toggleForm,
                child: Text(
                  isLogin
                      ? "Don't have an account? Register"
                      : "Already have an account? Login",
                  style: AppStyles.linkStyle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

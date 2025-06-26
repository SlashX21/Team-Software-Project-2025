import 'package:flutter/material.dart';
import '../theme/app_styles.dart';
import '../theme/app_colors.dart';
import '../widgets/inputFields.dart';
import 'package:page_transition/page_transition.dart';
import './SignUpPage.dart';
import './home_screen.dart';
import '../../services/api.dart'; // make sure the path is correct
import 'package:provider/provider.dart';
import '../../domain/entities/user.dart';
import '../../main.dart';

class SignInPage extends StatefulWidget {
  final String? pageTitle;

  const SignInPage({Key? key, this.pageTitle}) : super(key: key);

  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final passwordHash = _passwordController.text.trim();

    if (username.isEmpty || passwordHash.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username and password are required')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final user = await loginUser(userName: username, passwordHash: passwordHash);

    setState(() => _isLoading = false);

    if (user != null) {
      Provider.of<UserProvider>(context, listen: false).setUser(user);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Welcome ${user.userName}!')),
      );
      Navigator.pushReplacement(
        context,
        PageTransition(type: PageTransitionType.rightToLeft, child: HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid username or password')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.white,
        title: const Text(
          'Sign In',
          style: TextStyle(
            color: Colors.grey,
            fontFamily: 'Poppins',
            fontSize: 15,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                PageTransition(
                  type: PageTransitionType.rightToLeft,
                  child: SignUpPage(),
                ),
              );
            },
            child: Text(
              'Sign Up',
              style: AppStyles.bodyBold.copyWith(color: AppColors.primary),
            ),
          )
        ],
      ),
      body: ListView(
        shrinkWrap: true,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            height: 245,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Welcome Back!', style: AppStyles.h2),
                    Text(
                      "Let's log you in",
                      style: AppStyles.bodyRegular.copyWith(color: AppColors.textLight),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: Text(
                          'Forgot Password?',
                          style: AppStyles.bodyBold.copyWith(color: AppColors.primary),
                        ),
                      ),
                    )
                  ],
                ),
                Positioned(
                  bottom: 15,
                  right: -15,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(13),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Icon(Icons.arrow_forward, color: Colors.white),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

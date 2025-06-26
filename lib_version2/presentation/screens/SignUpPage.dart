import 'package:flutter/material.dart';
import '../theme/app_styles.dart';
import '../theme/app_colors.dart';
import '../widgets/inputFields.dart';
import 'package:page_transition/page_transition.dart';
import './SignInPage.dart';
import '../../services/api.dart';

class SignUpPage extends StatefulWidget {
  final String? pageTitle;

  const SignUpPage({Key? key, this.pageTitle}) : super(key: key);

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  String _selectedGender = 'Male';
  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final passwordHash = _passwordController.text.trim();
    final height = double.tryParse(_heightController.text.trim()) ?? 0;
    final weight = double.tryParse(_weightController.text.trim()) ?? 0;

    if (username.isEmpty || email.isEmpty || passwordHash.isEmpty) {
      _showError('Please fill in all required fields.');
      return;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      _showError('Invalid email format.');
      return;
    }

    if (passwordHash.length < 6) {
      _showError('Password must be at least 6 characters.');
      return;
    }

    if (height <= 0 || weight <= 0) {
      _showError('Height and weight must be positive numbers.');
      return;
    }

    setState(() => _isLoading = true);

    final success = await registerUser(
      userName: username,
      passwordHash: passwordHash,
      email: email,
      gender: _selectedGender.toUpperCase(),
      heightCm: height,
      weightKg: weight,
    );

    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration successful')),
      );
      Navigator.pushReplacementNamed(context, '/main');
    } else {
      _showError('Registration failed. Please try again.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.white,
        title: const Text(
          'Sign Up',
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
                  child: const SignInPage(),
                ),
              );
            },
            child: Text(
              'Sign In',
              style: AppStyles.bodyBold.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome to Grocery Guardian!', style: AppStyles.h2),
                const SizedBox(height: 8),
                Text(
                  'Create your account to get started',
                  style: AppStyles.bodyRegular.copyWith(color: AppColors.textLight),
                ),
                const SizedBox(height: 24),
                _buildTextField('Username', _usernameController),
                const SizedBox(height: 16),
                _buildTextField('Email', _emailController, inputType: TextInputType.emailAddress),
                const SizedBox(height: 16),
                _buildTextField('Password', _passwordController, obscureText: true),
                const SizedBox(height: 16),
                Text('Gender', style: AppStyles.bodyBold),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  items: _genderOptions.map((String gender) {
                    return DropdownMenuItem<String>(
                      value: gender,
                      child: Text(gender),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    setState(() {
                      _selectedGender = value!;
                    });
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 16),
                _buildTextField('Height (cm)', _heightController, inputType: TextInputType.number),
                const SizedBox(height: 16),
                _buildTextField('Weight (kg)', _weightController, inputType: TextInputType.number),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSignUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text('Create Account', style: AppStyles.buttonText),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool obscureText = false,
    TextInputType inputType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppStyles.bodyBold),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: inputType,
          decoration: InputDecoration(
            hintText: 'Enter $label',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }
}

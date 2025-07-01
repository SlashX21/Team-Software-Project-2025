import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';
import '../../services/api_service.dart';
import '../../services/user_service.dart';
import '../widgets/inputFields.dart';
import '../widgets/buttons.dart';
import 'main_navigation_screen.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({Key? key}) : super(key: key);

  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _registeredUsername;

  // Preset test accounts
  final List<Map<String, String>> _testAccounts = [
    {'username': 'tpz', 'password': '123456'},
    {'username': 'tang', 'password': '123456'},
  ];

  @override
  void initState() {
    super.initState();
    // Auto-fill first test account
    _emailController.text = _testAccounts[0]['username']!;
    _passwordController.text = _testAccounts[0]['password']!;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      
      if (_isLogin && _registeredUsername != null) {
        // If switching to login mode and have registered username, auto-fill
        _emailController.text = _registeredUsername!;
        // Keep password for direct login
      } else if (!_isLogin) {
        // If switching to register mode, clear form
        _formKey.currentState?.reset();
        _emailController.clear();
        _passwordController.clear();
        _usernameController.clear();
      }
    });
  }

  void _fillTestAccount(int index) {
    if (index < _testAccounts.length) {
      setState(() {
        _emailController.text = _testAccounts[index]['username']!;
        _passwordController.text = _testAccounts[index]['password']!;
      });
    }
  }

  Future<void> _autoRegisterIfNeeded() async {
    // If login fails, try auto-registration with same info
    try {
      print("🔄 Attempting auto-registration for user: ${_emailController.text.trim()}");
      
      final success = await ApiService.registerUser(
        userName: _emailController.text.trim(),
        email: '${_emailController.text.trim()}@example.com', // Generate default email
        passwordHash: _passwordController.text,
        gender: 'MALE',
        heightCm: 175.0,
        weightKg: 70.0,
      );

      if (success) {
        print("✅ Auto-registration successful");
        // After successful registration, try login again
        await _performLogin();
      } else {
        print("❌ Auto-registration failed");
        _showErrorSnackBar('User does not exist and auto-registration failed. Please register manually.');
      }
    } catch (e) {
      print("❌ Auto-registration error: $e");
      _showErrorSnackBar('Auto-registration failed: $e');
    }
  }

  Future<void> _performLogin() async {
    try {
      print("🔐 尝试登录用户: ${_emailController.text.trim()}");
      
      final userData = await ApiService.loginUser(
        userName: _emailController.text.trim(),
        passwordHash: _passwordController.text,
      );

      print("📥 登录API返回: $userData");

      if (userData != null) {
        final saveSuccess = await UserService.instance.saveUserInfo(userData);
        print("💾 保存用户信息: $saveSuccess");
        
        if (saveSuccess) {
          // 安全的userId类型转换
          final dynamic rawUserId = userData['userId'] ?? userData['user_id'] ?? userData['id'];
          int userId = 1; // 默认值
          
          if (rawUserId is int) {
            userId = rawUserId;
          } else if (rawUserId is String) {
            userId = int.tryParse(rawUserId) ?? 1;
          } else if (rawUserId is double) {
            userId = rawUserId.toInt();
          }
          
          print("✅ Login successful, User ID: $userId");
          _showSuccessSnackBar('Login successful! Welcome back');
          
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => MainNavigationScreen(userId: userId),
            ),
          );
        } else {
          _showErrorSnackBar('Login successful but failed to save user data');
        }
      } else {
        print("❌ Login failed, attempting auto-registration");
        // Login failed, try auto-registration
        await _autoRegisterIfNeeded();
      }
    } catch (e) {
      print("❌ 登录错误: $e");
      
      // 根据错误类型显示不同的用户友好信息
      String errorMessage;
      if (e.toString().contains('database issue') || e.toString().contains('数据库问题')) {
        errorMessage = 'Login system temporarily unavailable, attempting auto-registration...';
        // If database issue, try auto-registration
        await _autoRegisterIfNeeded();
      } else if (e.toString().contains('Network')) {
        errorMessage = 'Network connection error, please check your connection and try again';
      } else if (e.toString().contains('timeout')) {
        errorMessage = 'Connection timeout, please try again later';
      } else {
        errorMessage = 'Login failed, attempting auto-registration...';
        // For other errors, also try auto-registration
        await _autoRegisterIfNeeded();
      }
      
      _showErrorSnackBar(errorMessage);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isLogin) {
        await _performLogin();
      } else {
        // 注册逻辑
        final success = await ApiService.registerUser(
          userName: _usernameController.text.trim(),
          email: _emailController.text.trim(),
          passwordHash: _passwordController.text,
          gender: 'MALE',
          heightCm: 170.0,
          weightKg: 70.0,
        );

        if (success) {
          // Save registered username
          _registeredUsername = _usernameController.text.trim();
          
          _showSuccessSnackBar('Registration successful! Please login');
          setState(() {
            _isLogin = true;
            // Auto-fill login form
            _emailController.text = _registeredUsername!;
            // Keep password unchanged for direct login
          });
        } else {
          _showErrorSnackBar('Registration failed, please try again');
        }
      }
    } catch (e) {
      _showErrorSnackBar('Operation failed, please try again');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.alert,
        duration: Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo and Title
                  Column(
                    children: [
                      Icon(
                        Icons.shopping_basket,
                        size: 80,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Grocery Guardian',
                        style: AppStyles.logo.copyWith(
                          fontSize: 32,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isLogin ? 'Welcome back!' : 'Create your account',
                        style: AppStyles.bodyRegular.copyWith(
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),

                  // 测试账户快速选择
                  if (_isLogin) ...[
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '🚀 Quick Login with Test Account',
                            style: AppStyles.bodyBold.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: _testAccounts.asMap().entries.map((entry) {
                              int index = entry.key;
                              String username = entry.value['username']!;
                              return Expanded(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 4),
                                  child: ElevatedButton(
                                    onPressed: () => _fillTestAccount(index),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.white,
                                      foregroundColor: AppColors.primary,
                                      padding: EdgeInsets.symmetric(vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    child: Text(username, style: TextStyle(fontSize: 12)),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // Form Fields
                  if (!_isLogin) ...[
                    _buildTextField(
                      controller: _usernameController,
                      labelText: 'Username',
                      prefixIcon: Icons.person,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a username';
                        }
                        if (value.trim().length < 3) {
                          return 'Username must be at least 3 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  _buildTextField(
                    controller: _emailController,
                    labelText: _isLogin ? 'Username' : 'Email',
                    prefixIcon: _isLogin ? Icons.person : Icons.email,
                    keyboardType: _isLogin ? TextInputType.text : TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return _isLogin ? 'Please enter your username' : 'Please enter your email';
                      }
                      if (!_isLogin && !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildTextField(
                    controller: _passwordController,
                    labelText: 'Password',
                    prefixIcon: Icons.lock,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        color: AppColors.textLight,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (!_isLogin && value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Submit Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                            ),
                          )
                        : Text(
                            _isLogin ? 'Login' : 'Register',
                            style: AppStyles.buttonText,
                          ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Toggle Mode
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isLogin ? "Don't have an account? " : "Already have an account? ",
                        style: AppStyles.bodyRegular.copyWith(
                          color: AppColors.textLight,
                        ),
                      ),
                      GestureDetector(
                        onTap: _toggleMode,
                        child: Text(
                          _isLogin ? 'Register' : 'Login',
                          style: AppStyles.bodyBold.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // 使用提示
                  if (_isLogin) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '💡 Tip: If account doesn\'t exist, system will auto-register for you',
                        style: AppStyles.bodyRegular.copyWith(
                          color: Colors.blue[700],
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: _isLogin && controller == _emailController 
        ? (value) {
            // 如果用户在登录模式下修改了用户名字段，清除自动填充标记
            if (value != _registeredUsername) {
              _registeredUsername = null;
            }
          }
        : null,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(prefixIcon, color: AppColors.textLight),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.textLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
} 
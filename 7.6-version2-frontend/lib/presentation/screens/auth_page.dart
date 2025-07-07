import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../../services/api_service.dart';
import '../../services/api.dart';
import '../../services/user_service.dart';
import 'main_navigation_screen.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({Key? key}) : super(key: key);

  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _registeredUsername;
  
  // Animation controllers for modern UI effects
  late AnimationController _buttonAnimationController;
  late AnimationController _fadeAnimationController;
  late Animation<double> _fadeAnimation;
  
  // Focus nodes for input field animations
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _usernameFocusNode = FocusNode();
  
  bool _isEmailFocused = false;
  bool _isPasswordFocused = false;
  bool _isUsernameFocused = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _buttonAnimationController = AnimationController(
      duration: Duration(milliseconds: 150),
      vsync: this,
    );
    
    _fadeAnimationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeInOut,
    ));
    
    // Set up focus listeners
    _emailFocusNode.addListener(() {
      setState(() {
        _isEmailFocused = _emailFocusNode.hasFocus;
      });
    });
    
    _passwordFocusNode.addListener(() {
      setState(() {
        _isPasswordFocused = _passwordFocusNode.hasFocus;
      });
    });
    
    _usernameFocusNode.addListener(() {
      setState(() {
        _isUsernameFocused = _usernameFocusNode.hasFocus;
      });
    });
    
    // Start fade-in animation
    _fadeAnimationController.forward();
    
    // Set status bar style
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _buttonAnimationController.dispose();
    _fadeAnimationController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _usernameFocusNode.dispose();
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

  Future<void> _handleUserNotFound() async {
    // Show dialog asking user if they want to register
    final bool? shouldRegister = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('User not found'),
          content: Text('Username "${_emailController.text.trim()}" does not exist.\n\nWould you like to register a new account?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Register'),
            ),
          ],
        );
      },
    );

    if (shouldRegister == true) {
      // Pre-fill registration form with current credentials BEFORE switching mode
      final currentInput = _emailController.text.trim();
      
      setState(() {
        _isLogin = false; // Switch to registration mode
        
        // Immediately set form values within setState to ensure atomicity
        _usernameController.text = currentInput;
        
        // Only modify email if it's not already in email format
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(currentInput)) {
          _emailController.text = '$currentInput@example.com';
        }
        // If it's already an email, keep it as is
      });
      
      _showSuccessSnackBar('Please complete registration information');
    }
  }

  Future<void> _performLogin() async {
    try {
      print("🔐 尝试登录用户: ${_emailController.text.trim()}");
      
      final userData = await loginUser(
        userName: _emailController.text.trim(),
        passwordHash: _passwordController.text,
      );

      print("📥 登录API返回: $userData");

      if (userData != null) {
        final saveSuccess = await UserService.instance.saveUserInfo(userData);
        print("💾 保存用户信息: $saveSuccess");
        
        if (saveSuccess) {
          // 安全的userId类型转换，添加详细日志
          final dynamic rawUserId = userData['userId'] ?? userData['user_id'] ?? userData['id'];
          int userId = 1; // 默认值
          
          print('🔍 Auth: Processing userId for navigation:');
          print('   Raw value: $rawUserId (type: ${rawUserId.runtimeType})');
          
          if (rawUserId is int) {
            userId = rawUserId;
            print('   ✅ Direct int assignment: $userId');
          } else if (rawUserId is String) {
            final parsed = int.tryParse(rawUserId);
            userId = parsed ?? 1;
            print('   🔄 String->int conversion: "$rawUserId" -> $userId ${parsed == null ? "(fallback)" : ""}');
          } else if (rawUserId is double) {
            userId = rawUserId.toInt();
            print('   🔄 Double->int conversion: $rawUserId -> $userId');
          } else {
            print('   ⚠️ Unexpected type, using fallback: ${rawUserId.runtimeType} -> $userId');
          }
          
          print("✅ Login successful, User ID: $userId");
          _showSuccessSnackBar('Login successful! Welcome back');
          
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => MainNavigationScreen(userId: userId),
            ),
          );
        } else {
          print('❌ Login successful but failed to save user data');
          print('   Backend response: $userData');
          _showErrorSnackBar('Login successful but failed to save user data, please retry');
        }
      } else {
        print('❌ Login API returned null');
        _showErrorSnackBar('Username or password incorrect, please check and retry');
      }
    } catch (e) {
      print("❌ 登录错误: $e");
      
      // 根据具体异常类型进行处理
      if (e is UserNotFoundException) {
        print("👤 User not found, switching to registration mode");
        await _handleUserNotFound();
      } else if (e is AuthenticationException) {
        print("🔒 Authentication failed - wrong credentials");
        _showErrorSnackBar('Username or password incorrect');
      } else if (e is ConflictException) {
        print("⚠️ Registration conflict");
        _showErrorSnackBar('Username already exists, please choose another username');
      } else if (e is InternalServerException) {
        print("🖥️ Internal server error occurred");
        _showErrorSnackBar('Internal server error, please try again later');
      } else if (e is ServerException) {
        print("🖥️ Server error occurred");
        _showErrorSnackBar('Login service temporarily unavailable, please try again later');
      } else if (e.toString().contains('Network') || e.toString().contains('network')) {
        print("🌐 Network error occurred");
        _showErrorSnackBar('Network connection failed, please check network settings');
      } else if (e.toString().contains('timeout')) {
        print("⏰ Request timeout");
        _showErrorSnackBar('Connection timeout, please retry');
      } else {
        print("❓ Unknown error occurred");
        _showErrorSnackBar('Login failed, please retry');
      }
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
        final userData = await registerUser(
          userName: _usernameController.text.trim(),
          passwordHash: _passwordController.text,
          email: _emailController.text.trim(),
          gender: 'MALE',
          height: 170.0,
          weight: 70.0,
        );

        if (userData != null) {
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
          _showErrorSnackBar('Registration failed, please retry');
        }
      }
    } catch (e) {
      _showErrorSnackBar('Operation failed, please retry');
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
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                ModernColors.backgroundStart,
                ModernColors.backgroundEnd,
              ],
              stops: [0.0, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Main content
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                        
                        // Logo Container
                        _buildModernLogo(),
                        
                        const SizedBox(height: 80),
                        
                        // User Avatar
                        _buildUserAvatar(),
                        
                        const SizedBox(height: 40),
                        
                        // Welcome Text
                        _buildWelcomeText(),
                        
                        const SizedBox(height: 32),
                        
                        // Form Fields
                        if (!_isLogin) ...[
                          _buildModernTextField(
                            controller: _usernameController,
                            focusNode: _usernameFocusNode,
                            labelText: 'Username',
                            prefixIcon: Icons.person,
                            isFocused: _isUsernameFocused,
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
                        
                        _buildModernTextField(
                          controller: _emailController,
                          focusNode: _emailFocusNode,
                          labelText: _isLogin ? 'Username' : 'Email',
                          prefixIcon: _isLogin ? Icons.person : Icons.email,
                          keyboardType: _isLogin ? TextInputType.text : TextInputType.emailAddress,
                          isFocused: _isEmailFocused,
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
                        
                        _buildModernTextField(
                          controller: _passwordController,
                          focusNode: _passwordFocusNode,
                          labelText: 'Password',
                          prefixIcon: Icons.lock,
                          obscureText: _obscurePassword,
                          isFocused: _isPasswordFocused,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility : Icons.visibility_off,
                              color: ModernColors.darkGray,
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
                        
                        // Modern Button Row
                        _buildModernButtons(),
                        
                        SizedBox(height: 100), // Extra space for scroll
                      ],
                    ),
                  ),
                ),
              ),
              
              // Settings Button - Bottom Right
              _buildSettingsButton(),
            ],
          ),
        ),
      ),
    );
  }

  // 🎨 Modern Logo with Shadow and Health Theme
  Widget _buildModernLogo() {
    return Center(
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: ModernColors.primaryGreen,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Icon(
          Icons.shopping_basket,
          size: 60,
          color: ModernColors.white,
        ),
      ),
    );
  }
  
  // 👤 User Avatar Section
  Widget _buildUserAvatar() {
    return Center(
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: ModernColors.lightGreen,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: ModernColors.lightGreen.withOpacity(0.4),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.person_outline,
          size: 40,
          color: ModernColors.primaryGreen,
        ),
      ),
    );
  }
  
  // 📝 Welcome Text Section
  Widget _buildWelcomeText() {
    return Column(
      children: [
        Text(
          'Grocery Guardian',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: ModernColors.primaryGreen,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isLogin ? 'Welcome back!' : 'Create your account',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: ModernColors.darkGray,
          ),
        ),
      ],
    );
  }
  
  // 📝 Modern Input Field with Material Design 3.0
  Widget _buildModernTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String labelText,
    required IconData prefixIcon,
    required bool isFocused,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: ModernColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isFocused ? ModernColors.primaryGreen : ModernColors.borderGray,
          width: isFocused ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        onChanged: _isLogin && controller == _emailController 
          ? (value) {
              if (value != _registeredUsername) {
                _registeredUsername = null;
              }
            }
          : null,
        style: TextStyle(
          fontSize: 16,
          color: ModernColors.darkGray,
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(
            fontSize: 14,
            color: isFocused ? ModernColors.primaryGreen : ModernColors.darkGray,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(
            prefixIcon, 
            color: isFocused ? ModernColors.primaryGreen : ModernColors.darkGray,
          ),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
  
  // 🔲 Modern Capsule Buttons with Animation
  Widget _buildModernButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Primary Button (Login/Register)
        _buildAnimatedButton(
          text: _isLogin ? 'Log In' : 'Register',
          isPrimary: true,
          onPressed: _isLoading ? null : _handleSubmit,
        ),
        
        const SizedBox(width: 16),
        
        // Secondary Button (opposite action)
        _buildAnimatedButton(
          text: _isLogin ? 'Sign Up' : 'Log In',
          isPrimary: false,
          onPressed: _toggleMode,
        ),
      ],
    );
  }
  
  Widget _buildAnimatedButton({
    required String text,
    required bool isPrimary,
    required VoidCallback? onPressed,
  }) {
    return GestureDetector(
      onTapDown: (_) => _buttonAnimationController.forward(),
      onTapUp: (_) => _buttonAnimationController.reverse(),
      onTapCancel: () => _buttonAnimationController.reverse(),
      onTap: onPressed,
      child: AnimatedBuilder(
        animation: _buttonAnimationController,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 - (_buttonAnimationController.value * 0.05),
            child: Container(
              width: 120,
              height: 48,
              decoration: BoxDecoration(
                color: isPrimary ? ModernColors.primaryGreen : ModernColors.lightGreen,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: (isPrimary ? ModernColors.primaryGreen : ModernColors.lightGreen)
                        .withOpacity(0.3),
                    blurRadius: isPrimary ? 8 : 6,
                    offset: Offset(0, isPrimary ? 4 : 2),
                  ),
                ],
              ),
              child: Center(
                child: _isLoading && isPrimary
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(ModernColors.white),
                        ),
                      )
                    : Text(
                        text,
                        style: TextStyle(
                          color: isPrimary ? ModernColors.white : ModernColors.primaryGreen,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  // ⚙️ Settings Button in Bottom Right
  Widget _buildSettingsButton() {
    return Positioned(
      bottom: 60,
      right: 24,
      child: Container(
        width: 80,
        height: 32,
        decoration: BoxDecoration(
          color: ModernColors.lightGreen,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: ModernColors.lightGreen.withOpacity(0.3),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.settings_outlined,
              size: 16,
              color: ModernColors.primaryGreen,
            ),
            const SizedBox(width: 4),
            Text(
              'Settings',
              style: TextStyle(
                fontSize: 11,
                color: ModernColors.primaryGreen,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 
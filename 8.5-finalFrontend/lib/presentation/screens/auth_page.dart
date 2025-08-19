import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/screen_adapter.dart';
import '../theme/responsive_layout.dart';
import '../widgets/adaptive_widgets.dart';
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
  final FocusNode _heightFocusNode = FocusNode();
  final FocusNode _weightFocusNode = FocusNode();
  final FocusNode _ageFocusNode = FocusNode();
  
  bool _isEmailFocused = false;
  bool _isPasswordFocused = false;
  bool _isUsernameFocused = false;
  bool _isHeightFocused = false;
  bool _isWeightFocused = false;
  bool _isAgeFocused = false;

  // Registration field control variables
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  String _activityLevel = 'MODERATELY_ACTIVE';
  String _nutritionGoal = 'HEALTH_MAINTENANCE';
  String _selectedGender = 'MALE';

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
    
    _heightFocusNode.addListener(() {
      setState(() {
        _isHeightFocused = _heightFocusNode.hasFocus;
      });
    });
    
    _weightFocusNode.addListener(() {
      setState(() {
        _isWeightFocused = _weightFocusNode.hasFocus;
      });
    });
    
    _ageFocusNode.addListener(() {
      setState(() {
        _isAgeFocused = _ageFocusNode.hasFocus;
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
    _heightController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    _buttonAnimationController.dispose();
    _fadeAnimationController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _usernameFocusNode.dispose();
    _heightFocusNode.dispose();
    _weightFocusNode.dispose();
    _ageFocusNode.dispose();
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
        _heightController.clear();
        _weightController.clear();
        _ageController.clear();
        _activityLevel = 'MODERATELY_ACTIVE';
        _nutritionGoal = 'HEALTH_MAINTENANCE';
        _selectedGender = 'MALE';
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
      print("Attempting to login user: ${_emailController.text.trim()}");
      
      final userData = await loginUser(
        userName: _emailController.text.trim(),
        passwordHash: _passwordController.text,
      );

      print("Login API response: $userData");

      if (userData != null) {
        final saveSuccess = await UserService.instance.saveUserInfo(userData);
        print("Saving user info: $saveSuccess");
        
        if (saveSuccess) {
          // Safe userId type conversion with detailed logging
          final dynamic rawUserId = userData['userId'] ?? userData['user_id'] ?? userData['id'];
          int userId = 1; // Default value
          
          print('Auth: Processing userId for navigation:');
          print('   Raw value: $rawUserId (type: ${rawUserId.runtimeType})');
          
          if (rawUserId is int) {
            userId = rawUserId;
            print('   Direct int assignment: $userId');
          } else if (rawUserId is String) {
            final parsed = int.tryParse(rawUserId);
            userId = parsed ?? 1;
            print('   String->int conversion: "$rawUserId" -> $userId ${parsed == null ? "(fallback)" : ""}');
          } else if (rawUserId is double) {
            userId = rawUserId.toInt();
            print('   Double->int conversion: $rawUserId -> $userId');
          } else {
            print('   Unexpected type, using fallback: ${rawUserId.runtimeType} -> $userId');
          }
          
          print("Login successful, User ID: $userId");
          _showSuccessSnackBar('Login successful! Welcome back');
          
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => MainNavigationScreen(userId: userId),
            ),
          );
        } else {
          print('Login successful but failed to save user data');
          print('   Backend response: $userData');
          _showErrorSnackBar('Login successful but failed to save user data, please retry');
        }
      } else {
        print('Login API returned null');
        _showErrorSnackBar('Username or password incorrect, please check and retry');
      }
    } catch (e) {
      print("Login error: $e");
      
      // Handle specific exception types
      if (e is UserNotFoundException) {
        print("User not found, switching to registration mode");
        await _handleUserNotFound();
      } else if (e is AuthenticationException) {
        print("Authentication failed - wrong credentials");
        _showErrorSnackBar('Username or password incorrect');
      } else if (e is ConflictException) {
        print("Registration conflict");
        _showErrorSnackBar('Username already exists, please choose another username');
      } else if (e is InternalServerException) {
        print("Internal server error occurred");
        _showErrorSnackBar('Internal server error, please try again later');
      } else if (e is ServerException) {
        print("Server error occurred");
        _showErrorSnackBar('Login service temporarily unavailable, please try again later');
      } else if (e.toString().contains('Network') || e.toString().contains('network')) {
        print("Network error occurred");
        _showErrorSnackBar('Network connection failed, please check network settings');
      } else if (e.toString().contains('timeout')) {
        print("Request timeout");
        _showErrorSnackBar('Connection timeout, please retry');
      } else {
        print("Unknown error occurred");
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
        // Registration logic
        print('Registration form data:');
        print('  Username: ${_usernameController.text.trim()}');
        print('  Email: ${_emailController.text.trim()}');
        print('  Age: ${_ageController.text} -> ${int.tryParse(_ageController.text)}');
        print('  Gender: $_selectedGender');
        print('  Height: ${_heightController.text} -> ${double.tryParse(_heightController.text) ?? 170.0}');
        print('  Weight: ${_weightController.text} -> ${double.tryParse(_weightController.text) ?? 70.0}');
        print('  Activity Level: $_activityLevel');
        print('  Nutrition Goal: $_nutritionGoal');
        
        final userData = await registerUser(
          userName: _usernameController.text.trim(),
          passwordHash: _passwordController.text,
          email: _emailController.text.trim(),
          age: int.tryParse(_ageController.text),
          gender: _selectedGender,
          height: double.tryParse(_heightController.text) ?? 170.0,
          weight: double.tryParse(_weightController.text) ?? 70.0,
          activityLevel: _activityLevel,
          goal: _nutritionGoal,
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
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top,
                  ),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                        SizedBox(height: ResponsiveLayout.isNarrowScreen(context) 
                          ? MediaQuery.of(context).size.height * 0.05  // 窄屏只用5%
                          : MediaQuery.of(context).size.height * 0.08), // 普通屏幕用8%
                        
                        // Logo Container
                        _buildModernLogo(),
                        
                        SizedBox(height: ResponsiveLayout.isNarrowScreen(context) ? 50 : 80),
                        
                        // User Avatar
                        _buildUserAvatar(),
                        
                        SizedBox(height: ResponsiveLayout.isNarrowScreen(context) ? 30 : 40),
                        
                        // Welcome Text
                        _buildWelcomeText(),
                        
                        SizedBox(height: ResponsiveLayout.isNarrowScreen(context) ? 20 : 32),
                        
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
                          
                          _buildModernTextField(
                            controller: _emailController,
                            focusNode: _emailFocusNode,
                            labelText: 'Email',
                            prefixIcon: Icons.email,
                            keyboardType: TextInputType.emailAddress,
                            isFocused: _isEmailFocused,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                        ] else ...[
                          // Login mode - show username field
                          _buildModernTextField(
                            controller: _emailController,
                            focusNode: _emailFocusNode,
                            labelText: 'Username',
                            prefixIcon: Icons.person,
                            keyboardType: TextInputType.text,
                            isFocused: _isEmailFocused,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your username';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                        
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
                        
                        const SizedBox(height: 16),
                        if (!_isLogin) ...[
                          // Age input field
                          _buildModernTextField(
                            controller: _ageController,
                            focusNode: _ageFocusNode,
                            labelText: 'Age',
                            prefixIcon: Icons.cake,
                            isFocused: _isAgeFocused,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your age';
                              }
                              final age = int.tryParse(value);
                              if (age == null || age < 13 || age > 120) {
                                return 'Age should be between 13 and 120';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Gender selection with modern styling
                          _buildModernDropdown(
                            value: _selectedGender,
                            labelText: 'Gender',
                            icon: Icons.person_outline,
                            items: [
                              DropdownMenuItem(value: 'MALE', child: Text('Male')),
                              DropdownMenuItem(value: 'FEMALE', child: Text('Female')),
                              DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _selectedGender = val!;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Height and Weight section with improved layout
                          _buildSectionTitle('Physical Information'),
                          const SizedBox(height: 12),
                          
                          // Height and Weight in a row
                          Row(
                            children: [
                              Expanded(
                                child: _buildModernTextField(
                                  controller: _heightController,
                                  focusNode: _heightFocusNode,
                                  labelText: 'Height (cm)',
                                  prefixIcon: Icons.height,
                                  isFocused: _isHeightFocused,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Required';
                                    }
                                    final num? h = num.tryParse(value);
                                    if (h == null || h < 50 || h > 250) {
                                      return '50-250 cm';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildModernTextField(
                                  controller: _weightController,
                                  focusNode: _weightFocusNode,
                                  labelText: 'Weight (kg)',
                                  prefixIcon: Icons.monitor_weight,
                                  isFocused: _isWeightFocused,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Required';
                                    }
                                    final num? w = num.tryParse(value);
                                    if (w == null || w < 20 || w > 300) {
                                      return '20-300 kg';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Activity and Nutrition Goals section
                          _buildSectionTitle('Goals & Activity'),
                          const SizedBox(height: 12),
                          
                          // Activity level dropdown with modern styling
                          _buildModernDropdown(
                            value: _activityLevel,
                            labelText: 'Activity Level',
                            icon: Icons.fitness_center,
                            items: [
                              DropdownMenuItem(value: 'LIGHTLY_ACTIVE', child: Text('Lightly Active')),
                              DropdownMenuItem(value: 'MODERATELY_ACTIVE', child: Text('Moderately Active')),
                              DropdownMenuItem(value: 'VERY_ACTIVE', child: Text('Very Active')),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _activityLevel = val!;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Nutrition goal dropdown with modern styling
                          _buildModernDropdown(
                            value: _nutritionGoal,
                            labelText: 'Nutrition Goal',
                            icon: Icons.track_changes,
                            items: [
                              DropdownMenuItem(value: 'HEALTH_MAINTENANCE', child: Text('Health Maintenance')),
                              DropdownMenuItem(value: 'WEIGHT_LOSS', child: Text('Weight Loss')),
                              DropdownMenuItem(value: 'MUSCLE_GAIN', child: Text('Muscle Gain')),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _nutritionGoal = val!;
                              });
                            },
                          ),
                          const SizedBox(height: 24),
                        ],
                        
                        SizedBox(height: ResponsiveLayout.isNarrowScreen(context) ? 20 : 32),
                        
                        // Modern Button Row
                        _buildModernButtons(),
                        
                        SizedBox(height: ResponsiveLayout.isNarrowScreen(context) 
                          ? 40  // 窄屏减少底部空间
                          : 60), // 普通屏幕适中空间
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              // Settings Button - Bottom Right
            ],
          ),
        ),
      ),
    );
  }

  // Modern Logo with Shadow and Health Theme
  Widget _buildModernLogo() {
    return Center(
      child: Image.asset(
        'assets/images/logo_icon.png',
        fit: BoxFit.contain,
        width: 120,
        height: 120,
      ),
    );
  }
  
  // User Avatar Section
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
  
  // Welcome Text Section
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
  
  // Modern Input Field with Material Design 3.0
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
    List<TextInputFormatter>? inputFormatters,
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
        inputFormatters: inputFormatters,
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
  
  // Modern Capsule Buttons with Animation
  Widget _buildModernButtons() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Row(
        children: [
          // Primary Button (Login/Register)
          Expanded(
            child: _buildAnimatedButton(
              text: _isLogin ? 'Log In' : 'Register',
              isPrimary: true,
              onPressed: _isLoading ? null : _handleSubmit,
            ),
          ),
          
          AdaptiveSpacing.horizontal(16),
          
          // Secondary Button (opposite action)
          Expanded(
            child: _buildAnimatedButton(
              text: _isLogin ? 'Sign Up' : 'Log In',
              isPrimary: false,
              onPressed: _toggleMode,
            ),
          ),
        ],
      ),
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
              height: 48.h,
              constraints: BoxConstraints(minWidth: 120.w),
              decoration: BoxDecoration(
                color: isPrimary ? ModernColors.primaryGreen : ModernColors.lightGreen,
                borderRadius: BorderRadius.circular(24.r),
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
                    ? AdaptiveLoadingIndicator(
                        size: 20,
                        strokeWidth: 2,
                        color: ModernColors.white,
                      )
                    : AdaptiveText(
                        text: text,
                        style: TextStyle(
                          color: isPrimary ? ModernColors.white : ModernColors.primaryGreen,
                          fontSize: ResponsiveFontSizes.base.getValue(context),
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                        useResponsiveFontSize: true,
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  // Section title builder for better organization
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: ModernColors.primaryGreen,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
  
  // Modern dropdown builder with consistent styling
  Widget _buildModernDropdown({
    required String value,
    required String labelText,
    required IconData icon,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: ModernColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ModernColors.borderGray,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: labelText,
          prefixIcon: Icon(icon, color: ModernColors.primaryGreen),
          filled: true,
          fillColor: ModernColors.white,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        style: TextStyle(
          fontSize: 16,
          color: ModernColors.darkGray,
          fontWeight: FontWeight.w400,
        ),
        items: items,
        onChanged: onChanged,
        isExpanded: true,
        icon: Icon(Icons.arrow_drop_down, color: ModernColors.primaryGreen),
      ),
    );
  }
  
  // Settings Button in Bottom Right
  // Removed _buildSettingsButton method
} 
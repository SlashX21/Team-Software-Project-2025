import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';
import '../../theme/screen_adapter.dart';
import '../../theme/responsive_layout.dart';
import '../../widgets/adaptive_widgets.dart' as adaptive;
import '../../../services/user_service.dart';
import '../../../services/error_handler.dart';
import '../../../services/performance_monitor.dart';
import '../../../services/api.dart';
import 'package:page_transition/page_transition.dart';
import '../auth_page.dart';
import 'allergen_management_page.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userProfile;
  List<Map<String, dynamic>>? _userAllergens;
  bool _isLoading = true;
  bool _hasError = false;
  String? _passwordHash;
  double? _dailySugarGoal;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final monitor = PerformanceMonitor();
    final errorHandler = ErrorHandler();
    
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      monitor.startTimer('profile_load_total');
      
      // 检查用户是否已登录
      final isLoggedIn = await UserService.instance.isLoggedIn();
      if (!isLoggedIn) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
        
        if (mounted) {
          errorHandler.showErrorSnackBar(
            context,
            ApiErrorResult(
              type: ErrorType.unauthorized,
              userMessage: 'Need to login again',
              technicalMessage: 'User not logged in',
              actionRequired: 'login',
            ),
            onAction: _handleLogout,
          );
        }
        return;
      }

      // 获取当前用户ID
      final userId = await UserService.instance.getCurrentUserId();
      if (userId == null) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
        return;
      }

      // 并行加载用户信息和过敏原信息
      monitor.startTimer('profile_api_calls');
      
      final results = await Future.wait([
        getUserDetails(userId),
        getUserAllergens(userId),
      ]);
      
      monitor.endTimer('profile_api_calls');

      final userData = results[0] as Map<String, dynamic>?;
      final userAllergens = results[1] as List<Map<String, dynamic>>?;

      if (userData != null) {
        setState(() {
          _userProfile = userData;
          _userAllergens = userAllergens ?? [];
          _isLoading = false;
          _passwordHash = userData['passwordHash'];
        });
        
        // 加载糖分目标
        try {
          final sugarGoal = await getSugarGoal(userId);
          if (sugarGoal != null) {
            setState(() {
              _dailySugarGoal = sugarGoal.dailyGoalMg / 1000; // 转换为克
            });
          }
        } catch (e) {
          print('⚠️ 加载糖分目标失败: $e');
        }
        
        final totalTime = monitor.endTimer('profile_load_total');
        print('✅ Profile loaded successfully in ${totalTime.inMilliseconds}ms');
        
      } else {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
        
        if (mounted) {
          errorHandler.showErrorSnackBar(
            context,
            errorHandler.handleApiError('Profile data not found', context: 'profile'),
            onRetry: _loadUserProfile,
          );
        }
      }
    } catch (e) {
      monitor.endTimer('profile_load_total');
      print('❌ Error loading user profile: $e');
      
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
      
      if (mounted) {
        final errorResult = errorHandler.handleApiError(e, context: 'profile');
        errorHandler.showErrorSnackBar(
          context,
          errorResult,
          onRetry: errorResult.canRetry ? _loadUserProfile : null,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile', style: AppStyles.h2.copyWith(color: AppColors.white)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.white),
            onPressed: _loadUserProfile,
          ),
          IconButton(
            icon: Icon(Icons.edit, color: AppColors.white),
            onPressed: _showEditDialog,
          ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text('Loading profile...', style: AppStyles.bodyRegular),
          ],
        ),
      );
    }

    if (_hasError || _userProfile == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.alert),
            SizedBox(height: 16),
            Text('Failed to load profile', style: AppStyles.h2),
            SizedBox(height: 8),
            Text('Please try again later', style: AppStyles.bodyRegular),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadUserProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text('Retry', style: AppStyles.bodyBold.copyWith(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Profile Header
        _buildProfileHeader(),
        SizedBox(height: 24),
        
        // Basic Information Section
        _buildSection(
          title: 'Basic Information',
          children: [
            _buildInfoRow('Username', _userProfile!['userName'] ?? 'N/A'),
            _buildInfoRow('Email', _userProfile!['email'] ?? 'N/A'),
          ],
        ),
        SizedBox(height: 20),
        
        // Health Information Section
        _buildModernSection(
          title: 'Health Information',
          icon: Icons.health_and_safety,
          children: [
            _buildModernInfoCard(
              icon: Icons.cake,
              label: 'Age',
              value: _userProfile!['age'] != null ? '${_userProfile!['age']} years' : 'N/A',
              color: Colors.orange,
            ),
            _buildModernInfoCard(
              icon: _userProfile!['gender'] == 'FEMALE' ? Icons.person_2 : Icons.person,
              label: 'Gender',
              value: _userProfile!['gender'] ?? 'N/A',
              color: Colors.purple,
            ),
            _buildModernInfoCard(
              icon: Icons.height,
              label: 'Height',
              value: _userProfile!['heightCm'] != null ? '${_userProfile!['heightCm']} cm' : 'N/A',
              color: Colors.blue,
            ),
            _buildModernInfoCard(
              icon: Icons.monitor_weight,
              label: 'Weight',
              value: _userProfile!['weightKg'] != null ? '${_userProfile!['weightKg']} kg' : 'N/A',
              color: Colors.green,
            ),
            _buildModernInfoCard(
              icon: Icons.fitness_center,
              label: 'Activity Level',
              value: _getActivityLevelDescription(_userProfile!['activityLevel']) ?? 'N/A',
              color: Colors.red,
            ),
          ],
        ),
        SizedBox(height: 20),
        

        
        // Allergies Section
        _buildSection(
          title: 'Allergies & Restrictions',
          children: [
            if (_userAllergens != null && _userAllergens!.isNotEmpty) ...[
              ..._userAllergens!.map((allergen) => _buildAllergenRow(allergen)),
              SizedBox(height: 12),
            ] else ...[
              _buildInfoRow('Allergies', 'No allergies recorded'),
            ],
            _buildSettingsTile(
              icon: Icons.warning,
              title: 'Allergen Management',
              subtitle: 'Manage all your allergies and dietary restrictions',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AllergenManagementPage(),
                  ),
                ).then((_) {
                  // 返回时刷新用户配置文件以显示更新的过敏原信息
                  _loadUserProfile();
                });
              },
            ),
          ],
        ),
        SizedBox(height: 32),
        
        // App Settings Section
        _buildSection(
          title: 'App Settings',
          children: [
            _buildSettingsTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Settings',
              subtitle: 'Control your data privacy',
              onTap: () => _showFeatureDialog('Privacy Settings'),
            ),
            _buildSettingsTile(
              icon: Icons.help_outline,
              title: 'Help & Support',
              subtitle: 'Get help and send feedback',
              onTap: () => _showFeatureDialog('Help & Support'),
            ),
            _buildSettingsTile(
              icon: Icons.logout,
              title: 'Logout',
              subtitle: 'Sign out of your account',
              onTap: _handleLogout,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfileHeader() {
    final userName = _userProfile!['userName'] ?? 'User';
    final email = _userProfile!['email'] ?? 'No email';
    final nutritionGoal = _getNutritionGoalDescription(_userProfile!['nutritionGoal']) ?? 'No goal set';
    final age = _userProfile!['age'];
    final gender = _userProfile!['gender'];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                // Enhanced Profile Avatar
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    gender == 'FEMALE' ? Icons.person_2 : Icons.person,
                    size: 45,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(width: 20),
                
                // Profile Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: AppStyles.h1.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),

                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.email, color: Colors.white70, size: 16),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              email,
                              style: AppStyles.bodyRegular.copyWith(
                                color: Colors.white70,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (age != null) ...[
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.cake, color: Colors.white70, size: 16),
                            SizedBox(width: 4),
                            Text(
                              '$age years old',
                              style: AppStyles.bodyRegular.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            // Goal Badge
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.flag, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    nutritionGoal,
                    style: AppStyles.bodyBold.copyWith(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppStyles.bodyBold),
          SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildModernSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                SizedBox(width: 12),
                Text(
                  title,
                  style: AppStyles.h2.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppStyles.bodyRegular.copyWith(
                    color: AppColors.textLight,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: AppStyles.bodyBold.copyWith(
                    color: AppColors.textDark,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              AppColors.primary.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppStyles.bodyBold.copyWith(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppStyles.bodyRegular.copyWith(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isAlert = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppStyles.bodyRegular.copyWith(
                color: AppColors.textLight,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppStyles.bodyRegular.copyWith(
                color: isAlert ? AppColors.alert : AppColors.textDark,
                fontWeight: isAlert ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllergenRow(Map<String, dynamic> allergen) {
    final allergenName = allergen['allergenName'] ?? 'Unknown Allergen';
    final severity = allergen['severityLevel'] ?? 'MODERATE';
    final notes = allergen['notes'] ?? '';
    final severityColor = _getSeverityColor(severity);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: severityColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: severityColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber,
            color: severityColor,
            size: 20,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  allergenName,
                  style: AppStyles.bodyBold.copyWith(
                    color: AppColors.textDark,
                  ),
                ),
                if (severity.isNotEmpty) ...[
                  SizedBox(height: 2),
                  Text(
                    'Severity: ${_getSeverityText(severity)}',
                    style: AppStyles.bodyRegular.copyWith(
                      color: AppColors.textLight,
                      fontSize: 12,
                    ),
                  ),
                ],
                if (notes.isNotEmpty) ...[
                  SizedBox(height: 2),
                  Text(
                    notes,
                    style: AppStyles.bodyRegular.copyWith(
                      color: AppColors.textDark,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                color: title == 'Logout' ? AppColors.alert : AppColors.primary,
                size: 24,
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title, 
                      style: AppStyles.bodyBold.copyWith(
                        color: title == 'Logout' ? AppColors.alert : AppColors.textDark,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppStyles.bodyRegular.copyWith(
                        color: AppColors.textLight,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.textLight,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toUpperCase()) {
      case 'MILD':
        return Colors.orangeAccent;
      case 'MODERATE':
        return Color(0xFFFD4209);
      case 'SEVERE':
        return Color(0xFFCC0000);
      default:
        return AppColors.textLight;
    }
  }

  String _getSeverityText(String severity) {
    switch (severity.toUpperCase()) {
      case 'MILD':
        return 'Mild';
      case 'MODERATE':
        return 'Moderate';
      case 'SEVERE':
        return 'Severe';
      default:
        return 'Unknown';
    }
  }

  String? _getActivityLevelDescription(String? activityLevel) {
    if (activityLevel == null) return null;
    
    switch (activityLevel.toUpperCase()) {
      case 'SEDENTARY':
        return 'Sedentary - Little or no exercise';
      case 'LIGHTLY_ACTIVE':
        return 'Lightly Active - 1-3 days/week light exercise';
      case 'MODERATELY_ACTIVE':
        return 'Moderately Active - 3-5 days/week moderate exercise';
      case 'VERY_ACTIVE':
        return 'Very Active - 6-7 days/week hard exercise';
      case 'EXTRA_ACTIVE':
        return 'Extra Active - very hard exercise or physical job';
      default:
        return activityLevel;
    }
  }

  String? _getNutritionGoalDescription(String? nutritionGoal) {
    if (nutritionGoal == null) return null;
    
    switch (nutritionGoal.toUpperCase()) {
      case 'WEIGHT_LOSS':
      case 'LOSE_WEIGHT':
        return 'Weight Loss';
      case 'WEIGHT_GAIN':
        return 'Weight Gain';
      case 'MUSCLE_GAIN':
      case 'GAIN_MUSCLE':
        return 'Muscle Gain';
      case 'MAINTENANCE':
      case 'MAINTAIN':
        return 'Maintenance';
      case 'GENERAL_HEALTH':
        return 'General Health';
      case 'HEALTH_MAINTENANCE':
        return 'Health Maintenance';
      default:
        return nutritionGoal;
    }
  }

  void _showEditDialog() {
    if (_userProfile == null) return;

    final userNameController = TextEditingController(text: _userProfile!['userName']?.toString() ?? '');
    final emailController = TextEditingController(text: _userProfile!['email']?.toString() ?? '');
    final ageController = TextEditingController(text: _userProfile!['age']?.toString() ?? '');
    final heightController = TextEditingController(text: _userProfile!['heightCm']?.toString() ?? '');
    final weightController = TextEditingController(text: _userProfile!['weightKg']?.toString() ?? '');
    
    String? selectedActivityLevel = _userProfile!['activityLevel'];
    String? selectedNutritionGoal = _userProfile!['nutritionGoal'];
    String? selectedGender = _userProfile!['gender'];

    adaptive.showAdaptiveDialog(
      context: context,
      barrierDismissible: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.edit, color: Colors.white, size: 24),
                      ),
                      adaptive.AdaptiveSpacing.horizontal(16),
                      Expanded(
                        child: adaptive.AdaptiveText(
                          text: 'Edit Profile',
                          style: AppStyles.h2.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          useResponsiveFontSize: true,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                
                // Form Content
                Flexible(
                  child: StatefulBuilder(
                    builder: (context, setState) {
                      return adaptive.AdaptiveSingleChildScrollView(
                        padding: EdgeInsets.all(20.r),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                                                         // Personal Information Section
                             _buildFormSection(
                               title: 'Basic Information',
                               icon: Icons.person,
                               children: [
                                 _buildReadOnlyField(
                                   label: 'Username',
                                   value: userNameController.text,
                                   icon: Icons.person_outline,
                                 ),
                                 adaptive.AdaptiveSpacing.vertical(16),
                                 _buildReadOnlyField(
                                   label: 'Email Address',
                                   value: emailController.text,
                                   icon: Icons.email_outlined,
                                 ),
                               ],
                             ),
                            
                            SizedBox(height: 24),
                            
                                                         // Physical Information Section
                             _buildFormSection(
                               title: 'Physical Information',
                               icon: Icons.fitness_center,
                               children: [
                                 Row(
                                   children: [
                                     Expanded(
                                       child: _buildModernTextField(
                                         controller: ageController,
                                         label: 'Age',
                                         hint: '13-120',
                                         icon: Icons.cake,
                                         keyboardType: TextInputType.number,
                                       ),
                                     ),
                                     SizedBox(width: 16),
                                     Expanded(
                                       child: _buildModernDropdown(
                                         label: 'Gender',
                                         icon: Icons.person_2_outlined,
                                         value: selectedGender,
                                         items: [
                                           DropdownMenuItem(value: 'MALE', child: Text('Male')),
                                           DropdownMenuItem(value: 'FEMALE', child: Text('Female')),
                                           DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                                         ],
                                         onChanged: (value) {
                                           setState(() {
                                             selectedGender = value;
                                           });
                                         },
                                       ),
                                     ),
                                   ],
                                 ),
                                 adaptive.AdaptiveSpacing.vertical(16),
                                 Row(
                                   children: [
                                     Expanded(
                                       child: _buildModernTextField(
                                         controller: heightController,
                                         label: 'Height (cm)',
                                         hint: '100-250',
                                         icon: Icons.height,
                                         keyboardType: TextInputType.number,
                                       ),
                                     ),
                                     SizedBox(width: 16),
                                     Expanded(
                                       child: _buildModernTextField(
                                         controller: weightController,
                                         label: 'Weight (kg)',
                                         hint: '30-300',
                                         icon: Icons.monitor_weight_outlined,
                                         keyboardType: TextInputType.number,
                                       ),
                                     ),
                                   ],
                                 ),
                               ],
                             ),
                            
                            SizedBox(height: 24),
                            
                                                         // Health Goals Section
                             _buildFormSection(
                               title: 'Health Goals',
                               icon: Icons.flag,
                               children: [
                                 _buildModernDropdown(
                                   label: 'Activity Level',
                                   icon: Icons.directions_run,
                                   value: selectedActivityLevel,
                                   items: [
                                     DropdownMenuItem(
                                       value: 'LIGHTLY_ACTIVE',
                                       child: Text('Lightly Active'),
                                     ),
                                     DropdownMenuItem(
                                       value: 'MODERATELY_ACTIVE',
                                       child: Text('Moderately Active'),
                                     ),
                                     DropdownMenuItem(
                                       value: 'VERY_ACTIVE',
                                       child: Text('Very Active'),
                                     ),
                                   ],
                                   onChanged: (value) {
                                     setState(() {
                                       selectedActivityLevel = value;
                                     });
                                   },
                                 ),
                                 adaptive.AdaptiveSpacing.vertical(16),
                                 _buildModernDropdown(
                                   label: 'Nutrition Goal',
                                   icon: Icons.track_changes,
                                   value: selectedNutritionGoal,
                                   items: [
                                     DropdownMenuItem(
                                       value: 'HEALTH_MAINTENANCE',
                                       child: Text('Health Maintenance'),
                                     ),
                                     DropdownMenuItem(
                                       value: 'WEIGHT_LOSS',
                                       child: Text('Weight Loss'),
                                     ),
                                     DropdownMenuItem(
                                       value: 'MUSCLE_GAIN',
                                       child: Text('Muscle Gain'),
                                     ),
                                   ],
                                   onChanged: (value) {
                                     setState(() {
                                       selectedNutritionGoal = value;
                                     });
                                   },
                                 ),
                               ],
                             ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                
                // Action Buttons
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(color: AppColors.primary),
                          ),
                                                     child: Text(
                             'Cancel',
                             style: AppStyles.bodyBold.copyWith(
                               color: AppColors.primary,
                             ),
                           ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            await _performEditProfile(
                              userNameController.text,
                              emailController.text,
                              ageController.text,
                              selectedGender,
                              heightController.text,
                              weightController.text,
                              selectedActivityLevel,
                              selectedNutritionGoal,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                                                     child: Text(
                             'Save',
                             style: AppStyles.bodyBold.copyWith(
                               color: Colors.white,
                             ),
                           ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ),
    );
  }

  Widget _buildFormSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              SizedBox(width: 12),
              Text(
                title,
                style: AppStyles.bodyBold.copyWith(
                  color: AppColors.textDark,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool isRequired = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: isRequired ? '$label *' : label,
          hintText: hint,
          prefixIcon: Icon(icon, color: AppColors.primary),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          labelStyle: AppStyles.bodyRegular.copyWith(
            color: AppColors.textLight,
          ),
          hintStyle: AppStyles.bodyRegular.copyWith(
            color: AppColors.textLight.withOpacity(0.6),
          ),
        ),
        style: AppStyles.bodyRegular.copyWith(
          color: AppColors.textDark,
        ),
      ),
    );
  }

     Widget _buildModernDropdown({
     required String label,
     required IconData icon,
     required String? value,
     required List<DropdownMenuItem<String>> items,
     required ValueChanged<String?> onChanged,
   }) {
     return Container(
       decoration: BoxDecoration(
         color: Colors.white,
         borderRadius: BorderRadius.circular(12),
         border: Border.all(color: Colors.grey[300]!),
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
         items: items,
         onChanged: onChanged,
         decoration: InputDecoration(
           labelText: label,
           prefixIcon: Icon(icon, color: AppColors.primary),
           border: InputBorder.none,
           contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
           labelStyle: AppStyles.bodyRegular.copyWith(
             color: AppColors.textLight,
           ),
         ),
         style: AppStyles.bodyRegular.copyWith(
           color: AppColors.textDark,
         ),
         dropdownColor: Colors.white,
         icon: Icon(Icons.arrow_drop_down, color: AppColors.primary),
         isExpanded: true,
       ),
     );
   }

   Widget _buildReadOnlyField({
     required String label,
     required String value,
     required IconData icon,
   }) {
     return Container(
       decoration: BoxDecoration(
         color: Colors.grey[100],
         borderRadius: BorderRadius.circular(12),
         border: Border.all(color: Colors.grey[300]!),
       ),
       child: Padding(
         padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
         child: Row(
           children: [
             Icon(icon, color: AppColors.textLight, size: 20),
             SizedBox(width: 12),
             Expanded(
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text(
                     label,
                     style: AppStyles.bodyRegular.copyWith(
                       color: AppColors.textLight,
                       fontSize: 12,
                     ),
                   ),
                   SizedBox(height: 2),
                   Text(
                     value,
                     style: AppStyles.bodyBold.copyWith(
                       color: AppColors.textDark,
                       fontSize: 16,
                     ),
                   ),
                 ],
               ),
             ),
             Icon(Icons.lock, color: AppColors.textLight, size: 16),
           ],
         ),
       ),
     );
   }

  Future<void> _performEditProfile(
    String userName,
    String email,
    String ageText,
    String? gender,
    String heightText,
    String weightText,
    String? activityLevel,
    String? nutritionGoal,
  ) async {
    try {
      // Username and email are read-only, so we use the original values
      final originalUserName = _userProfile!['userName']?.toString() ?? '';
      final originalEmail = _userProfile!['email']?.toString() ?? '';

      // Validate other fields
      final age = int.tryParse(ageText);
      final height = int.tryParse(heightText);
      final weight = double.tryParse(weightText);

      if (age != null && (age < 13 || age > 120)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Age must be between 13 and 120')),
        );
        return;
      }

      if (height != null && (height < 100 || height > 250)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Height must be between 100 and 250 cm')),
        );
        return;
      }

      if (weight != null && (weight < 30 || weight > 300)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Weight must be between 30 and 300 kg')),
        );
        return;
      }

      final userId = await UserService.instance.getCurrentUserId();
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please log in again to update your profile')),
        );
        return;
      }

      // Validate userId is positive
      if (userId <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid user session. Please log in again.')),
        );
        return;
      }

      final updateData = <String, dynamic>{};
      updateData['userName'] = originalUserName;
      updateData['email'] = originalEmail;
      if (age != null) updateData['age'] = age;
      if (gender != null) updateData['gender'] = gender;
      if (height != null) updateData['heightCm'] = height;
      if (weight != null) updateData['weightKg'] = weight;
      if (activityLevel != null) updateData['activityLevel'] = activityLevel;
      if (nutritionGoal != null) updateData['nutritionGoal'] = nutritionGoal;
      if (_passwordHash != null) updateData['passwordHash'] = _passwordHash;

      print('🔄 Profile update - UserID: $userId (type: ${userId.runtimeType}), Data: $updateData');
      
      final success = await updateUserDetails(userId, updateData);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        _loadUserProfile(); // Refresh the profile
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile. Please check your data and try again.'),
            backgroundColor: AppColors.alert,
            duration: Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _performEditProfile(
                userName, email, ageText, gender, heightText, weightText,
                activityLevel, nutritionGoal,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      print('Error updating profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred while updating profile.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showFeatureDialog(String feature) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(feature, style: AppStyles.bodyBold),
          content: Text(
            '$feature functionality is currently under development.',
            style: AppStyles.bodyRegular,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK', style: AppStyles.bodyBold.copyWith(
                color: AppColors.primary,
              )),
            ),
          ],
        );
      },
    );
  }

  void _handleLogout() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Logout', style: AppStyles.bodyBold),
          content: Text(
            'Are you sure you want to logout?',
            style: AppStyles.bodyRegular,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: AppStyles.bodyBold.copyWith(
                color: AppColors.textLight,
              )),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _performLogout();
              },
              child: Text('Logout', style: AppStyles.bodyBold.copyWith(
                color: AppColors.alert,
              )),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performLogout() async {
    try {
      final success = await UserService.instance.logout();
      if (success) {
        // Use PageTransition to navigate to login/register page
        Navigator.pushAndRemoveUntil(
          context,
          PageTransition(type: PageTransitionType.fade, child: AuthPage()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed. Please try again.')),
        );
      }
    } catch (e) {
      print('Error during logout: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred during logout.')),
      );
    }
  }
}
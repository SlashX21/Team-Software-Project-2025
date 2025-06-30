import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';
import '../../../services/user_service.dart';
import '../../../services/api.dart';
import 'package:page_transition/page_transition.dart';
import '../auth_page.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userProfile;
  List<Map<String, dynamic>>? _userAllergens;
  List<Map<String, dynamic>>? _allAllergens;
  bool _isLoading = true;
  bool _hasError = false;
  String? _passwordHash;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // 检查用户是否已登录
      final isLoggedIn = await UserService.instance.isLoggedIn();
      if (!isLoggedIn) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
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
      final results = await Future.wait([
        getUserDetails(userId),
        getUserAllergens(userId),
        getAllAllergens(),
      ]);

      final userData = results[0] as Map<String, dynamic>?;
      final userAllergens = results[1] as List<Map<String, dynamic>>?;
      final allAllergens = results[2] as List<Map<String, dynamic>>?;

      if (userData != null) {
        setState(() {
          _userProfile = userData;
          _userAllergens = userAllergens ?? [];
          _allAllergens = allAllergens ?? [];
          _isLoading = false;
          _passwordHash = userData['passwordHash'];
        });
      } else {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user profile: $e');
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile', style: AppStyles.h2),
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
        _buildSection(
          title: 'Health Information',
          children: [
            _buildInfoRow('Age', _userProfile!['age'] != null ? '${_userProfile!['age']} years' : 'N/A'),
            _buildInfoRow('Gender', _userProfile!['gender'] ?? 'N/A'),
            _buildInfoRow('Height', _userProfile!['heightCm'] != null ? '${_userProfile!['heightCm']} cm' : 'N/A'),
            _buildInfoRow('Weight', _userProfile!['weightKg'] != null ? '${_userProfile!['weightKg']} kg' : 'N/A'),
            _buildInfoRow('Activity Level', _getActivityLevelDescription(_userProfile!['activityLevel']) ?? 'N/A'),
          ],
        ),
        SizedBox(height: 20),
        
        // Nutrition Goals Section
        _buildSection(
          title: 'Nutrition Goals',
          children: [
            _buildInfoRow('Goal', _getNutritionGoalDescription(_userProfile!['nutritionGoal']) ?? 'N/A'),
            _buildInfoRow('Daily Calories', _userProfile!['dailyCaloriesTarget'] != null ? '${_userProfile!['dailyCaloriesTarget']} kcal' : 'N/A'),
            _buildInfoRow('Daily Protein', _userProfile!['dailyProteinTarget'] != null ? '${_userProfile!['dailyProteinTarget']} g' : 'N/A'),
            _buildInfoRow('Daily Carbs', _userProfile!['dailyCarbTarget'] != null ? '${_userProfile!['dailyCarbTarget']} g' : 'N/A'),
            _buildInfoRow('Daily Fat', _userProfile!['dailyFatTarget'] != null ? '${_userProfile!['dailyFatTarget']} g' : 'N/A'),
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
              icon: Icons.add_circle_outline,
              title: 'Add Allergy',
              subtitle: 'Add new allergy or restriction',
              onTap: _showAddAllergyDialog,
            ),
          ],
        ),
        SizedBox(height: 32),
        
        // App Settings Section
        _buildSection(
          title: 'App Settings',
          children: [
            _buildSettingsTile(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              subtitle: 'Manage alert preferences',
              onTap: () => _showFeatureDialog('Notifications'),
            ),
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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Profile Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              Icons.person,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          SizedBox(width: 16),
          
          // Profile Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: AppStyles.h2,
                ),
                SizedBox(height: 4),
                Text(
                  email,
                  style: AppStyles.bodyRegular.copyWith(
                    color: AppColors.textLight,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    nutritionGoal,
                    style: AppStyles.bodyRegular.copyWith(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
    final severity = allergen['severityLevel'] ?? 'moderate';
    final notes = allergen['notes'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.alert.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.alert.withOpacity(0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber,
            color: AppColors.alert,
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
                    'Severity: ${severity.toUpperCase()}',
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
          IconButton(
            icon: Icon(Icons.delete, color: AppColors.alert, size: 20),
            onPressed: () => _removeAllergen(allergen['allergenId']),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
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
    
    switch (nutritionGoal.toLowerCase()) {
      case 'lose_weight':
        return 'Lose Weight';
      case 'gain_muscle':
        return 'Gain Muscle';
      case 'maintain':
        return 'Maintain';
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

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Profile', style: AppStyles.bodyBold),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Username field
                    TextField(
                      controller: userNameController,
                      decoration: InputDecoration(
                        labelText: 'Username *',
                        border: OutlineInputBorder(),
                        helperText: 'Enter your username',
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Email field
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: 'Email *',
                        border: OutlineInputBorder(),
                        helperText: 'Enter your email address',
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    SizedBox(height: 16),
                    
                    // Age field
                    TextField(
                      controller: ageController,
                      decoration: InputDecoration(
                        labelText: 'Age (13-120)',
                        border: OutlineInputBorder(),
                        helperText: 'Enter your age in years',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 16),
                    
                    // Gender dropdown
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Gender',
                        border: OutlineInputBorder(),
                      ),
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
                    SizedBox(height: 16),
                    
                    // Height field
                    TextField(
                      controller: heightController,
                      decoration: InputDecoration(
                        labelText: 'Height (100-250 cm)',
                        border: OutlineInputBorder(),
                        helperText: 'Enter your height in centimeters',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 16),
                    
                    // Weight field
                    TextField(
                      controller: weightController,
                      decoration: InputDecoration(
                        labelText: 'Weight (30-300 kg)',
                        border: OutlineInputBorder(),
                        helperText: 'Enter your weight in kilograms',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 16),
                    
                    // Activity Level dropdown
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Activity Level',
                        border: OutlineInputBorder(),
                      ),
                      value: selectedActivityLevel,
                      items: [
                        DropdownMenuItem(
                          value: 'SEDENTARY',
                          child: Text('Sedentary - Little or no exercise'),
                        ),
                        DropdownMenuItem(
                          value: 'LIGHTLY_ACTIVE',
                          child: Text('Lightly Active - 1-3 days/week light exercise'),
                        ),
                        DropdownMenuItem(
                          value: 'MODERATELY_ACTIVE',
                          child: Text('Moderately Active - 3-5 days/week moderate exercise'),
                        ),
                        DropdownMenuItem(
                          value: 'VERY_ACTIVE',
                          child: Text('Very Active - 6-7 days/week hard exercise'),
                        ),
                        DropdownMenuItem(
                          value: 'EXTRA_ACTIVE',
                          child: Text('Extra Active - very hard exercise or physical job'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedActivityLevel = value;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    
                    // Nutrition Goal dropdown
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Nutrition Goal',
                        border: OutlineInputBorder(),
                      ),
                      value: selectedNutritionGoal,
                      items: [
                        DropdownMenuItem(
                          value: 'lose_weight',
                          child: Text('Lose Weight'),
                        ),
                        DropdownMenuItem(
                          value: 'gain_muscle',
                          child: Text('Gain Muscle'),
                        ),
                        DropdownMenuItem(
                          value: 'maintain',
                          child: Text('Maintain'),
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
              );
            },
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
              child: Text('Save', style: AppStyles.bodyBold.copyWith(
                color: AppColors.primary,
              )),
            ),
          ],
        );
      },
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
      // 验证必填字段
      if (userName.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Username is required')),
        );
        return;
      }

      if (email.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Email is required')),
        );
        return;
      }

      // 验证邮箱格式
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(email)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter a valid email address')),
        );
        return;
      }

      // 验证其他字段
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
      if (userId == null) return;

      final updateData = <String, dynamic>{};
      updateData['userName'] = userName.trim();
      updateData['email'] = email.trim();
      if (age != null) updateData['age'] = age;
      if (gender != null) updateData['gender'] = gender;
      if (height != null) updateData['heightCm'] = height;
      if (weight != null) updateData['weightKg'] = weight;
      if (activityLevel != null) updateData['activityLevel'] = activityLevel;
      if (nutritionGoal != null) updateData['nutritionGoal'] = nutritionGoal;
      if (_passwordHash != null) updateData['passwordHash'] = _passwordHash;

      final success = await updateUserDetails(userId, updateData);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated successfully')),
        );
        _loadUserProfile(); // Refresh the profile
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile. Please try again.')),
        );
      }
    } catch (e) {
      print('Error updating profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred while updating profile.')),
      );
    }
  }

  void _showAddAllergyDialog() {
    if (_allAllergens == null || _allAllergens!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to load allergens. Please try again.')),
      );
      return;
    }

    String? selectedAllergenId;
    String severityLevel = 'moderate';
    final notesController = TextEditingController();
    final searchController = TextEditingController();
    List<Map<String, dynamic>> filteredAllergens = List.from(_allAllergens!);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Allergy', style: AppStyles.bodyBold),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Search field
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      labelText: 'Search Allergens',
                      hintText: 'Type to search (e.g., milk, nuts, gluten)',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        if (value.isEmpty) {
                          filteredAllergens = List.from(_allAllergens!);
                        } else {
                          filteredAllergens = _allAllergens!.where((allergen) {
                            final name = (allergen['name'] ?? '').toString().toLowerCase();
                            final category = (allergen['category'] ?? '').toString().toLowerCase();
                            final description = (allergen['description'] ?? '').toString().toLowerCase();
                            final searchTerm = value.toLowerCase();
                            
                            return name.contains(searchTerm) || 
                                   category.contains(searchTerm) || 
                                   description.contains(searchTerm);
                          }).toList();
                        }
                        selectedAllergenId = null; // Reset selection when searching
                      });
                    },
                  ),
                  SizedBox(height: 16),
                  
                  // Allergen dropdown with search results
                  Container(
                    height: 200,
                    child: filteredAllergens.isEmpty
                        ? Center(
                            child: Text(
                              'No allergens found matching your search',
                              style: AppStyles.bodyRegular.copyWith(color: AppColors.textLight),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: filteredAllergens.length,
                            itemBuilder: (context, index) {
                              final allergen = filteredAllergens[index];
                              final isSelected = selectedAllergenId == allergen['allergenId'].toString();
                              
                              return ListTile(
                                title: Text(
                                  allergen['name'] ?? 'Unknown',
                                  style: AppStyles.bodyRegular,
                                ),
                                subtitle: Text(
                                  allergen['category'] ?? '',
                                  style: AppStyles.bodyRegular.copyWith(color: AppColors.textLight),
                                ),
                                selected: isSelected,
                                onTap: () {
                                  setState(() {
                                    selectedAllergenId = allergen['allergenId'].toString();
                                  });
                                },
                              );
                            },
                          ),
                  ),
                  SizedBox(height: 16),
                  
                  // Severity dropdown
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Severity Level',
                      border: OutlineInputBorder(),
                    ),
                    value: severityLevel,
                    items: [
                      DropdownMenuItem(value: 'mild', child: Text('Mild')),
                      DropdownMenuItem(value: 'moderate', child: Text('Moderate')),
                      DropdownMenuItem(value: 'severe', child: Text('Severe')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        severityLevel = value!;
                      });
                    },
                  ),
                  SizedBox(height: 16),
                  
                  // Notes field
                  TextField(
                    controller: notesController,
                    decoration: InputDecoration(
                      labelText: 'Notes (Optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              );
            },
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
                if (selectedAllergenId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please select an allergen')),
                  );
                  return;
                }

                Navigator.of(context).pop();
                await _addAllergen(
                  int.parse(selectedAllergenId!),
                  severityLevel,
                  notesController.text,
                );
              },
              child: Text('Add', style: AppStyles.bodyBold.copyWith(
                color: AppColors.primary,
              )),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addAllergen(int allergenId, String severityLevel, String notes) async {
    try {
      final userId = await UserService.instance.getCurrentUserId();
      if (userId == null) return;

      final success = await addUserAllergen(userId, allergenId, severityLevel, notes);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Allergy added successfully')),
        );
        _loadUserProfile(); // Refresh the profile
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add allergy. Please try again.')),
        );
      }
    } catch (e) {
      print('Error adding allergen: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred while adding allergy.')),
      );
    }
  }

  Future<void> _removeAllergen(int allergenId) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Remove Allergy', style: AppStyles.bodyBold),
          content: Text(
            'Are you sure you want to remove this allergy?',
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
                await _performRemoveAllergen(allergenId);
              },
              child: Text('Remove', style: AppStyles.bodyBold.copyWith(
                color: AppColors.alert,
              )),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performRemoveAllergen(int allergenId) async {
    try {
      final userId = await UserService.instance.getCurrentUserId();
      if (userId == null) return;

      final success = await removeUserAllergen(userId, allergenId);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Allergy removed successfully')),
        );
        _loadUserProfile(); // Refresh the profile
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove allergy. Please try again.')),
        );
      }
    } catch (e) {
      print('Error removing allergen: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred while removing allergy.')),
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
        // 使用PageTransition导航到登录/注册页面
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
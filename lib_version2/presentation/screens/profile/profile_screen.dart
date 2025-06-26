import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/user.dart';
import '../../../main.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';
import '../../../services/api.dart';
import '../../widgets/labelled_number_input.dart';
import '../../widgets/labelled_dropdown.dart';

// 性别枚举
enum Gender { MALE, FEMALE }

// 活动水平枚举
enum ActivityLevel {
  SEDENTARY,
  LIGHTLY_ACTIVE,
  MODERATELY_ACTIVE,
  VERY_ACTIVE,
  EXTRA_ACTIVE,
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isEditing = false;
  bool isSaving = false;
  final _formKey = GlobalKey<FormState>();
  
  // 控制器
  late TextEditingController ageController;
  late TextEditingController heightController;
  late TextEditingController weightController;
  late TextEditingController dailyCaloriesController;
  late TextEditingController dailyProteinController;
  late TextEditingController dailyCarbsController;
  late TextEditingController dailyFatController;
  
  // 焦点节点
  late FocusNode ageFocusNode;
  late FocusNode heightFocusNode;
  late FocusNode weightFocusNode;
  late FocusNode dailyCaloriesFocusNode;
  late FocusNode dailyProteinFocusNode;
  late FocusNode dailyCarbsFocusNode;
  late FocusNode dailyFatFocusNode;
  
  // 枚举值
  Gender gender = Gender.MALE;
  ActivityLevel activityLevel = ActivityLevel.MODERATELY_ACTIVE;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<UserProvider>(context, listen: false).user!;
    
    // 初始化控制器
    ageController = TextEditingController(text: user.age?.toString() ?? '');
    heightController = TextEditingController(text: user.heightCm.toString());
    weightController = TextEditingController(text: user.weightKg.toString());
    dailyCaloriesController = TextEditingController(text: user.dailyCaloriesTarget?.toString() ?? '');
    dailyProteinController = TextEditingController(text: user.dailyProteinTarget?.toString() ?? '');
    dailyCarbsController = TextEditingController(text: user.dailyCarbTarget?.toString() ?? '');
    dailyFatController = TextEditingController(text: user.dailyFatTarget?.toString() ?? '');
    
    // 初始化焦点节点
    ageFocusNode = FocusNode();
    heightFocusNode = FocusNode();
    weightFocusNode = FocusNode();
    dailyCaloriesFocusNode = FocusNode();
    dailyProteinFocusNode = FocusNode();
    dailyCarbsFocusNode = FocusNode();
    dailyFatFocusNode = FocusNode();
    
    // 初始化枚举值
    gender = _stringToGender(user.gender);
    activityLevel = _stringToActivityLevel(user.activityLevel ?? 'MODERATELY_ACTIVE');
    
    // 设置焦点链
    _setupFocusChain();
  }

  @override
  void dispose() {
    // 释放控制器
    ageController.dispose();
    heightController.dispose();
    weightController.dispose();
    dailyCaloriesController.dispose();
    dailyProteinController.dispose();
    dailyCarbsController.dispose();
    dailyFatController.dispose();
    
    // 释放焦点节点
    ageFocusNode.dispose();
    heightFocusNode.dispose();
    weightFocusNode.dispose();
    dailyCaloriesFocusNode.dispose();
    dailyProteinFocusNode.dispose();
    dailyCarbsFocusNode.dispose();
    dailyFatFocusNode.dispose();
    
    super.dispose();
  }

  void _setupFocusChain() {
    ageFocusNode.addListener(() {
      if (!ageFocusNode.hasFocus) {
        heightFocusNode.requestFocus();
      }
    });
    heightFocusNode.addListener(() {
      if (!heightFocusNode.hasFocus) {
        weightFocusNode.requestFocus();
      }
    });
    weightFocusNode.addListener(() {
      if (!weightFocusNode.hasFocus) {
        dailyCaloriesFocusNode.requestFocus();
      }
    });
    dailyCaloriesFocusNode.addListener(() {
      if (!dailyCaloriesFocusNode.hasFocus) {
        dailyProteinFocusNode.requestFocus();
      }
    });
    dailyProteinFocusNode.addListener(() {
      if (!dailyProteinFocusNode.hasFocus) {
        dailyCarbsFocusNode.requestFocus();
      }
    });
    dailyCarbsFocusNode.addListener(() {
      if (!dailyCarbsFocusNode.hasFocus) {
        dailyFatFocusNode.requestFocus();
      }
    });
  }

  void _resetFields(User user) {
    setState(() {
      ageController.text = user.age?.toString() ?? '';
      heightController.text = user.heightCm.toString();
      weightController.text = user.weightKg.toString();
      dailyCaloriesController.text = user.dailyCaloriesTarget?.toString() ?? '';
      dailyProteinController.text = user.dailyProteinTarget?.toString() ?? '';
      dailyCarbsController.text = user.dailyCarbTarget?.toString() ?? '';
      dailyFatController.text = user.dailyFatTarget?.toString() ?? '';
      gender = _stringToGender(user.gender);
      activityLevel = _stringToActivityLevel(user.activityLevel ?? 'MODERATELY_ACTIVE');
    });
  }

  // 宏量营养素与热量交叉校验
  String? _validateMacros() {
    final calories = double.tryParse(dailyCaloriesController.text);
    final protein = double.tryParse(dailyProteinController.text);
    final carbs = double.tryParse(dailyCarbsController.text);
    final fat = double.tryParse(dailyFatController.text);
    
    if (calories != null && (protein != null || carbs != null || fat != null)) {
      double calculatedCalories = 0;
      if (protein != null) calculatedCalories += protein * 4; // 1g protein = 4 calories
      if (carbs != null) calculatedCalories += carbs * 4;     // 1g carbs = 4 calories
      if (fat != null) calculatedCalories += fat * 9;         // 1g fat = 9 calories
      
      if (calculatedCalories > 0 && (calories - calculatedCalories).abs() > 100) {
        return 'Macro totals should roughly match calorie target (±100 cal)';
      }
    }
    return null;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    final macroError = _validateMacros();
    if (macroError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(macroError),
          backgroundColor: Colors.orange,
          action: SnackBarAction(
            label: 'Continue Anyway',
            textColor: Colors.white,
            onPressed: () => _performSave(),
          ),
        ),
      );
      return;
    }
    
    await _performSave();
  }

  Future<void> _performSave() async {
    setState(() => isSaving = true);
    
    try {
      final user = Provider.of<UserProvider>(context, listen: false).user!;
      final updatedUser = User(
        userId: user.userId,
        userName: user.userName,
        email: user.email, // 邮箱不允许编辑
        passwordHash: user.passwordHash,
        age: ageController.text.trim().isEmpty ? null : int.tryParse(ageController.text.trim()),
        gender: _genderToString(gender),
        heightCm: double.tryParse(heightController.text.trim()) ?? 0,
        weightKg: double.tryParse(weightController.text.trim()) ?? 0,
        activityLevel: _activityLevelToString(activityLevel),
        nutritionGoal: user.nutritionGoal,
        dailyCaloriesTarget: dailyCaloriesController.text.trim().isEmpty ? null : double.tryParse(dailyCaloriesController.text.trim()),
        dailyProteinTarget: dailyProteinController.text.trim().isEmpty ? null : double.tryParse(dailyProteinController.text.trim()),
        dailyCarbTarget: dailyCarbsController.text.trim().isEmpty ? null : double.tryParse(dailyCarbsController.text.trim()),
        dailyFatTarget: dailyFatController.text.trim().isEmpty ? null : double.tryParse(dailyFatController.text.trim()),
        createdTime: user.createdTime,
      );
      
      final result = await updateUser(updatedUser);
      if (result != null) {
        Provider.of<UserProvider>(context, listen: false).setUser(result);
        setState(() => isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Failed to update profile');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: ${e.toString()}'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: _saveProfile,
          ),
        ),
      );
    } finally {
      setState(() => isSaving = false);
    }
  }

  // 枚举转换辅助方法
  Gender _stringToGender(String genderStr) {
    switch (genderStr.toUpperCase()) {
      case 'MALE': return Gender.MALE;
      case 'FEMALE': return Gender.FEMALE;
      default: return Gender.MALE;
    }
  }

  String _genderToString(Gender gender) {
    switch (gender) {
      case Gender.MALE: return 'MALE';
      case Gender.FEMALE: return 'FEMALE';
    }
  }

  ActivityLevel _stringToActivityLevel(String activityStr) {
    switch (activityStr.toUpperCase()) {
      case 'SEDENTARY': return ActivityLevel.SEDENTARY;
      case 'LIGHTLY_ACTIVE': return ActivityLevel.LIGHTLY_ACTIVE;
      case 'MODERATELY_ACTIVE': return ActivityLevel.MODERATELY_ACTIVE;
      case 'VERY_ACTIVE': return ActivityLevel.VERY_ACTIVE;
      case 'EXTRA_ACTIVE': return ActivityLevel.EXTRA_ACTIVE;
      default: return ActivityLevel.MODERATELY_ACTIVE;
    }
  }

  String _activityLevelToString(ActivityLevel activity) {
    switch (activity) {
      case ActivityLevel.SEDENTARY: return 'SEDENTARY';
      case ActivityLevel.LIGHTLY_ACTIVE: return 'LIGHTLY_ACTIVE';
      case ActivityLevel.MODERATELY_ACTIVE: return 'MODERATELY_ACTIVE';
      case ActivityLevel.VERY_ACTIVE: return 'VERY_ACTIVE';
      case ActivityLevel.EXTRA_ACTIVE: return 'EXTRA_ACTIVE';
    }
  }

  String _getActivityDisplayText(ActivityLevel activity) {
    switch (activity) {
      case ActivityLevel.SEDENTARY: return 'Sedentary (little or no exercise)';
      case ActivityLevel.LIGHTLY_ACTIVE: return 'Lightly Active (light exercise 1-3 days/week)';
      case ActivityLevel.MODERATELY_ACTIVE: return 'Moderately Active (exercise 3-5 times/week)';
      case ActivityLevel.VERY_ACTIVE: return 'Very Active (hard exercise 6-7 days/week)';
      case ActivityLevel.EXTRA_ACTIVE: return 'Extra Active (very hard exercise, physical job)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;
    
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Profile', style: AppStyles.h2)),
        body: Center(child: Text('Not logged in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile', style: AppStyles.h2),
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: BackButton(color: AppColors.white),
        actions: [
          if (isEditing)
            TextButton(
              onPressed: isSaving ? null : () {
                _resetFields(user);
                setState(() => isEditing = false);
              },
              child: Text(
                'Cancel', 
                style: TextStyle(
                  color: isSaving ? Colors.grey : Colors.white, 
                  fontWeight: FontWeight.bold
                ),
              ),
            ),
          IconButton(
            icon: isSaving 
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(isEditing ? Icons.save : Icons.edit, color: AppColors.white),
            onPressed: isSaving ? null : () async {
              if (isEditing) {
                await _saveProfile();
              } else {
                setState(() => isEditing = true);
              }
            },
          ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            children: [
              _buildProfileHeader(user),
              SizedBox(height: 24),
              _buildSection(
                title: 'Basic Information',
                children: [
                  // 用户名只读
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text(
                            'Username',
                            style: AppStyles.bodyRegular.copyWith(
                              color: Theme.of(context).brightness == Brightness.dark 
                                  ? Colors.grey[300] 
                                  : AppColors.textLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            user.userName,
                            style: AppStyles.bodyRegular.copyWith(
                              color: Theme.of(context).brightness == Brightness.dark 
                                  ? Colors.grey[300] 
                                  : AppColors.textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 邮箱只读
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text(
                            'Email',
                            style: AppStyles.bodyRegular.copyWith(
                              color: Theme.of(context).brightness == Brightness.dark 
                                  ? Colors.grey[300] 
                                  : AppColors.textLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            user.email,
                            style: AppStyles.bodyRegular.copyWith(
                              color: Theme.of(context).brightness == Brightness.dark 
                                  ? Colors.grey[300] 
                                  : AppColors.textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              _buildSection(
                title: 'Health Information',
                children: [
                  LabelledNumberInput(
                    label: 'Age',
                    controller: ageController,
                    min: 1,
                    max: 150,
                    allowDecimal: false,
                    enabled: isEditing,
                    focusNode: ageFocusNode,
                    textInputAction: TextInputAction.next,
                  ),
                  LabelledDropdown<Gender>(
                    label: 'Gender',
                    value: gender,
                    options: Gender.values,
                    displayText: (gender) => gender == Gender.MALE ? 'Male' : 'Female',
                    onChanged: isEditing ? (val) => setState(() => gender = val) : null,
                    enabled: isEditing,
                  ),
                  LabelledNumberInput(
                    label: 'Height',
                    controller: heightController,
                    min: 50,
                    max: 300,
                    suffix: 'cm',
                    allowDecimal: true,
                    enabled: isEditing,
                    focusNode: heightFocusNode,
                    textInputAction: TextInputAction.next,
                  ),
                  LabelledNumberInput(
                    label: 'Weight',
                    controller: weightController,
                    min: 20,
                    max: 600,
                    suffix: 'kg',
                    allowDecimal: true,
                    enabled: isEditing,
                    focusNode: weightFocusNode,
                    textInputAction: TextInputAction.next,
                  ),
                  LabelledDropdown<ActivityLevel>(
                    label: 'Activity Level',
                    value: activityLevel,
                    options: ActivityLevel.values,
                    displayText: _getActivityDisplayText,
                    onChanged: isEditing ? (val) => setState(() => activityLevel = val) : null,
                    enabled: isEditing,
                  ),
                ],
              ),
              SizedBox(height: 20),
              _buildSection(
                title: 'Nutrition Goals',
                children: [
                  LabelledNumberInput(
                    label: 'Daily Calories',
                    controller: dailyCaloriesController,
                    min: 0,
                    max: 10000,
                    suffix: 'cal',
                    allowDecimal: false,
                    enabled: isEditing,
                    focusNode: dailyCaloriesFocusNode,
                    textInputAction: TextInputAction.next,
                  ),
                  LabelledNumberInput(
                    label: 'Daily Protein',
                    controller: dailyProteinController,
                    min: 0,
                    max: 2000,
                    suffix: 'g',
                    allowDecimal: true,
                    enabled: isEditing,
                    focusNode: dailyProteinFocusNode,
                    textInputAction: TextInputAction.next,
                  ),
                  LabelledNumberInput(
                    label: 'Daily Carbs',
                    controller: dailyCarbsController,
                    min: 0,
                    max: 2000,
                    suffix: 'g',
                    allowDecimal: true,
                    enabled: isEditing,
                    focusNode: dailyCarbsFocusNode,
                    textInputAction: TextInputAction.next,
                  ),
                  LabelledNumberInput(
                    label: 'Daily Fat',
                    controller: dailyFatController,
                    min: 0,
                    max: 2000,
                    suffix: 'g',
                    allowDecimal: true,
                    enabled: isEditing,
                    focusNode: dailyFatFocusNode,
                    textInputAction: TextInputAction.done,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(User user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? Colors.grey[800] 
            : AppColors.white,
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.userName, 
                  style: AppStyles.h2.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.white 
                        : AppColors.textDark,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  user.email, 
                  style: AppStyles.bodyRegular.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.grey[400] 
                        : AppColors.textLight,
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
                    user.nutritionGoal ?? '-',
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

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? Colors.grey[800] 
            : AppColors.white,
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
          Text(
            title, 
            style: AppStyles.bodyBold.copyWith(
              fontSize: 18,
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white 
                  : AppColors.textDark,
            ),
          ),
          SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
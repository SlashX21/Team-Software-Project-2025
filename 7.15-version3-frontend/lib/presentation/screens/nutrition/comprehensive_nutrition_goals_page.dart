import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';
import '../../../services/api.dart';
import '../../../services/user_service.dart';

class ComprehensiveNutritionGoalsPage extends StatefulWidget {
  const ComprehensiveNutritionGoalsPage({Key? key}) : super(key: key);

  @override
  State<ComprehensiveNutritionGoalsPage> createState() => _ComprehensiveNutritionGoalsPageState();
}

class _ComprehensiveNutritionGoalsPageState extends State<ComprehensiveNutritionGoalsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  // Nutrition goal values
  double _dailyCalories = 2000;
  double _dailyProtein = 150;
  double _dailyCarbs = 250;
  double _dailyFat = 65;
  double _dailyFiber = 25;
  double _dailySugar = 50;
  double _dailySodium = 2300;
  double _dailyWater = 2000; // ml

  // Personal information (for calculating recommended values)
  String _gender = 'male';
  int _age = 30;
  double _weight = 70;
  double _height = 170;
  String _activityLevel = 'moderate';
  String _goal = 'maintain';

  bool _isLoading = false;
  bool _useRecommendedValues = true;
  Map<String, dynamic>? _userProfile; // 添加用户资料存储

  // Nutrition goal configuration
  final Map<String, NutritionGoalConfig> _nutritionConfigs = {
    'calories': NutritionGoalConfig(
      title: 'Daily Calories',
      unit: 'kcal',
      icon: Icons.local_fire_department,
      color: Colors.orange,
      min: 1200,
      max: 4000,
      divisions: 56,
    ),
    'protein': NutritionGoalConfig(
      title: 'Protein',
      unit: 'g',
      icon: Icons.fitness_center,
      color: Colors.green,
      min: 50,
      max: 250,
      divisions: 40,
    ),
    'carbs': NutritionGoalConfig(
      title: 'Carbohydrates',
      unit: 'g',
      icon: Icons.grain,
      color: Colors.brown,
      min: 100,
      max: 400,
      divisions: 30,
    ),
    'fat': NutritionGoalConfig(
      title: 'Fat',
      unit: 'g',
      icon: Icons.water_drop,
      color: Colors.blue,
      min: 20,
      max: 120,
      divisions: 20,
    ),
    'fiber': NutritionGoalConfig(
      title: 'Dietary Fiber',
      unit: 'g',
      icon: Icons.grass,
      color: Colors.lightGreen,
      min: 15,
      max: 50,
      divisions: 14,
    ),
    'sugar': NutritionGoalConfig(
      title: 'Sugar Limit',
      unit: 'g',
      icon: Icons.cake,
      color: Colors.pink,
      min: 10,
      max: 100,
      divisions: 18,
    ),
    'sodium': NutritionGoalConfig(
      title: 'Sodium Limit',
      unit: 'mg',
      icon: Icons.grain,
      color: Colors.deepOrange,
      min: 1500,
      max: 3500,
      divisions: 20,
    ),
    'water': NutritionGoalConfig(
      title: 'Daily Water',
      unit: 'ml',
      icon: Icons.local_drink,
      color: Colors.lightBlue,
      min: 1500,
      max: 3500,
      divisions: 20,
    ),
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCurrentGoals();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentGoals() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = await UserService.instance.getCurrentUserId();
      if (userId != null) {
        // 加载用户的个人资料信息
        final userProfile = await getUserDetails(userId);
        if (userProfile != null) {
          setState(() {
            _userProfile = userProfile;
            
            // 从用户资料中获取真实数据
            _age = userProfile['age'] ?? 30;
            _weight = (userProfile['weightKg'] ?? 70.0).toDouble();
            _height = (userProfile['heightCm'] ?? 170.0).toDouble();
            _gender = (userProfile['gender'] ?? 'MALE').toLowerCase() == 'female' ? 'female' : 'male';
            
            // 映射活动等级
            final activityLevel = userProfile['activityLevel'];
            switch (activityLevel?.toUpperCase()) {
              case 'SEDENTARY':
                _activityLevel = 'sedentary';
                break;
              case 'LIGHTLY_ACTIVE':
                _activityLevel = 'light';
                break;
              case 'MODERATELY_ACTIVE':
                _activityLevel = 'moderate';
                break;
              case 'VERY_ACTIVE':
                _activityLevel = 'active';
                break;
              case 'EXTRA_ACTIVE':
                _activityLevel = 'very_active';
                break;
              default:
                _activityLevel = 'moderate';
            }
            
            // 映射营养目标
            final nutritionGoal = userProfile['nutritionGoal'];
            switch (nutritionGoal?.toUpperCase()) {
              case 'WEIGHT_LOSS':
                _goal = 'lose_weight';
                break;
              case 'WEIGHT_GAIN':
              case 'MUSCLE_GAIN':
                _goal = 'gain_muscle';
                break;
              case 'MAINTENANCE':
              case 'WEIGHT_MAINTENANCE':
                _goal = 'maintain';
                break;
              default:
                _goal = 'maintain';
            }
            
            // 如果用户已有营养目标，使用现有值
            if (userProfile['dailyCaloriesTarget'] != null) {
              _dailyCalories = (userProfile['dailyCaloriesTarget']).toDouble();
            }
            if (userProfile['dailyProteinTarget'] != null) {
              _dailyProtein = (userProfile['dailyProteinTarget']).toDouble();
            }
            if (userProfile['dailyCarbTarget'] != null) {
              _dailyCarbs = (userProfile['dailyCarbTarget']).toDouble();
            }
            if (userProfile['dailyFatTarget'] != null) {
              _dailyFat = (userProfile['dailyFatTarget']).toDouble();
            }
          });
          
          print('✅ 用户资料加载成功: 年龄=${_age}, 性别=${_gender}, 身高=${_height}, 体重=${_weight}, 活动等级=${_activityLevel}, 目标=${_goal}');
        }
        
        // 加载糖分目标
        try {
          final sugarGoal = await getSugarGoal(userId);
          if (sugarGoal != null) {
            setState(() {
              _dailySugar = (sugarGoal.dailyGoalMg / 1000).toDouble(); // 转换为克
            });
          }
        } catch (e) {
          print('⚠️ 加载糖分目标失败: $e');
        }
      }
      
      // 如果使用推荐值，重新计算推荐的营养目标
      if (_useRecommendedValues) {
        _calculateRecommendedGoals();
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('❌ Failed to load nutrition goals: $e');
      
      // 如果加载失败，仍然使用推荐值
      if (_useRecommendedValues) {
        _calculateRecommendedGoals();
      }
    }
  }

  void _calculateRecommendedGoals() {
    // Calculate recommended nutrition goals based on personal information
    double bmr = _calculateBMR();
    double tdee = _calculateTDEE(bmr);
    
    setState(() {
      // Adjust calories based on goal
      switch (_goal) {
        case 'lose_weight':
          _dailyCalories = tdee - 500; // Weight loss: reduce 500kcal
          break;
        case 'gain_muscle':
          _dailyCalories = tdee + 300; // Muscle gain: increase 300kcal
          break;
        default:
          _dailyCalories = tdee; // Maintain: TDEE
      }

      // Calculate macronutrients
      _dailyProtein = _weight * 1.6; // 1.6g/kg body weight
      _dailyCarbs = _dailyCalories * 0.5 / 4; // 50% calories from carbs
      _dailyFat = _dailyCalories * 0.25 / 9; // 25% calories from fat
      
      // Micronutrients
      _dailyFiber = _age < 50 ? 25 : 21; // Adjust based on age
      _dailySugar = _dailyCalories * 0.05 / 4; // 5% calories from added sugar
      _dailySodium = 2300; // WHO recommendation
      _dailyWater = _weight * 35; // 35ml/kg body weight
    });
  }

  double _calculateBMR() {
    // Mifflin-St Jeor equation
    if (_gender == 'male') {
      return 88.362 + (13.397 * _weight) + (4.799 * _height) - (5.677 * _age);
    } else {
      return 447.593 + (9.247 * _weight) + (3.098 * _height) - (4.330 * _age);
    }
  }

  double _calculateTDEE(double bmr) {
    switch (_activityLevel) {
      case 'sedentary':
        return bmr * 1.2;
      case 'light':
        return bmr * 1.375;
      case 'moderate':
        return bmr * 1.55;
      case 'active':
        return bmr * 1.725;
      case 'very_active':
        return bmr * 1.9;
      default:
        return bmr * 1.55;
    }
  }

  Future<void> _saveGoals() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = await UserService.instance.getCurrentUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // 保存用户的个人信息更新
      final personalInfoUpdates = <String, dynamic>{};
      
      // 如果个人信息有变化，更新用户资料
      if (_userProfile != null) {
        if (_userProfile!['age'] != _age) personalInfoUpdates['age'] = _age;
        if (_userProfile!['weightKg'] != _weight) personalInfoUpdates['weightKg'] = _weight;
        if (_userProfile!['heightCm'] != _height) personalInfoUpdates['heightCm'] = _height;
        
        // 映射性别
        final currentGender = (_userProfile!['gender'] ?? 'MALE').toLowerCase() == 'female' ? 'female' : 'male';
        if (currentGender != _gender) {
          personalInfoUpdates['gender'] = _gender.toUpperCase() == 'FEMALE' ? 'FEMALE' : 'MALE';
        }
        
        // 映射活动等级
        String mappedActivityLevel;
        switch (_activityLevel) {
          case 'sedentary':
            mappedActivityLevel = 'SEDENTARY';
            break;
          case 'light':
            mappedActivityLevel = 'LIGHTLY_ACTIVE';
            break;
          case 'moderate':
            mappedActivityLevel = 'MODERATELY_ACTIVE';
            break;
          case 'active':
            mappedActivityLevel = 'VERY_ACTIVE';
            break;
          case 'very_active':
            mappedActivityLevel = 'EXTRA_ACTIVE';
            break;
          default:
            mappedActivityLevel = 'MODERATELY_ACTIVE';
        }
        if (_userProfile!['activityLevel'] != mappedActivityLevel) {
          personalInfoUpdates['activityLevel'] = mappedActivityLevel;
        }
        
        // 映射营养目标
        String mappedNutritionGoal;
        switch (_goal) {
          case 'lose_weight':
            mappedNutritionGoal = 'WEIGHT_LOSS';
            break;
          case 'gain_muscle':
            mappedNutritionGoal = 'MUSCLE_GAIN';
            break;
          case 'maintain':
            mappedNutritionGoal = 'MAINTENANCE';
            break;
          default:
            mappedNutritionGoal = 'MAINTENANCE';
        }
        if (_userProfile!['nutritionGoal'] != mappedNutritionGoal) {
          personalInfoUpdates['nutritionGoal'] = mappedNutritionGoal;
        }
        
        // 保存营养目标到用户资料
        personalInfoUpdates['dailyCaloriesTarget'] = _dailyCalories;
        personalInfoUpdates['dailyProteinTarget'] = _dailyProtein;
        personalInfoUpdates['dailyCarbTarget'] = _dailyCarbs;
        personalInfoUpdates['dailyFatTarget'] = _dailyFat;
        
        // 如果有变化，更新用户资料
        if (personalInfoUpdates.isNotEmpty) {
          print('🔄 更新用户资料: $personalInfoUpdates');
          final success = await updateUserDetails(userId, personalInfoUpdates);
          if (!success) {
            throw Exception('Failed to update user profile');
          }
        }
      }

      // 保存糖分目标
      await setSugarGoal(userId, _dailySugar * 1000); // 转换为mg

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('营养目标保存成功'),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.pop(context, true);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('保存失败: $e'),
          backgroundColor: AppColors.alert,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Nutrition Goals Setting',
          style: AppStyles.h2.copyWith(color: AppColors.white),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveGoals,
            child: Text(
              'Save',
              style: AppStyles.bodyBold.copyWith(color: AppColors.white),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.white,
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.white.withOpacity(0.7),
          tabs: [
            Tab(text: 'Personal Info'),
            Tab(text: 'Nutrition Goals'),
            Tab(text: 'Goals Overview'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPersonalInfoTab(),
                _buildNutritionGoalsTab(),
                _buildGoalsOverviewTab(),
              ],
            ),
    );
  }

  Widget _buildPersonalInfoTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildPersonalInfoSection(),
          SizedBox(height: 16),
          _buildRecommendationToggle(),
          SizedBox(height: 24),
          if (_useRecommendedValues) _buildCalculatedValues(),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Personal Info', style: AppStyles.bodyBold),
          SizedBox(height: 16),
          
          // Gender selection
          Text('Gender', style: AppStyles.bodyRegular),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: Text('Male'),
                  value: 'male',
                  groupValue: _gender,
                  onChanged: (value) {
                    setState(() {
                      _gender = value!;
                      if (_useRecommendedValues) _calculateRecommendedGoals();
                    });
                  },
                  activeColor: AppColors.primary,
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: Text('Female'),
                  value: 'female',
                  groupValue: _gender,
                  onChanged: (value) {
                    setState(() {
                      _gender = value!;
                      if (_useRecommendedValues) _calculateRecommendedGoals();
                    });
                  },
                  activeColor: AppColors.primary,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          // Age, weight, height
          Row(
            children: [
              Expanded(
                child: _buildNumberInput(
                  'Age',
                  _age.toString(),
                  'years',
                  (value) {
                    _age = int.tryParse(value) ?? _age;
                    if (_useRecommendedValues) _calculateRecommendedGoals();
                  },
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildNumberInput(
                  'Weight',
                  _weight.toString(),
                  'kg',
                  (value) {
                    _weight = double.tryParse(value) ?? _weight;
                    if (_useRecommendedValues) _calculateRecommendedGoals();
                  },
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildNumberInput(
                  'Height',
                  _height.toString(),
                  'cm',
                  (value) {
                    _height = double.tryParse(value) ?? _height;
                    if (_useRecommendedValues) _calculateRecommendedGoals();
                  },
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          // Activity level
          Text('Activity Level', style: AppStyles.bodyRegular),
          SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _activityLevel,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            items: [
              DropdownMenuItem(value: 'sedentary', child: Text('Sedentary - Little or no exercise')),
              DropdownMenuItem(value: 'light', child: Text('Light - Exercise 1-3 days/week')),
              DropdownMenuItem(value: 'moderate', child: Text('Moderate - Exercise 3-5 days/week')),
              DropdownMenuItem(value: 'active', child: Text('Active - Exercise 6-7 days/week')),
              DropdownMenuItem(value: 'very_active', child: Text('Very Active - Hard exercise + Physical job')),
            ],
            onChanged: (value) {
              setState(() {
                _activityLevel = value!;
                if (_useRecommendedValues) _calculateRecommendedGoals();
              });
            },
          ),
          
          SizedBox(height: 16),
          
          // Goal
          Text('Fitness Goal', style: AppStyles.bodyRegular),
          SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _goal,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            items: [
              DropdownMenuItem(value: 'lose_weight', child: Text('Lose Weight')),
              DropdownMenuItem(value: 'maintain', child: Text('Maintain Weight')),
              DropdownMenuItem(value: 'gain_muscle', child: Text('Gain Muscle')),
            ],
            onChanged: (value) {
              setState(() {
                _goal = value!;
                if (_useRecommendedValues) _calculateRecommendedGoals();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNumberInput(String label, String value, String unit, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppStyles.bodyRegular.copyWith(fontSize: 12)),
        SizedBox(height: 4),
        TextFormField(
          initialValue: value,
          decoration: InputDecoration(
            suffixText: unit,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          keyboardType: TextInputType.number,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildRecommendationToggle() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, color: AppColors.primary),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Use Recommended Values', style: AppStyles.bodyBold),
                Text(
                  'Automatically calculate nutrition goals based on your personal information',
                  style: AppStyles.bodyRegular.copyWith(
                    color: AppColors.textLight,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _useRecommendedValues,
            onChanged: (value) {
              setState(() {
                _useRecommendedValues = value;
                if (value) _calculateRecommendedGoals();
              });
            },
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildCalculatedValues() {
    final bmr = _calculateBMR();
    final tdee = _calculateTDEE(bmr);
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calculate, color: AppColors.success),
              SizedBox(width: 8),
              Text('Calculation Results', style: AppStyles.bodyBold.copyWith(color: AppColors.success)),
            ],
          ),
          SizedBox(height: 12),
          Text('Basal Metabolic Rate (BMR): ${bmr.round()} kcal/day'),
          Text('Total Energy Expenditure (TDEE): ${tdee.round()} kcal/day'),
          Text('Target Calories: ${_dailyCalories.round()} kcal/day'),
        ],
      ),
    );
  }

  Widget _buildNutritionGoalsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildMacronutrientsSection(),
          SizedBox(height: 16),
          _buildMicronutrientsSection(),
        ],
      ),
    );
  }

  Widget _buildMacronutrientsSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Macronutrients', style: AppStyles.bodyBold),
          SizedBox(height: 16),
          _buildNutritionSlider('calories', _dailyCalories, (value) => setState(() => _dailyCalories = value)),
          _buildNutritionSlider('protein', _dailyProtein, (value) => setState(() => _dailyProtein = value)),
          _buildNutritionSlider('carbs', _dailyCarbs, (value) => setState(() => _dailyCarbs = value)),
          _buildNutritionSlider('fat', _dailyFat, (value) => setState(() => _dailyFat = value)),
        ],
      ),
    );
  }

  Widget _buildMicronutrientsSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Micronutrients & Others', style: AppStyles.bodyBold),
          SizedBox(height: 16),
          _buildNutritionSlider('fiber', _dailyFiber, (value) => setState(() => _dailyFiber = value)),
          _buildNutritionSlider('sugar', _dailySugar, (value) => setState(() => _dailySugar = value)),
          _buildNutritionSlider('sodium', _dailySodium, (value) => setState(() => _dailySodium = value)),
          _buildNutritionSlider('water', _dailyWater, (value) => setState(() => _dailyWater = value)),
        ],
      ),
    );
  }

  Widget _buildNutritionSlider(String key, double value, Function(double) onChanged) {
    final config = _nutritionConfigs[key]!;
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(config.icon, color: config.color, size: 20),
              SizedBox(width: 8),
              Expanded(child: Text(config.title, style: AppStyles.bodyRegular)),
              Text(
                '${value.round()} ${config.unit}',
                style: AppStyles.bodyBold.copyWith(color: config.color),
              ),
            ],
          ),
          SizedBox(height: 8),
          Slider(
            value: value,
            min: config.min,
            max: config.max,
            divisions: config.divisions,
            onChanged: onChanged,
            activeColor: config.color,
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsOverviewTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildGoalsSummaryCard(),
          SizedBox(height: 16),
          _buildCalorieBreakdown(),
          SizedBox(height: 16),
          _buildHealthTips(),
        ],
      ),
    );
  }

  Widget _buildGoalsSummaryCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Goals Overview', style: AppStyles.bodyBold),
          SizedBox(height: 16),
          _buildGoalRow(Icons.local_fire_department, 'Calories', '${_dailyCalories.round()} kcal', Colors.orange),
          _buildGoalRow(Icons.fitness_center, 'Protein', '${_dailyProtein.round()} g', Colors.green),
          _buildGoalRow(Icons.grain, 'Carbohydrates', '${_dailyCarbs.round()} g', Colors.brown),
          _buildGoalRow(Icons.water_drop, 'Fat', '${_dailyFat.round()} g', Colors.blue),
          _buildGoalRow(Icons.grass, 'Dietary Fiber', '${_dailyFiber.round()} g', Colors.lightGreen),
          _buildGoalRow(Icons.cake, 'Sugar Limit', '${_dailySugar.round()} g', Colors.pink),
          _buildGoalRow(Icons.grain, 'Sodium Limit', '${_dailySodium.round()} mg', Colors.deepOrange),
          _buildGoalRow(Icons.local_drink, 'Daily Water', '${_dailyWater.round()} ml', Colors.lightBlue),
        ],
      ),
    );
  }

  Widget _buildGoalRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(width: 12),
          Expanded(child: Text(label, style: AppStyles.bodyRegular)),
          Text(value, style: AppStyles.bodyBold.copyWith(color: color)),
        ],
      ),
    );
  }

  Widget _buildCalorieBreakdown() {
    final proteinCal = _dailyProtein * 4;
    final carbsCal = _dailyCarbs * 4;
    final fatCal = _dailyFat * 9;
    final total = proteinCal + carbsCal + fatCal;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Calorie Breakdown', style: AppStyles.bodyBold),
          SizedBox(height: 16),
          _buildCalorieBar('Protein', proteinCal, total, Colors.green),
          _buildCalorieBar('Carbohydrates', carbsCal, total, Colors.brown),
          _buildCalorieBar('Fat', fatCal, total, Colors.blue),
          SizedBox(height: 8),
          Text(
            'Total: ${total.round()} kcal',
            style: AppStyles.bodyBold.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildCalorieBar(String label, double calories, double total, Color color) {
    final percentage = calories / total;
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: AppStyles.bodyRegular),
              Text('${calories.round()} kcal (${(percentage * 100).round()}%)', 
                  style: AppStyles.bodyRegular.copyWith(color: color)),
            ],
          ),
          SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthTips() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: AppColors.success),
              SizedBox(width: 8),
              Text('Health Tips', style: AppStyles.bodyBold.copyWith(color: AppColors.success)),
            ],
          ),
          SizedBox(height: 12),
          ...([
            'Maintain a balanced diet, including protein, carbohydrates, and healthy fats in each meal',
            'Drink enough water to stay hydrated',
            'Limit added sugar intake, choose naturally sweet foods',
            'Increase dietary fiber intake, eat more vegetables and whole grains',
            'Control sodium intake, reduce consumption of processed foods',
          ].map((tip) => Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle, color: AppColors.success, size: 16),
                SizedBox(width: 8),
                Expanded(child: Text(tip, style: AppStyles.bodyRegular.copyWith(fontSize: 14))),
              ],
            ),
          ))),
        ],
      ),
    );
  }
}

class NutritionGoalConfig {
  final String title;
  final String unit;
  final IconData icon;
  final Color color;
  final double min;
  final double max;
  final int divisions;

  NutritionGoalConfig({
    required this.title,
    required this.unit,
    required this.icon,
    required this.color,
    required this.min,
    required this.max,
    required this.divisions,
  });
} 
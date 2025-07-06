import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';
import '../../../domain/entities/sugar_goal.dart';
import '../../../services/api.dart';
import '../../../services/user_service.dart';

class SugarGoalSettingPage extends StatefulWidget {
  final SugarGoal? currentGoal;

  const SugarGoalSettingPage({
    Key? key,
    this.currentGoal,
  }) : super(key: key);

  @override
  _SugarGoalSettingPageState createState() => _SugarGoalSettingPageState();
}

class _SugarGoalSettingPageState extends State<SugarGoalSettingPage> {
  final _formKey = GlobalKey<FormState>();
  final _goalController = TextEditingController();
  
  bool _isLoading = false;
  double _sliderValue = 1200.0;
  String _selectedUnit = 'mg';
  final List<String> _units = ['mg', 'g'];

  // 预设目标
  final List<PresetGoal> _presetGoals = [
    PresetGoal(name: 'Strict', value: 600.0, description: 'Very low sugar diet'),
    PresetGoal(name: 'Moderate', value: 1000.0, description: 'Balanced approach'),
    PresetGoal(name: 'Relaxed', value: 1500.0, description: 'Flexible diet'),
    PresetGoal(name: 'Custom', value: 0.0, description: 'Set your own goal'),
  ];

  String _selectedPreset = 'Moderate';

  @override
  void initState() {
    super.initState();
    if (widget.currentGoal != null) {
      _sliderValue = widget.currentGoal!.dailyGoalMg;
      _goalController.text = (_sliderValue / 1000).toStringAsFixed(1);
      _selectedUnit = 'g';
      _selectedPreset = _getPresetFromValue(_sliderValue);
    } else {
      _goalController.text = '1.2';
      _selectedUnit = 'g';
    }
  }

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  String _getPresetFromValue(double value) {
    if (value <= 600) return 'Strict';
    if (value <= 1000) return 'Moderate';
    if (value <= 1500) return 'Relaxed';
    return 'Custom';
  }

  void _onPresetSelected(String preset) {
    setState(() {
      _selectedPreset = preset;
      if (preset != 'Custom') {
        final presetGoal = _presetGoals.firstWhere((g) => g.name == preset);
        _sliderValue = presetGoal.value;
        _updateControllerFromSlider();
      }
    });
  }

  void _updateControllerFromSlider() {
    if (_selectedUnit == 'g') {
      _goalController.text = (_sliderValue / 1000).toStringAsFixed(1);
    } else {
      _goalController.text = _sliderValue.toInt().toString();
    }
  }

  void _updateSliderFromController() {
    final text = _goalController.text.trim();
    final value = double.tryParse(text);
    if (value != null) {
      setState(() {
        _sliderValue = _selectedUnit == 'g' ? value * 1000 : value;
        _sliderValue = _sliderValue.clamp(100.0, 3000.0);
        _selectedPreset = _getPresetFromValue(_sliderValue);
      });
    }
  }

  void _onUnitChanged(String unit) {
    setState(() {
      _selectedUnit = unit;
      _updateControllerFromSlider();
    });
  }

  void _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = await UserService.instance.getCurrentUserId();
      if (userId == null) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in')),
        );
        return;
      }

      final success = await setSugarGoal(userId, _sliderValue);

      setState(() => _isLoading = false);

      if (success) {
        Navigator.pop(context, true); // Return success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sugar goal updated successfully'),
            backgroundColor: AppColors.primary,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update sugar goal'),
            backgroundColor: AppColors.alert,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred. Please try again.'),
          backgroundColor: AppColors.alert,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Sugar Goal Setting', style: AppStyles.h2),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 当前目标显示卡片
              if (widget.currentGoal != null) _buildCurrentGoalCard(),
              
              // 预设目标选择
              _buildPresetGoalsSection(),
              SizedBox(height: 24),

              // 滑块调整
              _buildSliderSection(),
              SizedBox(height: 24),

              // 手动输入
              _buildManualInputSection(),
              SizedBox(height: 24),

              // 健康建议
              _buildHealthAdviceSection(),
              SizedBox(height: 32),

              // 保存按钮
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Save Goal', style: AppStyles.buttonText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentGoalCard() {
    return Container(
      margin: EdgeInsets.only(bottom: 24),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Current Goal', style: AppStyles.bodyBold),
          SizedBox(height: 8),
          Text(
            widget.currentGoal!.formattedGoal,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Set ${widget.currentGoal!.goalAge}',
            style: TextStyle(fontSize: 12, color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetGoalsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Choose a Preset Goal', style: AppStyles.h2),
        SizedBox(height: 16),
        ...(_presetGoals.where((goal) => goal.name != 'Custom').map((goal) {
          final isSelected = _selectedPreset == goal.name;
          return Container(
            margin: EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => _onPresetSelected(goal.name),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.grey[300]!,
                  ),
                ),
                child: Row(
                  children: [
                    Radio<String>(
                      value: goal.name,
                      groupValue: _selectedPreset,
                      onChanged: (value) => _onPresetSelected(value!),
                      activeColor: AppColors.primary,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? AppColors.primary : Colors.black87,
                            ),
                          ),
                          Text(
                            goal.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${(goal.value / 1000).toStringAsFixed(1)}g',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? AppColors.primary : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        })),
      ],
    );
  }

  Widget _buildSliderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Fine-tune Your Goal', style: AppStyles.h2),
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                '${(_sliderValue / 1000).toStringAsFixed(1)}g',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: 16),
              Slider(
                value: _sliderValue,
                min: 100.0,
                max: 3000.0,
                divisions: 58, // (3000-100)/50 = 58
                activeColor: AppColors.primary,
                onChanged: (value) {
                  setState(() {
                    _sliderValue = value;
                    _updateControllerFromSlider();
                    _selectedPreset = _getPresetFromValue(_sliderValue);
                  });
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('0.1g', style: TextStyle(color: Colors.grey[600])),
                  Text('3.0g', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildManualInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Manual Input', style: AppStyles.h2),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _goalController,
                decoration: InputDecoration(
                  labelText: 'Daily Goal',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) => _updateSliderFromController(),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a goal';
                  }
                  final goal = double.tryParse(value.trim());
                  if (goal == null || goal <= 0) {
                    return 'Invalid goal';
                  }
                  return null;
                },
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: DropdownButtonFormField<String>(
                value: _selectedUnit,
                decoration: InputDecoration(
                  labelText: 'Unit',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: _units.map((unit) {
                  return DropdownMenuItem(
                    value: unit,
                    child: Text(unit),
                  );
                }).toList(),
                onChanged: (value) => _onUnitChanged(value!),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHealthAdviceSection() {
    Color adviceColor;
    String adviceText;
    IconData adviceIcon;

    if (_sliderValue <= 600) {
      adviceColor = Colors.green;
      adviceIcon = Icons.star;
      adviceText = 'Excellent! This is a very strict goal that aligns with the lowest health recommendations.';
    } else if (_sliderValue <= 1000) {
      adviceColor = Colors.green;
      adviceIcon = Icons.thumb_up;
      adviceText = 'Great choice! This goal is within the recommended healthy range.';
    } else if (_sliderValue <= 1500) {
      adviceColor = Colors.orange;
      adviceIcon = Icons.warning;
      adviceText = 'Moderate goal. Consider reducing to 1000mg or less for better health benefits.';
    } else {
      adviceColor = Colors.red;
      adviceIcon = Icons.info;
      adviceText = 'High goal. WHO recommends no more than 25g (25000mg) of added sugar per day.';
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: adviceColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: adviceColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(adviceIcon, color: adviceColor, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Health Advice',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: adviceColor,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  adviceText,
                  style: TextStyle(
                    fontSize: 14,
                    color: adviceColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PresetGoal {
  final String name;
  final double value;
  final String description;

  PresetGoal({
    required this.name,
    required this.value,
    required this.description,
  });
}
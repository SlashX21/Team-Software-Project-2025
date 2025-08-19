import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';
import '../../theme/screen_adapter.dart';
import '../../theme/responsive_layout.dart';
import '../../widgets/adaptive_widgets.dart';
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
  double _sliderValue = 50000.0; // 默认值调整为50g
  String _selectedUnit = 'mg';
  final List<String> _units = ['mg', 'g'];

  // 预设目标 (基于WHO建议优化)
  final List<PresetGoal> _presetGoals = [
    PresetGoal(
      name: 'Strict', 
      value: 25000.0, 
      description: 'Very low sugar diet',
      detail: 'WHO ideal recommendation (5% of daily calories)',
      reference: '≈ 6 tsp sugar or 1 can of cola'
    ),
    PresetGoal(
      name: 'Moderate', 
      value: 40000.0, 
      description: 'Balanced approach',
      detail: 'Between ideal and maximum WHO recommendations',
      reference: '≈ 10 tsp sugar or 1.5 cans of cola'
    ),
    PresetGoal(
      name: 'Relaxed', 
      value: 50000.0, 
      description: 'Flexible diet',
      detail: 'WHO maximum recommendation (10% of daily calories)',
      reference: '≈ 12 tsp sugar or 2 cans of cola'
    ),
    PresetGoal(
      name: 'Custom', 
      value: 0.0, 
      description: 'Set your own goal',
      detail: '',
      reference: ''
    ),
  ];

  String _selectedPreset = 'Relaxed'; // 改为默认选择Relaxed (50g)

  @override
  void initState() {
    super.initState();
    if (widget.currentGoal != null) {
      _sliderValue = widget.currentGoal!.dailyGoalMg.clamp(10000.0, 100000.0);
      _goalController.text = (_sliderValue / 1000).toStringAsFixed(1);
      _selectedUnit = 'g';
      _selectedPreset = _getPresetFromValue(_sliderValue);
    } else {
      // 新用户默认使用Relaxed预设
      _sliderValue = 50000.0; // 50g
      _goalController.text = '50.0';
      _selectedUnit = 'g';
      _selectedPreset = 'Relaxed';
    }
  }

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  String _getPresetFromValue(double value) {
    if (value <= 25000) return 'Strict';
    if (value <= 40000) return 'Moderate';
    if (value <= 50000) return 'Relaxed';
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
        _sliderValue = _sliderValue.clamp(10000.0, 100000.0); // 10g - 100g范围
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

      final success = await setSugarGoal(userId, _sliderValue, _selectedPreset.toUpperCase());

      setState(() => _isLoading = false);

      if (success) {
        Navigator.pop(context, true); // Return success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sugar goal updated successfully'),
            backgroundColor: AppColors.primary,
            duration: Duration(seconds: 2), // 缩短到2秒
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update sugar goal'),
            backgroundColor: AppColors.alert,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred. Please try again.'),
          backgroundColor: AppColors.alert,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Sugar Goal Setting', style: AppStyles.h2.copyWith(color: AppColors.white)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        foregroundColor: Colors.white,
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
              // 添加参考信息显示
              SizedBox(height: 16),
              _buildReferenceInfo(),
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
                          SizedBox(height: 2),
                          Text(
                            goal.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (goal.detail.isNotEmpty) ...[
                            SizedBox(height: 4),
                            Text(
                              goal.detail,
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected ? AppColors.primary.withOpacity(0.8) : Colors.grey[500],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                          if (goal.reference.isNotEmpty) ...[
                            SizedBox(height: 4),
                            Text(
                              goal.reference,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
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
                  color: _getSliderColor(_sliderValue),
                ),
              ),
              SizedBox(height: 16),
              Slider(
                value: _sliderValue.clamp(10000.0, 100000.0),
                min: 10000.0,
                max: 100000.0,
                divisions: 90, // (100000-10000)/1000 = 90 (1g精度)
                activeColor: _getSliderColor(_sliderValue),
                inactiveColor: _getSliderColor(_sliderValue).withOpacity(0.3),
                thumbColor: _getSliderColor(_sliderValue),
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
                  Text('10g', style: TextStyle(color: Colors.grey[600])),
                  Text('100g', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
              SizedBox(height: 12),
              _buildColorLegend(),
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

    if (_sliderValue <= 25000) {
      adviceColor = Colors.green;
      adviceIcon = Icons.star;
      adviceText = 'Excellent! This aligns with WHO ideal recommendation (5% of daily calories).';
    } else if (_sliderValue <= 50000) {
      adviceColor = Colors.green;
      adviceIcon = Icons.thumb_up;
      adviceText = 'Good choice! This is within WHO maximum recommendation (10% of daily calories).';
    } else if (_sliderValue <= 75000) {
      adviceColor = Colors.orange;
      adviceIcon = Icons.warning;
      adviceText = 'Exceeds WHO recommendations. Consider reducing for better health.';
    } else {
      adviceColor = Colors.red;
      adviceIcon = Icons.warning;
      adviceText = 'Very high goal. This significantly exceeds WHO recommendations.';
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

  Widget _buildReferenceInfo() {
    final goalInGrams = _sliderValue / 1000;
    final teaspoons = (goalInGrams / 4).round();
    final colaCans = (goalInGrams / 35).toStringAsFixed(1);
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text(
                'Reference Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          _buildReferenceItem(
            Icons.restaurant,
            'Equivalent to',
            '≈ $teaspoons teaspoons of sugar',
          ),
          AdaptiveSpacing.vertical(8),
          _buildReferenceItem(
            Icons.local_drink,
            'Or about',
            '≈ $colaCans cans of cola (330ml)',
          ),
          AdaptiveSpacing.vertical(8),
          _buildReferenceItem(
            Icons.cake,
            'Similar to',
            _getFoodEquivalent(goalInGrams),
          ),
        ],
      ),
    );
  }

  Widget _buildReferenceItem(IconData icon, String label, String value) {
    // Web端字体缩放
    final shouldReduceTextScale = kIsWeb;
    final webFontSize = shouldReduceTextScale ? 12.0 : 14.0;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdaptiveIcon(
          icon: icon, 
          size: 18, 
          color: Colors.blue[600],
        ),
        AdaptiveSpacing.horizontal(8),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: webFontSize,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.blue[700],
              fontSize: webFontSize,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _getFoodEquivalent(double grams) {
    if (grams <= 15) return '1 tablespoon of honey';
    if (grams <= 25) return '1 chocolate bar (50g)';
    if (grams <= 35) return '1 can of cola (330ml)';
    if (grams <= 50) return '2 chocolate bars or 1.5 cans of cola';
    if (grams <= 75) return '3 chocolate bars or 2 cans of cola';
    return '4+ chocolate bars or 3+ cans of cola';
  }

  Color _getSliderColor(double value) {
    if (value <= 25000) {
      // 深绿色区域 (10-25g): WHO理想建议
      double ratio = (value - 10000) / 15000; // 0-1之间
      return Color.lerp(Color(0xFF2E7D32), Color(0xFF4CAF50), ratio)!; // 深绿到绿色
    } else if (value <= 50000) {
      // 绿色到黄绿色区域 (25-50g): WHO最大建议范围
      double ratio = (value - 25000) / 25000; // 0-1之间
      return Color.lerp(Color(0xFF4CAF50), Color(0xFF8BC34A), ratio)!; // 绿色到黄绿色
    } else if (value <= 75000) {
      // 黄色到橙色区域 (50-75g): 超出WHO建议
      double ratio = (value - 50000) / 25000; // 0-1之间
      return Color.lerp(Color(0xFFFF9800), Color(0xFFFF5722), ratio)!; // 橙色到深橙色
    } else {
      // 红色区域 (75g+): 严重超出建议
      double ratio = ((value - 75000) / 25000).clamp(0.0, 1.0); // 0-1之间
      return Color.lerp(Color(0xFFFF5722), Color(0xFFD32F2F), ratio)!; // 深橙色到红色
    }
  }

  Widget _buildColorLegend() {
    return Column(
      children: [
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 25,
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                  ),
                  borderRadius: BorderRadius.horizontal(left: Radius.circular(3)),
                ),
              ),
            ),
            Expanded(
              flex: 25,
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF8BC34A)],
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 25,
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 25,
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF5722), Color(0xFFD32F2F)],
                  ),
                  borderRadius: BorderRadius.horizontal(right: Radius.circular(3)),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Ideal', style: TextStyle(fontSize: 10, color: Color(0xFF4CAF50))),
            Text('Good', style: TextStyle(fontSize: 10, color: Color(0xFF8BC34A))),
            Text('High', style: TextStyle(fontSize: 10, color: Color(0xFFFF9800))),
            Text('Very High', style: TextStyle(fontSize: 10, color: Color(0xFFD32F2F))),
          ],
        ),
        SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('≤25g', style: TextStyle(fontSize: 9, color: Colors.grey[600])),
            Text('≤50g', style: TextStyle(fontSize: 9, color: Colors.grey[600])),
            Text('≤75g', style: TextStyle(fontSize: 9, color: Colors.grey[600])),
            Text('>75g', style: TextStyle(fontSize: 9, color: Colors.grey[600])),
          ],
        ),
      ],
    );
  }
}

class PresetGoal {
  final String name;
  final double value;
  final String description;
  final String detail;
  final String reference;

  PresetGoal({
    required this.name,
    required this.value,
    required this.description,
    this.detail = '',
    this.reference = '',
  });
}
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';
import '../main_navigation_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  final int userId;

  const ProfileSetupScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();
  
  // Form controllers
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  
  // Form values
  String? _selectedGender;
  String? _selectedActivityLevel;
  
  int _currentStep = 0;
  final int _totalSteps = 2;
  bool _isLoading = false;

  final List<String> _genderOptions = ['MALE', 'FEMALE', 'OTHER'];
  final List<String> _activityLevels = [
    'SEDENTARY',
    'LIGHTLY_ACTIVE', 
    'MODERATELY_ACTIVE',
    'VERY_ACTIVE',
    'EXTREMELY_ACTIVE'
  ];


  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeSetup();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeSetup() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);

    try {
      // Here you would typically update the user profile via API
      // await ApiService.updateUserProfile(...)
      
      // For now, just simulate API call
      await Future.delayed(Duration(milliseconds: 1000));
      
      if (!mounted) return;
      
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => MainNavigationScreen(userId: widget.userId),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save profile: $e'),
          backgroundColor: AppColors.alert,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          'Complete Your Profile',
          style: AppStyles.h2.copyWith(color: AppColors.white),
        ),
        leading: _currentStep > 0
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: AppColors.white),
                onPressed: _previousStep,
              )
            : null,
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentStep = index),
              physics: NeverScrollableScrollPhysics(),
              children: [
                _buildBasicInfoStep(),
                _buildActivityStep(),
              ],
            ),
          ),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: EdgeInsets.all(20),
      color: AppColors.primary,
      child: Row(
        children: List.generate(_totalSteps, (index) {
          final isActive = index <= _currentStep;
          final isCompleted = index < _currentStep;
          
          return Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 4),
              height: 4,
              decoration: BoxDecoration(
                color: isActive ? AppColors.white : AppColors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepHeader(
              'Basic Information',
              'Tell us about yourself to get personalized recommendations',
              Icons.person_outline,
            ),
            SizedBox(height: 32),
            
            Text('Age *', style: AppStyles.bodyBold),
            SizedBox(height: 8),
            _buildNumberField(_ageController, 'Enter your age', 'years'),
            SizedBox(height: 24),
            
            Text('Gender *', style: AppStyles.bodyBold),
            SizedBox(height: 8),
            _buildGenderSelection(),
            SizedBox(height: 24),
            
            Text('Height *', style: AppStyles.bodyBold),
            SizedBox(height: 8),
            _buildNumberField(_heightController, 'Enter your height', 'cm'),
            SizedBox(height: 24),
            
            Text('Weight *', style: AppStyles.bodyBold),
            SizedBox(height: 8),
            _buildNumberField(_weightController, 'Enter your weight', 'kg'),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            'Activity Level',
            'How active are you on a typical day?',
            Icons.fitness_center,
          ),
          SizedBox(height: 32),
          
          ..._activityLevels.map((level) => _buildActivityOption(level)),
        ],
      ),
    );
  }

  Widget _buildStepHeader(String title, String subtitle, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
        SizedBox(height: 16),
        Text(title, style: AppStyles.h1),
        SizedBox(height: 8),
        Text(
          subtitle,
          style: AppStyles.bodyRegular.copyWith(color: AppColors.textLight),
        ),
      ],
    );
  }

  Widget _buildNumberField(TextEditingController controller, String hint, String suffix) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        hintText: hint,
        suffixText: suffix,
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.alert),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'This field is required';
        }
        final number = double.tryParse(value);
        if (number == null || number <= 0) {
          return 'Please enter a valid number';
        }
        return null;
      },
    );
  }

  Widget _buildGenderSelection() {
    return Row(
      children: _genderOptions.map((gender) {
        final isSelected = _selectedGender == gender;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedGender = gender),
            child: Container(
              margin: EdgeInsets.only(right: gender != _genderOptions.last ? 8 : 0),
              padding: EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.primary.withOpacity(0.2),
                ),
              ),
              child: Text(
                _formatDisplayText(gender),
                style: AppStyles.bodyBold.copyWith(
                  color: isSelected ? AppColors.white : AppColors.textDark,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActivityOption(String level) {
    final isSelected = _selectedActivityLevel == level;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedActivityLevel = level),
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.primary.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.fitness_center,
                color: isSelected ? AppColors.white : AppColors.primary,
                size: 20,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatDisplayText(level),
                    style: AppStyles.bodyBold.copyWith(
                      color: isSelected ? AppColors.primary : AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _getActivityDescription(level),
                    style: AppStyles.bodyRegular.copyWith(color: AppColors.textLight),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: AppColors.primary),
          ],
        ),
      ),
    );
  }



  Widget _buildNavigationButtons() {
    return Container(
      padding: EdgeInsets.all(24),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'Back',
                  style: AppStyles.buttonText.copyWith(color: AppColors.primary),
                ),
              ),
            ),
          if (_currentStep > 0) SizedBox(width: 16),
          Expanded(
            flex: _currentStep > 0 ? 1 : 1,
            child: ElevatedButton(
              onPressed: _canProceed() ? (_isLoading ? null : _nextStep) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                      ),
                    )
                  : Text(
                      _currentStep == _totalSteps - 1 ? 'Complete Setup' : 'Next',
                      style: AppStyles.buttonText,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _ageController.text.isNotEmpty &&
               _heightController.text.isNotEmpty &&
               _weightController.text.isNotEmpty &&
               _selectedGender != null;
      case 1:
        return _selectedActivityLevel != null;
      default:
        return false;
    }
  }

  String _formatDisplayText(String value) {
    return value.split('_').map((word) => 
      word[0].toUpperCase() + word.substring(1).toLowerCase()
    ).join(' ');
  }

  String _getActivityDescription(String level) {
    switch (level) {
      case 'SEDENTARY':
        return 'Little to no exercise';
      case 'LIGHTLY_ACTIVE':
        return 'Light exercise 1-3 days/week';
      case 'MODERATELY_ACTIVE':
        return 'Moderate exercise 3-5 days/week';
      case 'VERY_ACTIVE':
        return 'Hard exercise 6-7 days/week';
      case 'EXTREMELY_ACTIVE':
        return 'Very hard exercise, physical job';
      default:
        return '';
    }
  }


}
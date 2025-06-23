import 'package:flutter/material.dart';
import '../theme/app_styles.dart';
import '../theme/app_colors.dart';
import '../widgets/inputFields.dart';
import 'package:page_transition/page_transition.dart';
import './SignInPage.dart';
// TODO: Will be updated to home_screen.dart after main_scaffold is replaced


class SignUpPage extends StatefulWidget {
  final String? pageTitle;

  SignUpPage({Key? key, this.pageTitle}) : super(key: key);

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _proteinController = TextEditingController();
  final TextEditingController _carbsController = TextEditingController();
  final TextEditingController _fatController = TextEditingController();
  final TextEditingController _allergyDescController = TextEditingController();

  String _selectedGender = 'Male';
  String _selectedActivityLevel = 'Sedentary';
  String _selectedNutritionGoal = 'Maintain Weight';
  bool _hasAllergies = false;

  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  final List<String> _activityLevels = ['Sedentary', 'Lightly Active', 'Moderately Active', 'Very Active', 'Extremely Active'];
  final List<String> _nutritionGoals = ['Lose Weight', 'Maintain Weight', 'Gain Weight', 'Build Muscle', 'General Health'];

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _allergyDescController.dispose();
    super.dispose();
  }

  void _handleSignUp() {
    // TODO: Implement sign up logic with all collected data
    print('Username: ${_usernameController.text}');
    print('Full Name: ${_fullNameController.text}');
    print('Email: ${_emailController.text}');
    print('Password: ${_passwordController.text}');
    print('Age: ${_ageController.text}');
    print('Gender: $_selectedGender');
    print('Height: ${_heightController.text}');
    print('Weight: ${_weightController.text}');
    print('Activity Level: $_selectedActivityLevel');
    print('Nutrition Goal: $_selectedNutritionGoal');
    print('Daily Calories: ${_caloriesController.text}');
    print('Daily Protein: ${_proteinController.text}');
    print('Daily Carbs: ${_carbsController.text}');
    print('Daily Fat: ${_fatController.text}');
    print('Has Allergies: $_hasAllergies');
    print('Allergy Description: ${_allergyDescController.text}');
    
    // Navigate to main screen after successful sign up
    Navigator.pushReplacementNamed(context, '/main');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.white,
        title: Text('Sign Up',
            style: TextStyle(
                color: Colors.grey, fontFamily: 'Poppins', fontSize: 15)),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              // Navigator.of(context).pushReplacementNamed('/signin');
              Navigator.pushReplacement(context, PageTransition(type: PageTransitionType.rightToLeft, child: SignInPage()));

            },
            child: Text('Sign In', style: AppStyles.bodyBold.copyWith(color: AppColors.primary)),
          )
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(18),
        children: <Widget>[
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Welcome to Grocery Guardian!', style: AppStyles.h2),
                SizedBox(height: 8),
                Text('Let\'s create your personalized health profile', style: AppStyles.bodyRegular.copyWith(color: AppColors.textLight)),
                SizedBox(height: 24),
                
                // Basic Information Section
                Text('Basic Information', style: AppStyles.bodyBold),
                SizedBox(height: 12),
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _fullNameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                SizedBox(height: 24),
                
                // Health Information Section
                Text('Health Information', style: AppStyles.bodyBold),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Age',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedGender,
                        decoration: InputDecoration(
                          labelText: 'Gender',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        items: _genderOptions.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedGender = newValue!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _heightController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Height (cm)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _weightController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Weight (kg)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedActivityLevel,
                  decoration: InputDecoration(
                    labelText: 'Activity Level',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: _activityLevels.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedActivityLevel = newValue!;
                    });
                  },
                ),
                SizedBox(height: 24),
                
                // Nutrition Goals Section
                Text('Nutrition Goals', style: AppStyles.bodyBold),
                SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedNutritionGoal,
                  decoration: InputDecoration(
                    labelText: 'Nutrition Goal',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: _nutritionGoals.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedNutritionGoal = newValue!;
                    });
                  },
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _caloriesController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Daily Calorie Target',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _proteinController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Protein (g)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _carbsController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Carbs (g)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _fatController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Fat (g)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                
                // Allergies Section
                Text('Allergies & Restrictions', style: AppStyles.bodyBold),
                SizedBox(height: 12),
                Row(
                  children: [
                    Switch(
                      value: _hasAllergies,
                      onChanged: (bool value) {
                        setState(() {
                          _hasAllergies = value;
                        });
                      },
                      activeColor: AppColors.primary,
                    ),
                    SizedBox(width: 8),
                    Text('I have food allergies or dietary restrictions', style: AppStyles.bodyRegular),
                  ],
                ),
                if (_hasAllergies) ...[
                  SizedBox(height: 16),
                  TextField(
                    controller: _allergyDescController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Describe your allergies and dietary restrictions',
                      hintText: 'e.g., nuts, dairy, gluten, vegetarian, etc.',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
                SizedBox(height: 32),
                
                // Sign Up Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _handleSignUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Create Account', style: AppStyles.buttonText),
                  ),
                ),
              ],
            ),
          ),
        ],
      )
    );
  }
}

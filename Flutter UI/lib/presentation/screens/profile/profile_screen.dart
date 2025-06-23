import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // TODO: Load this data from actual user storage
  Map<String, dynamic> _userProfile = {
    'username': 'john_doe',
    'fullName': 'John Doe',
    'email': 'john.doe@example.com',
    'age': '28',
    'gender': 'Male',
    'height': '175',
    'weight': '70',
    'activityLevel': 'Moderately Active',
    'nutritionGoal': 'Maintain Weight',
    'dailyCalories': '2200',
    'dailyProtein': '120',
    'dailyCarbs': '275',
    'dailyFat': '75',
    'hasAllergies': true,
    'allergyDescription': 'Allergic to peanuts and shellfish. Lactose intolerant.',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile', style: AppStyles.h2),
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: BackButton(color: AppColors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: AppColors.white),
            onPressed: _showEditDialog,
          ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Header
          _buildProfileHeader(),
          SizedBox(height: 24),
          
          // Basic Information Section
          _buildSection(
            title: 'Basic Information',
            children: [
              _buildInfoRow('Username', _userProfile['username']),
              _buildInfoRow('Full Name', _userProfile['fullName']),
              _buildInfoRow('Email', _userProfile['email']),
            ],
          ),
          SizedBox(height: 20),
          
          // Health Information Section
          _buildSection(
            title: 'Health Information',
            children: [
              _buildInfoRow('Age', '${_userProfile['age']} years'),
              _buildInfoRow('Gender', _userProfile['gender']),
              _buildInfoRow('Height', '${_userProfile['height']} cm'),
              _buildInfoRow('Weight', '${_userProfile['weight']} kg'),
              _buildInfoRow('Activity Level', _userProfile['activityLevel']),
            ],
          ),
          SizedBox(height: 20),
          
          // Nutrition Goals Section
          _buildSection(
            title: 'Nutrition Goals',
            children: [
              _buildInfoRow('Goal', _userProfile['nutritionGoal']),
              _buildInfoRow('Daily Calories', '${_userProfile['dailyCalories']} kcal'),
              _buildInfoRow('Daily Protein', '${_userProfile['dailyProtein']} g'),
              _buildInfoRow('Daily Carbs', '${_userProfile['dailyCarbs']} g'),
              _buildInfoRow('Daily Fat', '${_userProfile['dailyFat']} g'),
            ],
          ),
          SizedBox(height: 20),
          
          // Allergies Section
          _buildSection(
            title: 'Allergies & Restrictions',
            children: [
              _buildInfoRow(
                'Has Allergies', 
                _userProfile['hasAllergies'] ? 'Yes' : 'No',
                isAlert: _userProfile['hasAllergies'],
              ),
              if (_userProfile['hasAllergies'])
                _buildAllergyDescription(),
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
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
                  _userProfile['fullName'],
                  style: AppStyles.h2,
                ),
                SizedBox(height: 4),
                Text(
                  _userProfile['email'],
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
                    _userProfile['nutritionGoal'],
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

  Widget _buildAllergyDescription() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
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
            child: Text(
              _userProfile['allergyDescription'],
              style: AppStyles.bodyRegular.copyWith(
                color: AppColors.textDark,
              ),
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
                color: AppColors.primary,
                size: 24,
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppStyles.bodyBold),
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

  void _showEditDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Profile', style: AppStyles.bodyBold),
          content: Text(
            'Profile editing feature is coming soon!',
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
}
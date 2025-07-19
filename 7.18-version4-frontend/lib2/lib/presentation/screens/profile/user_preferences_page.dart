import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';

class UserPreferencesPage extends StatefulWidget {
  const UserPreferencesPage({Key? key}) : super(key: key);

  @override
  State<UserPreferencesPage> createState() => _UserPreferencesPageState();
}

class _UserPreferencesPageState extends State<UserPreferencesPage> {
  // Notification settings
  bool _scanResultNotifications = true;
  bool _dailySugarNotifications = true;
  bool _weeklyReportNotifications = true;
  bool _allergenAlerts = true;
  bool _recommendationNotifications = false;

  // Data preferences
  bool _saveScannedProducts = true;
  bool _shareDataForInsights = false;
  bool _enableProductSync = true;
  String _dataRetentionPeriod = '1_year';

  // Display preferences
  String _temperatureUnit = 'celsius';
  String _weightUnit = 'kg';
  String _heightUnit = 'cm';
  String _defaultScanMode = 'barcode';
  bool _showHealthScore = true;
  bool _showNutritionLabels = true;

  // Advanced filter preferences
  List<String> _excludedIngredients = ['artificial_colors', 'high_fructose_corn_syrup'];
  List<String> _preferredBrands = [];
  List<String> _avoidedBrands = [];
  double _maxCaloriesFilter = 500;
  double _maxSugarFilter = 25;
  double _minProteinFilter = 5;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load user preferences from local storage or API
      // Using default values for now, can connect to real API later
      await Future.delayed(Duration(milliseconds: 500)); // Simulate loading
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('❌ Failed to load preference settings: $e');
    }
  }

  Future<void> _savePreferences() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Save preference settings to API or local storage
      await Future.delayed(Duration(milliseconds: 1000)); // Simulate saving
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Preference settings saved'),
          backgroundColor: AppColors.success,
        ),
      );
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Save failed, please try again'),
          backgroundColor: AppColors.alert,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Preference Settings',
          style: AppStyles.h2.copyWith(color: AppColors.white),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _savePreferences,
            child: Text(
              'Save',
              style: AppStyles.bodyBold.copyWith(color: AppColors.white),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildNotificationSettings(),
                  SizedBox(height: 16),
                  _buildDataPreferences(),
                  SizedBox(height: 16),
                  _buildDisplayPreferences(),
                  SizedBox(height: 16),
                  _buildFilterPreferences(),
                  SizedBox(height: 24),
                  _buildResetSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildNotificationSettings() {
    return _buildSection(
      title: 'Notification Settings',
      icon: Icons.notifications,
      children: [
        _buildSwitchTile(
          title: 'Scan Result Notifications',
          subtitle: 'Receive notifications when product scanning is completed',
          value: _scanResultNotifications,
          onChanged: (value) => setState(() => _scanResultNotifications = value),
        ),
        _buildSwitchTile(
          title: 'Daily Sugar Reminders',
          subtitle: 'Remind when sugar intake goal is reached',
          value: _dailySugarNotifications,
          onChanged: (value) => setState(() => _dailySugarNotifications = value),
        ),
        _buildSwitchTile(
          title: 'Weekly Report Notifications',
          subtitle: 'Weekly nutrition analysis report',
          value: _weeklyReportNotifications,
          onChanged: (value) => setState(() => _weeklyReportNotifications = value),
        ),
        _buildSwitchTile(
          title: 'Allergen Alerts',
          subtitle: 'Immediate warning when allergens are detected',
          value: _allergenAlerts,
          onChanged: (value) => setState(() => _allergenAlerts = value),
        ),
        _buildSwitchTile(
          title: 'Product Recommendations',
          subtitle: 'New product recommendation notifications',
          value: _recommendationNotifications,
          onChanged: (value) => setState(() => _recommendationNotifications = value),
        ),
      ],
    );
  }

  Widget _buildDataPreferences() {
    return _buildSection(
      title: 'Data Preferences',
      icon: Icons.storage,
      children: [
        _buildSwitchTile(
          title: 'Save Scan Records',
          subtitle: 'Automatically save all scanned products',
          value: _saveScannedProducts,
          onChanged: (value) => setState(() => _saveScannedProducts = value),
        ),
        _buildSwitchTile(
          title: 'Share Data for Improvements',
          subtitle: 'Anonymously share data to help improve recommendation algorithms',
          value: _shareDataForInsights,
          onChanged: (value) => setState(() => _shareDataForInsights = value),
        ),
        _buildSwitchTile(
          title: 'Enable Product Sync',
          subtitle: 'Sync product data across multiple devices',
          value: _enableProductSync,
          onChanged: (value) => setState(() => _enableProductSync = value),
        ),
        _buildDropdownTile(
          title: 'Data Retention Period',
          subtitle: 'Historical data retention time',
          value: _dataRetentionPeriod,
          items: [
            DropdownMenuItem(value: '3_months', child: Text('3 months')),
            DropdownMenuItem(value: '6_months', child: Text('6 months')),
            DropdownMenuItem(value: '1_year', child: Text('1 year')),
            DropdownMenuItem(value: '2_years', child: Text('2 years')),
            DropdownMenuItem(value: 'forever', child: Text('Keep forever')),
          ],
          onChanged: (value) => setState(() => _dataRetentionPeriod = value!),
        ),
      ],
    );
  }

  Widget _buildDisplayPreferences() {
    return _buildSection(
      title: 'Display Preferences',
      icon: Icons.display_settings,
      children: [
        _buildDropdownTile(
          title: 'Default Scan Mode',
          subtitle: 'Default mode when starting scan',
          value: _defaultScanMode,
          items: [
            DropdownMenuItem(value: 'barcode', child: Text('Barcode Scan')),
            DropdownMenuItem(value: 'receipt', child: Text('Receipt Scan')),
          ],
          onChanged: (value) => setState(() => _defaultScanMode = value!),
        ),
        _buildDropdownTile(
          title: 'Weight Unit',
          subtitle: 'Unit used when displaying weight',
          value: _weightUnit,
          items: [
            DropdownMenuItem(value: 'kg', child: Text('Kilograms (kg)')),
            DropdownMenuItem(value: 'lb', child: Text('Pounds (lb)')),
          ],
          onChanged: (value) => setState(() => _weightUnit = value!),
        ),
        _buildDropdownTile(
          title: 'Height Unit',
          subtitle: 'Unit used when displaying height',
          value: _heightUnit,
          items: [
            DropdownMenuItem(value: 'cm', child: Text('Centimeters (cm)')),
            DropdownMenuItem(value: 'ft', child: Text('Feet (ft)')),
          ],
          onChanged: (value) => setState(() => _heightUnit = value!),
        ),
        _buildSwitchTile(
          title: 'Show Health Score',
          subtitle: 'Display health score in product information',
          value: _showHealthScore,
          onChanged: (value) => setState(() => _showHealthScore = value),
        ),
        _buildSwitchTile(
          title: 'Show Nutrition Labels',
          subtitle: 'Display detailed nutrition labels',
          value: _showNutritionLabels,
          onChanged: (value) => setState(() => _showNutritionLabels = value),
        ),
      ],
    );
  }

  Widget _buildFilterPreferences() {
    return _buildSection(
      title: 'Filter Preferences',
      icon: Icons.filter_alt,
      children: [
        _buildSliderTile(
          title: 'Max Calories Filter',
          subtitle: 'Filter products with calories above this value',
          value: _maxCaloriesFilter,
          min: 100,
          max: 1000,
          divisions: 18,
          label: '${_maxCaloriesFilter.round()} kcal',
          onChanged: (value) => setState(() => _maxCaloriesFilter = value),
        ),
        _buildSliderTile(
          title: 'Max Sugar Filter',
          subtitle: 'Filter products with sugar above this value',
          value: _maxSugarFilter,
          min: 5,
          max: 50,
          divisions: 9,
          label: '${_maxSugarFilter.round()}g',
          onChanged: (value) => setState(() => _maxSugarFilter = value),
        ),
        _buildSliderTile(
          title: 'Min Protein',
          subtitle: 'Filter products with protein content not below this value',
          value: _minProteinFilter,
          min: 0,
          max: 30,
          divisions: 15,
          label: '${_minProteinFilter.round()}g',
          onChanged: (value) => setState(() => _minProteinFilter = value),
        ),
        _buildChipSection(
          title: 'Avoided Ingredients',
          items: _excludedIngredients,
          allItems: [
            'artificial_colors',
            'high_fructose_corn_syrup',
            'trans_fats',
            'artificial_sweeteners',
            'preservatives',
            'msg',
          ],
          itemLabels: {
            'artificial_colors': 'Artificial Colors',
            'high_fructose_corn_syrup': 'High Fructose Corn Syrup',
            'trans_fats': 'Trans Fats',
            'artificial_sweeteners': 'Artificial Sweeteners',
            'preservatives': 'Preservatives',
            'msg': 'MSG',
          },
          onChanged: (items) => setState(() => _excludedIngredients = items),
        ),
      ],
    );
  }

  Widget _buildResetSection() {
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
        children: [
          Text(
            'Reset Settings',
            style: AppStyles.bodyBold,
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _resetToDefaults,
                  icon: Icon(Icons.restore, color: AppColors.warning),
                  label: Text('Restore Default Settings'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.warning,
                    side: BorderSide(color: AppColors.warning),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _clearAllData,
                  icon: Icon(Icons.delete_forever, color: AppColors.alert),
                  label: Text('Clear All Data'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.alert,
                    side: BorderSide(color: AppColors.alert),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
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
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 24),
              SizedBox(width: 12),
              Text(title, style: AppStyles.bodyBold),
            ],
          ),
          SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppStyles.bodyRegular),
                SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppStyles.bodyRegular.copyWith(
                    color: AppColors.textLight,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownTile({
    required String title,
    required String subtitle,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppStyles.bodyRegular),
          SizedBox(height: 2),
          Text(
            subtitle,
            style: AppStyles.bodyRegular.copyWith(
              color: AppColors.textLight,
              fontSize: 12,
            ),
          ),
          SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: value,
            items: items,
            onChanged: onChanged,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderTile({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String label,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppStyles.bodyRegular),
              Text(label, style: AppStyles.bodyBold.copyWith(color: AppColors.primary)),
            ],
          ),
          SizedBox(height: 2),
          Text(
            subtitle,
            style: AppStyles.bodyRegular.copyWith(
              color: AppColors.textLight,
              fontSize: 12,
            ),
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildChipSection({
    required String title,
    required List<String> items,
    required List<String> allItems,
    required Map<String, String> itemLabels,
    required ValueChanged<List<String>> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppStyles.bodyRegular),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: allItems.map((item) {
              final isSelected = items.contains(item);
              final label = itemLabels[item] ?? item;
              
              return FilterChip(
                label: Text(label),
                selected: isSelected,
                onSelected: (selected) {
                  final newItems = List<String>.from(items);
                  if (selected) {
                    newItems.add(item);
                  } else {
                    newItems.remove(item);
                  }
                  onChanged(newItems);
                },
                selectedColor: AppColors.primary.withOpacity(0.2),
                checkmarkColor: AppColors.primary,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _resetToDefaults() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Reset'),
        content: Text('Are you sure you want to reset all settings to default values? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                // Reset all settings to default values
                _scanResultNotifications = true;
                _dailySugarNotifications = true;
                _weeklyReportNotifications = true;
                _allergenAlerts = true;
                _recommendationNotifications = false;
                
                _saveScannedProducts = true;
                _shareDataForInsights = false;
                _enableProductSync = true;
                _dataRetentionPeriod = '1_year';
                
                _weightUnit = 'kg';
                _heightUnit = 'cm';
                _defaultScanMode = 'barcode';
                _showHealthScore = true;
                _showNutritionLabels = true;
                
                _excludedIngredients = ['artificial_colors', 'high_fructose_corn_syrup'];
                _maxCaloriesFilter = 500;
                _maxSugarFilter = 25;
                _minProteinFilter = 5;
              });
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Settings have been reset to default values'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: Text('Confirm', style: TextStyle(color: AppColors.warning)),
          ),
        ],
      ),
    );
  }

  void _clearAllData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Dangerous Operation'),
        content: Text('Are you sure you want to clear all user data? Including scan history, allergen information, etc. This action cannot be undone!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement clear all data functionality
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Data clearing feature under development...'),
                  backgroundColor: AppColors.warning,
                ),
              );
            },
            child: Text('Confirm Clear', style: TextStyle(color: AppColors.alert)),
          ),
        ],
      ),
    );
  }
} 
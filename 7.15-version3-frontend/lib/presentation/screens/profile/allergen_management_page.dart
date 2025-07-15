import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';
import '../../../services/api.dart';
import '../../../services/user_service.dart';
import 'add_allergen_page.dart';

class AllergenManagementPage extends StatefulWidget {
  const AllergenManagementPage({Key? key}) : super(key: key);

  @override
  State<AllergenManagementPage> createState() => _AllergenManagementPageState();
}

class _AllergenManagementPageState extends State<AllergenManagementPage> {
  List<Map<String, dynamic>> _userAllergens = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserAllergens();
  }

  Future<void> _loadUserAllergens() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userId = await UserService.instance.getCurrentUserId();
      if (userId == null) {
        setState(() {
          _error = 'User not logged in';
          _isLoading = false;
        });
        return;
      }

      final allergens = await getUserAllergens(userId);
      setState(() {
        _userAllergens = allergens ?? [];
        _isLoading = false;
      });
      
      print('✅ Loaded user allergens: ${_userAllergens.length} items');
    } catch (e) {
      setState(() {
        _error = 'Failed to load allergens: $e';
        _isLoading = false;
      });
      print('❌ Error loading user allergens: $e');
    }
  }

  Future<void> _deleteAllergen(int userAllergenId, String allergenName) async {
    if (userAllergenId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid allergen ID, cannot delete'),
          backgroundColor: AppColors.alert,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Allergen'),
        content: Text('Are you sure you want to delete allergen "$allergenName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.alert),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final userId = await UserService.instance.getCurrentUserId();
      if (userId == null) return;

      final success = await deleteUserAllergen(userId, userAllergenId);
      if (success) {
        setState(() {
          _userAllergens.removeWhere((allergen) => 
            (allergen['id'] ?? allergen['userAllergenId']) == userAllergenId);
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Allergen "$allergenName" has been deleted'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Delete failed, please try again'),
              backgroundColor: AppColors.alert,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delete failed: $e'),
            backgroundColor: AppColors.alert,
          ),
        );
      }
    }
  }

  Future<void> _navigateToAddAllergen() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const AddAllergenPage(),
      ),
    );

    if (result == true) {
      // Reload allergen list
      _loadUserAllergens();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Allergen Management',
          style: AppStyles.h2.copyWith(color: AppColors.white),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.white),
            onPressed: _loadUserAllergens,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddAllergen,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        icon: Icon(Icons.add),
        label: Text('Add Allergen'),
      ),
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
            Text(
              'Loading allergen information...',
              style: AppStyles.bodyRegular.copyWith(color: AppColors.textLight),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: AppColors.alert,
            ),
            SizedBox(height: 16),
            Text(
              'Load Failed',
              style: AppStyles.h2.copyWith(color: AppColors.alert),
            ),
            SizedBox(height: 8),
            Text(
              _error!,
              style: AppStyles.bodyRegular.copyWith(color: AppColors.textLight),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadUserAllergens,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_userAllergens.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_amber,
              size: 80,
              color: AppColors.warning,
            ),
            SizedBox(height: 16),
            Text(
              'No Allergen Records',
              style: AppStyles.h2.copyWith(color: AppColors.textLight),
            ),
            SizedBox(height: 8),
            Text(
              'Add your allergen information\nso we can provide safer food recommendations',
              style: AppStyles.bodyRegular.copyWith(color: AppColors.textLight),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _navigateToAddAllergen,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              icon: Icon(Icons.add),
              label: Text('Add Allergen'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUserAllergens,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _userAllergens.length,
        itemBuilder: (context, index) {
          final allergen = _userAllergens[index];
          return AllergenCard(
            allergen: allergen,
            onDelete: () => _deleteAllergen(
              allergen['id'] ?? allergen['userAllergenId'] ?? 0,
              allergen['allergenName'] ?? 'Unknown Allergen',
            ),
          );
        },
      ),
    );
  }
}

class AllergenCard extends StatelessWidget {
  final Map<String, dynamic> allergen;
  final VoidCallback onDelete;

  const AllergenCard({
    Key? key,
    required this.allergen,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final allergenName = allergen['allergenName'] ?? 'Unknown Allergen';
    final severityLevel = allergen['severityLevel'] ?? 'MILD';
    final notes = allergen['notes'];
    final createdAt = allergen['createdAt'];

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getSeverityColor(severityLevel).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.warning,
                      color: _getSeverityColor(severityLevel),
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          allergenName,
                          style: AppStyles.bodyBold.copyWith(fontSize: 16),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getSeverityColor(severityLevel),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getSeverityText(severityLevel),
                                style: AppStyles.bodyRegular.copyWith(
                                  color: AppColors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            if (createdAt != null) ...[
                              SizedBox(width: 8),
                              Text(
                                'Added on ${_formatDate(createdAt)}',
                                style: AppStyles.bodyRegular.copyWith(
                                  color: AppColors.textLight,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onDelete,
                    icon: Icon(Icons.delete_outline),
                    color: AppColors.alert,
                  ),
                ],
              ),
              if (notes != null && notes.toString().isNotEmpty) ...[
                SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notes',
                        style: AppStyles.bodyBold.copyWith(
                          color: AppColors.textLight,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        notes.toString(),
                        style: AppStyles.bodyRegular.copyWith(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toUpperCase()) {
      case 'MILD':
        return AppColors.warning;
      case 'MODERATE':
        return Colors.orange;
      case 'SEVERE':
        return AppColors.alert;
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

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }
} 
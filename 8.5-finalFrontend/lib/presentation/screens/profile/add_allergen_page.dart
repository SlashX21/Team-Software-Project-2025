import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';
import '../../../services/api.dart';
import '../../../services/user_service.dart';

class AddAllergenPage extends StatefulWidget {
  const AddAllergenPage({Key? key}) : super(key: key);

  @override
  State<AddAllergenPage> createState() => _AddAllergenPageState();
}

class _AddAllergenPageState extends State<AddAllergenPage> {
  List<Map<String, dynamic>> _availableAllergens = [];
  List<Map<String, dynamic>> _filteredAllergens = [];
  Map<String, dynamic>? _selectedAllergen;
  String _selectedSeverity = 'MILD';
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  final List<Map<String, String>> _severityOptions = [
    {'value': 'MILD', 'label': 'Mild', 'description': 'Mild discomfort, usually tolerable'},
    {'value': 'MODERATE', 'label': 'Moderate', 'description': 'Significant discomfort, need to avoid'},
    {'value': 'SEVERE', 'label': 'Severe', 'description': 'Severe reaction, must completely avoid'},
  ];

  @override
  void initState() {
    super.initState();
    _loadAvailableAllergens();
    _searchController.addListener(_filterAllergens);
  }

  @override
  void dispose() {
    _notesController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableAllergens() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final allergens = await getAllergens();
      setState(() {
        _availableAllergens = allergens ?? [];
        _filteredAllergens = _availableAllergens;
        _isLoading = false;
      });
      
      print('✅ Loaded available allergens: ${_availableAllergens.length} items');
    } catch (e) {
      setState(() {
        _error = 'Failed to load allergen list: $e';
        _isLoading = false;
      });
      print('❌ Error loading allergen list: $e');
    }
  }

  void _filterAllergens() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredAllergens = _availableAllergens.where((allergen) {
        final name = (allergen['name'] ?? '').toString().toLowerCase();
        final description = (allergen['description'] ?? '').toString().toLowerCase();
        return name.contains(query) || description.contains(query);
      }).toList();
    });
  }

  Future<void> _saveAllergen() async {
    if (_selectedAllergen == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select an allergen'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final userId = await UserService.instance.getCurrentUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final success = await addUserAllergen(
        userId: userId,
        allergenId: _selectedAllergen!['allergenId'] ?? _selectedAllergen!['id'],
        severityLevel: _selectedSeverity,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Allergen added successfully'),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.pop(context, true); // Return true to indicate successful addition
        }
      } else {
        throw Exception('Add failed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Add failed: $e'),
            backgroundColor: AppColors.alert,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Add Allergen',
          style: AppStyles.h2.copyWith(color: AppColors.white),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isSaving || _selectedAllergen == null ? null : _saveAllergen,
            child: _isSaving
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: AppColors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Save',
                    style: AppStyles.bodyBold.copyWith(color: AppColors.white),
                  ),
          ),
        ],
      ),
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
            Text(
              'Loading allergen list...',
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
              onPressed: _loadAvailableAllergens,
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

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAllergenSelection(),
          SizedBox(height: 24),
          _buildSeveritySelection(),
          SizedBox(height: 24),
          _buildNotesInput(),
          SizedBox(height: 32),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildAllergenSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Allergen',
          style: AppStyles.h2,
        ),
        SizedBox(height: 8),
        Text(
          'Choose your allergen from the list below',
          style: AppStyles.bodyRegular.copyWith(color: AppColors.textLight),
        ),
        SizedBox(height: 16),
        // Search box
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search allergens...',
            prefixIcon: Icon(Icons.search, color: AppColors.textLight),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.textLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary),
            ),
            filled: true,
            fillColor: AppColors.white,
          ),
        ),
        SizedBox(height: 16),
        // Allergen list
        Container(
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.textLight.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: _filteredAllergens.isEmpty
              ? Center(
                  child: Text(
                    'No matching allergens found',
                    style: AppStyles.bodyRegular.copyWith(color: AppColors.textLight),
                  ),
                )
              : ListView.builder(
                  itemCount: _filteredAllergens.length,
                  itemBuilder: (context, index) {
                    final allergen = _filteredAllergens[index];
                    final isSelected = (_selectedAllergen?['allergenId'] ?? _selectedAllergen?['id']) == 
                                       (allergen['allergenId'] ?? allergen['id']);
                    
                    return ListTile(
                      title: Text(
                        allergen['name'] ?? 'Unknown Allergen',
                        style: AppStyles.bodyBold,
                      ),
                      subtitle: allergen['description'] != null
                          ? Text(
                              allergen['description'],
                              style: AppStyles.bodyRegular.copyWith(
                                color: AppColors.textLight,
                                fontSize: 12,
                              ),
                            )
                          : null,
                      leading: Radio<Map<String, dynamic>>(
                        value: allergen,
                        groupValue: _selectedAllergen,
                        onChanged: (value) {
                          setState(() {
                            _selectedAllergen = value;
                          });
                        },
                        activeColor: AppColors.primary,
                      ),
                      selected: isSelected,
                      selectedTileColor: AppColors.primary.withOpacity(0.1),
                      onTap: () {
                        setState(() {
                          _selectedAllergen = allergen;
                        });
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSeveritySelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Severity Level',
          style: AppStyles.h2,
        ),
        SizedBox(height: 8),
        Text(
          'Select your reaction level to this allergen',
          style: AppStyles.bodyRegular.copyWith(color: AppColors.textLight),
        ),
        SizedBox(height: 16),
        Column(
          children: _severityOptions.map((option) {
            final isSelected = _selectedSeverity == option['value'];
            return Container(
              margin: EdgeInsets.only(bottom: 8),
              child: Material(
                color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.white,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedSeverity = option['value']!;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Radio<String>(
                          value: option['value']!,
                          groupValue: _selectedSeverity,
                          onChanged: (value) {
                            setState(() {
                              _selectedSeverity = value!;
                            });
                          },
                          activeColor: AppColors.primary,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                option['label']!,
                                style: AppStyles.bodyBold.copyWith(
                                  color: isSelected ? AppColors.primary : AppColors.textDark,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                option['description']!,
                                style: AppStyles.bodyRegular.copyWith(
                                  color: AppColors.textLight,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNotesInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notes (Optional)',
          style: AppStyles.h2,
        ),
        SizedBox(height: 8),
        Text(
          'Add any additional information or special notes',
          style: AppStyles.bodyRegular.copyWith(color: AppColors.textLight),
        ),
        SizedBox(height: 16),
        TextField(
          controller: _notesController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'e.g., Causes rash after contact...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.textLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary),
            ),
            filled: true,
            fillColor: AppColors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isSaving ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textDark,
              side: BorderSide(color: AppColors.textLight),
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('Cancel'),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isSaving || _selectedAllergen == null ? null : _saveAllergen,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSaving
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: AppColors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text('Add Allergen'),
          ),
        ),
      ],
    );
  }
} 
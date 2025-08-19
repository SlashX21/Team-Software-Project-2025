import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';
import '../../../services/api.dart';
import '../../../services/user_service.dart';

class DataExportPage extends StatefulWidget {
  const DataExportPage({Key? key}) : super(key: key);

  @override
  State<DataExportPage> createState() => _DataExportPageState();
}

class _DataExportPageState extends State<DataExportPage> {
  // Export options
  Set<String> _selectedDataTypes = {'scan_history', 'nutrition_goals'};
  String _exportFormat = 'json';
  DateTimeRange? _dateRange;
  
  // Progress status
  bool _isExporting = false;
  double _exportProgress = 0.0;
  String? _exportStatus;
  String? _exportResult;
  
  // Export history
  List<Map<String, dynamic>> _exportHistory = [];

  final Map<String, String> _dataTypeLabels = {
    'scan_history': 'Scan History',
    'nutrition_goals': 'Nutrition Goals',
    'allergen_info': 'Allergen Information',
    'sugar_tracking': 'Sugar Tracking',
    'monthly_reports': 'Monthly Reports',
    'product_ratings': 'Product Ratings',
    'user_preferences': 'User Preferences',
    'profile_data': 'Profile Data',
  };

  final Map<String, String> _formatLabels = {
    'json': 'JSON - Structured Data',
    'csv': 'CSV - Table Format',
    'pdf': 'PDF - Report Format',
    'xlsx': 'Excel - Spreadsheet',
  };

  @override
  void initState() {
    super.initState();
    _loadExportHistory();
  }

  Future<void> _loadExportHistory() async {
    // Simulate loading export history
    setState(() {
      _exportHistory = [
        {
          'id': '1',
          'type': 'Scan History + Nutrition Goals',
          'format': 'JSON',
          'date': DateTime.now().subtract(Duration(days: 2)),
          'size': '2.3 MB',
          'status': 'completed',
        },
        {
          'id': '2', 
          'type': 'Monthly Report',
          'format': 'PDF',
          'date': DateTime.now().subtract(Duration(days: 7)),
          'size': '1.8 MB',
          'status': 'completed',
        },
      ];
    });
  }

  Future<void> _startExport() async {
    if (_selectedDataTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select at least one data type'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() {
      _isExporting = true;
      _exportProgress = 0.0;
      _exportStatus = 'Preparing export...';
      _exportResult = null;
    });

    try {
      final userId = await UserService.instance.getCurrentUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Simulate step-by-step export process
      final steps = [
        'Verifying permissions...',
        'Collecting data...',
        'Formatting data...',
        'Generating file...',
        'Uploading to cloud...',
      ];

      for (int i = 0; i < steps.length; i++) {
        setState(() {
          _exportStatus = steps[i];
          _exportProgress = (i + 1) / steps.length;
        });
        
        await Future.delayed(Duration(seconds: 1));
        
        // Simulate actual API call during "Collecting data" step
        if (i == 1) {
          await _collectData(userId);
        }
      }

      // Export completed
      setState(() {
        _exportStatus = 'Export completed';
        _exportProgress = 1.0;
        _exportResult = 'Data exported successfully';
        _isExporting = false;
      });

      // Refresh export history
      _loadExportHistory();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Data export successful!'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
          action: SnackBarAction(
            label: 'View',
            textColor: AppColors.white,
            onPressed: () => _showExportResult(),
          ),
        ),
      );

    } catch (e) {
      setState(() {
        _isExporting = false;
        _exportStatus = 'Export failed';
        _exportResult = 'Export failed: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: AppColors.alert,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _collectData(int userId) async {
    // Collect data based on selected data types
    for (String dataType in _selectedDataTypes) {
      switch (dataType) {
        case 'scan_history':
          // Simulate getting scan history
          await Future.delayed(Duration(milliseconds: 300));
          break;
        case 'nutrition_goals':
          // Simulate getting nutrition goals
          await Future.delayed(Duration(milliseconds: 200));
          break;
        case 'allergen_info':
          await getUserAllergens(userId);
          break;
        case 'sugar_tracking':
          // Simulate getting sugar tracking data
          await Future.delayed(Duration(milliseconds: 400));
          break;
        // Add handling for other data types
      }
    }
  }

  void _showExportResult() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Export Completed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Data Types: ${_selectedDataTypes.map((e) => _dataTypeLabels[e]).join(', ')}'),
            SizedBox(height: 8),
            Text('Format: ${_formatLabels[_exportFormat]}'),
            SizedBox(height: 8),
            if (_dateRange != null)
              Text('Date Range: ${_formatDateRange(_dateRange!)}'),
            SizedBox(height: 16),
            Text('File Size: ~1.5 MB'),
            Text('Export Time: ${DateTime.now().toString().substring(0, 19)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement file download
            },
            child: Text('Download'),
          ),
        ],
      ),
    );
  }

  String _formatDateRange(DateTimeRange range) {
    return '${range.start.toString().substring(0, 10)} to ${range.end.toString().substring(0, 10)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Data Export',
          style: AppStyles.h2.copyWith(color: AppColors.white),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildDataTypeSelection(),
            SizedBox(height: 16),
            _buildFormatSelection(),
            SizedBox(height: 16),
            _buildDateRangeSelection(),
            SizedBox(height: 16),
            _buildExportSection(),
            SizedBox(height: 24),
            _buildExportHistory(),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTypeSelection() {
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
              Icon(Icons.dataset, color: AppColors.primary, size: 24),
              SizedBox(width: 12),
              Text('Select Data Types', style: AppStyles.bodyBold),
            ],
          ),
          SizedBox(height: 16),
          Text(
            'Select data types to export (multiple selection allowed)',
            style: AppStyles.bodyRegular.copyWith(color: AppColors.textLight),
          ),
          SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _dataTypeLabels.entries.map((entry) {
              final isSelected = _selectedDataTypes.contains(entry.key);
              return FilterChip(
                label: Text(entry.value),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedDataTypes.add(entry.key);
                    } else {
                      _selectedDataTypes.remove(entry.key);
                    }
                  });
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

  Widget _buildFormatSelection() {
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
              Icon(Icons.file_download, color: AppColors.primary, size: 24),
              SizedBox(width: 12),
              Text('Export Format', style: AppStyles.bodyBold),
            ],
          ),
          SizedBox(height: 16),
          ..._formatLabels.entries.map((entry) {
            return RadioListTile<String>(
              title: Text(entry.value.split(' - ')[0]),
              subtitle: Text(entry.value.split(' - ')[1]),
              value: entry.key,
              groupValue: _exportFormat,
              onChanged: (value) {
                setState(() {
                  _exportFormat = value!;
                });
              },
              activeColor: AppColors.primary,
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildDateRangeSelection() {
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
              Icon(Icons.date_range, color: AppColors.primary, size: 24),
              SizedBox(width: 12),
              Text('Date Range', style: AppStyles.bodyBold),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  _dateRange != null 
                      ? _formatDateRange(_dateRange!)
                      : 'All Time',
                  style: AppStyles.bodyRegular,
                ),
              ),
              TextButton(
                onPressed: () async {
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime.now().subtract(Duration(days: 365)),
                    lastDate: DateTime.now(),
                    initialDateRange: _dateRange,
                  );
                  if (range != null) {
                    setState(() {
                      _dateRange = range;
                    });
                  }
                },
                child: Text('Select'),
              ),
              if (_dateRange != null)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _dateRange = null;
                    });
                  },
                  child: Text('Clear'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExportSection() {
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
              Icon(Icons.cloud_download, color: AppColors.primary, size: 24),
              SizedBox(width: 12),
              Text('Start Export', style: AppStyles.bodyBold),
            ],
          ),
          SizedBox(height: 16),
          
          if (_isExporting) ...[
            Column(
              children: [
                LinearProgressIndicator(
                  value: _exportProgress,
                  backgroundColor: AppColors.background,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
                SizedBox(height: 8),
                Text(
                  _exportStatus ?? '',
                  style: AppStyles.bodyRegular,
                ),
                SizedBox(height: 8),
                Text(
                  '${(_exportProgress * 100).round()}%',
                  style: AppStyles.bodyBold.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _startExport,
                icon: Icon(Icons.download),
                label: Text('Start Export'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                ),
              ),
            ),
          ],
          
          if (_exportResult != null) ...[
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _exportResult!.contains('failed') 
                    ? AppColors.alert.withOpacity(0.1)
                    : AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _exportResult!,
                style: AppStyles.bodyRegular.copyWith(
                  color: _exportResult!.contains('failed') 
                      ? AppColors.alert
                      : AppColors.success,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExportHistory() {
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
              Icon(Icons.history, color: AppColors.primary, size: 24),
              SizedBox(width: 12),
              Text('Export History', style: AppStyles.bodyBold),
            ],
          ),
          SizedBox(height: 16),
          
          if (_exportHistory.isEmpty) ...[
            Center(
              child: Text(
                'No export records',
                style: AppStyles.bodyRegular.copyWith(color: AppColors.textLight),
              ),
            ),
          ] else ...[
            ..._exportHistory.map((export) => _buildHistoryItem(export)),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> export) {
    final isCompleted = export['status'] == 'completed';
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.error,
            color: isCompleted ? AppColors.success : AppColors.alert,
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  export['type'],
                  style: AppStyles.bodyBold.copyWith(fontSize: 14),
                ),
                SizedBox(height: 2),
                Text(
                  '${export['format']} • ${export['size']}',
                  style: AppStyles.bodyRegular.copyWith(
                    color: AppColors.textLight,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  _formatDate(export['date']),
                  style: AppStyles.bodyRegular.copyWith(
                    color: AppColors.textLight,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (isCompleted)
            IconButton(
              icon: Icon(Icons.download, color: AppColors.primary, size: 20),
              onPressed: () {
                // TODO: Implement re-download
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Download feature under development...')),
                );
              },
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
} 
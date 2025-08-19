import 'package:flutter/material.dart';
import '../../../services/api.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';

class NutritionReportPage extends StatefulWidget {
  final int userId;
  const NutritionReportPage({Key? key, required this.userId}) : super(key: key);

  @override
  State<NutritionReportPage> createState() => _NutritionReportPageState();
}

class _NutritionReportPageState extends State<NutritionReportPage> {
  String _period = 'monthly';
  String _format = 'json';
  String _result = '';
  bool _loading = false;

  Future<void> _generate() async {
    setState(() => _loading = true);
    try {
      await generateNutritionReport(_period, _format);
      setState(() {
        _result = 'Nutrition report generated successfully!';
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _result = 'Generation failed: $e';
        _loading = false;
      });
    }
  }

  Future<void> generateNutritionReport(String period, String format) async {
    // Simulate report generation
    await Future.delayed(Duration(seconds: 3));
    
    // Here should call actual report generation API
    // final result = await ApiService.generateReport(period, format);
    
    print('Generating nutrition report - Period: $period, Format: $format');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Nutrition Report Generation',
          style: AppStyles.h2.copyWith(color: AppColors.white),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Report Period', style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              value: _period,
              items: [
                DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
              ],
              onChanged: (v) => setState(() => _period = v!),
            ),
            SizedBox(height: 16),
            Text('Report Format', style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              value: _format,
              items: [
                DropdownMenuItem(value: 'json', child: Text('JSON')),
                DropdownMenuItem(value: 'pdf', child: Text('PDF')),
              ],
              onChanged: (v) => setState(() => _format = v!),
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: _loading ? null : _generate,
              child: _loading ? CircularProgressIndicator() : Text('Generate Report'),
            ),
            if (_result != null) ...[
              SizedBox(height: 24),
              Text(_result!, style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            ]
          ],
        ),
      ),
    );
  }
} 
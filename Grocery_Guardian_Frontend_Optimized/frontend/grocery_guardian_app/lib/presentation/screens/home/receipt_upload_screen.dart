import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';
import '../../../domain/entities/product_analysis.dart';
import '../../../services/api_service.dart';
import '../../../services/user_service.dart';

class ReceiptUploadScreen extends StatefulWidget {
  @override
  State<ReceiptUploadScreen> createState() => _ReceiptUploadScreenState();
}

class _ReceiptUploadScreenState extends State<ReceiptUploadScreen> {
  ProductAnalysis? _currentAnalysis;
  List<Map<String, dynamic>> _receiptItems = [];
  bool _isLoading = false;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final id = await UserService.instance.getCurrentUserId();
    setState(() {
      _userId = id;
    });
  }

  Future<void> _uploadReceipt() async {
    if (_userId == null) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() {
      _isLoading = true;
      _receiptItems.clear();
      _currentAnalysis = null;
    });

    try {
      final result = await ApiService.uploadReceiptImage(picked, _userId!);
      final items = result['itemAnalyses'] ?? [];
      final llm = result['llmInsights'] ?? {};
      setState(() {
        _receiptItems = List<Map<String, dynamic>>.from(items);
        _currentAnalysis = ProductAnalysis(
          name: 'Receipt Summary',
          imageUrl: '',
          ingredients: [],
          detectedAllergens: [],
          summary: (llm['summary'] as String?)?.isNotEmpty == true
              ? llm['summary']
              : 'No summary provided by AI. The product seems acceptable based on available data.',
          detailedAnalysis: (llm['keyFindings'] is List && llm['keyFindings'].isNotEmpty)
              ? (llm['keyFindings'] as List).join('\n')
              : 'No key findings were detected from your receipt items.',
          actionSuggestions: (llm['improvementSuggestions'] is List && llm['improvementSuggestions'].isNotEmpty)
              ? List<String>.from(llm['improvementSuggestions'])
              : ['Try selecting more varied products for better AI suggestions.'],
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: AppColors.alert,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload Receipt', style: AppStyles.h2),
        backgroundColor: AppColors.primary,
      ),
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _uploadReceipt,
              icon: Icon(Icons.upload_file),
              label: Text('Select and Upload Receipt'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 12),
                  Text(
                    'Processing...',
                    style: AppStyles.bodyRegular.copyWith(color: AppColors.textLight),
                  ),
                ],
              ),
            )
          else
            Expanded(child: _buildAnalysisResult()),
        ],
      ),
    );
  }

  Widget _buildAnalysisResult() {
    if (_receiptItems.isNotEmpty) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionHeader('Purchased Items', Icons.shopping_cart),
          SizedBox(height: 16),
          ..._receiptItems.map((item) => _buildReceiptItem(item)),
          if (_currentAnalysis != null) ...[
            SizedBox(height: 24),
            _buildAIInsights(),
          ],
        ],
      );
    }
    if (_currentAnalysis == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: AppColors.textLight),
            SizedBox(height: 16),
            Text(
              'Upload a grocery receipt to get started',
              style: AppStyles.bodyRegular.copyWith(color: AppColors.textLight),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (_currentAnalysis!.summary.isNotEmpty ||
            _currentAnalysis!.detailedAnalysis.isNotEmpty ||
            _currentAnalysis!.actionSuggestions.isNotEmpty)
          _buildAIInsights(),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        SizedBox(width: 12),
        Text(title, style: AppStyles.h2),
      ],
    );
  }

  Widget _buildReceiptItem(Map<String, dynamic> item) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.shopping_basket, color: AppColors.primary, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] ?? 'Unknown Item',
                  style: AppStyles.bodyBold,
                ),
                SizedBox(height: 4),
                Text(
                  "Quantity: "+(item['quantity']?.toString() ?? '1'),
                  style: AppStyles.bodyRegular.copyWith(color: AppColors.textLight),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIInsights() {
    if (_currentAnalysis == null) return SizedBox.shrink();
    return Container(
      margin: EdgeInsets.only(top: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('AI Insights', style: AppStyles.h2),
          SizedBox(height: 12),
          if (_currentAnalysis!.summary.isNotEmpty) ...[
            Text('Summary:', style: AppStyles.bodyBold),
            SizedBox(height: 4),
            Text(_currentAnalysis!.summary, style: AppStyles.bodyRegular),
            SizedBox(height: 12),
          ],
          if (_currentAnalysis!.detailedAnalysis.isNotEmpty) ...[
            Text('Key Findings:', style: AppStyles.bodyBold),
            SizedBox(height: 4),
            Text(_currentAnalysis!.detailedAnalysis, style: AppStyles.bodyRegular),
            SizedBox(height: 12),
          ],
          if (_currentAnalysis!.actionSuggestions.isNotEmpty) ...[
            Text('Suggestions:', style: AppStyles.bodyBold),
            SizedBox(height: 4),
            ..._currentAnalysis!.actionSuggestions.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('- $s', style: AppStyles.bodyRegular),
            )),
          ],
        ],
      ),
    );
  }
} 
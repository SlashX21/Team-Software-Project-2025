import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';
import '../../../domain/entities/product_analysis.dart';
import '../../../services/api_service.dart';
import '../../../services/api.dart';
import '../../../services/user_service.dart';

class ReceiptUploadScreen extends StatefulWidget {
  final List<Map<String, dynamic>>? preloadedReceiptItems;
  final Map<String, dynamic>? preloadedRecommendationData;
  final XFile? preloadedImageFile;
  final bool isFromScanner;
  final String? errorMessage; // Add errorMessage parameter

  const ReceiptUploadScreen({
    Key? key,
    this.preloadedReceiptItems,
    this.preloadedRecommendationData,
    this.preloadedImageFile,
    this.isFromScanner = false,
    this.errorMessage,
  }) : super(key: key);
  
  @override
  State<ReceiptUploadScreen> createState() => _ReceiptUploadScreenState();
}

class _ReceiptUploadScreenState extends State<ReceiptUploadScreen> {
  List<Map<String, dynamic>> _receiptItems = [];
  Map<String, dynamic>? _recommendationData;
  bool _isLoading = false;
  int? _userId;
  File? _selectedImage;
  XFile? _selectedImageFile;
  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    _loadUserId();
    
    // 如果有预加载的数据，直接设置状态显示结果
    if (widget.preloadedReceiptItems != null) {
      _receiptItems = widget.preloadedReceiptItems!;
      _recommendationData = widget.preloadedRecommendationData;
      _selectedImageFile = widget.preloadedImageFile;
      _loadImageBytes();
    }
  }

  Future<void> _loadUserId() async {
    final id = await UserService.instance.getCurrentUserId();
    setState(() {
      _userId = id;
    });
  }

  void _previewUI() {
    print('🎯 Preview UI: Switching to analysis view...');
    setState(() {
      _receiptItems = [
        {'productName': 'Organic Bananas', 'quantity': 6},
        {'productName': 'Whole Milk 2L', 'quantity': 1},
        {'productName': 'Brown Bread', 'quantity': 2},
        {'productName': 'Greek Yogurt', 'quantity': 3},
        {'productName': 'Chicken Breast', 'quantity': 1},
      ];
      _recommendationData = null; // 这将显示智能占位符
      _isLoading = false;
    });
  }

  Future<void> _loadImageBytes() async {
    if (_selectedImageFile != null) {
      try {
        final bytes = await _selectedImageFile!.readAsBytes();
        setState(() {
          _imageBytes = bytes;
        });
      } catch (e) {
        print('Error loading image bytes: $e');
      }
    }
  }

  Future<void> _uploadReceipt() async {
    if (_userId == null) return;
    
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() {
      _isLoading = true;
      _receiptItems.clear();
      _recommendationData = null;
      _selectedImage = File(picked.path);
      _selectedImageFile = picked;
    });
    
    // Load image bytes for web compatibility
    await _loadImageBytes();

    try {
      print('🧾 Starting receipt processing...');
      
      // Step 1: OCR Processing
      final ocrResult = await ApiService().scanReceipt(picked);
      print('🔍 OCR Result: $ocrResult');
      
      List<Map<String, dynamic>> ocrItems = [];
      
      if (ocrResult == null || ocrResult['success'] != true) {
        print('⚠️ OCR processing failed, continuing with empty items');
        ocrItems = [];
      } else {
        // Extract items from OCR result
        final items = ocrResult['items'] as List? ?? [];
        if (items.isEmpty) {
          print('⚠️ No items detected in receipt');
          ocrItems = [];
        } else {
          ocrItems = items.cast<Map<String, dynamic>>();
        }
      }
      
      print('✅ OCR detected ${ocrItems.length} items');
      
      // Step 2: Prepare recommendation request
      List<Map<String, dynamic>> purchasedItems = ocrItems.map((item) => {
        'productName': item['name'] ?? item['productName'] ?? 'Unknown Item',
        'quantity': item['quantity'] ?? 1,
      }).toList();
      
      print('📦 Prepared items for recommendation: $purchasedItems');
      
      // Step 3: Call recommendation system (with graceful handling)
      try {
        print('🤖 Calling recommendation system...');
        final recommendationResult = await getReceiptAnalysis(
          userId: _userId!,
          purchasedItems: purchasedItems,
        );
        print('✅ Recommendation result: $recommendationResult');
        
        setState(() {
          _receiptItems = ocrItems.cast<Map<String, dynamic>>();
          _recommendationData = recommendationResult;
          _isLoading = false;
        });
      } catch (e) {
        print('⚠️ Recommendation API not ready: $e');
        // Set up UI framework with placeholder data
        setState(() {
          _receiptItems = ocrItems.cast<Map<String, dynamic>>();
          _recommendationData = null; // This will trigger placeholder UI
          _isLoading = false;
        });
      }
      
    } catch (e) {
      print('❌ Receipt processing error: $e');
      
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Receipt processing failed: ${e.toString()}'),
          backgroundColor: AppColors.alert,
          duration: Duration(seconds: 5),
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
          '🧾 Receipt Analysis',
          style: AppStyles.h2.copyWith(color: AppColors.white),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.white),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : widget.errorMessage != null && !widget.isFromScanner
              ? _buildErrorState(widget.errorMessage!)
              : _receiptItems.isEmpty
                  ? (widget.isFromScanner ? _buildAnalysisResult() : _buildUploadState())
                  : _buildAnalysisResult(),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: AppColors.alert, size: 64),
            SizedBox(height: 16),
            Text(
              'Analysis Failed',
              style: AppStyles.h3.copyWith(color: AppColors.alert),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              message,
              style: AppStyles.bodyRegular.copyWith(color: AppColors.textLight),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(Icons.arrow_back),
              label: Text('Go Back'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Receipt image preview if available
            if (_imageBytes != null) ...[
              Container(
                width: 200,
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    _imageBytes!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(height: 32),
            ] else if (_selectedImage != null && !kIsWeb) ...[
              // Fallback for non-web platforms
              Container(
                width: 200,
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _selectedImage!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(height: 32),
            ],
            
            // Loading indicator
            CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),
            SizedBox(height: 24),
            
            Text(
              'Processing Your Receipt',
              style: AppStyles.h3.copyWith(color: AppColors.primary),
            ),
            SizedBox(height: 12),
            
            Text(
              'Analyzing items and generating nutrition recommendations...',
              style: AppStyles.bodyRegular.copyWith(color: AppColors.textLight),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Upload icon with gradient background
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withOpacity(0.1),
                    AppColors.primary.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(60),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.receipt_long,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 32),
            
            Text(
              'Upload Your Receipt',
              style: AppStyles.h2.copyWith(color: AppColors.primary),
            ),
            SizedBox(height: 16),
            
            Text(
              'Get AI-powered nutrition analysis and personalized recommendations for your grocery purchases.',
              style: AppStyles.bodyRegular.copyWith(color: AppColors.textLight),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40),
            
            // Upload button
            Container(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _uploadReceipt,
                icon: Icon(Icons.camera_alt, size: 24),
                label: Text(
                  'Select Receipt Photo',
                  style: AppStyles.buttonText,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  shadowColor: AppColors.primary.withOpacity(0.3),
                ),
              ),
            ),
            SizedBox(height: 16),
            
            // Preview UI button (for testing)
            Container(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _previewUI,
                icon: Icon(Icons.preview, size: 20),
                label: Text(
                  'Preview UI Framework (Test)',
                  style: AppStyles.buttonText.copyWith(color: Colors.orange),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                  side: BorderSide(color: Colors.orange),
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            
            // Tips section
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.tips_and_updates, 
                           color: AppColors.primary, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Tips for Best Results',
                        style: AppStyles.bodyBold.copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  _buildTip('Ensure receipt is well-lit and clearly visible'),
                  _buildTip('Include the entire receipt in the photo'),
                  _buildTip('Avoid shadows and reflections'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline, 
               color: AppColors.success, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppStyles.bodySmall.copyWith(color: AppColors.textDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisResult() {
    return ListView(
      padding: EdgeInsets.all(20),
      children: [
        // Error notice if OCR failed but we're still showing the UI framework
        if (widget.errorMessage != null) ...[
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Processing Notice',
                        style: AppStyles.bodyBold.copyWith(color: Colors.orange),
                      ),
                      SizedBox(height: 4),
                      Text(
                        widget.errorMessage!,
                        style: AppStyles.bodySmall.copyWith(color: Colors.orange[700]),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'The UI framework below shows what the analysis would look like once the backend is ready.',
                        style: AppStyles.bodySmall.copyWith(
                          color: Colors.orange[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
        ],
        
        // Overall Nutrition Analysis Card
        _buildNutritionOverviewCard(),
        SizedBox(height: 20),
        
        // LLM Insights Card
        _buildLLMInsightsCard(),
        SizedBox(height: 20),
        
        // Receipt Items Section
        _buildReceiptItemsSection(),
        SizedBox(height: 20),
        
        // Item-by-Item Analysis
        _buildItemAnalysisSection(),
        SizedBox(height: 32),
        
        // Action buttons
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildNutritionOverviewCard() {
    final overallAnalysis = _recommendationData?['overallNutritionAnalysis'];
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Overall Nutrition Analysis',
                style: AppStyles.cardTitle,
              ),
            ],
          ),
          SizedBox(height: 16),
          
          if (overallAnalysis != null) ...[
            Row(
              children: [
                Expanded(
                  child: _buildNutritionMetric(
                    'Total Calories',
                    '${overallAnalysis['totalCalories'] ?? 0}',
                    'kcal',
                    Colors.orange,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildNutritionMetric(
                    'Total Protein',
                    '${overallAnalysis['totalProtein'] ?? 0}',
                    'g',
                    Colors.blue,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            _buildNutritionMetric(
              'Goal Match',
              '${overallAnalysis['goalMatchPercentage'] ?? 0}',
              '%',
              overallAnalysis['goalMatchPercentage'] >= 75 
                  ? AppColors.success 
                  : Colors.orange,
            ),
          ] else ...[
            _buildPlaceholderMetrics(),
          ],
        ],
      ),
    );
  }

  Widget _buildPlaceholderMetrics() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildPlaceholderMetric('Total Calories', 'Calculating...', Colors.orange),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildPlaceholderMetric('Total Protein', 'Calculating...', Colors.blue),
            ),
          ],
        ),
        SizedBox(height: 12),
        _buildPlaceholderMetric('Goal Match', 'Analyzing...', AppColors.primary),
      ],
    );
  }

  Widget _buildPlaceholderMetric(String label, String placeholder, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppStyles.bodyBold.copyWith(color: color),
          ),
          SizedBox(height: 4),
          Text(
            placeholder,
            style: AppStyles.bodySmall.copyWith(
              color: color.withOpacity(0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionMetric(String label, String value, String unit, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppStyles.bodyBold.copyWith(color: color),
          ),
          SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: AppStyles.h3.copyWith(color: color),
              ),
              SizedBox(width: 4),
              Text(
                unit,
                style: AppStyles.bodySmall.copyWith(color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLLMInsightsCard() {
    final llmInsights = _recommendationData?['llmInsights'];
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'AI Nutrition Insights',
                style: AppStyles.cardTitle,
              ),
            ],
          ),
          SizedBox(height: 16),
          
          if (llmInsights != null) ...[
            // Summary
            if (llmInsights['summary'] != null) ...[
              _buildInsightField(
                'Summary',
                llmInsights['summary'],
                Icons.summarize,
                Colors.blue,
              ),
              SizedBox(height: 16),
            ],
            
            // Key Findings
            if (llmInsights['keyFindings'] != null) ...[
              _buildInsightField(
                'Key Findings',
                llmInsights['keyFindings'] is List 
                    ? (llmInsights['keyFindings'] as List).join('\n• ')
                    : llmInsights['keyFindings'].toString(),
                Icons.search,
                Colors.indigo,
                isList: true,
              ),
              SizedBox(height: 16),
            ],
            
            // Improvement Suggestions
            if (llmInsights['improvementSuggestions'] != null) ...[
              _buildInsightField(
                'Improvement Suggestions',
                llmInsights['improvementSuggestions'] is List 
                    ? (llmInsights['improvementSuggestions'] as List).join('\n• ')
                    : llmInsights['improvementSuggestions'].toString(),
                Icons.lightbulb,
                Colors.orange,
                isList: true,
              ),
            ],
          ] else ...[
            _buildPlaceholderInsights(),
          ],
        ],
      ),
    );
  }

  Widget _buildPlaceholderInsights() {
    return Column(
      children: [
        _buildPlaceholderInsight('Summary', 'AI is analyzing your shopping patterns...', Icons.summarize, Colors.blue),
        SizedBox(height: 16),
        _buildPlaceholderInsight('Key Findings', 'Generating personalized insights...', Icons.search, Colors.indigo),
        SizedBox(height: 16),
        _buildPlaceholderInsight('Suggestions', 'Preparing improvement recommendations...', Icons.lightbulb, Colors.orange),
      ],
    );
  }

  Widget _buildPlaceholderInsight(String title, String placeholder, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              SizedBox(width: 6),
              Text(
                title,
                style: AppStyles.bodyBold.copyWith(color: color),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            placeholder,
            style: AppStyles.bodySmall.copyWith(
              color: color.withOpacity(0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightField(String title, String content, IconData icon, Color color, {bool isList = false}) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              SizedBox(width: 6),
              Text(
                title,
                style: AppStyles.bodyBold.copyWith(color: color),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            isList ? '• $content' : content,
            style: AppStyles.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptItemsSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Detected Items (${_receiptItems.length})',
                style: AppStyles.cardTitle,
              ),
            ],
          ),
          SizedBox(height: 16),
          
          ..._receiptItems.take(5).map((item) => _buildReceiptItem(item)),
          
          if (_receiptItems.length > 5) ...[
            SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: () => _showAllItems(),
                icon: Icon(Icons.expand_more, color: AppColors.primary),
                label: Text(
                  'Show ${_receiptItems.length - 5} more items',
                  style: AppStyles.bodySmall.copyWith(color: AppColors.primary),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReceiptItem(Map<String, dynamic> item) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.shopping_basket, color: AppColors.primary, size: 16),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['productName'] ?? item['name'] ?? 'Unknown Item',
                  style: AppStyles.bodyBold.copyWith(
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  'Qty: ${item['quantity'] ?? 1}',
                  style: AppStyles.bodySmall.copyWith(color: AppColors.textLight),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle, color: AppColors.success, size: 20),
        ],
      ),
    );
  }

  Widget _buildItemAnalysisSection() {
    final itemAnalyses = _recommendationData?['itemAnalyses'] as List?;
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.compare_arrows, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Alternative Recommendations',
                style: AppStyles.cardTitle,
              ),
            ],
          ),
          SizedBox(height: 16),
          
          if (itemAnalyses != null && itemAnalyses.isNotEmpty) ...[
            ...itemAnalyses.map((analysis) => _buildItemAnalysisCard(analysis)),
          ] else ...[
            _buildPlaceholderAlternatives(),
          ],
        ],
      ),
    );
  }

  Widget _buildPlaceholderAlternatives() {
    return Column(
      children: [
        ...List.generate(3, (index) => Container(
          margin: EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.shopping_bag_outlined, 
                     color: AppColors.primary, size: 20),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Analyzing item ${index + 1}...',
                      style: AppStyles.bodyBold.copyWith(color: AppColors.primary),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Finding healthier alternatives',
                      style: AppStyles.bodySmall.copyWith(
                        color: AppColors.textLight,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildItemAnalysisCard(Map<String, dynamic> analysis) {
    final originalItem = analysis['originalItem'];
    final alternatives = analysis['alternatives'] as List?;
    
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Original item
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.shopping_cart, color: Colors.grey[600], size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        originalItem['productName'] ?? 'Unknown Product',
                        style: AppStyles.bodyBold,
                      ),
                      Text(
                        'Quantity: ${originalItem['quantity'] ?? 1}',
                        style: AppStyles.bodySmall.copyWith(color: AppColors.textLight),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 12),
          
          // Arrow indicator
          Center(
            child: Icon(Icons.arrow_downward, color: AppColors.success, size: 20),
          ),
          
          SizedBox(height: 12),
          
          // Alternatives
          if (alternatives != null && alternatives.isNotEmpty) ...[
            Text(
              'Recommended Alternatives:',
              style: AppStyles.bodyBold.copyWith(color: AppColors.success),
            ),
            SizedBox(height: 8),
            ...alternatives.map((alt) => Container(
              margin: EdgeInsets.only(bottom: 8),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.success.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.recommend, color: AppColors.success, size: 16),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          alt['product']['productName'] ?? 'Recommended Product',
                          style: AppStyles.bodyBold.copyWith(color: AppColors.success),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    alt['reasoning'] ?? 'Better nutritional choice',
                    style: AppStyles.bodySmall,
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Upload new receipt button
        Container(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _receiptItems.clear();
                _recommendationData = null;
                _selectedImage = null;
              });
            },
            icon: Icon(Icons.refresh, size: 20),
            label: Text(
              'Analyze Another Receipt',
              style: AppStyles.buttonText,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              shadowColor: AppColors.primary.withOpacity(0.3),
            ),
          ),
        ),
        SizedBox(height: 12),
        
        // Back button
        Container(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back, size: 20),
            label: Text(
              'Back to Home',
              style: AppStyles.buttonText.copyWith(color: AppColors.primary),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary),
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showAllItems() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    'All Receipt Items (${_receiptItems.length})',
                    style: AppStyles.h3,
                  ),
                  Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 20),
                itemCount: _receiptItems.length,
                itemBuilder: (context, index) => _buildReceiptItem(_receiptItems[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
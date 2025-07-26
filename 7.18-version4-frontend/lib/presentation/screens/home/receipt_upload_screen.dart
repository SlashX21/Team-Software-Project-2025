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
import '../../../services/receipt_loading_states.dart';
import '../../widgets/receipt_progress_indicator.dart';
import '../recommendation/recommendation_detail_screen.dart';

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
  ReceiptLoadingState? _loadingState;
  String? _recommendationError;
  int? _userId;
  File? _selectedImage;
  XFile? _selectedImageFile;
  Uint8List? _imageBytes;
  ProductAnalysis? _analysisResult;

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

    // Stage 1: Receipt uploaded
    setState(() {
      _loadingState = ReceiptLoadingState.uploaded();
      _receiptItems.clear();
      _recommendationData = null;
      _recommendationError = null;
      _selectedImage = File(picked.path);
      _selectedImageFile = picked;
    });
    
    // Load image bytes for web compatibility
    await _loadImageBytes();

    try {
      print('🧾 Starting receipt processing...');
      
      // Stage 2: OCR Processing
      setState(() {
        _loadingState = ReceiptLoadingState.ocrProcessing();
      });
      
      final ocrResult = await ApiService().scanReceipt(picked);
      print('🔍 OCR Result: $ocrResult');
      
      List<Map<String, dynamic>> ocrItems = [];
      
      if (ocrResult == null) {
        print('❌ OCR service unavailable or failed');
        // Set error state and return early - don't try to continue
        setState(() {
          _loadingState = ReceiptLoadingState.error('OCR service is currently unavailable. Please try again later.');
        });
        
        // Show error for a moment, then reset
        await Future.delayed(Duration(seconds: 3));
        if (mounted) {
          setState(() {
            _loadingState = null;
          });
        }
        return;
      } else {
        // Extract items from OCR result - check both 'items' and 'products' fields
        final items = (ocrResult['items'] as List?) ?? (ocrResult['products'] as List?) ?? [];
        if (items.isEmpty) {
          print('⚠️ OCR completed but no items detected in receipt');
          // Still set error - don't show placeholder UI for empty results
          setState(() {
            _loadingState = ReceiptLoadingState.error('No items could be detected from this receipt. Please ensure the image is clear and contains product information.');
          });
          
          // Show error for a moment, then reset
          await Future.delayed(Duration(seconds: 3));
          if (mounted) {
            setState(() {
              _loadingState = null;
            });
          }
          return;
        } else {
          ocrItems = items.cast<Map<String, dynamic>>();
          print('✅ OCR extracted items: $ocrItems');
        }
      }
      
      print('✅ OCR detected ${ocrItems.length} items');
      
      // Stage 3: Analyzing items and generating recommendations
      setState(() {
        _loadingState = ReceiptLoadingState.analyzingItems();
      });
      
      // Prepare recommendation request
      List<Map<String, dynamic>> purchasedItems = ocrItems.map((item) => {
        'productName': item['name'] ?? item['productName'] ?? 'Unknown Item',
        'quantity': item['quantity'] ?? 1,
      }).toList();
      
      print('📦 Prepared items for recommendation: $purchasedItems');
      
      // Call recommendation system
      try {
        print('🤖 Calling recommendation system...');
        final recommendationResult = await getReceiptAnalysis(
          userId: _userId!,
          purchasedItems: purchasedItems,
        );
        print('✅ Recommendation result: $recommendationResult');
        
        // Stage 4: Analysis completed
        setState(() {
          _loadingState = ReceiptLoadingState.completed();
        });
        
        // Brief delay to show completion state
        await Future.delayed(Duration(milliseconds: 1000));
        
        // Show analysis results in current page instead of navigating away
        if (mounted) {
          setState(() {
            _receiptItems = ocrItems.cast<Map<String, dynamic>>();
            _recommendationData = recommendationResult;
            _recommendationError = null; // Clear any previous errors
            _loadingState = null; // Clear loading state to show results
          });
        }
        
      } catch (e) {
        print('⚠️ Recommendation API error: $e');
        
        // Set completion state first
        setState(() {
          _loadingState = ReceiptLoadingState.completed();
        });
        
        // Brief delay to show completion
        await Future.delayed(Duration(milliseconds: 500));
        
        // Show results with OCR data but recommendation failure notice
        if (mounted) {
          setState(() {
            _receiptItems = ocrItems.cast<Map<String, dynamic>>();
            _recommendationData = null;
            _loadingState = null;
            _recommendationError = 'OCR detected ${ocrItems.length} items successfully, but recommendation analysis is temporarily unavailable. Please try again later.';
          });
        }
      }
      
    } catch (e) {
      print('❌ Receipt processing error: $e');
      
      setState(() {
        _loadingState = ReceiptLoadingState.error('Receipt processing failed: ${e.toString()}');
      });
      
      // Show error for a moment, then reset
      await Future.delayed(Duration(seconds: 3));
      if (mounted) {
        setState(() {
          _loadingState = null;
        });
      }
    }
  }

  Future<void> _retryRecommendationAnalysis() async {
    if (_userId == null || _receiptItems.isEmpty) return;
    
    // Clear previous error
    setState(() {
      _recommendationError = null;
      _loadingState = ReceiptLoadingState.analyzingItems();
    });
    
    try {
      print('🔄 Retrying recommendation analysis...');
      
      // Prepare recommendation request
      List<Map<String, dynamic>> purchasedItems = _receiptItems.map((item) => {
        'productName': item['name'] ?? item['productName'] ?? 'Unknown Item',
        'quantity': item['quantity'] ?? 1,
      }).toList();
      
      print('📦 Retry: Prepared items for recommendation: $purchasedItems');
      
      // Call recommendation system
      final recommendationResult = await getReceiptAnalysis(
        userId: _userId!,
        purchasedItems: purchasedItems,
      );
      
      print('✅ Retry: Recommendation result: $recommendationResult');
      
      // Set completion state first
      setState(() {
        _loadingState = ReceiptLoadingState.completed();
      });
      
      // Brief delay to show completion
      await Future.delayed(Duration(milliseconds: 500));
      
      // Show analysis results
      if (mounted) {
        setState(() {
          _recommendationData = recommendationResult;
          _recommendationError = null; // Clear any previous errors
          _loadingState = null; // Clear loading state to show results
        });
      }
      
    } catch (e) {
      print('⚠️ Retry failed: $e');
      
      // Set completion state first
      setState(() {
        _loadingState = ReceiptLoadingState.completed();
      });
      
      // Brief delay to show completion
      await Future.delayed(Duration(milliseconds: 500));
      
      // Update error message
      if (mounted) {
        setState(() {
          _loadingState = null;
          _recommendationError = 'Retry failed: Recommendation system is still unavailable. Please try again later or contact support.';
        });
      }
    }
  }

  /// 判断是否有真实的OCR数据可以显示
  bool _hasRealData() {
    // Only show analysis UI if we have actual OCR items detected
    return _receiptItems.isNotEmpty || widget.preloadedReceiptItems != null;
  }

  /// 判断是否已经处理过小票（无论是否检测到商品）
  bool _hasProcessedReceipt() {
    // 只有当有真实数据时才显示分析界面
    return _hasRealData();
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
      body: _loadingState != null
          ? _buildLoadingState()
          : widget.errorMessage != null && !widget.isFromScanner
              ? _buildErrorState(widget.errorMessage!)
              : _hasProcessedReceipt()
                  ? _buildAnalysisResult()
                  : _buildUploadState(),
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
    if (_loadingState == null) return SizedBox.shrink();
    
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: ReceiptProgressIndicator(
          currentStage: _loadingState!.stage,
          progress: _loadingState!.progress,
          message: _loadingState!.message,
          secondaryMessage: _loadingState!.secondaryMessage,
          receiptImage: _buildReceiptImagePreview(),
          onCancel: () {
            setState(() {
              _loadingState = null;
              _receiptItems.clear();
              _recommendationData = null;
            });
          },
        ),
      ),
    );
  }

  Widget? _buildReceiptImagePreview() {
    if (_imageBytes != null) {
      return Container(
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
      );
    } else if (_selectedImage != null && !kIsWeb) {
      return Container(
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
      );
    }
    return null;
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
    final hasRecommendationError = _recommendationError != null;
    
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
                'Nutrition Analysis',
                style: AppStyles.cardTitle,
              ),
              if (hasRecommendationError) ...[
                SizedBox(width: 8),
                Icon(Icons.warning_amber, color: Colors.orange, size: 16),
              ],
            ],
          ),
          SizedBox(height: 16),
          
          // Show recommendation error if it exists
          if (hasRecommendationError) ...[
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Analysis Status',
                        style: AppStyles.bodyBold.copyWith(color: Colors.orange),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    _recommendationError!,
                    style: AppStyles.bodySmall.copyWith(color: Colors.orange[700]),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Items detected: ${_receiptItems.length}',
                    style: AppStyles.bodySmall.copyWith(
                      color: AppColors.textLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
          ],
          
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
            // Don't show placeholder metrics - show message that analysis requires recommendation data
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey, size: 24),
                  SizedBox(height: 8),
                  Text(
                    'Nutrition Analysis Unavailable',
                    style: AppStyles.bodyBold.copyWith(color: Colors.grey),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Detailed nutrition analysis requires the recommendation system to be operational.',
                    style: AppStyles.bodySmall.copyWith(color: AppColors.textLight),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
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
    // Show different messages based on whether there's a recommendation error
    final hasRecommendationError = _recommendationError != null;
    
    if (hasRecommendationError) {
      return Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(Icons.info_outline, color: Colors.orange, size: 24),
            SizedBox(height: 8),
            Text(
              'AI Analysis Unavailable',
              style: AppStyles.bodyBold.copyWith(color: Colors.orange),
            ),
            SizedBox(height: 4),
            Text(
              'AI-powered nutrition insights are temporarily unavailable. Your detected items are still shown below.',
              style: AppStyles.bodySmall.copyWith(color: AppColors.textLight),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    // Don't show fake "analyzing" messages - show clear unavailable message
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.psychology_outlined, color: Colors.grey, size: 24),
          SizedBox(height: 8),
          Text(
            'AI Insights Unavailable',
            style: AppStyles.bodyBold.copyWith(color: Colors.grey),
          ),
          SizedBox(height: 4),
          Text(
            'AI-powered nutrition insights require the recommendation system to be operational.',
            style: AppStyles.bodySmall.copyWith(color: AppColors.textLight),
            textAlign: TextAlign.center,
          ),
        ],
      ),
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
          
          if (_receiptItems.isEmpty) ...[
            // 没有检测到商品的情况
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 24),
                  SizedBox(height: 8),
                  Text(
                    'No Items Detected',
                    style: AppStyles.bodyBold.copyWith(color: Colors.orange),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'We could not detect any items from your receipt. This could be due to image quality or receipt format. You can try uploading a clearer image.',
                    style: AppStyles.bodySmall.copyWith(color: AppColors.textLight),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ] else ...[
            // 有检测到商品的情况
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
            // Don't show placeholder alternatives - show clear message
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Icon(Icons.compare_arrows_outlined, color: Colors.grey, size: 24),
                  SizedBox(height: 8),
                  Text(
                    'Alternative Recommendations Unavailable',
                    style: AppStyles.bodyBold.copyWith(color: Colors.grey),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Product alternatives require the recommendation system to be operational.',
                    style: AppStyles.bodySmall.copyWith(color: AppColors.textLight),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
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
    final hasRecommendationError = _recommendationError != null;
    
    return Column(
      children: [
        // Retry recommendation button (only show if there's an error)
        if (hasRecommendationError) ...[
          Container(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _retryRecommendationAnalysis(),
              icon: Icon(Icons.replay, size: 20),
              label: Text(
                'Retry Recommendation Analysis',
                style: AppStyles.buttonText,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: AppColors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                shadowColor: Colors.orange.withOpacity(0.3),
              ),
            ),
          ),
          SizedBox(height: 12),
        ],
        
        // Upload new receipt button
        Container(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _receiptItems.clear();
                _recommendationData = null;
                _recommendationError = null;
                _selectedImage = null;
                _selectedImageFile = null;
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
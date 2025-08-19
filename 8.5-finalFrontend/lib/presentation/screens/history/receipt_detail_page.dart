import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';
import '../../../domain/entities/receipt_detail.dart';
import '../../../domain/entities/purchased_item.dart';
import '../../../domain/entities/recommendation_group.dart';
import '../../../domain/entities/alternative_product.dart';
import '../../../services/receipt_history_service.dart';
import 'dart:convert';

class ReceiptDetailPage extends StatefulWidget {
  final int receiptId;

  const ReceiptDetailPage({Key? key, required this.receiptId}) : super(key: key);

  @override
  _ReceiptDetailPageState createState() => _ReceiptDetailPageState();
}

class _ReceiptDetailPageState extends State<ReceiptDetailPage> {
  ReceiptDetail? receiptDetail;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadReceiptDetail();
  }

  Future<void> _loadReceiptDetail() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Use real API call
      final receiptHistoryService = ReceiptHistoryService();
      final detail = await receiptHistoryService.getReceiptDetails(widget.receiptId);
      
      setState(() {
        receiptDetail = detail;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load receipt details: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Receipt Details',
          style: AppStyles.h2.copyWith(color: AppColors.white),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: AppColors.background,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'Loading receipt details...',
              style: TextStyle(
                color: AppColors.textLight,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return _buildErrorWidget();
    }

    if (receiptDetail == null) {
      return _buildEmptyWidget();
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildReceiptHeader(),
          SizedBox(height: 24),
          _buildPurchasedItemsSection(),
          SizedBox(height: 24),
          _buildLLMAnalysisSection(),
          if (receiptDetail!.areRecommendationsAvailable) ...[
            SizedBox(height: 24),
            _buildRecommendationsSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildReceiptHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withOpacity(0.1), AppColors.primary.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'Receipt uploaded at ${receiptDetail!.formattedScanTime}',
          style: TextStyle(
            color: AppColors.textLight,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildPurchasedItemsSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section with improved design
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal.withOpacity(0.1), Colors.teal.withOpacity(0.05)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.shopping_basket,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Purchased Items',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.teal,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${receiptDetail!.purchasedItems.length} items',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            
            // Items list
            ...receiptDetail!.purchasedItems.map((item) => 
              PurchasedItemCard(item: item)
            ).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildLLMAnalysisSection() {
    if (!receiptDetail!.isAnalysisAvailable) {
      return Container(
        padding: EdgeInsets.all(16),
        margin: EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.psychology,
                  color: AppColors.primary,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'AI Receipt Analysis',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Icon(
              Icons.info_outline,
              color: Colors.grey[600],
              size: 20,
            ),
            SizedBox(height: 8),
            Text(
              'No analysis available',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    // Parse the LLM summary to extract structured data
    Map<String, dynamic>? analysisData = _parseAnalysisData();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary Section
        _buildAnalysisCard(
          title: 'Shopping Analysis Summary',
          content: analysisData?['summary'] ?? receiptDetail!.llmSummary,
          icon: Icons.analytics_outlined,
          color: AppColors.primary,
        ),
        
        SizedBox(height: 12),
        
        // Detailed Analysis Section (for new format)
        if (analysisData?['detailedAnalysis'] != null) ...[
          _buildAnalysisCard(
            title: 'Nutrition & Health Analysis',
            content: analysisData!['detailedAnalysis'],
            icon: Icons.health_and_safety_outlined,
            color: Colors.teal,
          ),
          SizedBox(height: 12),
        ],
        
        // Key Findings Section (for old format)
        if (analysisData?['keyFindings'] != null && analysisData!['keyFindings'] is List && (analysisData!['keyFindings'] as List).isNotEmpty) ...[
          _buildAnalysisCard(
            title: 'Key Findings',
            content: (analysisData!['keyFindings'] as List).join('\n• '),
            icon: Icons.insights_outlined,
            color: Colors.blue,
          ),
          SizedBox(height: 12),
        ],
        
        // Action Suggestions Section (for new format)
        if (analysisData?['actionSuggestions'] != null) ...[
          _buildActionSuggestionsCard(
            title: 'Action Suggestions',
            suggestions: analysisData!['actionSuggestions'] as List<dynamic>,
          ),
        ],
        
        // Improvement Suggestions Section (for old format)
        if (analysisData?['improvementSuggestions'] != null) ...[
          _buildActionSuggestionsCard(
            title: 'Improvement Suggestions',
            suggestions: analysisData!['improvementSuggestions'] as List<dynamic>,
          ),
        ],
      ],
    );
  }
  
  Map<String, dynamic>? _parseAnalysisData() {
    try {
      String rawSummary = receiptDetail!.llmSummary.trim();
      
      // First try to parse as direct JSON object
      if (rawSummary.startsWith('{')) {
        try {
          Map<String, dynamic> jsonData = jsonDecode(rawSummary);
          print('✅ Successfully parsed LLM summary as JSON: $jsonData');
          return jsonData;
        } catch (e) {
          print('❌ Failed to parse as direct JSON: $e');
        }
      }
      
      // Check if it's a JSON string embedded within other text
      RegExp jsonRegex = RegExp(r'\{[^{}]*\"summary\"[^{}]*\}');
      Match? jsonMatch = jsonRegex.firstMatch(rawSummary);
      
      if (jsonMatch != null) {
        try {
          String jsonString = jsonMatch.group(0)!;
          Map<String, dynamic> jsonData = jsonDecode(jsonString);
          print('✅ Successfully extracted and parsed embedded JSON: $jsonData');
          return jsonData;
        } catch (e) {
          print('❌ Failed to parse embedded JSON: $e');
        }
      }
      
      // Try to extract structured JSON using regex patterns
      Map<String, dynamic> extractedData = {};
      
      // Extract summary
      RegExp summaryRegex = RegExp(r'\"summary\"\s*:\s*\"([^\"]+)\"');
      Match? summaryMatch = summaryRegex.firstMatch(rawSummary);
      if (summaryMatch != null) {
        extractedData['summary'] = summaryMatch.group(1)!;
      }
      
      // Extract detailedAnalysis
      RegExp detailRegex = RegExp(r'\"detailedAnalysis\"\s*:\s*\"([^\"]+)\"');
      Match? detailMatch = detailRegex.firstMatch(rawSummary);
      if (detailMatch != null) {
        extractedData['detailedAnalysis'] = detailMatch.group(1)!;
      }
      
      // Extract actionSuggestions array
      RegExp suggestionRegex = RegExp(r'\"actionSuggestions\"\s*:\s*\[(.*?)\]', dotAll: true);
      Match? suggestionMatch = suggestionRegex.firstMatch(rawSummary);
      if (suggestionMatch != null) {
        String suggestionsString = suggestionMatch.group(1)!;
        List<String> suggestions = [];
        
        RegExp itemRegex = RegExp(r'\"([^\"]+)\"');
        Iterable<Match> itemMatches = itemRegex.allMatches(suggestionsString);
        
        for (Match itemMatch in itemMatches) {
          suggestions.add(itemMatch.group(1)!);
        }
        
        if (suggestions.isNotEmpty) {
          extractedData['actionSuggestions'] = suggestions;
        }
      }
      
      if (extractedData.isNotEmpty) {
        print('✅ Successfully extracted structured data: $extractedData');
        return extractedData;
      }
      
      // Fallback to simple text parsing
      print('⚠️ Falling back to simple text parsing');
      return {'summary': rawSummary};
      
    } catch (e) {
      print('❌ Error parsing analysis data: $e');
      return {'summary': receiptDetail!.llmSummary};
    }
  }
  
  Widget _buildAnalysisCard({
    required String title,
    required String content,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
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
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionSuggestionsCard({
    required String title,
    required List<dynamic> suggestions,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
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
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.lightbulb_outline, color: Colors.orange, size: 20),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ...suggestions.asMap().entries.map((entry) {
            int index = entry.key;
            String suggestion = entry.value.toString();
            return Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      suggestion,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...receiptDetail!.recommendationsList.map((group) => 
          RecommendationGroupCard(group: group)
        ).toList(),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.alert,
            ),
            SizedBox(height: 16),
            Text(
              'Error Loading Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: 8),
            Text(
              errorMessage ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textLight,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadReceiptDetail,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_outlined,
              size: 64,
              color: AppColors.textLight,
            ),
            SizedBox(height: 16),
            Text(
              'Receipt Not Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'This receipt may have been deleted or does not exist.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textLight,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PurchasedItemCard extends StatelessWidget {
  final PurchasedItem item;

  const PurchasedItemCard({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.shopping_basket,
                color: Colors.white,
                size: 24,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                item.productName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.teal.withOpacity(0.3)),
              ),
              child: Text(
                'x${item.quantity}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RecommendationGroupCard extends StatelessWidget {
  final RecommendationGroup group;

  const RecommendationGroupCard({Key? key, required this.group}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section with improved design
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary.withOpacity(0.1), AppColors.primary.withOpacity(0.05)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.lightbulb,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      group.originalItem.productName == 'Shopping Receipt' 
                        ? 'Smart Product Recommendations'
                        : 'Alternatives for ${group.originalItem.productName}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${group.alternatives.length} items',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            
            // Alternatives list
            ...group.alternatives.map((alternative) => 
              AlternativeProductCard(alternative: alternative)
            ).toList(),
          ],
        ),
      ),
    );
  }
}

class AlternativeProductCard extends StatefulWidget {
  final AlternativeProduct alternative;

  const AlternativeProductCard({Key? key, required this.alternative}) : super(key: key);

  @override
  _AlternativeProductCardState createState() => _AlternativeProductCardState();
}

class _AlternativeProductCardState extends State<AlternativeProductCard> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 6),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
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
          // Product header with rank and clickable product name
          InkWell(
            onTap: () {
              setState(() {
                isExpanded = !isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: EdgeInsets.all(8),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.shopping_bag,
                      color: AppColors.success,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.alternative.product.productName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
          
          // Expandable content
          if (isExpanded) ...[
            SizedBox(height: 8),
            
            // Score display
            if (widget.alternative.recommendationScore > 0) ...[
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, size: 16, color: Colors.green),
                    SizedBox(width: 4),
                    Text(
                      'Recommendation Score: ${widget.alternative.formattedScore}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
            ],
            
            // Brand and category info
            if (widget.alternative.product.brand.isNotEmpty || widget.alternative.product.category.isNotEmpty) ...[
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  [
                    if (widget.alternative.product.brand.isNotEmpty) widget.alternative.product.brand,
                    if (widget.alternative.product.category.isNotEmpty) widget.alternative.product.category,
                  ].join(' • '),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(height: 12),
            ],
            
            // Nutrition information with improved design
            if (widget.alternative.product.energyKcal100g != null || 
                widget.alternative.product.proteins100g != null ||
                widget.alternative.product.sugars100g != null) ...[
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal.withOpacity(0.05), Colors.teal.withOpacity(0.1)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.teal.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    if (widget.alternative.product.energyKcal100g != null) 
                      _buildNutritionInfo('Calories', '${widget.alternative.product.energyKcal100g!.toStringAsFixed(0)}', Icons.local_fire_department, Colors.red),
                    if (widget.alternative.product.proteins100g != null) 
                      _buildNutritionInfo('Protein', '${widget.alternative.product.proteins100g!.toStringAsFixed(1)}g', Icons.fitness_center, Colors.blue),
                    if (widget.alternative.product.sugars100g != null) 
                      _buildNutritionInfo('Sugar', '${widget.alternative.product.sugars100g!.toStringAsFixed(1)}g', Icons.cake, Colors.orange),
                  ],
                ),
              ),
              SizedBox(height: 12),
            ],
            
            // Reasoning with markdown support and improved styling
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildReasoningContent(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  /// Build recommendation content - render Markdown properly, based on the reference implementation.
  Widget _buildReasoningContent() {
    String content = widget.alternative.reasoning;
    
    // Check if content contains Markdown formatting
    bool hasMarkdown = content.contains('###') || 
                      content.contains('**') || 
                      content.contains('- ') ||
                      content.contains('💪') ||
                      content.contains('🌟') ||
                      content.contains('⚡') ||
                      content.contains('💡');
    
    if (hasMarkdown) {
      // Use MarkdownBody for Markdown content
      return MarkdownBody(
        data: content,
        shrinkWrap: true,
        styleSheet: MarkdownStyleSheet(
          h3: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
            height: 1.3,
          ),
          strong: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
            fontSize: 13,
          ),
          p: TextStyle(
            fontSize: 13,
            height: 1.4,
            color: AppColors.textDark,
          ),
          listBullet: TextStyle(
            fontSize: 13,
            color: AppColors.primary,
            height: 1.3,
          ),
        ),
      );
    } else {
      // Use Text widget for plain content
      return Text(
        content,
        style: TextStyle(
          color: AppColors.textDark,
          height: 1.5,
          fontSize: 14,
        ),
      );
    }
  }
  
  Widget _buildNutritionInfo(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: AppColors.textLight,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';
import '../../theme/screen_adapter.dart';
import '../../theme/responsive_layout.dart';
import '../../widgets/adaptive_widgets.dart';

class ReceiptRecommendationScreen extends StatefulWidget {
  final List<Map<String, dynamic>> receiptItems;
  final Map<String, dynamic>? recommendationData;
  final String? errorMessage;

  const ReceiptRecommendationScreen({
    Key? key,
    required this.receiptItems,
    this.recommendationData,
    this.errorMessage,
  }) : super(key: key);

  @override
  State<ReceiptRecommendationScreen> createState() => _ReceiptRecommendationScreenState();
}

class _ReceiptRecommendationScreenState extends State<ReceiptRecommendationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Receipt Analysis',
          style: AppStyles.h2.copyWith(color: AppColors.white),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.white),
      ),
      body: widget.errorMessage != null 
          ? _buildErrorState()
          : _buildAnalysisResult(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              size: 64,
              color: AppColors.primary,
            ),
            SizedBox(height: 24),
            Text(
              'Receipt Analysis Coming Soon!',
              style: AppStyles.h2.copyWith(color: AppColors.primary),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              'The receipt analysis feature is currently under development. We\'re working hard to bring you intelligent shopping recommendations based on your receipts.',
              style: AppStyles.bodyRegular.copyWith(color: AppColors.textLight),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            _buildBackButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisResult() {
    return ListView(
      padding: EdgeInsets.all(20),
      children: [
        // 整体营养分析卡片
        _buildNutritionOverviewCard(),
        SizedBox(height: 20),
        
        // LLM洞察卡片
        _buildLLMInsightsCard(),
        SizedBox(height: 20),
        
        // 商品逐项分析
        _buildItemAnalysisSection(),
        SizedBox(height: 24),
        
        // 返回按钮
        _buildBackButton(),
      ],
    );
  }

  Widget _buildNutritionOverviewCard() {
    final overallAnalysis = widget.recommendationData?['overallNutritionAnalysis'];
    
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
            // Use IntrinsicHeight to ensure consistent card heights
            IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: _buildNutritionMetric(
                      'Total Calories',
                      '${overallAnalysis['totalCalories'] ?? 0}',
                      'kcal',
                      Colors.orange,
                    ),
                  ),
                  AdaptiveSpacing.horizontal(12),
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
            ),
            AdaptiveSpacing.vertical(12),
            _buildNutritionMetric(
              'Goal Match',
              '${overallAnalysis['goalMatchPercentage'] ?? 0}',
              '%',
              overallAnalysis['goalMatchPercentage'] >= 75 
                  ? AppColors.success 
                  : Colors.orange,
            ),
          ] else ...[
            Text(
              'Nutrition analysis will be available once the backend is ready.',
              style: AppStyles.bodyRegular.copyWith(
                color: AppColors.textLight,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNutritionMetric(String label, String value, String unit, Color color) {
    return AdaptiveCard(
      padding: EdgeInsets.all(12.r),
      margin: EdgeInsets.zero,
      color: color.withOpacity(0.1),
      border: Border.all(color: color.withOpacity(0.3)),
      useResponsiveSpacing: false,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: AdaptiveText(
              text: label,
              style: AppStyles.bodyBold.copyWith(color: color),
              useResponsiveFontSize: true,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            mainAxisSize: MainAxisSize.min,
            children: [
              AdaptiveText(
                text: value,
                style: AppStyles.h3.copyWith(color: color),
                useResponsiveFontSize: true,
              ),
              AdaptiveSpacing.horizontal(4),
              AdaptiveText(
                text: unit,
                style: AppStyles.bodySmall.copyWith(color: color),
                useResponsiveFontSize: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLLMInsightsCard() {
    final llmInsights = widget.recommendationData?['llmInsights'];
    
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
                'AI Insights',
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
            Text(
              'AI insights will be generated once the recommendation system is active.',
              style: AppStyles.bodyRegular.copyWith(
                color: AppColors.textLight,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
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

  Widget _buildItemAnalysisSection() {
    final itemAnalyses = widget.recommendationData?['itemAnalyses'] as List?;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.list_alt, color: AppColors.primary, size: 20),
            SizedBox(width: 8),
            Text(
              'Item-by-Item Analysis',
              style: AppStyles.cardTitle,
            ),
          ],
        ),
        SizedBox(height: 16),
        
        if (itemAnalyses != null && itemAnalyses.isNotEmpty) ...[
          ...itemAnalyses.map((analysis) => _buildItemAnalysisCard(analysis)),
        ] else ...[
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.receipt_long,
                  size: 48,
                  color: AppColors.primary.withOpacity(0.5),
                ),
                SizedBox(height: 12),
                Text(
                  'Receipt Items Detected',
                  style: AppStyles.bodyBold.copyWith(color: AppColors.primary),
                ),
                SizedBox(height: 8),
                Text(
                  'We successfully processed your receipt and detected ${widget.receiptItems.length} items. Individual recommendations will be available once our analysis system is complete.',
                  style: AppStyles.bodyRegular.copyWith(color: AppColors.textLight),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                
                // 显示识别到的商品
                ...widget.receiptItems.map((item) => Container(
                  margin: EdgeInsets.only(bottom: 8),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, 
                           color: AppColors.success, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${item['productName'] ?? item['name'] ?? 'Unknown Item'} (${item['quantity'] ?? 1}x)',
                          style: AppStyles.bodySmall,
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildItemAnalysisCard(Map<String, dynamic> analysis) {
    final originalItem = analysis['originalItem'];
    final alternatives = analysis['alternatives'] as List?;
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
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
          // 原始商品
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
          
          // 替代品
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
                  Text(
                    alt['product']['productName'] ?? 'Recommended Product',
                    style: AppStyles.bodyBold.copyWith(color: AppColors.success),
                  ),
                  SizedBox(height: 4),
                  Text(
                    alt['reasoning'] ?? 'Better nutritional choice',
                    style: AppStyles.bodySmall,
                  ),
                ],
              ),
            )),
          ] else ...[
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Alternatives analysis pending backend completion',
                style: AppStyles.bodySmall.copyWith(
                  color: Colors.orange[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return Container(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.pop(context),
        icon: Icon(Icons.arrow_back, size: 20),
        label: Text(
          'Back to Scanner',
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
    );
  }
}
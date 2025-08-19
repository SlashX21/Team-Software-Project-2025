import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';
import '../../../domain/entities/scan_history_item.dart';
import '../../../domain/entities/scan_history_product_detail.dart';
import '../../../services/api.dart';
import '../../../services/user_service.dart';
import '../../widgets/ingredients_display.dart';
import '../../../domain/entities/product_analysis.dart';

class ScanHistoryDetailPage extends StatefulWidget {
  final ScanHistoryItem scanHistoryItem;

  const ScanHistoryDetailPage({
    Key? key,
    required this.scanHistoryItem,
  }) : super(key: key);

  @override
  _ScanHistoryDetailPageState createState() => _ScanHistoryDetailPageState();
}

class _ScanHistoryDetailPageState extends State<ScanHistoryDetailPage> {
  ScanHistoryProductDetail? _productDetail;
  bool _isLoading = true;
  String? _error;
  Map<int, bool> _expandedRecommendations = {};

  @override
  void initState() {
    super.initState();
    _loadProductDetail();
  }

  Future<void> _loadProductDetail() async {
    setState(() {
      _isLoading = true;
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

      final detail = await getScanHistoryProductDetails(
        scanId: widget.scanHistoryItem.scanId,
        userId: userId,
      );
      
      if (detail != null) {
        setState(() {
          _productDetail = detail;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Unable to load product details';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Load failed: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Details', style: AppStyles.h2.copyWith(color: AppColors.white)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: BackButton(color: AppColors.white),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _error != null
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 16),
          Text(
            'Loading product details...',
            style: AppStyles.bodyRegular.copyWith(color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.alert),
          SizedBox(height: 16),
          Text(
            'Load failed',
            style: AppStyles.h2.copyWith(color: AppColors.alert),
          ),
          SizedBox(height: 8),
          Text(
            _error!,
            style: AppStyles.bodyRegular.copyWith(color: AppColors.textLight),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadProductDetail,
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

  Widget _buildContent() {
    if (_productDetail == null) return SizedBox();

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProductHeader(),
          SizedBox(height: 16),
          _buildAllergensSection(),
          SizedBox(height: 16),
          _buildIngredientsSection(),
          SizedBox(height: 16),
          _buildAIAnalysisSection(),
          SizedBox(height: 16),
          _buildRecommendationsSection(),
        ],
      ),
    );
  }

  Widget _buildProductHeader() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _productDetail!.productInfo.name,
            style: AppStyles.h2,
          ),
          SizedBox(height: 8),
          Text(
            'Scanned on: ${_formatFullDate(_productDetail!.scannedAt)}',
            style: AppStyles.bodyRegular.copyWith(color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  Widget _buildAllergensSection() {
    final allergens = _productDetail!.productInfo.allergens;
    
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
                child: Icon(
                  Icons.warning,
                  color: Colors.orange,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Allergens',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          if (allergens.isNotEmpty) ...[
            _buildSmartAllergenLayout(allergens),
          ] else ...[
            Text(
              'No known allergens',
              style: AppStyles.bodyRegular.copyWith(color: AppColors.textLight),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建智能allergen布局：优化空间利用
  Widget _buildSmartAllergenLayout(List<String> allergens) {
    List<Widget> rows = [];
    
    // 先分类：长文本和短文本
    List<String> longAllergens = [];
    List<String> shortAllergens = [];
    
    for (String allergen in allergens) {
      if (allergen.length > 20) {
        longAllergens.add(allergen);
      } else {
        shortAllergens.add(allergen);
      }
    }
    
    // 重新排列：优先填满短文本的双列，然后穿插长文本
    List<Widget> layoutRows = _createOptimizedLayout(longAllergens, shortAllergens);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: layoutRows,
    );
  }

  /// 创建优化的布局
  List<Widget> _createOptimizedLayout(List<String> longAllergens, List<String> shortAllergens) {
    List<Widget> rows = [];
    int shortIndex = 0;
    int longIndex = 0;
    
    // 先尽可能多地创建短文本的双列行
    while (shortIndex + 1 < shortAllergens.length) {
      rows.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildAllergenItem(shortAllergens[shortIndex])),
          SizedBox(width: 12),
          Expanded(child: _buildAllergenItem(shortAllergens[shortIndex + 1])),
        ],
      ));
      rows.add(SizedBox(height: 4));
      shortIndex += 2;
    }
    
    // 处理剩余的一个短文本（如果有的话）
    if (shortIndex < shortAllergens.length) {
      // 如果还有长文本要显示，可以考虑把这个短文本放在后面
      // 但现在先简单处理：独占一行
      rows.add(_buildFullWidthAllergenItem(shortAllergens[shortIndex]));
      if (longIndex < longAllergens.length) {
        rows.add(SizedBox(height: 4));
      }
    }
    
    // 添加所有长文本
    while (longIndex < longAllergens.length) {
      rows.add(_buildFullWidthAllergenItem(longAllergens[longIndex]));
      longIndex++;
      if (longIndex < longAllergens.length) {
        rows.add(SizedBox(height: 4));
      }
    }
    
    return rows;
  }

  /// 构建单个allergen项（用于双列）
  Widget _buildAllergenItem(String allergen) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text('• ', style: AppStyles.bodyRegular),
          Expanded(
            child: Text(
              allergen, 
              style: AppStyles.bodyRegular,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建全宽allergen项（用于独占一行）
  Widget _buildFullWidthAllergenItem(String allergen) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text('• ', style: AppStyles.bodyRegular),
          Expanded(
            child: Text(
              allergen, 
              style: AppStyles.bodyRegular,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsSection() {
    final ingredients = _productDetail!.productInfo.ingredients;
    
    return IngredientsDisplay(
      ingredients: _parseIngredientsString(ingredients),
      title: "Ingredients",
      maxDisplayCount: 10,
      padding: EdgeInsets.all(16),
    );
  }
  
  /// 使用与ProductAnalysis相同的解析方法来保持一致性
  List<String>? _parseIngredientsString(String? ingredientsText) {
    // 直接使用ProductAnalysis中的静态解析方法
    // 这确保了与扫描后显示页面完全相同的解析逻辑
    return ProductAnalysis.parseIngredientsFromString(ingredientsText);
  }

  Widget _buildAIAnalysisSection() {
    final aiAnalysis = _productDetail!.aiAnalysis;
    
    return Container(
      padding: EdgeInsets.all(20),
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with soft green background
          Container(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Color(0xFF4CAF50),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.psychology,
                  color: Colors.white,
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  'AI Nutrition Analysis',
                  style: AppStyles.bodyBold.copyWith(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          
          // Summary Section
          _buildAnalysisSubSection(
            icon: Icons.summarize,
            iconColor: Color(0xFF4CAF50),
            title: 'Summary',
            content: aiAnalysis.summary.trim().isNotEmpty
                ? aiAnalysis.summary
                : 'No summary available',
            isEmpty: aiAnalysis.summary.trim().isEmpty,
          ),
          
          SizedBox(height: 16),
          
          // Detailed Analysis Section
          _buildAnalysisSubSection(
            icon: Icons.analytics,
            iconColor: Color(0xFF2196F3),
            title: 'Detailed Analysis',
            content: aiAnalysis.detailedAnalysis.trim().isNotEmpty
                ? aiAnalysis.detailedAnalysis
                : 'No detailed analysis available',
            isEmpty: aiAnalysis.detailedAnalysis.trim().isEmpty,
          ),
          
          SizedBox(height: 16),
          
          // Action Suggestions Section
          _buildActionSuggestionsSubSection(aiAnalysis.actionSuggestions),
        ],
      ),
    );
  }

  Widget _buildAnalysisSubSection({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
    required bool isEmpty,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: iconColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 18,
                ),
              ),
              SizedBox(width: 12),
              Text(
                title,
                style: AppStyles.bodyBold.copyWith(
                  color: iconColor,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isEmpty ? AppColors.background : iconColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isEmpty ? AppColors.textLight.withOpacity(0.3) : iconColor.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Text(
              content,
              style: AppStyles.bodyRegular.copyWith(
                height: 1.6,
                color: isEmpty ? AppColors.textLight : AppColors.textDark,
                fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionSuggestionsSubSection(List<String> suggestions) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(0xFFFF9800).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Color(0xFFFF9800).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.lightbulb_outline,
                  color: Color(0xFFFF9800),
                  size: 18,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Action Suggestions',
                style: AppStyles.bodyBold.copyWith(
                  color: Color(0xFFFF9800),
                  fontSize: 15,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: suggestions.isNotEmpty 
                  ? Color(0xFFFF9800).withOpacity(0.05)
                  : AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: suggestions.isNotEmpty 
                    ? Color(0xFFFF9800).withOpacity(0.1)
                    : AppColors.textLight.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: suggestions.isNotEmpty
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: suggestions.map((suggestion) => Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: EdgeInsets.only(top: 6),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Color(0xFFFF9800),
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              suggestion,
                              style: AppStyles.bodyRegular.copyWith(
                                height: 1.5,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
                  )
                : Text(
                    'No action suggestions available',
                    style: AppStyles.bodyRegular.copyWith(
                      color: AppColors.textLight,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    final recommendations = _productDetail!.recommendations;

    return Container(
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
                      'Recommended Alternatives',
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
                      '${recommendations.length} items',
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
            
            // Recommendations list - following recommendation_detail_screen design
            if (recommendations.isNotEmpty) ...[
              ...recommendations.asMap().entries.map((entry) {
                int index = entry.key;
                var recommendation = entry.value;
                bool isExpanded = _expandedRecommendations[index] ?? false;
                
                return Container(
                  margin: EdgeInsets.only(bottom: 12),
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
                      // Product header (always visible) - similar to recommendation_detail_screen
                      Row(
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
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  recommendation.product.name,
                                  style: AppStyles.bodyBold.copyWith(
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Expand/collapse button
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _expandedRecommendations[index] = !isExpanded;
                              });
                            },
                            icon: Icon(
                              isExpanded ? Icons.expand_less : Icons.expand_more,
                              color: AppColors.primary,
                              size: 24,
                            ),
                            tooltip: isExpanded ? 'Collapse Details' : 'Expand Details',
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      
                      // Barcode or recommendation label (always visible)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: recommendation.product.barcode != null && recommendation.product.barcode!.isNotEmpty
                              ? AppColors.primary
                              : AppColors.success,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          recommendation.product.barcode != null && recommendation.product.barcode!.isNotEmpty
                              ? recommendation.product.barcode!
                              : 'Recommended',
                          style: AppStyles.statusLabel.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                      ),
                      
                      // Expandable content with animation - following recommendation_detail_screen pattern
                      AnimatedCrossFade(
                        duration: Duration(milliseconds: 300),
                        crossFadeState: isExpanded 
                            ? CrossFadeState.showSecond 
                            : CrossFadeState.showFirst,
                        firstChild: SizedBox.shrink(),
                        secondChild: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 12),
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: _buildRecommendationContent(recommendation),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ] else ...[
              Text(
                'No recommendations available for this product',
                style: AppStyles.bodyRegular.copyWith(color: AppColors.textLight),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatFullDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
  
  /// Build recommendation content - render Markdown properly
  Widget _buildRecommendationContent(RecommendationItem recommendation) {
    String content = recommendation.reasoning;
    
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
        styleSheet: MarkdownStyleSheet(
          h3: AppStyles.bodyBold.copyWith(
            fontSize: 14,
            color: AppColors.primary,
            height: 1.3,
          ),
          strong: AppStyles.bodyBold.copyWith(
            color: AppColors.textDark,
            fontSize: 13,
          ),
          p: AppStyles.bodyRegular.copyWith(
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
        style: AppStyles.bodyRegular.copyWith(
          color: AppColors.textDark,
          height: 1.5,
          fontSize: 14,
        ),
      );
    }
  }
}
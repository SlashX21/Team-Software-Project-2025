import 'package:flutter/material.dart';
import '../../../domain/entities/product_analysis.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';
import '../../../services/api.dart';
import '../../../services/user_service.dart';

class RecommendationDetailScreen extends StatefulWidget {
  final ProductAnalysis productAnalysis;
  
  const RecommendationDetailScreen({
    Key? key,
    required this.productAnalysis,
  }) : super(key: key);

  @override
  State<RecommendationDetailScreen> createState() => _RecommendationDetailScreenState();
}

class _RecommendationDetailScreenState extends State<RecommendationDetailScreen> {
  List<String> userAllergens = [];
  bool isLoadingAllergens = true;

  @override
  void initState() {
    super.initState();
    _loadUserAllergens();
  }

  Future<void> _loadUserAllergens() async {
    try {
      final userId = await UserService.instance.getCurrentUserId();
      if (userId != null) {
        final allergenData = await getUserAllergens(userId);
        if (allergenData != null) {
          setState(() {
            userAllergens = allergenData.map((allergen) => allergen['name']?.toString() ?? '').where((name) => name.isNotEmpty).toList();
            isLoadingAllergens = false;
          });
        } else {
          setState(() {
            isLoadingAllergens = false;
          });
        }
      } else {
        setState(() {
          isLoadingAllergens = false;
        });
      }
    } catch (e) {
      print('Error loading user allergens: $e');
      setState(() {
        isLoadingAllergens = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          '📊 ${widget.productAnalysis.name}',
          style: AppStyles.h2.copyWith(color: AppColors.white),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.white),
      ),
      body: ListView(
        padding: EdgeInsets.all(20),
        children: [
          _buildDetailedAnalysis(),
          SizedBox(height: 24),
          _buildRecommendations(),
          SizedBox(height: 24),
          _buildBackButton(context),
        ],
      ),
    );
  }

  Widget _buildDetailedAnalysis() {
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
                "Nutritional Breakdown", // 修复：改变卡片标题避免重复
                style: AppStyles.cardTitle, // 使用新的卡片标题样式
              ),
              ],
            ),
            SizedBox(height: 16),
            
          // Display analysis content
          _buildAnalysisContent(),
          
          // Add allergen warnings if the user has a match
          if (userAllergens.isNotEmpty) ...[
            SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _buildAllergenWarnings(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnalysisContent() {
    final detailedAnalysis = widget.productAnalysis.detailedAnalysis;
    final actionSuggestions = widget.productAnalysis.actionSuggestions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section 2: Product Analysis (修复标题重复问题)
        _buildDetailAnalysisField(
          icon: Icons.analytics,
          title: 'Product Analysis', // 修复：改变字段标题避免重复
          content: detailedAnalysis,
          color: Colors.indigo,
          fieldKey: 'detailedAnalysis',
        ),
        SizedBox(height: 20),
        
        // Section 3: Action Suggestions (应用新字体系统)
        if (actionSuggestions.isNotEmpty) ...[
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.orange, size: 20),
              SizedBox(width: 8),
            Text(
                'Action Suggestions',
                style: AppStyles.cardTitle.copyWith( // 使用新的卡片标题样式
                  color: Colors.orange, // 保持橙色主题
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ...actionSuggestions.map((suggestion) => 
            Container(
              margin: EdgeInsets.only(bottom: 8),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Colors.orange,
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      suggestion,
                      style: AppStyles.bodySmall, // 使用新的字体系统
                    ),
                  ),
                ],
              ),
            ),
          ).toList(),
        ],
      ],
    );
  }

  /// 构建详情页面的分析字段 - 应用新字体系统
  Widget _buildDetailAnalysisField({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
    required String fieldKey,
    bool isList = false,
    List<String>? listItems,
  }) {
    // 判断字段状态
    bool hasContent = content.isNotEmpty;
    bool isMeaningful = hasContent && content.length > 5 && content != 'null';

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isMeaningful ? color.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 字段标题和状态
          Row(
            children: [
              Icon(
                icon, 
                color: isMeaningful ? color : Colors.grey, 
                size: 18
              ),
              SizedBox(width: 6),
              Text(
                title,
                style: AppStyles.bodyBold.copyWith(
                  color: isMeaningful ? color : Colors.grey.shade600,
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getFieldStatusColor(isMeaningful, hasContent).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getFieldStatusIcon(isMeaningful, hasContent),
                      size: 12,
                      color: _getFieldStatusColor(isMeaningful, hasContent),
                    ),
                    SizedBox(width: 4),
                    Text(
                      _getFieldStatusText(isMeaningful, hasContent),
                      style: AppStyles.statusLabel.copyWith( // 使用新的状态标签样式
                        color: _getFieldStatusColor(isMeaningful, hasContent),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          
          // 字段内容
          if (isMeaningful) ...[
            if (isList && listItems != null && listItems.isNotEmpty) ...[
              ...listItems.map((item) => 
                Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.arrow_right, color: color, size: 16),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item,
                          style: AppStyles.bodySmall, // 使用新字体系统
                        ),
                      ),
          ],
        ),
                ),
              ).toList(),
            ] else ...[
              Text(
                content,
                style: AppStyles.bodySmall, // 使用新字体系统
              ),
            ],
          ] else ...[
            Text(
              hasContent ? 'Placeholder content: "$content"' : 'No data available',
              style: AppStyles.caption.copyWith( // 使用新字体系统
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          
          // 原始数据长度信息（调试用）
          SizedBox(height: 4),
          Text(
            'Field: $fieldKey | Length: ${content.length} chars',
            style: AppStyles.caption.copyWith( // 使用新字体系统
              color: Colors.grey.shade500,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
  
  /// 字段状态辅助方法
  Color _getFieldStatusColor(bool isMeaningful, bool hasContent) {
    if (isMeaningful) return AppColors.success;
    if (hasContent) return Colors.orange;
    return AppColors.textLight;
  }

  IconData _getFieldStatusIcon(bool isMeaningful, bool hasContent) {
    if (isMeaningful) return Icons.check_circle;
    if (hasContent) return Icons.warning;
    return Icons.help_outline;
  }

  String _getFieldStatusText(bool isMeaningful, bool hasContent) {
    if (isMeaningful) return 'DATA';
    if (hasContent) return 'RAW';
    return 'EMPTY';
  }

  Widget _buildRecommendations() {
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
              Icon(Icons.shopping_cart, color: AppColors.primary, size: 20),
                SizedBox(width: 8),
              Text(
                "Alternative Products",
                style: AppStyles.cardTitle, // 使用统一的卡片标题样式
              ),
              ],
            ),
          SizedBox(height: 16),
            
          // 显示替代商品建议
          _buildAlternativeProducts(),
        ],
      ),
    );
  }

  Widget _buildAlternativeProducts() {
    final recommendations = widget.productAnalysis.recommendations;

    if (recommendations.isEmpty) {
      return Text("No alternative products available.", style: AppStyles.bodyRegular);
    }

    return Column(
      children: recommendations.map((product) {
        // 确定标签显示内容：优先显示条码
        bool hasBarcode = product.barcode != null && product.barcode!.isNotEmpty;
        String labelText = hasBarcode ? product.barcode! : 'Recommended';
        Color labelColor = hasBarcode ? AppColors.primary : AppColors.success;
        
        return Container(
          margin: EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white, // 修复：改为白色背景
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
                          product.name,
                          style: AppStyles.bodyBold.copyWith(
                            color: AppColors.textDark, // 修复：改为深色文字
                          ),
                        ),
                        Text(
                          "Recommended Alternative",
                          style: AppStyles.bodySmall.copyWith( // 使用新字体系统
                            color: AppColors.textLight, // 修复：改为中性色
                        ),
                      ),
                    ],
                  ),
                ),
                ],
              ),
              SizedBox(height: 12),
              // 优化：显示条码（如果有）或推荐标签
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: labelColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                      child: Text(
                  labelText, // 修复：显示完整条码
                  style: AppStyles.statusLabel.copyWith( // 使用新字体系统
                    color: AppColors.white,
                  ),
                ),
              ),
              SizedBox(height: 8),
              Text(
                _buildDetailedRecommendationReason(product),
                style: AppStyles.bodySmall.copyWith( // 使用新字体系统
                  color: AppColors.textLight, // 修复：改为中性色
                      ),
                    ),
                  ],
                ),
        );
      }).toList(),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Container(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.pop(context),
        icon: Icon(Icons.arrow_back, size: 20),
        label: Text(
          "Back to Scan",
          style: AppStyles.buttonText, // 使用统一的按钮文字样式
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16), // 统一padding
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          shadowColor: AppColors.primary.withOpacity(0.3),
        ),
      ),
    );
  }

  /// 构建详细的推荐理由 - 为详情页面提供更丰富的推荐信息
  String _buildDetailedRecommendationReason(ProductAnalysis product) {
    // 优先使用后端提供的详细推荐理由 - 使用detailedAnalysis而不是detailedSummary
    if (product.detailedAnalysis.isNotEmpty) {
      return product.detailedAnalysis;
    }
    
    // 回退到基于简短理由的增强版本
    String baseReason = product.summary.isNotEmpty ? 
      product.summary : 
      "This product offers better nutritional value for your dietary goals.";
    
    // 如果基础理由过短，添加更多详细信息
    if (baseReason.length < 50) {
      return "$baseReason This alternative has been selected based on your personal nutrition preferences and dietary requirements, offering a healthier option that aligns with your wellness goals.";
    }
    
    // 如果基础理由已经足够详细，直接返回
    return baseReason;
  }

  List<Widget> _buildAllergenWarnings() {
    final productAllergens = widget.productAnalysis.detectedAllergens;
    final matchingAllergens = productAllergens.where((allergen) => 
      userAllergens.any((userAllergen) => 
        allergen.toLowerCase().contains(userAllergen.toLowerCase()) ||
        userAllergen.toLowerCase().contains(allergen.toLowerCase())
      )
    ).toList();

    if (matchingAllergens.isEmpty) {
      return [];
    }

    return [
      Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.alert.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.alert.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: AppColors.alert, size: 20),
            SizedBox(width: 8),
                Text(
                  'Allergen Alert',
                  style: AppStyles.bodyBold.copyWith(color: AppColors.alert),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'This product contains ingredients you are allergic to:',
              style: AppStyles.bodyRegular,
            ),
            SizedBox(height: 8),
            Text(
              matchingAllergens.join(', '),
              style: AppStyles.bodyRegular.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.alert.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    ];
  }
}

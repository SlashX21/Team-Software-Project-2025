import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';
import '../../../domain/entities/scan_history_item.dart';
import '../../../domain/entities/scan_history_product_detail.dart';
import '../../../services/api.dart';
import '../../../services/user_service.dart';

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

      print('🔍 Loading product detail for scanId ${widget.scanHistoryItem.scanId}');
      final detail = await getScanHistoryProductDetails(
        scanId: widget.scanHistoryItem.scanId,
        userId: userId,
      );
      
      if (detail != null) {
        setState(() {
          _productDetail = detail;
          _isLoading = false;
        });
        print('✅ Product detail loaded successfully');
      } else {
        setState(() {
          _error = 'Unable to load product details';
          _isLoading = false;
        });
        print('❌ Product detail API returned null');
      }
    } catch (e) {
      setState(() {
        _error = 'Load failed: $e';
        _isLoading = false;
      });
      print('❌ Error loading product detail: $e');
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
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
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
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning,
                color: Color(0xFFFF9800),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Allergens',
                style: AppStyles.bodyBold,
              ),
            ],
          ),
          SizedBox(height: 16),
          if (allergens.isNotEmpty) ...[
            ...allergens.map((allergen) => Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Text('• ', style: AppStyles.bodyRegular),
                  Text(allergen, style: AppStyles.bodyRegular),
                ],
              ),
            )).toList(),
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

  Widget _buildIngredientsSection() {
    final ingredients = _productDetail!.productInfo.ingredients;
    
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.science,
                color: Color(0xFF2196F3),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Ingredients',
                style: AppStyles.bodyBold,
              ),
            ],
          ),
          SizedBox(height: 16),
          if (ingredients != null && ingredients.isNotEmpty) ...[
            Text(
              ingredients,
              style: AppStyles.bodyRegular.copyWith(height: 1.5),
            ),
          ] else ...[
            Text(
              'No ingredients information available',
              style: AppStyles.bodyRegular.copyWith(color: AppColors.textLight),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAIAnalysisSection() {
    final aiAnalysis = _productDetail!.aiAnalysis;
    
    
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 2,
            offset: Offset(0, 1),
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
                color: Color(0xFF9C27B0),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'AI Nutrition Analysis',
                style: AppStyles.bodyBold,
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            'Summary:',
            style: AppStyles.bodyBold,
          ),
          SizedBox(height: 8),
          if (aiAnalysis.summary.trim().isNotEmpty) ...[
            Text(
              aiAnalysis.summary,
              style: AppStyles.bodyRegular.copyWith(height: 1.5),
            ),
          ] else ...[
            Text(
              'No summary available',
              style: AppStyles.bodyRegular.copyWith(
                color: AppColors.textLight,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          SizedBox(height: 12),
          Text(
            'Detailed Analysis:',
            style: AppStyles.bodyBold,
          ),
          SizedBox(height: 8),
          if (aiAnalysis.detailedAnalysis.trim().isNotEmpty) ...[
            Text(
              aiAnalysis.detailedAnalysis,
              style: AppStyles.bodyRegular.copyWith(height: 1.5),
            ),
          ] else ...[
            Text(
              'No detailed analysis available',
              style: AppStyles.bodyRegular.copyWith(
                color: AppColors.textLight,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          SizedBox(height: 12),
          Text(
            'Action Suggestions:',
            style: AppStyles.bodyBold,
          ),
          SizedBox(height: 8),
          if (aiAnalysis.actionSuggestions.isNotEmpty) ...[
            ...aiAnalysis.actionSuggestions.map((suggestion) => Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: AppStyles.bodyRegular),
                  Expanded(
                    child: Text(suggestion, style: AppStyles.bodyRegular),
                  ),
                ],
              ),
            )).toList(),
          ] else ...[
            Text(
              'No action suggestions available',
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

  Widget _buildRecommendationsSection() {
    final recommendations = _productDetail!.recommendations;

    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb,
                color: Color(0xFF4CAF50),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Recommended Alternatives',
                style: AppStyles.bodyBold,
              ),
            ],
          ),
          SizedBox(height: 16),
          if (recommendations.isNotEmpty) ...[
            ...recommendations.map((recommendation) => Container(
              margin: EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '#${recommendation.rank}',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          recommendation.product.name,
                          style: AppStyles.bodyBold,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Score: ${(recommendation.recommendationScore * 100).toStringAsFixed(0)}%',
                    style: AppStyles.bodyRegular.copyWith(color: AppColors.primary),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Nutrition Improvements:',
                    style: AppStyles.bodyBold,
                  ),
                  SizedBox(height: 4),
                  if (recommendation.nutritionImprovement != null) ...[
                    Text(
                      '• Protein: ${recommendation.nutritionImprovement!.proteinIncrease}\n'
                      '• Sugar: ${recommendation.nutritionImprovement!.sugarReduction}\n'
                      '• Calories: ${recommendation.nutritionImprovement!.calorieChange}',
                      style: AppStyles.bodyRegular.copyWith(height: 1.5),
                    ),
                  ] else ...[
                    Text(
                      'Nutrition improvement data not available',
                      style: AppStyles.bodyRegular.copyWith(
                        color: AppColors.textLight,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  SizedBox(height: 8),
                  Text(
                    'Reason: ${recommendation.reasoning}',
                    style: AppStyles.bodyRegular.copyWith(
                      color: AppColors.textLight,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            )).toList(),
          ] else ...[
            Text(
              'No recommendations available for this product',
              style: AppStyles.bodyRegular.copyWith(color: AppColors.textLight),
            ),
          ],
        ],
      ),
    );
  }

  String _formatFullDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
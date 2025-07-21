import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';
import '../../../domain/entities/history_response.dart';
import '../../../domain/entities/history_detail.dart';
import '../../../services/api.dart';
import '../../../services/user_service.dart';
import '../../../services/receipt_history_service.dart';

class HistoryDetailPage extends StatefulWidget {
  final HistoryItem historyItem;

  const HistoryDetailPage({
    Key? key,
    required this.historyItem,
  }) : super(key: key);

  @override
  _HistoryDetailPageState createState() => _HistoryDetailPageState();
}

class _HistoryDetailPageState extends State<HistoryDetailPage> {
  HistoryDetail? _historyDetail;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistoryDetail();
  }

  Future<void> _loadHistoryDetail() async {
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

      HistoryDetail? detail;
      
      if (widget.historyItem.scanType == 'scan') {
        // Load scan history details
        final scanDetail = await getScanHistoryProductDetails(
          scanId: int.parse(widget.historyItem.id),
          userId: userId,
        );
        if (scanDetail != null) {
          // Convert ScanHistoryProductDetail to HistoryDetail
          detail = HistoryDetail(
            id: widget.historyItem.id,
            scanType: 'scan',
            createdAt: widget.historyItem.createdAt,
            productName: scanDetail.productInfo.name,
            productImage: widget.historyItem.productImage,
            barcode: widget.historyItem.barcode,
            recommendationCount: scanDetail.recommendations.length,
            summary: widget.historyItem.summary,
            fullAnalysis: {
              'summary': scanDetail.aiAnalysis.summary,
              'detailedAnalysis': scanDetail.aiAnalysis.detailedAnalysis,
              'actionSuggestions': scanDetail.aiAnalysis.actionSuggestions,
            },
            recommendations: scanDetail.recommendations.map((rec) => {
              'rank': rec.rank,
              'product': {
                'barCode': rec.product.barcode ?? '',
                'productName': rec.product.name,
                'brand': rec.product.brand ?? '',
                'category': rec.product.category ?? '',
              },
              'recommendationScore': rec.recommendationScore,
              'reasoning': rec.reasoning,
              'title': rec.product.name, // Add title for display
              'brand': rec.product.brand ?? '', // Add brand for display
              'score': (rec.recommendationScore * 100).toStringAsFixed(0), // Add score for display
              'description': rec.reasoning, // Add description for display
            }).toList(),
            nutritionData: {
              'allergens': scanDetail.productInfo.allergens,
              'ingredients': scanDetail.productInfo.ingredients ?? '',
            },
          );
        }
      } else if (widget.historyItem.scanType == 'receipt') {
        // Load receipt history details
        final receiptDetail = await ReceiptHistoryService().getReceiptDetails(
          int.parse(widget.historyItem.id),
        );
        
        // Convert ReceiptDetail to HistoryDetail
        // Use the first purchased item name if the original productName is generic
        String displayName = widget.historyItem.productName;
        if (displayName == 'Receipt Upload' || displayName == 'Receipt Items' || displayName.toLowerCase().contains('receipt')) {
          if (receiptDetail.purchasedItems.isNotEmpty) {
            if (receiptDetail.purchasedItems.length == 1) {
              displayName = receiptDetail.purchasedItems.first.productName;
            } else {
              displayName = '${receiptDetail.purchasedItems.first.productName} +${receiptDetail.purchasedItems.length - 1} more';
            }
          }
        }
        
        detail = HistoryDetail(
          id: widget.historyItem.id,
          scanType: 'receipt',
          createdAt: widget.historyItem.createdAt,
          productName: displayName,
          productImage: widget.historyItem.productImage,
          barcode: widget.historyItem.barcode,
          recommendationCount: receiptDetail.recommendationsList.length,
          summary: widget.historyItem.summary,
          fullAnalysis: {
            'summary': receiptDetail.llmSummary,
            'detailedAnalysis': '', // Receipt history doesn't have detailed analysis
            'actionSuggestions': [], // Receipt history doesn't have action suggestions
          },
          recommendations: receiptDetail.recommendationsList.expand((rec) =>
            rec.alternatives.map((alt) => {
              'rank': alt.rank,
              'product': {
                'barCode': alt.product.barCode,
                'productName': alt.product.productName,
                'brand': alt.product.brand,
                'category': alt.product.category,
              },
              'recommendationScore': alt.recommendationScore,
              'reasoning': alt.reasoning,
            })
          ).toList(),
          nutritionData: {
            'purchasedItems': receiptDetail.purchasedItems.map((item) => {
              'productName': item.productName,
              'quantity': item.quantity,
            }).toList(),
          },
        );
      }

      if (detail != null) {
        setState(() {
          _historyDetail = detail;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Unable to load history details';
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
          ? Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.alert),
          SizedBox(height: 16),
          Text(_error!, style: AppStyles.bodyRegular),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadHistoryDetail,
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_historyDetail == null) return SizedBox();

    final isReceiptHistory = _historyDetail!.scanType == 'receipt';

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProductHeader(),
          SizedBox(height: 16),
          // 只有扫描历史才显示过敏原和成分信息
          if (!isReceiptHistory) ...[
            _buildAllergensSection(),
            SizedBox(height: 16),
            _buildIngredientsSection(),
            SizedBox(height: 16),
          ],
          // 对于小票历史，显示购买商品列表
          if (isReceiptHistory) ...[
            _buildPurchasedItemsSection(),
            SizedBox(height: 16),
          ],
          _buildAIAnalysisSection(),
          SizedBox(height: 16),
          _buildRecommendationsSection(),
        ],
      ),
    );
  }

  Widget _buildPurchasedItemsSection() {
    final purchasedItems = _historyDetail!.nutritionData['purchasedItems'] as List?;
    
    return Container(
      padding: EdgeInsets.all(20),
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
              Icon(
                Icons.shopping_bag,
                color: AppColors.primary,
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                'Purchased Items',
                style: AppStyles.bodyBold.copyWith(fontSize: 18),
              ),
            ],
          ),
          SizedBox(height: 16),
          if (purchasedItems != null && purchasedItems.isNotEmpty) ...[
            ...purchasedItems.map((item) => Container(
              margin: EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.shopping_cart_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['productName']?.toString() ?? 'Unknown Product',
                          style: AppStyles.bodyBold,
                        ),
                        Text(
                          'Qty: ${item['quantity']?.toString() ?? '1'}',
                          style: AppStyles.bodyRegular.copyWith(
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )).toList(),
          ] else ...[
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.textLight,
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No purchased items information available',
                      style: AppStyles.bodyRegular.copyWith(
                        color: AppColors.textLight,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
            _historyDetail!.productName,
            style: AppStyles.h2,
          ),
          SizedBox(height: 8),
          Text(
            'Scanned on: ${_formatFullDate(_historyDetail!.createdAt)}',
            style: AppStyles.bodyRegular.copyWith(color: AppColors.textLight),
          ),
        ],
      ),
    );
  }


  Widget _buildAllergensSection() {
    final allergens = _historyDetail!.nutritionData['allergens'] as List?;
    
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
          if (allergens != null && allergens.isNotEmpty) ...[
            ...allergens.map((allergen) => Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Text('• ', style: AppStyles.bodyRegular),
                  Text(allergen.toString(), style: AppStyles.bodyRegular),
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
    final ingredients = _historyDetail!.nutritionData['ingredients'] as String?;
    
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
    final summary = _historyDetail!.fullAnalysis['summary'] as String?;
    final detailedAnalysis = _historyDetail!.fullAnalysis['detailedAnalysis'] as String?;
    final actionSuggestions = _historyDetail!.fullAnalysis['actionSuggestions'] as List?;
    final isReceiptHistory = _historyDetail!.scanType == 'receipt';
    
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
                isReceiptHistory ? 'AI Receipt Analysis' : 'AI Nutrition Analysis',
                style: AppStyles.bodyBold,
              ),
            ],
          ),
          SizedBox(height: 16),
          if (summary != null && summary.trim().isNotEmpty) ...[
            Text(
              isReceiptHistory ? 'Analysis Summary:' : 'Summary:',
              style: AppStyles.bodyBold,
            ),
            SizedBox(height: 8),
            Text(
              summary,
              style: AppStyles.bodyRegular.copyWith(height: 1.5),
            ),
            SizedBox(height: 12),
          ],
          if (detailedAnalysis != null && detailedAnalysis.trim().isNotEmpty) ...[
            Text(
              'Detailed Analysis:',
              style: AppStyles.bodyBold,
            ),
            SizedBox(height: 8),
            Text(
              detailedAnalysis,
              style: AppStyles.bodyRegular.copyWith(height: 1.5),
            ),
            SizedBox(height: 12),
          ],
          if (actionSuggestions != null && actionSuggestions.isNotEmpty) ...[
            Text(
              'Action Suggestions:',
              style: AppStyles.bodyBold,
            ),
            SizedBox(height: 8),
            ...actionSuggestions.map((suggestion) => Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: AppStyles.bodyRegular),
                  Expanded(
                    child: Text(suggestion.toString(), style: AppStyles.bodyRegular),
                  ),
                ],
              ),
            )).toList(),
          ],
          if ((summary == null || summary.trim().isEmpty) && 
              (detailedAnalysis == null || detailedAnalysis.trim().isEmpty) && 
              (actionSuggestions == null || actionSuggestions.isEmpty)) ...[
            Text(
              isReceiptHistory 
                  ? 'No AI analysis available for this receipt'
                  : 'No AI analysis available for this product',
              style: AppStyles.bodyRegular.copyWith(color: AppColors.textLight),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    final recommendations = _historyDetail!.recommendations;
    final isReceiptHistory = _historyDetail!.scanType == 'receipt';

    return Container(
      padding: EdgeInsets.all(20),
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
              Icon(
                Icons.recommend,
                color: Colors.green,
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                isReceiptHistory ? 'Alternative Products' : 'Smart Recommendations',
                style: AppStyles.h2,
              ),
              Spacer(),
              if (recommendations.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${recommendations.length} found',
                    style: AppStyles.bodyRegular.copyWith(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
                border: Border.all(color: Colors.green.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Rank badge
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            '#${recommendation['rank']?.toString() ?? '1'}',
                            style: AppStyles.bodyBold.copyWith(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      // Product name and details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              recommendation['title']?.toString() ?? 
                              recommendation['product']?['productName']?.toString() ?? 
                              'Unknown Product',
                              style: AppStyles.bodyBold,
                            ),
                            if (recommendation['brand']?.toString().isNotEmpty == true ||
                                recommendation['product']?['brand']?.toString().isNotEmpty == true)
                              Text(
                                recommendation['brand']?.toString() ?? 
                                recommendation['product']?['brand']?.toString() ?? '',
                                style: AppStyles.bodyRegular.copyWith(
                                  color: AppColors.textLight,
                                ),
                              ),
                            SizedBox(height: 2),
                            // Barcode display if available
                            if (recommendation['product']?['barCode']?.toString().isNotEmpty == true)
                              Row(
                                children: [
                                  Icon(Icons.qr_code, size: 14, color: AppColors.textLight),
                                  SizedBox(width: 4),
                                  Text(
                                    recommendation['product']['barCode'].toString(),
                                    style: AppStyles.bodyRegular.copyWith(
                                      color: AppColors.textLight,
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      // Score badge
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Score: ${recommendation['score']?.toString() ?? 
                                   (recommendation['recommendationScore'] != null ? 
                                    (recommendation['recommendationScore'] * 100).toStringAsFixed(0) : 
                                    'N/A')}',
                          style: AppStyles.bodyBold.copyWith(
                            color: Colors.green.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (recommendation['description']?.toString().isNotEmpty == true ||
                      recommendation['reasoning']?.toString().isNotEmpty == true) ...[
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.lightbulb_outline, color: Colors.green, size: 16),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              recommendation['description']?.toString() ?? 
                              recommendation['reasoning']?.toString() ?? '',
                              style: AppStyles.bodyRegular.copyWith(
                                color: Colors.green.shade800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            )).toList(),
          ] else ...[
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue,
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isReceiptHistory 
                          ? 'No alternative products available for this receipt'
                          : 'No recommendations available for this product',
                      style: AppStyles.bodyRegular.copyWith(
                        color: AppColors.textLight,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }


  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatFullDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../../domain/entities/receipt_detail.dart';
import '../../../domain/entities/purchased_item.dart';
import '../../../domain/entities/recommendation_group.dart';
import '../../../domain/entities/alternative_product.dart';
import '../../../domain/entities/product_info.dart';

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
      // TODO: Replace with actual API call
      await Future.delayed(Duration(milliseconds: 1500)); // Simulate API call
      
      // Mock data for demonstration
      final mockDetail = _generateMockReceiptDetail();
      
      setState(() {
        receiptDetail = mockDetail;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load receipt details. Please try again.';
      });
    }
  }

  ReceiptDetail _generateMockReceiptDetail() {
    // Mock data generation - replace with actual API call
    final purchasedItems = [
      PurchasedItem(productName: 'Sprite Lemon 330ml', quantity: 2),
      PurchasedItem(productName: 'Oreo Original Cookies', quantity: 1),
      PurchasedItem(productName: 'Fresh Apple', quantity: 3),
      PurchasedItem(productName: 'Whole Milk 1L', quantity: 1),
    ];

    final recommendations = [
      RecommendationGroup(
        originalItem: PurchasedItem(productName: 'Sprite Lemon 330ml', quantity: 2),
        alternatives: [
          AlternativeProduct(
            rank: 1,
            product: ProductInfo(
              barCode: '1234567890',
              productName: 'Sparkling Water Lemon',
              brand: 'Healthy Choice',
              category: 'Beverages',
            ),
            recommendationScore: 0.92,
            reasoning: 'Zero sugar alternative with natural lemon flavor',
          ),
          AlternativeProduct(
            rank: 2,
            product: ProductInfo(
              barCode: '1234567891',
              productName: 'Diet Sprite',
              brand: 'Coca Cola',
              category: 'Beverages',
            ),
            recommendationScore: 0.75,
            reasoning: 'Lower calorie option with artificial sweeteners',
          ),
        ],
      ),
      RecommendationGroup(
        originalItem: PurchasedItem(productName: 'Oreo Original Cookies', quantity: 1),
        alternatives: [
          AlternativeProduct(
            rank: 1,
            product: ProductInfo(
              barCode: '2234567890',
              productName: 'Oat Cookies Organic',
              brand: 'Nature Valley',
              category: 'Snacks',
            ),
            recommendationScore: 0.88,
            reasoning: 'Higher fiber content and less processed sugar',
          ),
        ],
      ),
    ];

    return ReceiptDetail(
      receiptId: widget.receiptId,
      scanTime: DateTime.now().subtract(Duration(hours: 2)),
      recommendationId: 'rec_receipt_20250714_001',
      purchasedItems: purchasedItems,
      llmSummary: widget.receiptId % 3 == 0 
          ? 'Overall healthy choices with some room for improvement in sugar intake. Consider reducing high-sugar beverages and opt for more natural alternatives. Your fruit selection is excellent!'
          : 'Analysis is temporarily unavailable. Please check individual product recommendations below.',
      recommendationsList: widget.receiptId % 3 == 0 ? recommendations : [],
      hasLLMAnalysis: widget.receiptId % 3 == 0,
      hasRecommendations: widget.receiptId % 3 == 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Receipt Details',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.receipt_long,
                  color: AppColors.primary,
                  size: 24,
                ),
                SizedBox(width: 8),
                Text(
                  'Receipt #${receiptDetail!.receiptId}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppColors.textLight,
                ),
                SizedBox(width: 4),
                Text(
                  receiptDetail!.formattedScanTime,
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontSize: 14,
                  ),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${receiptDetail!.totalItemCount} total items',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchasedItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Purchased Items',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        SizedBox(height: 12),
        ...receiptDetail!.purchasedItems.map((item) => 
          PurchasedItemCard(item: item)
        ).toList(),
      ],
    );
  }

  Widget _buildLLMAnalysisSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nutritional Analysis',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: receiptDetail!.isAnalysisAvailable 
                ? Colors.blue[50] 
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: receiptDetail!.isAnalysisAvailable 
                  ? Colors.blue[200]! 
                  : Colors.grey[300]!,
            ),
          ),
          child: Column(
            children: [
              if (!receiptDetail!.isAnalysisAvailable) ...[
                Icon(
                  Icons.info_outline,
                  color: Colors.grey[600],
                  size: 20,
                ),
                SizedBox(height: 8),
              ],
              Text(
                receiptDetail!.llmSummary,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: receiptDetail!.isAnalysisAvailable 
                      ? Colors.black87 
                      : Colors.grey[600],
                  fontStyle: receiptDetail!.isAnalysisAvailable 
                      ? FontStyle.normal 
                      : FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Smart Recommendations',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        SizedBox(height: 12),
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
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            SizedBox(width: 12),
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
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'x${item.quantity}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textLight,
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
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.swap_horiz,
                  color: AppColors.primary,
                  size: 20,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Alternatives for ${group.originalItem.productName}',
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
            ...group.alternatives.map((alternative) => 
              AlternativeProductCard(alternative: alternative)
            ).toList(),
          ],
        ),
      ),
    );
  }
}

class AlternativeProductCard extends StatelessWidget {
  final AlternativeProduct alternative;

  const AlternativeProductCard({Key? key, required this.alternative}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '#${alternative.rank}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  alternative.product.productName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  alternative.formattedScore,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '${alternative.product.brand} • ${alternative.product.category}',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textLight,
            ),
          ),
          SizedBox(height: 8),
          Text(
            alternative.reasoning,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textLight,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
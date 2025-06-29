import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';
import '../../../domain/entities/history_response.dart';
import '../../../domain/entities/history_detail.dart';
import '../../../services/api.dart';
import '../../../services/user_service.dart';

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

  void _loadHistoryDetail() async {
    try {
      final userId = await UserService.instance.getCurrentUserId();
      if (userId == null) {
        setState(() {
          _isLoading = false;
          _error = 'User not logged in';
        });
        return;
      }

      final detail = await getHistoryDetail(
        userId: userId,
        historyId: widget.historyItem.id,
      );

      setState(() {
        _historyDetail = detail;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load history details';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Scan Details', style: AppStyles.h2),
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: BackButton(color: AppColors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: AppColors.white),
            onPressed: () => _shareResults(),
          ),
        ],
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

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProductHeader(),
          SizedBox(height: 16),
          _buildNutritionInfo(),
          SizedBox(height: 16),
          _buildIngredientsSection(),
          SizedBox(height: 16),
          _buildRecommendations(),
          SizedBox(height: 16),
          _buildScanInfo(),
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
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.background,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                _historyDetail!.productImage ?? 'https://via.placeholder.com/120x120',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    _historyDetail!.scanType == 'receipt' ? Icons.receipt : Icons.qr_code,
                    color: AppColors.primary,
                    size: 60,
                  );
                },
              ),
            ),
          ),
          SizedBox(height: 16),
          Text(
            _historyDetail!.productName,
            style: AppStyles.h2,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _historyDetail!.scanType == 'receipt' ? Icons.receipt : Icons.qr_code_scanner,
                size: 16,
                color: AppColors.primary,
              ),
              SizedBox(width: 4),
              Text(
                _historyDetail!.scanType == 'receipt' ? 'Receipt Scan' : 'Barcode Scan',
                style: AppStyles.bodyRegular.copyWith(color: AppColors.primary),
              ),
              SizedBox(width: 16),
              Icon(Icons.access_time, size: 16, color: AppColors.textLight),
              SizedBox(width: 4),
              Text(
                _formatDate(_historyDetail!.createdAt),
                style: AppStyles.bodyRegular.copyWith(color: AppColors.textLight),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildNutritionInfo() {
    final nutrition = _historyDetail!.fullAnalysis['nutrition_per_100g'];
    if (nutrition == null) return SizedBox();

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
          Text('Nutrition Facts (per 100g)', style: AppStyles.h2),
          SizedBox(height: 16),
          _buildNutritionRow('Calories', '${nutrition['calories'] ?? 0}', 'kcal'),
          _buildNutritionRow('Protein', '${nutrition['protein'] ?? 0}', 'g'),
          _buildNutritionRow('Carbs', '${nutrition['carbs'] ?? 0}', 'g'),
          _buildNutritionRow('Fiber', '${nutrition['fiber'] ?? 0}', 'g'),
          _buildNutritionRow('Sugar', '${nutrition['sugar'] ?? 0}', 'g'),
          _buildNutritionRow('Fat', '${nutrition['fat'] ?? 0}', 'g'),
          _buildNutritionRow('Sodium', '${nutrition['sodium'] ?? 0}', 'mg'),
        ],
      ),
    );
  }

  Widget _buildNutritionRow(String label, String value, String unit) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppStyles.bodyRegular),
          Text('$value $unit', style: AppStyles.bodyBold),
        ],
      ),
    );
  }

  Widget _buildIngredientsSection() {
    final ingredients = _historyDetail!.fullAnalysis['ingredients'] as List?;
    final allergens = _historyDetail!.fullAnalysis['allergens'] as List?;

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
          Text('Ingredients & Allergens', style: AppStyles.h2),
          SizedBox(height: 16),
          if (ingredients != null) ...[
            Text('Ingredients:', style: AppStyles.bodyBold),
            SizedBox(height: 8),
            Text(
              ingredients.join(', '),
              style: AppStyles.bodyRegular,
            ),
            SizedBox(height: 16),
          ],
          if (allergens != null && allergens.isNotEmpty) ...[
            Text('Allergens:', style: AppStyles.bodyBold.copyWith(color: AppColors.alert)),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: allergens.map((allergen) => Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.alert.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.alert.withOpacity(0.3)),
                ),
                child: Text(
                  allergen.toString(),
                  style: TextStyle(
                    color: AppColors.alert,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )).toList(),
            ),
          ] else ...[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 16),
                  SizedBox(width: 8),
                  Text('No known allergens detected', style: TextStyle(color: Colors.green)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    final recommendations = _historyDetail!.recommendations;

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
          Text('Recommendations', style: AppStyles.h2),
          SizedBox(height: 16),
          ...recommendations.map((recommendation) => Container(
            margin: EdgeInsets.only(bottom: 16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getRecommendationIcon(recommendation['type']),
                      color: AppColors.primary,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        recommendation['title'],
                        style: AppStyles.bodyBold.copyWith(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  recommendation['description'],
                  style: AppStyles.bodyRegular,
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildScanInfo() {
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
          Text('Scan Information', style: AppStyles.h2),
          SizedBox(height: 16),
          _buildInfoRow('Scan Type', _historyDetail!.scanType == 'receipt' ? 'Receipt' : 'Barcode'),
          if (_historyDetail!.barcode != null)
            _buildInfoRow('Barcode', _historyDetail!.barcode!),
          _buildInfoRow('Scan Date', _formatFullDate(_historyDetail!.createdAt)),
          _buildInfoRow('Recommendations', '${_historyDetail!.recommendationCount} available'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: AppStyles.bodyRegular.copyWith(color: AppColors.textLight)),
          ),
          Expanded(
            child: Text(value, style: AppStyles.bodyRegular),
          ),
        ],
      ),
    );
  }


  IconData _getRecommendationIcon(String type) {
    switch (type) {
      case 'alternative':
        return Icons.swap_horiz;
      case 'portion':
        return Icons.straighten;
      case 'pairing':
        return Icons.restaurant;
      default:
        return Icons.lightbulb_outline;
    }
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

  void _shareResults() {
    // TODO: Implement sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Share functionality coming soon!')),
    );
  }
}
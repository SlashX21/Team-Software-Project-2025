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

      final detail = await getHistoryDetail(userId, widget.historyItem.id);
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
        title: Text('Product Details', style: AppStyles.h2.copyWith(color: AppColors.white)),
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
    final allergens = _historyDetail!.fullAnalysis['allergens'] as List?;
    
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
    final ingredients = _historyDetail!.fullAnalysis['ingredients'] as List?;
    
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
              ingredients.join(', '),
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
    final llmInsights = _historyDetail!.fullAnalysis['llm_insights'] as String?;
    
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
          if (llmInsights != null && llmInsights.isNotEmpty) ...[
            Text(
              llmInsights,
              style: AppStyles.bodyRegular.copyWith(
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ] else ...[
            Text(
              'No AI analysis available for this product',
              style: AppStyles.bodyRegular.copyWith(color: AppColors.textLight),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    final recommendations = _historyDetail!.recommendations;

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
            ...recommendations.asMap().entries.map((entry) {
              final index = entry.key;
              final recommendation = entry.value;
              return Container(
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
                    Text(
                      '#${index + 1} ${recommendation['title'] ?? 'Unknown Product'}',
                      style: AppStyles.bodyRegular.copyWith(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    if (recommendation['brand'] != null)
                      Text(
                        'Brand: ${recommendation['brand']}',
                        style: AppStyles.bodyRegular,
                      ),
                    SizedBox(height: 4),
                    if (recommendation['score'] != null)
                      Text(
                        'Score: ${recommendation['score']}%',
                        style: AppStyles.bodyRegular.copyWith(color: AppColors.primary),
                      ),
                    SizedBox(height: 4),
                    if (recommendation['description'] != null)
                      Text(
                        'Reason: ${recommendation['description']}',
                        style: AppStyles.bodyRegular.copyWith(color: AppColors.textLight),
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
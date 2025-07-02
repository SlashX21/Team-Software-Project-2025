import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';
import '../../../domain/entities/history_response.dart';
import '../analysis/analysis_result_screen.dart';
import 'history_detail_page.dart';

class HistoryScreen extends StatefulWidget {
  final int userId;
  
  const HistoryScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<HistoryItem> _historyItems = [];

  @override
  void initState() {
    super.initState();
    _loadHistoryItems();
  }

  void _loadHistoryItems() {
    // TODO: Load from actual data source (SharedPreferences, Database, etc.)
    // For now, using demo data
    setState(() {
      _historyItems = _getDemoHistoryItems();
    });
  }

  List<HistoryItem> _getDemoHistoryItems() {
    return [
      HistoryItem(
        id: '1',
        scanType: 'barcode',
        createdAt: DateTime.now().subtract(Duration(minutes: 30)),
        productName: 'Organic Almond Butter',
        productImage: 'https://via.placeholder.com/60x60',
        barcode: '123456',
        recommendationCount: 1,
        summary: {'allergens': ['Tree Nuts']},
      ),
      HistoryItem(
        id: '2',
        scanType: 'barcode',
        createdAt: DateTime.now().subtract(Duration(hours: 2)),
        productName: 'Whole Grain Bread',
        productImage: 'https://via.placeholder.com/60x60',
        barcode: '234567',
        recommendationCount: 1,
        summary: {'allergens': ['Gluten']},
      ),
      HistoryItem(
        id: '3',
        scanType: 'barcode',
        createdAt: DateTime.now().subtract(Duration(days: 1)),
        productName: 'Greek Yogurt',
        productImage: 'https://via.placeholder.com/60x60',
        barcode: '345678',
        recommendationCount: 0,
        summary: {'allergens': []},
      ),
      HistoryItem(
        id: '4',
        scanType: 'barcode',
        createdAt: DateTime.now().subtract(Duration(days: 2)),
        productName: 'Peanut Butter Cookies',
        productImage: 'https://via.placeholder.com/60x60',
        barcode: '456789',
        recommendationCount: 2,
        summary: {'allergens': ['Peanuts', 'Gluten']},
      ),
      HistoryItem(
        id: '5',
        scanType: 'barcode',
        createdAt: DateTime.now().subtract(Duration(days: 3)),
        productName: 'Coconut Water',
        productImage: 'https://via.placeholder.com/60x60',
        barcode: '567890',
        recommendationCount: 0,
        summary: {'allergens': []},
      ),
    ];
  }

  void _onHistoryItemTap(HistoryItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HistoryDetailPage(historyItem: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Scan History', style: AppStyles.h2.copyWith(color: AppColors.white)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: _historyItems.isEmpty
          ? _buildEmptyState()
          : _buildHistoryList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: AppColors.textLight,
          ),
          SizedBox(height: 16),
          Text(
            'No scan history yet',
            style: AppStyles.h2.copyWith(color: AppColors.textLight),
          ),
          SizedBox(height: 8),
          Text(
            'Start scanning products to see\nyour history here',
            style: AppStyles.bodyRegular.copyWith(color: AppColors.textLight),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _historyItems.length,
      itemBuilder: (context, index) {
        return HistoryListItem(
          historyItem: _historyItems[index],
          onTap: () => _onHistoryItemTap(_historyItems[index]),
        );
      },
    );
  }
}

class HistoryListItem extends StatelessWidget {
  final HistoryItem historyItem;
  final VoidCallback onTap;

  const HistoryListItem({
    Key? key,
    required this.historyItem,
    required this.onTap,
  }) : super(key: key);

  String _formatScanDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 2,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Product Thumbnail
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: AppColors.background,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      historyItem.productImage ?? '',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.image_not_supported,
                          color: AppColors.textLight,
                          size: 30,
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(width: 16),
                
                // Product Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        historyItem.productName,
                        style: AppStyles.bodyBold,
                      ),
                      SizedBox(height: 4),
                      Text(
                        _formatScanDate(historyItem.createdAt),
                        style: AppStyles.bodyRegular.copyWith(color: AppColors.textLight),
                      ),
                      if ((historyItem.summary?['allergens'] ?? []).isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Row(
                            children: [
                              Icon(Icons.warning, size: 16, color: AppColors.alert),
                              SizedBox(width: 4),
                              Text(
                                '${(historyItem.summary?['allergens'] as List).length} allergen${(historyItem.summary?['allergens'] as List).length > 1 ? 's' : ''}',
                                style: AppStyles.bodyRegular.copyWith(
                                  color: (historyItem.summary?['allergens'] as List).length > 1 ? AppColors.alert : AppColors.warning,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Arrow Icon
                Icon(
                  Icons.arrow_forward_ios,
                  size: 18,
                  color: AppColors.textLight,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';
import '../../../domain/entities/history_item.dart';
import '../../../domain/entities/product_analysis.dart';
import '../analysis/analysis_result_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

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
        productId: '1',
        productName: 'Organic Almond Butter',
        scanDate: DateTime.now().subtract(Duration(minutes: 30)),
        thumbnailUrl: 'https://via.placeholder.com/60x60',
        detectedAllergens: ['Tree Nuts'],
        hasAllergenAlert: true,
      ),
      HistoryItem(
        productId: '2',
        productName: 'Whole Grain Bread',
        scanDate: DateTime.now().subtract(Duration(hours: 2)),
        thumbnailUrl: 'https://via.placeholder.com/60x60',
        detectedAllergens: ['Gluten'],
        hasAllergenAlert: false,
      ),
      HistoryItem(
        productId: '3',
        productName: 'Greek Yogurt',
        scanDate: DateTime.now().subtract(Duration(days: 1)),
        thumbnailUrl: 'https://via.placeholder.com/60x60',
        detectedAllergens: [],
        hasAllergenAlert: false,
      ),
      HistoryItem(
        productId: '4',
        productName: 'Peanut Butter Cookies',
        scanDate: DateTime.now().subtract(Duration(days: 2)),
        thumbnailUrl: 'https://via.placeholder.com/60x60',
        detectedAllergens: ['Peanuts', 'Gluten'],
        hasAllergenAlert: true,
      ),
      HistoryItem(
        productId: '5',
        productName: 'Coconut Water',
        scanDate: DateTime.now().subtract(Duration(days: 3)),
        thumbnailUrl: 'https://via.placeholder.com/60x60',
        detectedAllergens: [],
        hasAllergenAlert: false,
      ),
    ];
  }

  void _onHistoryItemTap(HistoryItem item) {
    // TODO: Fetch full ProductAnalysis data based on productId
    // For now, create demo ProductAnalysis
    final productAnalysis = ProductAnalysis(
      name: item.productName,
      imageUrl: item.thumbnailUrl,
      ingredients: ['Demo ingredient 1', 'Demo ingredient 2'],
      detectedAllergens: item.detectedAllergens,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnalysisResultScreen(
          productAnalysis: productAnalysis,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan History', style: AppStyles.h2),
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: BackButton(color: AppColors.white),
      ),
      backgroundColor: AppColors.background,
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
                      historyItem.thumbnailUrl,
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        historyItem.formattedScanDate,
                        style: AppStyles.bodyRegular.copyWith(
                          color: AppColors.textLight,
                          fontSize: 14,
                        ),
                      ),
                      if (historyItem.detectedAllergens.isNotEmpty) ...[
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: historyItem.hasAllergenAlert
                                ? AppColors.alert.withOpacity(0.1)
                                : AppColors.warning.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                historyItem.hasAllergenAlert
                                    ? Icons.warning
                                    : Icons.info_outline,
                                size: 12,
                                color: historyItem.hasAllergenAlert
                                    ? AppColors.alert
                                    : AppColors.warning,
                              ),
                              SizedBox(width: 4),
                              Text(
                                '${historyItem.detectedAllergens.length} allergen${historyItem.detectedAllergens.length > 1 ? 's' : ''}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: historyItem.hasAllergenAlert
                                      ? AppColors.alert
                                      : AppColors.warning,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Arrow Icon
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
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
import 'package:flutter/material.dart';
import '../services/app_colors.dart';
import '../services/app_styles.dart';
import 'history_item.dart'; // Adjust import path if needed
import 'feedback_page.dart'; // Adjust as needed
import 'product_analysis.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<HistoryItem> _historyItems = [];

  @override
  void initState() {
    super.initState();
    _loadHistoryItems();
  }

  void _loadHistoryItems() {
    setState(() {
      _historyItems = _getDemoHistoryItems();
    });
  }

  List<HistoryItem> _getDemoHistoryItems() {
    return [
      HistoryItem(
        productId: '1',
        productName: 'Organic Almond Butter',
        scanDate: DateTime.now().subtract(const Duration(minutes: 30)),
        thumbnailUrl: 'https://via.placeholder.com/60x60',
        detectedAllergens: ['Tree Nuts'],
        hasAllergenAlert: true,
      ),
      HistoryItem(
        productId: '2',
        productName: 'Whole Grain Bread',
        scanDate: DateTime.now().subtract(const Duration(hours: 2)),
        thumbnailUrl: 'https://via.placeholder.com/60x60',
        detectedAllergens: ['Gluten'],
        hasAllergenAlert: false,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Scan History', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _historyItems.length,
        itemBuilder: (context, index) {
          final item = _historyItems[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FeedbackPage(productAnalysis: ProductAnalysis(
                    name: item.productName,
                    imageUrl: item.thumbnailUrl,
                    ingredients: ['Ingredient 1', 'Ingredient 2'], // Placeholder
                    detectedAllergens: item.detectedAllergens,
                  )),
                ),
              );
            },
            child: Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: Image.network(item.thumbnailUrl, width: 60, height: 60, fit: BoxFit.cover),
                title: Text(item.productName, style: AppStyles.bodyBold),
                subtitle: Text(
                  'Scanned: ${_formatDateTime(item.scanDate)}\nAllergens: ${item.detectedAllergens.join(', ')}',
                  style: AppStyles.bodyRegular,
                ),
                trailing: Icon(
                  item.hasAllergenAlert ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                  color: item.hasAllergenAlert ? AppColors.alert : AppColors.primary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}  •  ${dt.day}/${dt.month}/${dt.year}';
  }
}

import 'package:flutter/material.dart';
import '../services/app_colors.dart';
import '../services/app_styles.dart';
import 'product_analysis.dart'; // Ensure this import points to your model

class FeedbackPage extends StatefulWidget {
  final ProductAnalysis? productAnalysis;

  const FeedbackPage({super.key, this.productAnalysis});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  ProductAnalysis? _currentAnalysis;

  @override
  void initState() {
    super.initState();
    _currentAnalysis = widget.productAnalysis ?? _getDemoScanResult();
  }

  ProductAnalysis _getDemoScanResult() {
    return ProductAnalysis(
      name: 'Organic Almond Butter',
      imageUrl: 'https://via.placeholder.com/300x200',
      ingredients: [
        'Organic Almonds',
        'Sea Salt',
        'Natural Vitamin E (mixed tocopherols)'
      ],
      detectedAllergens: ['Tree Nuts (Almonds)'],
    );
  }

  @override
  Widget build(BuildContext context) {
    final pa = _currentAnalysis;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Product Feedback', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: pa == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: ListView(
                children: [
                  Image.network(pa.imageUrl, height: 200, fit: BoxFit.cover),
                  const SizedBox(height: 16),
                  Text(pa.name, style: AppStyles.h2),
                  const SizedBox(height: 16),
                  Text("Ingredients", style: AppStyles.bodyBold),
                  const SizedBox(height: 6),
                  ...pa.ingredients.map((i) => Text("- $i", style: AppStyles.bodyRegular)),
                  const SizedBox(height: 20),
                  Text("Detected Allergens", style: AppStyles.bodyBold),
                  const SizedBox(height: 6),
                  pa.detectedAllergens.isNotEmpty
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: pa.detectedAllergens
                              .map((a) => Text("- $a", style: AppStyles.bodyRegular.copyWith(color: AppColors.alert)))
                              .toList(),
                        )
                      : Text("No allergens detected", style: AppStyles.bodyRegular),
                ],
              ),
            ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../domain/entities/product_analysis.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';

class AnalysisResultScreen extends StatefulWidget {
  final ProductAnalysis? productAnalysis;

  const AnalysisResultScreen({
    Key? key,
    this.productAnalysis,
  }) : super(key: key);

  @override
  _AnalysisResultScreenState createState() => _AnalysisResultScreenState();
}

class _AnalysisResultScreenState extends State<AnalysisResultScreen> {
  ProductAnalysis? _currentAnalysis;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _currentAnalysis = widget.productAnalysis;
  }

  void _startScan() {
    setState(() {
      _isScanning = true;
    });
    
    // TODO: Implement actual camera scanning
    // For now, simulate scan with demo data after 2 seconds
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _currentAnalysis = _getDemoScanResult();
        });
      }
    });
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _currentAnalysis?.name ?? 'Product Scanner',
          style: AppStyles.h2,
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: BackButton(color: AppColors.white),
      ),
      body: Column(
        children: [
          // Scanning Area (Top Half)
          Container(
            height: 250,
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _buildScanningArea(),
          ),
          
          // Information Area (Bottom Half)
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _buildInformationArea(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanningArea() {
    if (_isScanning) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            SizedBox(height: 16),
            Text(
              'Scanning product...',
              style: AppStyles.bodyBold.copyWith(color: AppColors.primary),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.qr_code_scanner,
            size: 64,
            color: AppColors.primary,
          ),
          SizedBox(height: 16),
          Text(
            'Tap to scan product',
            style: AppStyles.bodyBold.copyWith(color: AppColors.textDark),
          ),
          SizedBox(height: 8),
          Text(
            'Position product barcode in camera view',
            style: AppStyles.bodyRegular.copyWith(color: AppColors.textLight),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: _startScan,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Start Scanning', style: AppStyles.buttonText),
          ),
        ],
      ),
    );
  }

  Widget _buildInformationArea() {
    if (_currentAnalysis == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.eco,
              size: 80,
              color: AppColors.primary.withOpacity(0.3),
            ),
            SizedBox(height: 16),
            Text(
              'Grocery Guardian',
              style: AppStyles.h2.copyWith(
                color: AppColors.primary.withOpacity(0.7),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Scan a product to see detailed\ningredient analysis and health insights',
              style: AppStyles.bodyRegular.copyWith(
                color: AppColors.textLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20.0),
      children: [
        // Product Image
        Container(
          height: 150,
          margin: const EdgeInsets.only(bottom: 20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              _currentAnalysis!.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: AppColors.textLight.withOpacity(0.1),
                  child: Icon(
                    Icons.image_not_supported,
                    size: 50,
                    color: AppColors.textLight,
                  ),
                );
              },
            ),
          ),
        ),

        // Allergen Alert Card (conditional)
        if (_currentAnalysis!.detectedAllergens.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.alert.withOpacity(0.1),
              border: Border.all(color: AppColors.alert),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning, color: AppColors.alert, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Allergen Alert', style: AppStyles.bodyBold.copyWith(color: AppColors.alert)),
                      const SizedBox(height: 4),
                      Text(
                        'Detected allergens: ${_currentAnalysis!.detectedAllergens.join(', ')}',
                        style: AppStyles.bodyRegular,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // Ingredients Section
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ingredients', style: AppStyles.bodyBold),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.textLight.withOpacity(0.2),
                  ),
                ),
                child: Text(
                  _currentAnalysis!.ingredients.join(', '),
                  style: AppStyles.bodyRegular,
                ),
              ),
            ],
          ),
        ),

        // Safe Alternatives Section
        Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Health Insights', style: AppStyles.bodyBold),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.textLight.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, 
                             color: AppColors.primary, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Nutritional Analysis',
                          style: AppStyles.bodyBold.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'This product contains natural ingredients and appears to be suitable for most dietary preferences. Always check the full ingredient list for specific allergies.',
                      style: AppStyles.bodyRegular.copyWith(
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
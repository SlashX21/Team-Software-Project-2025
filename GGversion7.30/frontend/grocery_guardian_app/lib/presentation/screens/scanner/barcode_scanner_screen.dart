import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../domain/entities/product_analysis.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';
import '../../../services/api_service.dart';

class BarcodeScannerScreen extends StatefulWidget {
  final int userId;
  final ProductAnalysis? productAnalysis;

  const BarcodeScannerScreen({Key? key, this.productAnalysis, required this.userId}) : super(key: key);

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  ProductAnalysis? _currentAnalysis;
  List<Map<String, dynamic>> _receiptItems = [];
  bool _showScanner = false;
  bool _isLoading = false;
  bool _scannedOnce = false;

  @override
  void initState() {
    super.initState();
    _currentAnalysis = widget.productAnalysis;
    _showScanner = true;
  }

  Future<void> _onBarcodeScanned(BarcodeCapture capture) async {
    if (capture.barcodes.isEmpty) return;

    final rawCode = capture.barcodes.first.rawValue?.trim();
    if (rawCode == null || rawCode.isEmpty || _isLoading) return;

    setState(() {
      _isLoading = true;
      _receiptItems = [];
      _scannedOnce = true;
    });

    try {
      final product = await ApiService.fetchProductByBarcode(rawCode, widget.userId);
      setState(() {
        _currentAnalysis = product;
        _showScanner = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Scan failed: $e'),
          backgroundColor: AppColors.alert,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadReceipt() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() {
      _isLoading = true;
      _receiptItems.clear();
      _currentAnalysis = null;
    });

    try {
      final result = await ApiService.uploadReceiptImage(picked, widget.userId);

      final items = result['itemAnalyses'] ?? [];
      final llm = result['llmInsights'] ?? {};

      setState(() {
        _receiptItems = List<Map<String, dynamic>>.from(items);
        _currentAnalysis = ProductAnalysis(
          name: 'Receipt Summary',
          imageUrl: '',
          ingredients: [],
          detectedAllergens: [],
          summary: (llm['summary'] as String?)?.isNotEmpty == true
              ? llm['summary']
              : 'No summary provided by AI. The product seems acceptable based on available data.',
          detailedAnalysis: (llm['keyFindings'] is List && llm['keyFindings'].isNotEmpty)
              ? (llm['keyFindings'] as List).join('\n')
              : 'No key findings were detected from your receipt items.',
          actionSuggestions: (llm['improvementSuggestions'] is List && llm['improvementSuggestions'].isNotEmpty)
              ? List<String>.from(llm['improvementSuggestions'])
              : ['Try selecting more varied products for better AI suggestions.'],
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: AppColors.alert,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _currentAnalysis?.name ?? 'Product Scanner',
          style: AppStyles.h2.copyWith(color: AppColors.white),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _showScanner
              ? Expanded(
                  child: Stack(
                    children: [
                      MobileScanner(onDetect: _onBarcodeScanned),
                      Positioned(
                        top: 40,
                        left: 16,
                        right: 16,
                        child: Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Point camera at barcode',
                                style: AppStyles.bodyBold.copyWith(color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () => setState(() => _showScanner = false),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.white,
                                  foregroundColor: AppColors.textDark,
                                ),
                                child: Text("Cancel"),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : _buildScannerUI(),

          if (_isLoading)
            Container(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 12),
                  Text(
                    'Processing...',
                    style: AppStyles.bodyRegular.copyWith(color: AppColors.textLight),
                  ),
                ],
              ),
            )
          else
            Expanded(child: _buildAnalysisResult()),
        ],
      ),
    );
  }

  Widget _buildScannerUI() {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.qr_code_scanner,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Scan a product barcode',
              style: AppStyles.h2.copyWith(color: AppColors.textDark),
            ),
            SizedBox(height: 8),
            Text(
              'Scan a product barcode to get nutrition insights',
              style: AppStyles.bodyRegular.copyWith(color: AppColors.textLight),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => setState(() {
                _showScanner = true;
                _receiptItems.clear();
                _currentAnalysis = null;
              }),
              icon: Icon(Icons.qr_code_scanner),
              label: Text("Scan Barcode"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisResult() {
    if (_receiptItems.isNotEmpty) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionHeader('Purchased Items', Icons.shopping_cart),
          SizedBox(height: 16),
          ..._receiptItems.map((item) => _buildReceiptItem(item)),
          if (_currentAnalysis != null) ...[
            SizedBox(height: 24),
            _buildAIInsights(),
          ],
        ],
      );
    }

    if (_currentAnalysis == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _scannedOnce ? Icons.search_off : Icons.qr_code_scanner,
              size: 64,
              color: AppColors.textLight,
            ),
            SizedBox(height: 16),
            Text(
              _scannedOnce
                  ? 'No information available for this product.'
                  : 'Scan a product or upload a receipt to get started',
              style: AppStyles.bodyRegular.copyWith(color: AppColors.textLight),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildProductInfo(),
        if (_currentAnalysis!.summary.isNotEmpty ||
            _currentAnalysis!.detailedAnalysis.isNotEmpty ||
            _currentAnalysis!.actionSuggestions.isNotEmpty)
          _buildAIInsights(),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        SizedBox(width: 12),
        Text(title, style: AppStyles.h2),
      ],
    );
  }

  Widget _buildReceiptItem(Map<String, dynamic> item) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.shopping_basket, color: AppColors.primary, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] ?? 'Unknown Item',
                  style: AppStyles.bodyBold,
                ),
                SizedBox(height: 4),
                Text(
                  "Quantity: ${item['quantity'] ?? 1}",
                  style: AppStyles.bodyRegular.copyWith(color: AppColors.textLight),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Product Information", Icons.info_outline),
        SizedBox(height: 16),

        if (_currentAnalysis!.detectedAllergens.isNotEmpty) ...[
          _buildInfoCard(
            title: "Allergens",
            content: _currentAnalysis!.detectedAllergens.join(', '),
            icon: Icons.warning,
            color: AppColors.alert,
          ),
          SizedBox(height: 12),
        ],

        _buildInfoCard(
          title: "Ingredients",
          content: _currentAnalysis!.ingredients.isNotEmpty
              ? _currentAnalysis!.ingredients.join(', ')
              : 'No ingredients listed.',
          icon: Icons.list,
          color: AppColors.primary,
        ),
        SizedBox(height: 24),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String content,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              SizedBox(width: 8),
              Text(title, style: AppStyles.bodyBold.copyWith(color: color)),
            ],
          ),
          SizedBox(height: 8),
          Text(content, style: AppStyles.bodyRegular),
        ],
      ),
    );
  }

  Widget _buildAIInsights() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("AI Nutrition Insights", Icons.psychology),
        SizedBox(height: 16),

        if (_currentAnalysis!.summary.isNotEmpty) ...[
          _buildInsightCard(
            title: "Summary",
            content: _currentAnalysis!.summary,
            icon: Icons.summarize,
          ),
          SizedBox(height: 12),
        ],

        if (_currentAnalysis!.detailedAnalysis.isNotEmpty) ...[
          _buildInsightCard(
            title: "Detailed Analysis",
            content: _currentAnalysis!.detailedAnalysis,
            icon: Icons.analytics,
          ),
          SizedBox(height: 12),
        ],

        if (_currentAnalysis!.actionSuggestions.isNotEmpty) ...[
          _buildInsightCard(
            title: "Recommendations",
            content: _currentAnalysis!.actionSuggestions.map((s) => "• $s").join('\n'),
            icon: Icons.lightbulb,
          ),
        ],
      ],
    );
  }

  Widget _buildInsightCard({
    required String title,
    required String content,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: AppColors.primary, size: 16),
              ),
              SizedBox(width: 8),
              Text(title, style: AppStyles.bodyBold.copyWith(color: AppColors.primary)),
            ],
          ),
          SizedBox(height: 12),
          Text(content, style: AppStyles.bodyRegular),
        ],
      ),
    );
  }
}
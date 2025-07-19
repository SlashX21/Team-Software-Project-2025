import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';
import '../../../services/api.dart';
import '../../../services/user_service.dart';
import '../../../domain/entities/product_analysis.dart';
import '../../widgets/ingredients_display.dart';

class ProductDetailPage extends StatefulWidget {
  final String? barcode;
  final ProductAnalysis? productAnalysis;
  final Map<String, dynamic>? productData;

  const ProductDetailPage({
    Key? key,
    this.barcode,
    this.productAnalysis,
    this.productData,
  }) : super(key: key);

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage>
    with TickerProviderStateMixin {
  ProductAnalysis? _productAnalysis;
  Map<String, dynamic>? _productData;
  List<Map<String, dynamic>> _userAllergens = [];
  List<String> _detectedAllergens = [];
  bool _isLoading = false;
  String? _error;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _productAnalysis = widget.productAnalysis;
    _productData = widget.productData;
    
    if (_productAnalysis == null && widget.barcode != null) {
      _loadProductData();
    } else {
      _loadAdditionalData();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProductData() async {
    if (widget.barcode == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userId = await UserService.instance.getCurrentUserId() ?? 0;
      
      // 并行加载产品数据
      final futures = await Future.wait([
        fetchProductByBarcode(widget.barcode!, userId),
        getProduct(widget.barcode!),
      ]);

      _productAnalysis = futures[0] as ProductAnalysis;
      _productData = futures[1] as Map<String, dynamic>?;

      await _loadAdditionalData();
    } catch (e) {
      setState(() {
        _error = 'Failed to load product information: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAdditionalData() async {
    try {
      final userId = await UserService.instance.getCurrentUserId();
      if (userId == null) return;

      // 只加载用户过敏原，推荐数据已经包含在ProductAnalysis中
      final userAllergens = await getUserAllergens(userId);

      setState(() {
        _userAllergens = userAllergens ?? [];
        _isLoading = false;
      });

      // 检查过敏原
      _checkAllergens();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('❌ 加载额外数据错误: $e');
    }
  }

  void _checkAllergens() {
    if (_productAnalysis == null || _userAllergens.isEmpty) return;

    final productAllergens = _productAnalysis!.detectedAllergens;
    final userAllergenNames = _userAllergens
        .map((a) => (a['allergenName'] ?? '').toString().toLowerCase())
        .toSet();

    _detectedAllergens = productAllergens
        .where((allergen) => userAllergenNames.contains(allergen.toLowerCase()))
        .toList();

    if (_detectedAllergens.isNotEmpty) {
      _showAllergenWarning();
    }
  }

  void _showAllergenWarning() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: AppColors.alert),
            SizedBox(width: 8),
            Text('Allergen Warning'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This product contains ingredients you are allergic to:'),
            SizedBox(height: 8),
            ..._detectedAllergens.map((allergen) => 
              Padding(
                padding: EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(Icons.error, color: AppColors.alert, size: 16),
                    SizedBox(width: 8),
                    Text(allergen, style: AppStyles.bodyBold),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Please carefully check the product ingredients and avoid consuming products that may cause allergic reactions.',
              style: AppStyles.bodyRegular.copyWith(color: AppColors.textLight),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('I understand'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productName = _productAnalysis?.name ?? 
                      _productData?['name'] ?? 
                      'Product Details';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          productName,
          style: AppStyles.h2.copyWith(color: AppColors.white),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          if (widget.barcode != null)
            IconButton(
              icon: Icon(Icons.share, color: AppColors.white),
              onPressed: () => _shareProduct(),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.white,
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.white.withOpacity(0.7),
          tabs: [
            Tab(text: 'Overview'),
            Tab(text: 'Nutrition'),
            Tab(text: 'Recommendations'),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text('Loading product information...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: AppColors.alert),
            SizedBox(height: 16),
            Text('加载失败', style: AppStyles.h2.copyWith(color: AppColors.alert)),
            SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadProductData,
              child: Text('重试'),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildOverviewTab(),
        _buildNutritionTab(),
        _buildRecommendationTab(),
      ],
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProductHeader(),
          SizedBox(height: 16),
          _buildAllergenStatus(),
          SizedBox(height: 16),
          _buildHealthScore(),
          SizedBox(height: 16),
          _buildQuickNutrition(),
          SizedBox(height: 16),
          _buildIngredientsSection(),
        ],
      ),
    );
  }

  Widget _buildProductHeader() {
    final productName = _productAnalysis?.name ?? _productData?['name'] ?? '未知产品';
    final brand = _productData?['brand'] ?? '';
    final category = _productData?['category'] ?? '';

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
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.inventory_2,
                  size: 40,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productName,
                      style: AppStyles.h2,
                    ),
                    if (brand.isNotEmpty) ...[
                      SizedBox(height: 4),
                      Text(
                        brand,
                        style: AppStyles.bodyRegular.copyWith(
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                    if (category.isNotEmpty) ...[
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          category,
                          style: AppStyles.bodyRegular.copyWith(
                            color: AppColors.primary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (widget.barcode != null) ...[
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.qr_code, size: 16, color: AppColors.textLight),
                SizedBox(width: 8),
                Text(
                  '条码: ${widget.barcode}',
                  style: AppStyles.bodyRegular.copyWith(
                    color: AppColors.textLight,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAllergenStatus() {
    final hasAllergens = _detectedAllergens.isNotEmpty;
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasAllergens ? AppColors.alert.withOpacity(0.1) : AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasAllergens ? AppColors.alert.withOpacity(0.3) : AppColors.success.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasAllergens ? Icons.warning : Icons.check_circle,
            color: hasAllergens ? AppColors.alert : AppColors.success,
            size: 24,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasAllergens ? 'Allergen Warning' : 'No Allergen Risk',
                  style: AppStyles.bodyBold.copyWith(
                    color: hasAllergens ? AppColors.alert : AppColors.success,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  hasAllergens 
                      ? 'Contains ${_detectedAllergens.join(', ')}'
                      : 'According to your allergen information, this product is safe for you',
                  style: AppStyles.bodyRegular.copyWith(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthScore() {
    // 模拟健康评分计算
    final score = _calculateHealthScore();
    final scoreColor = _getScoreColor(score);
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Health Score', style: AppStyles.bodyBold),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: scoreColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              score.toString(),
                              style: AppStyles.h2.copyWith(
                                color: scoreColor,
                                fontSize: 24,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getScoreDescription(score),
                                style: AppStyles.bodyBold.copyWith(color: scoreColor),
                              ),
                              SizedBox(height: 4),
                              Text(
                                _getScoreExplanation(score),
                                style: AppStyles.bodyRegular.copyWith(
                                  fontSize: 12,
                                  color: AppColors.textLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickNutrition() {
    final nutrition = _productData;
    if (nutrition == null) return SizedBox();

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nutrition Overview (per 100g)', style: AppStyles.bodyBold),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildNutritionItem(
                  'Calories',
                  '${nutrition['energy_kcal_100g'] ?? '--'} kcal',
                  Icons.local_fire_department,
                  Colors.orange,
                ),
              ),
              Expanded(
                child: _buildNutritionItem(
                  'Sugar',
                  '${nutrition['sugars_100g'] ?? '--'} g',
                  Icons.cake,
                  Colors.pink,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildNutritionItem(
                  'Protein',
                  '${nutrition['proteins_100g'] ?? '--'} g',
                  Icons.fitness_center,
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildNutritionItem(
                  'Fat',
                  '${nutrition['fat_100g'] ?? '--'} g',
                  Icons.water_drop,
                  Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      margin: EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(label, style: AppStyles.bodyRegular.copyWith(fontSize: 12)),
          SizedBox(height: 4),
          Text(value, style: AppStyles.bodyBold.copyWith(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildIngredientsSection() {
    final ingredients = _productAnalysis?.ingredients ?? _extractIngredientsFromProductData();
    
    return IngredientsDisplay(
      ingredients: ingredients,
      title: "Ingredient List",
      maxDisplayCount: 8,
      padding: EdgeInsets.all(20),
    );
  }

  List<String>? _extractIngredientsFromProductData() {
    final ingredients = _productData?['ingredients'];
    if (ingredients == null) return null;

    if (ingredients is List) {
      return ingredients.map((e) => e.toString()).toList();
    } else if (ingredients is String) {
      // 如果是逗号分隔的字符串，进行分割
      if (ingredients.contains(',')) {
        return ingredients.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      } else {
        return [ingredients];
      }
    }
    
    return null;
  }

  Widget _buildNutritionTab() {
    final nutrition = _productData;
    if (nutrition == null) {
      return Center(
        child: Text('暂无营养信息'),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildDetailedNutrition(nutrition),
        ],
      ),
    );
  }

  Widget _buildDetailedNutrition(Map<String, dynamic> nutrition) {
    final nutritionItems = [
      {'label': 'Calories', 'value': nutrition['energy_kcal_100g'], 'unit': 'kcal', 'icon': Icons.local_fire_department, 'color': Colors.orange},
      {'label': 'Protein', 'value': nutrition['proteins_100g'], 'unit': 'g', 'icon': Icons.fitness_center, 'color': Colors.green},
      {'label': 'Carbohydrates', 'value': nutrition['carbohydrates_100g'], 'unit': 'g', 'icon': Icons.grain, 'color': Colors.brown},
      {'label': 'Sugar', 'value': nutrition['sugars_100g'], 'unit': 'g', 'icon': Icons.cake, 'color': Colors.pink},
      {'label': 'Fat', 'value': nutrition['fat_100g'], 'unit': 'g', 'icon': Icons.water_drop, 'color': Colors.blue},
      {'label': 'Saturated Fat', 'value': nutrition['saturated_fat_100g'], 'unit': 'g', 'icon': Icons.opacity, 'color': Colors.red},
    ];

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Detailed Nutrition Information (per 100g)', style: AppStyles.bodyBold),
          SizedBox(height: 20),
          ...nutritionItems.map((item) => _buildNutritionRow(
            item['label'] as String,
            item['value'],
            item['unit'] as String,
            item['icon'] as IconData,
            item['color'] as Color,
          )),
        ],
      ),
    );
  }

  Widget _buildNutritionRow(String label, dynamic value, String unit, IconData icon, Color color) {
    final displayValue = value != null ? '$value $unit' : '-- $unit';
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(label, style: AppStyles.bodyRegular),
          ),
          Text(
            displayValue,
            style: AppStyles.bodyBold,
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // 使用ProductAnalysis中的LLM数据而不是重新调用API
          _buildDetailedAnalysis(),
          SizedBox(height: 16),
          _buildSmartRecommendations(),
        ],
      ),
    );
  }

  Widget _buildDetailedAnalysis() {
    final hasDetailedAnalysis = _productAnalysis?.detailedAnalysis?.isNotEmpty == true;
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: AppColors.primary, size: 24),
              SizedBox(width: 8),
              Text('Detailed Analysis', style: AppStyles.bodyBold),
            ],
          ),
          SizedBox(height: 16),
          Text(
            hasDetailedAnalysis 
                ? _productAnalysis!.detailedAnalysis!
                : 'No detailed analysis available.',
            style: AppStyles.bodyRegular,
          ),
        ],
      ),
    );
  }

  Widget _buildSmartRecommendations() {
    final hasActionSuggestions = _productAnalysis?.actionSuggestions?.isNotEmpty == true;
    
    if (!hasActionSuggestions) {
      return Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(Icons.info_outline, color: AppColors.primary, size: 48),
            SizedBox(height: 16),
            Text(
              'Smart Recommendations',
              style: AppStyles.bodyBold.copyWith(color: AppColors.primary),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue.shade600, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'AI recommendations currently unavailable. The system needs more product data to provide personalized suggestions for this category.',
                      style: AppStyles.bodyRegular.copyWith(color: Colors.blue.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: AppColors.primary, size: 24),
              SizedBox(width: 8),
              Text('Smart Recommendations', style: AppStyles.bodyBold),
            ],
          ),
          SizedBox(height: 16),
          ..._productAnalysis!.actionSuggestions.asMap().entries.map((entry) {
            final index = entry.key;
            final suggestion = entry.value;
            return Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: AppStyles.bodyBold.copyWith(
                          color: AppColors.primary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      suggestion,
                      style: AppStyles.bodyRegular,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  int _calculateHealthScore() {
    if (_productData == null) return 50;
    
    int score = 50; // 基础分数
    
    // 根据营养成分调整分数
    final sugar = _productData!['sugars_100g'];
    final fat = _productData!['fat_100g'];
    final protein = _productData!['proteins_100g'];
    
    if (sugar != null) {
      if (sugar < 5) score += 10;
      else if (sugar > 20) score -= 20;
    }
    
    if (fat != null) {
      if (fat < 3) score += 10;
      else if (fat > 20) score -= 15;
    }
    
    if (protein != null) {
      if (protein > 10) score += 15;
    }
    
    // 过敏原影响
    if (_detectedAllergens.isNotEmpty) {
      score -= 30;
    }
    
    return score.clamp(0, 100);
  }

  Color _getScoreColor(int score) {
    if (score >= 70) return AppColors.success;
    if (score >= 40) return AppColors.warning;
    return AppColors.alert;
  }

  String _getScoreDescription(int score) {
    if (score >= 70) return '健康';
    if (score >= 40) return '一般';
    return '不建议';
  }

  String _getScoreExplanation(int score) {
    if (score >= 70) return '营养均衡，适合日常食用';
    if (score >= 40) return '营养一般，偶尔食用';
    return '营养不良或含有过敏原，建议避免';
  }

  void _shareProduct() {
    // TODO: 实现分享功能
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('分享功能开发中...')),
    );
  }
} 
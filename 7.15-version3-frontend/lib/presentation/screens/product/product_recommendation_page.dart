import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';
import '../../../services/api.dart';
import '../../../services/user_service.dart';
import 'product_detail_page.dart';

class ProductRecommendationPage extends StatefulWidget {
  const ProductRecommendationPage({Key? key}) : super(key: key);

  @override
  State<ProductRecommendationPage> createState() => _ProductRecommendationPageState();
}

class _ProductRecommendationPageState extends State<ProductRecommendationPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _personalizedRecommendations = [];
  List<Map<String, dynamic>> _healthyAlternatives = [];
  List<Map<String, dynamic>> _nutritionTips = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadRecommendations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRecommendations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userId = await UserService.instance.getCurrentUserId();
      if (userId == null) {
        setState(() {
          _error = '用户未登录';
          _isLoading = false;
        });
        return;
      }

      // 并行加载不同类型的推荐
      final futures = await Future.wait([
        _loadPersonalizedRecommendations(userId),
        _loadHealthyAlternatives(userId),
        _loadNutritionTips(userId),
      ]);

      setState(() {
        _personalizedRecommendations = futures[0];
        _healthyAlternatives = futures[1];
        _nutritionTips = futures[2];
        _isLoading = false;
      });

      print('✅ 加载推荐数据完成');
    } catch (e) {
      setState(() {
        _error = '加载推荐失败: $e';
        _isLoading = false;
      });
      print('❌ 加载推荐错误: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _loadPersonalizedRecommendations(int userId) async {
    try {
      // 根据用户偏好获取推荐产品
      final result = await searchProducts(name: '', page: 0, size: 10);
      if (result != null && result['content'] != null) {
        return List<Map<String, dynamic>>.from(result['content']).take(6).toList();
      }
    } catch (e) {
      print('❌ 加载个性化推荐错误: $e');
    }
    
    // 返回模拟数据
    return _getMockPersonalizedRecommendations();
  }

  Future<List<Map<String, dynamic>>> _loadHealthyAlternatives(int userId) async {
    try {
      // 获取健康替代产品
      final result = await searchProducts(name: 'healthy', page: 0, size: 8);
      if (result != null && result['content'] != null) {
        return List<Map<String, dynamic>>.from(result['content']).take(4).toList();
      }
    } catch (e) {
      print('❌ 加载健康替代品错误: $e');
    }
    
    // 返回模拟数据
    return _getMockHealthyAlternatives();
  }

  Future<List<Map<String, dynamic>>> _loadNutritionTips(int userId) async {
    // 营养建议通常是静态内容，可以基于用户偏好生成
    return _getMockNutritionTips();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          '产品推荐',
          style: AppStyles.h2.copyWith(color: AppColors.white),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.white),
            onPressed: _loadRecommendations,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.white,
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.white.withOpacity(0.7),
          tabs: [
            Tab(text: '为您推荐'),
            Tab(text: '健康替代'),
            Tab(text: '营养建议'),
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
            Text('加载推荐中...'),
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
              onPressed: _loadRecommendations,
              child: Text('重试'),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildPersonalizedTab(),
        _buildAlternativesTab(),
        _buildNutritionTipsTab(),
      ],
    );
  }

  Widget _buildPersonalizedTab() {
    return RefreshIndicator(
      onRefresh: _loadRecommendations,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              '基于您的偏好',
              '根据您的历史记录和偏好为您推荐',
              Icons.person,
            ),
            SizedBox(height: 16),
            if (_personalizedRecommendations.isEmpty)
              _buildEmptyState('暂无个性化推荐', '完善您的个人信息和偏好设置获得更好的推荐')
            else
              _buildProductGrid(_personalizedRecommendations),
          ],
        ),
      ),
    );
  }

  Widget _buildAlternativesTab() {
    return RefreshIndicator(
      onRefresh: _loadRecommendations,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              '健康替代品',
              '更健康的产品选择',
              Icons.health_and_safety,
            ),
            SizedBox(height: 16),
            if (_healthyAlternatives.isEmpty)
              _buildEmptyState('暂无健康替代品', '我们正在为您寻找更健康的选择')
            else
              _buildAlternativesList(_healthyAlternatives),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionTipsTab() {
    return RefreshIndicator(
      onRefresh: _loadRecommendations,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              '营养建议',
              '个性化的营养指导',
              Icons.lightbulb,
            ),
            SizedBox(height: 16),
            ..._nutritionTips.map((tip) => _buildNutritionTip(tip)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, IconData icon) {
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
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppStyles.bodyBold),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppStyles.bodyRegular.copyWith(
                    color: AppColors.textLight,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid(List<Map<String, dynamic>> products) {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final name = product['name'] ?? '未知产品';
    final brand = product['brand'] ?? '';
    final barcode = product['barcode'] ?? '';

    return Container(
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToProductDetail(barcode, product),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 产品图片占位符
                Container(
                  width: double.infinity,
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
                SizedBox(height: 12),
                // 产品名称
                Text(
                  name,
                  style: AppStyles.bodyBold.copyWith(fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (brand.isNotEmpty) ...[
                  SizedBox(height: 4),
                  Text(
                    brand,
                    style: AppStyles.bodyRegular.copyWith(
                      color: AppColors.textLight,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                Spacer(),
                // 健康评分
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '推荐',
                        style: AppStyles.bodyRegular.copyWith(
                          color: AppColors.success,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    Spacer(),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: AppColors.textLight,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlternativesList(List<Map<String, dynamic>> alternatives) {
    return Column(
      children: alternatives.map((alternative) => 
        _buildAlternativeCard(alternative)
      ).toList(),
    );
  }

  Widget _buildAlternativeCard(Map<String, dynamic> alternative) {
    final name = alternative['name'] ?? '未知产品';
    final brand = alternative['brand'] ?? '';
    final barcode = alternative['barcode'] ?? '';
    final reason = alternative['reason'] ?? '更健康的选择';

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToProductDetail(barcode, alternative),
          borderRadius: BorderRadius.circular(16),
          child: Row(
            children: [
              // 产品图片
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.inventory_2,
                  size: 30,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(width: 16),
              // 产品信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppStyles.bodyBold,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (brand.isNotEmpty) ...[
                      SizedBox(height: 2),
                      Text(
                        brand,
                        style: AppStyles.bodyRegular.copyWith(
                          color: AppColors.textLight,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.check_circle, 
                            size: 14, color: AppColors.success),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            reason,
                            style: AppStyles.bodyRegular.copyWith(
                              color: AppColors.success,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.textLight,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNutritionTip(Map<String, dynamic> tip) {
    final title = tip['title'] ?? '';
    final content = tip['content'] ?? '';
    final category = tip['category'] ?? '';
    final icon = _getNutritionTipIcon(category);
    final color = _getNutritionTipColor(category);

    return Container(
      margin: EdgeInsets.only(bottom: 16),
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
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: AppStyles.bodyBold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            content,
            style: AppStyles.bodyRegular,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Container(
      padding: EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.search_off, size: 80, color: AppColors.textLight),
            SizedBox(height: 16),
            Text(title, style: AppStyles.h2.copyWith(color: AppColors.textLight)),
            SizedBox(height: 8),
            Text(
              subtitle,
              style: AppStyles.bodyRegular.copyWith(color: AppColors.textLight),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToProductDetail(String barcode, Map<String, dynamic> productData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailPage(
          barcode: barcode.isNotEmpty ? barcode : null,
          productData: productData,
        ),
      ),
    );
  }

  IconData _getNutritionTipIcon(String category) {
    switch (category.toLowerCase()) {
      case 'protein':
        return Icons.fitness_center;
      case 'sugar':
        return Icons.cake;
      case 'fat':
        return Icons.water_drop;
      case 'fiber':
        return Icons.grass;
      case 'vitamins':
        return Icons.healing;
      default:
        return Icons.lightbulb;
    }
  }

  Color _getNutritionTipColor(String category) {
    switch (category.toLowerCase()) {
      case 'protein':
        return Colors.green;
      case 'sugar':
        return Colors.pink;
      case 'fat':
        return Colors.blue;
      case 'fiber':
        return Colors.brown;
      case 'vitamins':
        return Colors.purple;
      default:
        return AppColors.primary;
    }
  }

  // 模拟数据方法
  List<Map<String, dynamic>> _getMockPersonalizedRecommendations() {
    return [
      {
        'name': '有机杏仁奶',
        'brand': 'Alpro',
        'barcode': '5411188123456',
        'category': '饮品',
        'healthScore': 85,
      },
      {
        'name': '全麦面包',
        'brand': 'Brennans',
        'barcode': '5412345678901',
        'category': '烘焙',
        'healthScore': 78,
      },
      {
        'name': '希腊酸奶',
        'brand': 'Fage',
        'barcode': '5412345678902',
        'category': '乳制品',
        'healthScore': 90,
      },
      {
        'name': '藜麦沙拉',
        'brand': 'Tesco',
        'barcode': '5412345678903',
        'category': '沙拉',
        'healthScore': 92,
      },
    ];
  }

  List<Map<String, dynamic>> _getMockHealthyAlternatives() {
    return [
      {
        'name': '无糖燕麦饼干',
        'brand': 'Nairns',
        'barcode': '5412345678904',
        'reason': '比普通饼干减少60%糖分',
      },
      {
        'name': '椰子水',
        'brand': 'Vita Coco',
        'barcode': '5412345678905',
        'reason': '天然电解质，无添加糖',
      },
      {
        'name': '坚果混合装',
        'brand': 'Tesco',
        'barcode': '5412345678906',
        'reason': '富含健康脂肪和蛋白质',
      },
    ];
  }

  List<Map<String, dynamic>> _getMockNutritionTips() {
    return [
      {
        'title': '增加蛋白质摄入',
        'content': '根据您的活动量，建议每天摄入更多优质蛋白质。可以选择鱼类、豆类或坚果作为蛋白质来源。',
        'category': 'protein',
      },
      {
        'title': '控制糖分摄入',
        'content': '建议减少加工食品中的添加糖。选择新鲜水果代替含糖零食，有助于维持血糖稳定。',
        'category': 'sugar',
      },
      {
        'title': '增加膳食纤维',
        'content': '多吃全谷物、蔬菜和水果可以增加膳食纤维摄入，有助于消化健康和血糖控制。',
        'category': 'fiber',
      },
      {
        'title': '维生素补充',
        'content': '根据您的饮食习惯，建议增加富含维生素C和D的食物，如柑橘类水果和深海鱼类。',
        'category': 'vitamins',
      },
    ];
  }
} 
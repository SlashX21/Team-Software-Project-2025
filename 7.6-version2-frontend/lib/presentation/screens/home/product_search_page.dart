import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';
import '../../../services/api.dart';
import '../product/product_detail_page.dart';

class ProductSearchPage extends StatefulWidget {
  const ProductSearchPage({Key? key}) : super(key: key);

  @override
  State<ProductSearchPage> createState() => _ProductSearchPageState();
}

class _ProductSearchPageState extends State<ProductSearchPage>
    with TickerProviderStateMixin {
  // Search controller
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  // Basic search
  String _searchQuery = '';
  
  // Advanced filtering
  String? _selectedCategory;
  double _maxCalories = 1000;
  double _maxSugar = 50;
  double _minProtein = 0;
  double _maxFat = 100;
  double _minFiber = 0;
  Set<String> _excludedIngredients = {};
  Set<String> _preferredBrands = {};
  
  // Results and status
  bool _isLoading = false;
  List<Map<String, dynamic>> _searchResults = [];
  int _currentPage = 0;
  bool _hasMoreResults = true;
  String? _error;

  // Filter option data
  final List<String> _categories = [
    'Beverages', 'Snacks', 'Dairy', 'Bread', 'Meat', 'Vegetables', 'Fruits', 
    'Condiments', 'Frozen Foods', 'Canned Goods', 'Grains', 'Nuts', 'Candy', 'Others'
  ];

  final List<String> _commonIngredients = [
    'Artificial Colors', 'Preservatives', 'MSG', 'Artificial Sweeteners', 'Trans Fats', 
    'High Fructose Corn Syrup', 'Nitrates', 'Sulfites'
  ];

  final List<String> _popularBrands = [
    'Coca-Cola', 'Pepsi', 'Nestle', 'Unilever', 'P&G',
    'Kraft', 'General Mills', 'Kellogg\'s', 'Mars', 'Mondelez'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _performSearch({bool loadMore = false}) async {
    if (_searchQuery.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter search keywords'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (!loadMore) {
      setState(() {
        _isLoading = true;
        _searchResults.clear();
        _currentPage = 0;
        _hasMoreResults = true;
        _error = null;
      });
    }

    try {
      final result = await searchProducts(
        name: _searchQuery,
        page: _currentPage,
        size: 20,
      );

      if (result != null && result['content'] != null) {
        final newResults = List<Map<String, dynamic>>.from(result['content']);
        
        // Apply advanced filters
        final filteredResults = _applyAdvancedFilters(newResults);

        setState(() {
          if (loadMore) {
            _searchResults.addAll(filteredResults);
          } else {
            _searchResults = filteredResults;
          }
          _hasMoreResults = newResults.length == 20;
          _currentPage++;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _hasMoreResults = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Search failed: $e';
      });
    }
  }

  List<Map<String, dynamic>> _applyAdvancedFilters(List<Map<String, dynamic>> products) {
    return products.where((product) {
      // Category filter
      if (_selectedCategory != null && 
          product['category'] != _selectedCategory) {
        return false;
      }

      // Nutrition filter
      final calories = (product['energy_kcal_100g'] as num?)?.toDouble() ?? 0;
      final sugar = (product['sugars_100g'] as num?)?.toDouble() ?? 0;
      final protein = (product['proteins_100g'] as num?)?.toDouble() ?? 0;
      final fat = (product['fat_100g'] as num?)?.toDouble() ?? 0;
      final fiber = (product['fiber_100g'] as num?)?.toDouble() ?? 0;

      if (calories > _maxCalories || 
          sugar > _maxSugar || 
          protein < _minProtein ||
          fat > _maxFat ||
          fiber < _minFiber) {
        return false;
      }

      // Avoid ingredient filter
      final ingredients = (product['ingredients'] as String?)?.toLowerCase() ?? '';
      for (String ingredient in _excludedIngredients) {
        if (ingredients.contains(ingredient.toLowerCase())) {
          return false;
        }
      }

      // Brand preference filter
      if (_preferredBrands.isNotEmpty) {
        final brand = (product['brand'] as String?)?.toLowerCase() ?? '';
        bool hasPreferredBrand = false;
        for (String preferredBrand in _preferredBrands) {
          if (brand.contains(preferredBrand.toLowerCase())) {
            hasPreferredBrand = true;
            break;
          }
        }
        if (!hasPreferredBrand) return false;
      }

      return true;
    }).toList();
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = null;
      _maxCalories = 1000;
      _maxSugar = 50;
      _minProtein = 0;
      _maxFat = 100;
      _minFiber = 0;
      _excludedIngredients.clear();
      _preferredBrands.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Product Search',
          style: AppStyles.h2.copyWith(color: AppColors.white),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.white,
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.white.withOpacity(0.7),
          tabs: [
            Tab(text: 'Basic Search'),
            Tab(text: 'Advanced Filter'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBasicSearchTab(),
                _buildAdvancedFilterTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.all(16),
      color: AppColors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search product name, brand or keywords...',
                prefixIcon: Icon(Icons.search, color: AppColors.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
              onChanged: (value) => _searchQuery = value,
              onSubmitted: (_) => _performSearch(),
            ),
          ),
          SizedBox(width: 12),
          ElevatedButton(
            onPressed: _isLoading ? null : () => _performSearch(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading 
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                    ),
                  )
                : Icon(Icons.search, color: AppColors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicSearchTab() {
    return RefreshIndicator(
      onRefresh: () => _performSearch(),
      child: _buildSearchResults(),
    );
  }

  Widget _buildAdvancedFilterTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildCategoryFilter(),
          SizedBox(height: 16),
          _buildNutritionFilters(),
          SizedBox(height: 16),
          _buildIngredientFilter(),
          SizedBox(height: 16),
          _buildBrandFilter(),
          SizedBox(height: 24),
          _buildFilterActions(),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
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
          Text('Product Categories', style: AppStyles.bodyBold),
          SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((category) {
              final isSelected = _selectedCategory == category;
              return FilterChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedCategory = selected ? category : null;
                  });
                },
                selectedColor: AppColors.primary.withOpacity(0.2),
                checkmarkColor: AppColors.primary,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionFilters() {
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
          Text('Nutrition Filters', style: AppStyles.bodyBold),
          SizedBox(height: 16),
          _buildSliderFilter(
            'Max Calories',
            _maxCalories,
            0,
            1000,
            'kcal',
            (value) => setState(() => _maxCalories = value),
          ),
          _buildSliderFilter(
            'Max Sugar',
            _maxSugar,
            0,
            100,
            'g',
            (value) => setState(() => _maxSugar = value),
          ),
          _buildSliderFilter(
            'Min Protein',
            _minProtein,
            0,
            50,
            'g',
            (value) => setState(() => _minProtein = value),
          ),
          _buildSliderFilter(
            'Max Fat',
            _maxFat,
            0,
            100,
            'g',
            (value) => setState(() => _maxFat = value),
          ),
          _buildSliderFilter(
            'Min Fiber',
            _minFiber,
            0,
            30,
            'g',
            (value) => setState(() => _minFiber = value),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderFilter(
    String label,
    double value,
    double min,
    double max,
    String unit,
    ValueChanged<double> onChanged,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: AppStyles.bodyRegular),
              Text(
                '${value.round()} $unit',
                style: AppStyles.bodyBold.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: ((max - min) / (max > 50 ? 10 : 1)).round(),
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientFilter() {
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
          Text('Avoided Ingredients', style: AppStyles.bodyBold),
          SizedBox(height: 8),
          Text(
            'Select ingredients you want to avoid',
            style: AppStyles.bodyRegular.copyWith(color: AppColors.textLight),
          ),
          SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _commonIngredients.map((ingredient) {
              final isSelected = _excludedIngredients.contains(ingredient);
              return FilterChip(
                label: Text(ingredient),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _excludedIngredients.add(ingredient);
                    } else {
                      _excludedIngredients.remove(ingredient);
                    }
                  });
                },
                selectedColor: AppColors.alert.withOpacity(0.2),
                checkmarkColor: AppColors.alert,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandFilter() {
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
          Text('Preferred Brands', style: AppStyles.bodyBold),
          SizedBox(height: 8),
          Text(
            'Select your preferred brands (multiple selection allowed)',
            style: AppStyles.bodyRegular.copyWith(color: AppColors.textLight),
          ),
          SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _popularBrands.map((brand) {
              final isSelected = _preferredBrands.contains(brand);
              return FilterChip(
                label: Text(brand),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _preferredBrands.add(brand);
                    } else {
                      _preferredBrands.remove(brand);
                    }
                  });
                },
                selectedColor: AppColors.success.withOpacity(0.2),
                checkmarkColor: AppColors.success,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _clearFilters,
            icon: Icon(Icons.clear_all),
            label: Text('Clear Filters'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textLight,
              side: BorderSide(color: AppColors.textLight),
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              _tabController.animateTo(0); // Switch to search results tab
              _performSearch();
            },
            icon: Icon(Icons.filter_alt),
            label: Text('Apply Filters'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.alert),
            SizedBox(height: 16),
            Text('Search Error', style: AppStyles.h2.copyWith(color: AppColors.alert)),
            SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _performSearch(),
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: AppColors.textLight),
            SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty ? 'Enter keywords to start searching' : 'No related products found',
              style: AppStyles.h2.copyWith(color: AppColors.textLight),
            ),
            SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty 
                  ? 'Use the search box above or advanced filters to find products'
                  : 'Try adjusting search conditions or filters',
              style: AppStyles.bodyRegular.copyWith(color: AppColors.textLight),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (!_isLoading && 
            _hasMoreResults &&
            scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
          _performSearch(loadMore: true);
        }
        return false;
      },
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _searchResults.length + (_hasMoreResults ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _searchResults.length) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
          }

          final product = _searchResults[index];
          return _buildProductCard(product);
        },
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final name = product['name'] ?? product['productName'] ?? 'Unknown Product';
    final brand = product['brand'] ?? '';
    final barcode = product['barcode'] ?? '';
    final category = product['category'] ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: 12),
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
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailPage(
                barcode: barcode.isNotEmpty ? barcode : null,
                productData: product,
              ),
            ),
          ),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // 产品图标
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
                      SizedBox(height: 8),
                      Row(
                        children: [
                          if (category.isNotEmpty) ...[
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
                SizedBox(width: 8),
                          ],
                          if (barcode.isNotEmpty)
                            Text(
                              barcode,
                              style: AppStyles.bodyRegular.copyWith(
                                color: AppColors.textLight,
                                fontSize: 12,
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
      ),
    );
  }
} 
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';
import '../../../domain/entities/monthly_overview.dart';
import '../../../services/api.dart';
import '../../../services/user_service.dart';

class MonthlyOverviewScreen extends StatefulWidget {
  const MonthlyOverviewScreen({Key? key}) : super(key: key);

  @override
  _MonthlyOverviewScreenState createState() => _MonthlyOverviewScreenState();
}

class _MonthlyOverviewScreenState extends State<MonthlyOverviewScreen> {
  MonthlyOverviewPageState _pageState = MonthlyOverviewPageState();

  @override
  void initState() {
    super.initState();
    _loadMonthlyData();
  }

  Future<void> _loadMonthlyData() async {
    setState(() => _pageState = _pageState.copyWith(isLoading: true));

    try {
      final userId = await UserService.instance.getCurrentUserId();
      if (userId == null) {
        setState(() {
          _pageState = _pageState.copyWith(
            isLoading: false,
            error: 'User not logged in',
          );
        });
        return;
      }

      final overview = await getMonthlyOverview(
        userId: userId,
        year: DateTime.now().year,
        month: DateTime.now().month,
      );

      if (overview != null) {
        setState(() {
          _pageState = _pageState.copyWith(
            isLoading: false,
            overview: overview,
            // 暂时使用默认数据，等待后端API完善
            purchaseSummary: null,
            nutritionInsights: null,
            healthInsights: [],
          );
        });
      } else {
        setState(() {
          _pageState = _pageState.copyWith(
            isLoading: false,
            error: 'Unable to load monthly data',
          );
        });
      }
    } catch (e) {
      setState(() {
        _pageState = _pageState.copyWith(
          isLoading: false,
          error: 'Load failed: $e',
        );
      });
    }
  }

  void _onMonthChanged(DateTime date) {
    _loadMonthlyData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Monthly Overview', style: AppStyles.h2.copyWith(color: AppColors.white)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: BackButton(color: AppColors.white),
      ),
      body: _pageState.isLoading
          ? _buildLoadingState()
          : _pageState.error != null
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          SizedBox(height: 16),
          Text(
            'Loading monthly data...',
            style: AppStyles.bodyRegular,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.alert,
          ),
          SizedBox(height: 16),
          Text(
            'Failed to load data',
            style: AppStyles.h2.copyWith(color: AppColors.alert),
          ),
          SizedBox(height: 8),
          Text(
            _pageState.error ?? 'Unknown error',
            style: AppStyles.bodyRegular,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadMonthlyData,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Retry', style: AppStyles.buttonText),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMonthSelector(),
          SizedBox(height: 16),
          if (_pageState.overview != null) _buildOverviewCard(),
          SizedBox(height: 16),
          if (_pageState.purchaseSummary != null) _buildPurchaseSummaryCard(),
          SizedBox(height: 16),
          if (_pageState.nutritionInsights != null) _buildNutritionInsightsCard(),
          SizedBox(height: 16),
          if (_pageState.healthInsights.isNotEmpty) _buildHealthInsightsCard(),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    final monthNames = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_month, color: AppColors.primary),
          SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: '${monthNames[DateTime.now().month]} ${DateTime.now().year}',
                onChanged: (value) {
                  // Handle month selection
                },
                style: AppStyles.bodyBold,
                items: [
                  DropdownMenuItem(
                    value: '${monthNames[DateTime.now().month]} ${DateTime.now().year}',
                    child: Text('${monthNames[DateTime.now().month]} ${DateTime.now().year}'),
                  ),
                ],
              ),
            ),
          ),
          Icon(Icons.arrow_drop_down, color: AppColors.textLight),
        ],
      ),
    );
  }

  Widget _buildOverviewCard() {
    final overview = _pageState.overview!;
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            overview.formattedMonth,
            style: AppStyles.h2.copyWith(color: AppColors.white),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildOverviewStat('Receipt Uploads', '${overview.receiptUploads} times'),
              ),
              Expanded(
                child: _buildOverviewStat('Products Purchased', '${overview.totalProducts} items'),
              ),
            ],
          ),
          SizedBox(height: 12),
          _buildOverviewStat('Total Spent', overview.formattedSpent),
        ],
      ),
    );
  }

  Widget _buildOverviewStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppStyles.bodyRegular.copyWith(
            color: AppColors.white.withOpacity(0.8),
            fontSize: 14,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: AppStyles.bodyBold.copyWith(
            color: AppColors.white,
            fontSize: 18,
          ),
        ),
      ],
    );
  }

  Widget _buildPurchaseSummaryCard() {
    final summary = _pageState.purchaseSummary!;
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('📊', style: TextStyle(fontSize: 24)),
              SizedBox(width: 8),
              Text('Purchase Summary', style: AppStyles.h2),
            ],
          ),
          SizedBox(height: 16),
          ...summary.categoryBreakdown.map((category) => _buildCategoryItem(category)),
          SizedBox(height: 16),
          Text('Top Products', style: AppStyles.bodyBold),
          SizedBox(height: 8),
          ...summary.popularProducts.take(3).map((product) => _buildPopularProductItem(product)),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(CategorySummary category) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(category.iconName, style: TextStyle(fontSize: 20)),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category.categoryName, style: AppStyles.bodyBold),
                SizedBox(height: 4),
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: AppColors.background,
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: category.percentage / 100,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          Text('${category.percentage.toInt()}%', style: AppStyles.bodyBold),
        ],
      ),
    );
  }

  Widget _buildPopularProductItem(PopularProduct product) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(product.productName, style: AppStyles.bodyRegular),
          ),
          Text('${product.purchaseCount} times', style: AppStyles.bodyRegular.copyWith(color: AppColors.textLight)),
        ],
      ),
    );
  }

  Widget _buildNutritionInsightsCard() {
    final insights = _pageState.nutritionInsights!;
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('🍎', style: TextStyle(fontSize: 24)),
              SizedBox(width: 8),
              Text('Nutrition Insights', style: AppStyles.h2),
            ],
          ),
          SizedBox(height: 16),
          ...insights.nutritionBreakdown.entries.map((entry) => _buildNutritionMetricItem(entry.key, entry.value)),
        ],
      ),
    );
  }

  Widget _buildNutritionMetricItem(String name, NutritionMetric metric) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: AppStyles.bodyBold),
              Row(
                children: [
                  Text('${metric.percentage.toInt()}%', style: AppStyles.bodyBold),
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: metric.statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      metric.statusText,
                      style: TextStyle(
                        color: metric.statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 8),
          Container(
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: AppColors.background,
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: metric.percentage / 100,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: metric.statusColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthInsightsCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('💡', style: TextStyle(fontSize: 24)),
              SizedBox(width: 8),
              Text('This Month\'s Insights', style: AppStyles.h2),
            ],
          ),
          SizedBox(height: 16),
          ..._pageState.healthInsights.map((insight) => _buildHealthInsightItem(insight)),
        ],
      ),
    );
  }

  Widget _buildHealthInsightItem(HealthInsight insight) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 4,
            margin: EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              '"${insight.description}"',
              style: AppStyles.bodyRegular.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MonthlyOverviewPageState {
  final bool isLoading;
  final MonthlyOverview? overview;
  final MonthlypurchaseSummary? purchaseSummary;
  final MonthlyNutritionInsights? nutritionInsights;
  final List<HealthInsight> healthInsights;
  final int selectedYear;
  final int selectedMonth;
  final String? error;

  MonthlyOverviewPageState({
    this.isLoading = false,
    this.overview,
    this.purchaseSummary,
    this.nutritionInsights,
    this.healthInsights = const [],
    int? selectedYear,
    int? selectedMonth,
    this.error,
  }) : selectedYear = selectedYear ?? DateTime.now().year,
       selectedMonth = selectedMonth ?? DateTime.now().month;

  MonthlyOverviewPageState copyWith({
    bool? isLoading,
    MonthlyOverview? overview,
    MonthlypurchaseSummary? purchaseSummary,
    MonthlyNutritionInsights? nutritionInsights,
    List<HealthInsight>? healthInsights,
    int? selectedYear,
    int? selectedMonth,
    String? error,
  }) {
    return MonthlyOverviewPageState(
      isLoading: isLoading ?? this.isLoading,
      overview: overview ?? this.overview,
      purchaseSummary: purchaseSummary ?? this.purchaseSummary,
      nutritionInsights: nutritionInsights ?? this.nutritionInsights,
      healthInsights: healthInsights ?? this.healthInsights,
      selectedYear: selectedYear ?? this.selectedYear,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      error: error ?? this.error,
    );
  }
}
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';
import '../../../domain/entities/monthly_overview.dart';
import '../../../domain/entities/history_response.dart' as history_response;
import '../../../domain/entities/receipt_history_item.dart';
import '../../../domain/entities/paged_response.dart';
import '../../../domain/entities/scan_history_response.dart';
import '../../../services/api.dart';
import '../../../services/user_service.dart';
import '../../../services/receipt_history_service.dart';
import '../history/history_detail_page.dart';
import '../history/scan_history_detail_page.dart';
import '../history/receipt_detail_page.dart';
import '../../../domain/entities/scan_history_item.dart';

// Helper class for scan history merging
class MergedScanItem {
  final String id;
  final String productName;
  int scanCount;
  DateTime latestTimestamp;
  String latestItemId;

  MergedScanItem({
    required this.id,
    required this.productName,
    required this.scanCount,
    required this.latestTimestamp,
    required this.latestItemId,
  });
}

class MonthlyOverviewScreen extends StatefulWidget {
  final int userId;
  
  const MonthlyOverviewScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _MonthlyOverviewScreenState createState() => _MonthlyOverviewScreenState();
}

class _MonthlyOverviewScreenState extends State<MonthlyOverviewScreen> {
  MonthlyOverviewPageState _pageState = MonthlyOverviewPageState();
  bool _isShowingScanHistory = true;
  List<history_response.HistoryItem> _scanHistory = [];
  List<history_response.HistoryItem> _receiptHistory = [];
  bool _isLoadingHistory = false;
  
  // 分页相关变量
  int _currentHistoryPage = 1;
  final int _historyPageSize = 10;
  bool _hasMoreHistory = true;

  @override
  void initState() {
    super.initState();
    _loadMonthlyDataAndHistory();
  }
  
  Future<void> _loadMonthlyDataAndHistory() async {
    // First load monthly data to set the overview state
    await _loadMonthlyData();
    // Then load history data which depends on the overview state
    await _loadHistoryData();
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

      // 创建简化的月度概览，只包含年月信息
      // 统计数据将通过 _updateMonthlyStats 方法异步更新
      final now = DateTime.now();
      final monthNames = [
        '', 'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      
      final simpleOverview = MonthlyOverview(
        year: now.year,
        month: now.month,
        monthName: monthNames[now.month],
        receiptUploads: 0, // 将通过 _updateMonthlyStats 更新
        scanTimes: 0,      // 将通过 _updateMonthlyStats 更新
        totalProducts: 0,  // 不再使用
        totalSpent: 0.0,   // 不再使用
      );

      setState(() {
        _pageState = _pageState.copyWith(
          isLoading: false,
          overview: simpleOverview,
          // 暂时使用默认数据，等待后端API完善
          purchaseSummary: null,
          nutritionInsights: null,
          healthInsights: [],
        );
      });
    } catch (e) {
      setState(() {
        _pageState = _pageState.copyWith(
          isLoading: false,
          error: 'Load failed: $e',
        );
      });
    }
  }

  Future<void> _loadHistoryData() async {
    setState(() => _isLoadingHistory = true);

    try {
      final userId = await UserService.instance.getCurrentUserId();
      if (userId == null) {
        setState(() {
          _isLoadingHistory = false;
        });
        return;
      }


      // ✅ Correct: Parallel calls to both SCAN_HISTORY and RECEIPT_HISTORY tables
      // Use selected month if available, otherwise default to current month
      final now = DateTime.now();
      final selectedMonth = _pageState.overview != null 
          ? '${_pageState.overview!.year}-${_pageState.overview!.month.toString().padLeft(2, '0')}'
          : '${now.year}-${now.month.toString().padLeft(2, '0')}';
      
      print('📅 Loading history for month: $selectedMonth');
      print('📊 PageState overview: ${_pageState.overview != null ? "Year: ${_pageState.overview!.year}, Month: ${_pageState.overview!.month}" : "null"}');
      
      final scanHistoryFuture = getScanHistoryList(
        userId: userId,
        page: 1,
        limit: 10,
        month: selectedMonth,
      );
      
      final receiptHistoryFuture = ReceiptHistoryService().getReceiptHistory(
        userId: userId,
        page: 1,
        limit: 10,
        month: selectedMonth,
      );

      // Wait for both API calls to complete
      final results = await Future.wait([scanHistoryFuture, receiptHistoryFuture]);
      
      final scanResponse = results[0] as ScanHistoryResponse?;
      final receiptResponse = results[1] as PagedResponse<ReceiptHistoryItem>?;

      // Convert scan history response to HistoryItem format with deduplication
      List<history_response.HistoryItem> scanHistoryItems = [];
      if (scanResponse != null && scanResponse.items.isNotEmpty) {
        final rawScanItems = scanResponse.items.map((item) {
          return history_response.HistoryItem(
            id: item.scanId.toString(),
            productName: item.productName ?? 'Unknown Product',
            scanType: 'scan',
            createdAt: item.scannedAt,
            summary: {},
            recommendationCount: 0,
          );
        }).toList();
        
        // Apply merge logic for deduplication
        scanHistoryItems = _mergeScanHistory(rawScanItems);
      }

      // Convert receipt history response to HistoryItem format with optimized display
      List<history_response.HistoryItem> receiptHistoryItems = [];
      if (receiptResponse != null && receiptResponse.data != null) {
        print('📝 Received ${receiptResponse.data.length} receipt items from API');
        
        receiptHistoryItems = receiptResponse.data.map((item) {
          print('🧾 Receipt item: ${item.displayTitle}, Date: ${item.scanTime}');
          
          // Use the optimized smart summary format from ReceiptHistoryItem
          final optimizedTitle = _formatReceiptSummary(item.displayTitle, item.itemCount);
          
          return history_response.HistoryItem(
            id: item.receiptId.toString(),
            productName: optimizedTitle,
            scanType: 'receipt',
            createdAt: item.scanTime,
            summary: {},
            recommendationCount: 0,
          );
        }).toList();
      } else {
        print('❌ No receipt response data received');
      }


      setState(() {
        _scanHistory = scanHistoryItems;
        _receiptHistory = receiptHistoryItems;
        _isLoadingHistory = false;
      });

      // Update monthly statistics with separate API calls
      await _updateMonthlyStats(userId);
      
    } catch (e) {
      setState(() {
        _scanHistory = [];
        _receiptHistory = [];
        _isLoadingHistory = false;
      });
    }
  }

  Future<void> _updateMonthlyStats(int userId) async {
    try {
      final currentMonth = '${_pageState.overview!.year}-${_pageState.overview!.month.toString().padLeft(2, '0')}';
      
      
      // ✅ Correct: Separate statistics from both tables
      final scanCountFuture = getMonthlyScanCount(userId: userId, month: currentMonth);
      final receiptCountFuture = getMonthlyReceiptCount(userId: userId, month: currentMonth);
      
      final counts = await Future.wait([scanCountFuture, receiptCountFuture]);
      
      final scanCount = counts[0];
      final receiptCount = counts[1];


      if (_pageState.overview != null) {
        final updatedOverview = MonthlyOverview(
          year: _pageState.overview!.year,
          month: _pageState.overview!.month,
          receiptUploads: receiptCount,    // From RECEIPT_HISTORY COUNT(*)
          scanTimes: scanCount,            // From SCAN_HISTORY COUNT(*)
          totalProducts: _pageState.overview!.totalProducts,
          totalSpent: _pageState.overview!.totalSpent,
          monthName: _pageState.overview!.monthName,
        );
        
        setState(() {
          _pageState = _pageState.copyWith(overview: updatedOverview);
        });
        
      }
    } catch (e) {
    }
  }

  void _onMonthChanged(DateTime date) {
    final monthNames = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    
    setState(() {
      _pageState = _pageState.copyWith(
        overview: MonthlyOverview(
          year: date.year,
          month: date.month,
          monthName: monthNames[date.month],
          receiptUploads: 0,
          scanTimes: 0,
          totalProducts: 0,
          totalSpent: 0.0,
        ),
      );
    });
    // Don't call _loadMonthlyData() as it will override the selected month with current month
    // Instead directly load history data and update stats for the selected month
    _loadHistoryData();
  }

  Future<void> _refreshHistory() async {
    setState(() {
      _scanHistory = [];
      _receiptHistory = [];
      _isLoadingHistory = true;
    });
    await _loadHistoryData();
  }

  void _toggleHistoryView() {
    setState(() {
      _isShowingScanHistory = !_isShowingScanHistory;
      _currentHistoryPage = 1; // 切换历史类型时重置到第一页
    });
  }

  void _goToHistoryPage(int page) {
    setState(() {
      _currentHistoryPage = page;
    });
  }

  void _previousHistoryPage() {
    if (_currentHistoryPage > 1) {
      _goToHistoryPage(_currentHistoryPage - 1);
    }
  }

  void _nextHistoryPage(int totalPages) {
    if (_currentHistoryPage < totalPages) {
      _goToHistoryPage(_currentHistoryPage + 1);
    }
  }


  void _onHistoryItemTap(history_response.HistoryItem item) {
    if (item.scanType == 'receipt') {
      // Navigate to receipt detail page
      final receiptId = int.tryParse(item.id) ?? 0;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReceiptDetailPage(receiptId: receiptId),
        ),
      );
    } else {
      // Navigate to scan history detail page (for barcode scans)
      final scanHistoryItem = ScanHistoryItem(
        scanId: int.tryParse(item.id) ?? 0,
        productName: item.productName,
        brand: null,
        scannedAt: item.createdAt,
      );
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ScanHistoryDetailPage(scanHistoryItem: scanHistoryItem),
        ),
      );
    }
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
          SizedBox(height: 16),
          _buildHistorySection(),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    final monthNames = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    final currentYear = DateTime.now().year;
    final currentValue = _pageState.overview != null 
        ? '${monthNames[_pageState.overview!.month]} ${_pageState.overview!.year}'
        : '${monthNames[DateTime.now().month]} ${currentYear}';

    // Generate options for current month and last few months (limit to current year)
    List<DropdownMenuItem<String>> items = [];
    final now = DateTime.now();
    for (int i = 0; i <= now.month - 1; i++) { // Only go back to January of current year
      final monthIndex = now.month - i;
      if (monthIndex > 0) { // Ensure valid month index
        final date = DateTime(now.year, monthIndex, 1);
        final value = '${monthNames[date.month]} ${date.year}';
        items.add(
          DropdownMenuItem(
            value: value,
            child: Text(value),
          ),
        );
      }
    }

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
                value: currentValue,
                onChanged: (value) {
                  if (value != null) {
                    // Parse the selected month and year
                    final parts = value.split(' ');
                    final monthName = parts[0];
                    final year = int.parse(parts[1]);
                    final month = monthNames.indexOf(monthName);
                    
                    // Call the month changed callback
                    _onMonthChanged(DateTime(year, month, 1));
                  }
                },
                style: AppStyles.bodyBold,
                items: items,
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
                child: _buildOverviewStat('Scan Times', '${overview.scanTimes} times'),
              ),
            ],
          ),
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

  Widget _buildHistorySection() {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      _isShowingScanHistory ? Icons.qr_code_scanner : Icons.receipt_long,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _isShowingScanHistory ? 'Scan History' : 'Receipt History',
                        style: AppStyles.h2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: _refreshHistory,
                    icon: Icon(Icons.refresh, color: AppColors.primary),
                    tooltip: 'Refresh History',
                    padding: EdgeInsets.all(8),
                    constraints: BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
                  SizedBox(width: 4),
                  IconButton(
                    onPressed: _toggleHistoryView,
                    icon: Icon(
                      _isShowingScanHistory ? Icons.receipt_long : Icons.qr_code_scanner,
                      color: AppColors.primary,
                    ),
                    tooltip: _isShowingScanHistory ? 'Switch to Receipt History' : 'Switch to Scan History',
                    padding: EdgeInsets.all(8),
                    constraints: BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16),
          _isLoadingHistory
              ? _buildHistoryLoadingState()
              : _buildHistoryContent(),
        ],
      ),
    );
  }

  Widget _buildHistoryLoadingState() {
    return Container(
      height: 200,
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ),
    );
  }

  /// 客户端过滤历史数据，确保只显示选定月份的数据
  List<history_response.HistoryItem> _filterHistoryBySelectedMonth(List<history_response.HistoryItem> items) {
    if (_pageState.overview == null || items.isEmpty) {
      return items;
    }
    
    final selectedYear = _pageState.overview!.year;
    final selectedMonth = _pageState.overview!.month;
    
    return items.where((item) {
      final itemDate = item.createdAt;
      final isInSelectedMonth = itemDate.year == selectedYear && itemDate.month == selectedMonth;
      
      if (!isInSelectedMonth) {
        print('🚫 Filtering out item from ${itemDate.year}-${itemDate.month.toString().padLeft(2, '0')}: ${item.productName}');
      }
      
      return isInSelectedMonth;
    }).toList();
  }

  Widget _buildHistoryContent() {
    final allHistoryItems = _isShowingScanHistory ? _scanHistory : _receiptHistory;
    
    // 客户端额外过滤：确保显示的数据属于选定的月份
    final historyItems = _filterHistoryBySelectedMonth(allHistoryItems);
    
    
    if (historyItems.isEmpty) {
      return Container(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isShowingScanHistory ? Icons.qr_code_scanner : Icons.receipt_long,
                size: 48,
                color: AppColors.textLight,
              ),
              SizedBox(height: 16),
              Text(
                _isShowingScanHistory 
                    ? 'No scan history found' 
                    : 'No receipt history found',
                style: AppStyles.bodyRegular.copyWith(color: AppColors.textLight),
              ),
              SizedBox(height: 8),
              Text(
                _isShowingScanHistory 
                    ? 'Total scan items: ${_scanHistory.length}, Filtered: ${historyItems.length}'
                    : 'Total receipt items: ${_receiptHistory.length}, Filtered: ${historyItems.length}',
                style: AppStyles.bodyRegular.copyWith(
                  color: AppColors.textLight,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 计算当前页的历史项目
    final startIndex = (_currentHistoryPage - 1) * _historyPageSize;
    final endIndex = startIndex + _historyPageSize;
    final currentPageItems = historyItems.skip(startIndex).take(_historyPageSize).toList();
    final totalPages = (historyItems.length / _historyPageSize).ceil();
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Showing ${currentPageItems.length} of ${historyItems.length} ${_isShowingScanHistory ? "scan" : "receipt"} items',
              style: AppStyles.bodyRegular.copyWith(
                color: AppColors.textLight,
                fontSize: 12,
              ),
            ),
            if (totalPages > 1)
              Text(
                'Page $_currentHistoryPage of $totalPages',
                style: AppStyles.bodyRegular.copyWith(
                  color: AppColors.textLight,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        SizedBox(height: 8),
        ...currentPageItems.map((item) => _buildHistoryItem(item)).toList(),
        if (totalPages > 1) ...[
          SizedBox(height: 16),
          _buildPaginationControls(totalPages),
        ],
      ],
    );
  }

  Widget _buildHistoryItem(history_response.HistoryItem item) {
    // Determine subtitle based on scan type
    String subtitle;
    if (item.scanType == 'scan') {
      subtitle = 'Last scanned: ${_getFormattedScanDate(item.createdAt)}';
    } else {
      subtitle = _getFormattedScanDate(item.createdAt);
    }
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onHistoryItemTap(item),
          borderRadius: BorderRadius.circular(8),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Text(
              item.productName ?? 'Unknown Product',
              style: AppStyles.bodyBold.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                subtitle,
                style: AppStyles.bodyRegular.copyWith(
                  color: AppColors.textLight,
                  fontSize: 12,
                ),
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textLight,
              size: 16,
            ),
          ),
        ),
      ),
    );
  }


  // Smart timestamp display logic
  String _getFormattedScanDate(DateTime scanDate) {
    final now = DateTime.now();
    final difference = now.difference(scanDate);
    
    // Check if it's the same day
    final isSameDay = now.year == scanDate.year && 
                      now.month == scanDate.month && 
                      now.day == scanDate.day;
    
    if (isSameDay) {
      // Show relative time for today's records
      if (difference.inMinutes <= 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} minutes ago';
      } else {
        return '${difference.inHours} hours ago';
      }
    } else {
      // Show specific date for non-today records
      return '${scanDate.day.toString().padLeft(2, '0')}/${scanDate.month.toString().padLeft(2, '0')}/${scanDate.year}';
    }
  }

  // Smart product name formatting for consistent display
  String _formatProductName(String productName, {int maxLength = 20}) {
    if (productName.length <= maxLength) {
      return productName;
    }
    return '${productName.substring(0, maxLength - 3)}...';
  }

  // Smart receipt summary formatting according to optimization requirements
  String _formatReceiptSummary(String displayTitle, int totalItems) {
    final items = displayTitle.split(', ').map((item) => item.trim()).where((item) => item.isNotEmpty).toList();
    
    if (items.isEmpty) {
      return 'Receipt';
    }
    
    if (items.length == 1) {
      return _formatProductName(items.first);
    }
    
    // Get the first product name
    final firstProduct = items.first;
    final truncatedFirstProduct = firstProduct.length > 15 
        ? '${firstProduct.substring(0, 15)}...' 
        : firstProduct;
    
    // Format according to optimization: "[First Product] (+X items)"
    final remainingCount = totalItems - 1;
    if (remainingCount > 0) {
      return '$truncatedFirstProduct (+$remainingCount item${remainingCount > 1 ? 's' : ''})';
    } else {
      return truncatedFirstProduct;
    }
  }

  // Scan history merge logic for deduplication
  List<history_response.HistoryItem> _mergeScanHistory(List<history_response.HistoryItem> rawScanHistory) {
    Map<String, MergedScanItem> mergedMap = {};
    
    for (var item in rawScanHistory) {
      String productName = item.productName ?? 'Unknown Product';
      
      if (mergedMap.containsKey(productName)) {
        // Product already exists, increment scan count and update latest timestamp
        var existing = mergedMap[productName]!;
        existing.scanCount++;
        
        if (item.createdAt.isAfter(existing.latestTimestamp)) {
          existing.latestTimestamp = item.createdAt;
          existing.latestItemId = item.id; // Keep the latest scan's ID for navigation
        }
      } else {
        // New product, initialize with scan count of 1
        mergedMap[productName] = MergedScanItem(
          id: item.id,
          productName: productName,
          scanCount: 1,
          latestTimestamp: item.createdAt,
          latestItemId: item.id,
        );
      }
    }
    
    // Convert back to HistoryItem list and sort by latest scan time
    return mergedMap.values.map((mergedItem) {
      // Format display name with scan count
      final displayName = mergedItem.scanCount > 1 
          ? '${_formatProductName(mergedItem.productName)} (Scanned ${mergedItem.scanCount} times)'
          : _formatProductName(mergedItem.productName);
      
      return history_response.HistoryItem(
        id: mergedItem.latestItemId,
        productName: displayName,
        scanType: 'scan',
        createdAt: mergedItem.latestTimestamp,
        summary: {},
        recommendationCount: 0,
      );
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Sort by latest scan time
  }

  Widget _buildPaginationControls(int totalPages) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 上一页按钮
          IconButton(
            onPressed: _currentHistoryPage > 1 ? _previousHistoryPage : null,
            icon: Icon(
              Icons.chevron_left,
              color: _currentHistoryPage > 1 ? AppColors.primary : AppColors.textLight,
            ),
            iconSize: 24,
          ),
          
          // 页码指示器
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '$_currentHistoryPage / $totalPages',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          
          // 下一页按钮
          IconButton(
            onPressed: _currentHistoryPage < totalPages ? () => _nextHistoryPage(totalPages) : null,
            icon: Icon(
              Icons.chevron_right,
              color: _currentHistoryPage < totalPages ? AppColors.primary : AppColors.textLight,
            ),
            iconSize: 24,
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
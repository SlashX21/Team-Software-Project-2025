import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';
import '../../../domain/entities/history_response.dart';
import '../../../domain/entities/history_statistics.dart';
import '../../../services/api.dart';
import '../../../services/user_service.dart';
import 'history_detail_page.dart';

class HistoryRecordPage extends StatefulWidget {
  @override
  _HistoryRecordPageState createState() => _HistoryRecordPageState();
}

class _HistoryRecordPageState extends State<HistoryRecordPage> {
  HistoryPageState _pageState = HistoryPageState();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializePage();
    _setupScrollListener();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _initializePage() async {
    setState(() {
      _pageState = _pageState.copyWith(isLoading: true);
    });

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

      // 并行加载统计数据和历史记录
      final futures = await Future.wait([
        getHistoryStatistics(userId: userId),
        getUserHistory(userId: userId, page: 1),
      ]);

      final statistics = futures[0] as HistoryStatistics?;
      final historyResponse = futures[1] as HistoryResponse?;

      setState(() {
        _pageState = _pageState.copyWith(
          isLoading: false,
          statistics: statistics,
          historyItems: historyResponse?.items ?? [],
          hasMore: historyResponse?.hasMore ?? false,
          currentPage: historyResponse?.currentPage ?? 1,
        );
      });
    } catch (e) {
      setState(() {
        _pageState = _pageState.copyWith(
          isLoading: false,
          error: 'Failed to load history data',
        );
      });
    }
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent * 0.8) {
        _loadMoreHistory();
      }
    });
  }

  void _loadMoreHistory() async {
    if (_pageState.isLoadingMore || !_pageState.hasMore) return;

    setState(() {
      _pageState = _pageState.copyWith(isLoadingMore: true);
    });

    try {
      final userId = await UserService.instance.getCurrentUserId();
      if (userId == null) {
        setState(() {
          _pageState = _pageState.copyWith(isLoadingMore: false);
        });
        return;
      }

      final nextPage = _pageState.currentPage + 1;
      final historyResponse = await getUserHistory(
        userId: userId,
        page: nextPage,
        searchKeyword: _pageState.searchKeyword.isEmpty ? null : _pageState.searchKeyword,
        filterType: _pageState.filterType == 'all' ? null : _pageState.filterType,
      );

      if (historyResponse != null) {
        setState(() {
          _pageState = _pageState.copyWith(
            isLoadingMore: false,
            historyItems: [..._pageState.historyItems, ...historyResponse.items],
            hasMore: historyResponse.hasMore,
            currentPage: nextPage,
          );
        });
      }
    } catch (e) {
      setState(() {
        _pageState = _pageState.copyWith(
          isLoadingMore: false,
          error: 'Failed to load more items',
        );
      });
    }
  }

  void _onSearch(String keyword) async {
    setState(() {
      _pageState = _pageState.copyWith(
        isLoading: true,
        searchKeyword: keyword,
        currentPage: 1,
      );
    });

    try {
      final userId = await UserService.instance.getCurrentUserId();
      if (userId == null) {
        setState(() {
          _pageState = _pageState.copyWith(isLoading: false);
        });
        return;
      }

      final historyResponse = await getUserHistory(
        userId: userId,
        page: 1,
        searchKeyword: keyword.isEmpty ? null : keyword,
        filterType: _pageState.filterType == 'all' ? null : _pageState.filterType,
      );

      setState(() {
        _pageState = _pageState.copyWith(
          isLoading: false,
          historyItems: historyResponse?.items ?? [],
          hasMore: historyResponse?.hasMore ?? false,
          currentPage: 1,
        );
      });
    } catch (e) {
      setState(() {
        _pageState = _pageState.copyWith(
          isLoading: false,
          error: 'Search failed',
        );
      });
    }
  }

  void _onFilterChanged(String filterType) async {
    setState(() {
      _pageState = _pageState.copyWith(
        isLoading: true,
        filterType: filterType,
        currentPage: 1,
      );
    });

    try {
      final userId = await UserService.instance.getCurrentUserId();
      if (userId == null) {
        setState(() {
          _pageState = _pageState.copyWith(isLoading: false);
        });
        return;
      }

      final historyResponse = await getUserHistory(
        userId: userId,
        page: 1,
        searchKeyword: _pageState.searchKeyword.isEmpty ? null : _pageState.searchKeyword,
        filterType: filterType == 'all' ? null : filterType,
      );

      setState(() {
        _pageState = _pageState.copyWith(
          isLoading: false,
          historyItems: historyResponse?.items ?? [],
          hasMore: historyResponse?.hasMore ?? false,
          currentPage: 1,
        );
      });
    } catch (e) {
      setState(() {
        _pageState = _pageState.copyWith(
          isLoading: false,
          error: 'Filter failed',
        );
      });
    }
  }

  void _onHistoryItemTap(HistoryItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HistoryDetailPage(historyItem: item),
      ),
    );
  }

  void _onDeleteItem(String historyId) async {
    final userId = await UserService.instance.getCurrentUserId();
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      return;
    }

    final success = await deleteHistoryRecord(userId: userId, historyId: historyId);
    if (success) {
      setState(() {
        _pageState = _pageState.copyWith(
          historyItems: _pageState.historyItems
              .where((item) => item.id != historyId)
              .toList(),
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('History item deleted')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE8F5E8),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildAppBar(),
          if (_pageState.statistics != null) _buildStatisticsCard(),
          _buildFilterBar(),
          if (_pageState.isLoading && _pageState.historyItems.isEmpty)
            _buildLoadingSliver()
          else if (_pageState.historyItems.isEmpty)
            _buildEmptyState()
          else
            _buildHistoryList(),
          if (_pageState.isLoadingMore) _buildLoadingMore(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        title: Text('Scan History', style: AppStyles.h2.copyWith(color: AppColors.white)),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.search, color: AppColors.white),
          onPressed: () => _showSearchDialog(),
        ),
      ],
    );
  }

  Widget _buildStatisticsCard() {
    final stats = _pageState.statistics!;
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.all(16),
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
            Text('This Month', style: AppStyles.h2),
            SizedBox(height: 16),
            Row(
              children: [
                _buildStatItem('Total Scans', stats.totalScans.toString(), Icons.qr_code_scanner),
                _buildStatItem('Categories', stats.topCategories.length.toString(), Icons.category),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                _buildStatItem('Barcode', stats.barcodeScans.toString(), Icons.barcode_reader),
                _buildStatItem('Receipt', stats.receiptScans.toString(), Icons.receipt),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12),
        margin: EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            SizedBox(height: 8),
            Text(value, style: AppStyles.bodyBold.copyWith(fontSize: 18)),
            Text(label, style: AppStyles.bodyRegular.copyWith(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return SliverToBoxAdapter(
      child: Container(
        height: 60,
        margin: EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _buildFilterChip('All', 'all'),
            SizedBox(width: 8),
            _buildFilterChip('Barcode', 'barcode'),
            SizedBox(width: 8),
            _buildFilterChip('Receipt', 'receipt'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _pageState.filterType == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) => _onFilterChanged(value),
      backgroundColor: AppColors.white,
      selectedColor: AppColors.primary.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textDark,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildHistoryList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final item = _pageState.historyItems[index];
          return HistoryListItem(
            historyItem: item,
            onTap: () => _onHistoryItemTap(item),
            onDelete: () => _onDeleteItem(item.id),
          );
        },
        childCount: _pageState.historyItems.length,
      ),
    );
  }

  Widget _buildLoadingSliver() {
    return SliverFillRemaining(
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 80, color: AppColors.textLight),
            SizedBox(height: 16),
            Text('No scan history yet', style: AppStyles.h2.copyWith(color: AppColors.textLight)),
            SizedBox(height: 8),
            Text(
              'Start scanning products to see\nyour history here',
              style: AppStyles.bodyRegular.copyWith(color: AppColors.textLight),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingMore() {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Search History'),
        content: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Enter product name...',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _onSearch(_searchController.text);
              Navigator.pop(context);
            },
            child: Text('Search'),
          ),
        ],
      ),
    );
  }
}

class HistoryPageState {
  final bool isLoading;
  final bool isLoadingMore;
  final List<HistoryItem> historyItems;
  final HistoryStatistics? statistics;
  final String? error;
  final bool hasMore;
  final String searchKeyword;
  final String filterType;
  final int currentPage;

  HistoryPageState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.historyItems = const [],
    this.statistics,
    this.error,
    this.hasMore = true,
    this.searchKeyword = '',
    this.filterType = 'all',
    this.currentPage = 1,
  });

  HistoryPageState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    List<HistoryItem>? historyItems,
    HistoryStatistics? statistics,
    String? error,
    bool? hasMore,
    String? searchKeyword,
    String? filterType,
    int? currentPage,
  }) {
    return HistoryPageState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      historyItems: historyItems ?? this.historyItems,
      statistics: statistics ?? this.statistics,
      error: error ?? this.error,
      hasMore: hasMore ?? this.hasMore,
      searchKeyword: searchKeyword ?? this.searchKeyword,
      filterType: filterType ?? this.filterType,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

class HistoryListItem extends StatelessWidget {
  final HistoryItem historyItem;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const HistoryListItem({
    Key? key,
    required this.historyItem,
    required this.onTap,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 2,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // Product Image
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
                      historyItem.productImage ?? 'https://via.placeholder.com/60x60',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          historyItem.scanType == 'receipt' ? Icons.receipt : Icons.qr_code,
                          color: AppColors.primary,
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              historyItem.productName,
                              style: AppStyles.bodyBold,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        _formatDate(historyItem.createdAt),
                        style: AppStyles.bodyRegular.copyWith(
                          color: AppColors.textLight,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            historyItem.scanType == 'receipt' ? Icons.receipt : Icons.qr_code_scanner,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 4),
                          Text(
                            historyItem.scanType == 'receipt' ? 'Receipt' : 'Barcode',
                            style: AppStyles.bodyRegular.copyWith(fontSize: 12),
                          ),
                          Spacer(),
                          Text(
                            '${historyItem.recommendationCount} tips',
                            style: AppStyles.bodyRegular.copyWith(
                              fontSize: 12,
                              color: AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Actions
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: AppColors.alert),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                  child: Icon(
                    Icons.more_vert,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hr ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
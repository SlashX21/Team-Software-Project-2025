import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';
import '../../../domain/entities/history_response.dart';
import '../../../services/api.dart';
import '../../../services/user_service.dart';
import 'history_detail_page.dart';

class HistoryScreen extends StatefulWidget {
  final int userId;
  
  const HistoryScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<HistoryItem> _historyItems = [];
  bool _isLoading = true;
  String? _error;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _pageSize = 20;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadHistoryItems();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (_hasMore && !_isLoading) {
        _loadMoreItems();
      }
    }
  }

  Future<void> _loadHistoryItems() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userId = await UserService.instance.getCurrentUserId();
      if (userId == null) {
        setState(() {
          _error = 'User not logged in';
          _isLoading = false;
        });
        return;
      }

      final response = await getUserHistory(
        userId: userId,
        page: 1,
        limit: _pageSize,
      );

      if (response != null) {
        setState(() {
          _historyItems = response.items;
          _hasMore = response.hasMore;
          _currentPage = 1;
          _isLoading = false;
        });
        
        print('✅ History loaded successfully: ${_historyItems.length} records');
      } else {
        setState(() {
          _error = 'Unable to load history';
          _isLoading = false;
        });
        print('❌ History API returned null');
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load history: $e';
        _isLoading = false;
      });
      print('❌ Error loading history: $e');
    }
  }

  Future<void> _loadMoreItems() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    try {
      final userId = await UserService.instance.getCurrentUserId();
      if (userId == null) return;

      final response = await getUserHistory(
        userId: userId,
        page: _currentPage + 1,
        limit: _pageSize,
      );

      if (response != null) {
        setState(() {
          _historyItems.addAll(response.items);
          _hasMore = response.hasMore;
          _currentPage += 1;
          _isLoading = false;
        });
        
        print('✅ Loaded more history: +${response.items.length} records');
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('❌ Error loading more history: $e');
    }
  }

  Future<void> _refreshHistory() async {
    _currentPage = 1;
    _hasMore = true;
    await _loadHistoryItems();
  }

  void _onHistoryItemTap(HistoryItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HistoryDetailPage(historyItem: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Scan History', style: AppStyles.h2.copyWith(color: AppColors.white)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.white),
            onPressed: _refreshHistory,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _historyItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'Loading history...',
              style: AppStyles.bodyRegular.copyWith(color: AppColors.textLight),
            ),
          ],
        ),
      );
    }

    if (_error != null && _historyItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: AppColors.alert,
            ),
            SizedBox(height: 16),
            Text(
              'Load failed',
              style: AppStyles.h2.copyWith(color: AppColors.alert),
            ),
            SizedBox(height: 8),
            Text(
              _error!,
              style: AppStyles.bodyRegular.copyWith(color: AppColors.textLight),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshHistory,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_historyItems.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshHistory,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height - 200,
            child: _buildEmptyState(),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshHistory,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _historyItems.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < _historyItems.length) {
            return HistoryListItem(
              historyItem: _historyItems[index],
              onTap: () => _onHistoryItemTap(_historyItems[index]),
            );
          } else {
            // Loading indicator for pagination
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: AppColors.textLight,
          ),
          SizedBox(height: 16),
          Text(
            'No scan records',
            style: AppStyles.h2.copyWith(color: AppColors.textLight),
          ),
          SizedBox(height: 8),
          Text(
            'Start scanning products, your scan history\nwill appear here',
            style: AppStyles.bodyRegular.copyWith(color: AppColors.textLight),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Navigate to scan page
              DefaultTabController.of(context)?.animateTo(1);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text('Start Scanning'),
          ),
        ],
      ),
    );
  }
}

class HistoryListItem extends StatelessWidget {
  final HistoryItem historyItem;
  final VoidCallback onTap;

  const HistoryListItem({
    Key? key,
    required this.historyItem,
    required this.onTap,
  }) : super(key: key);

  String _formatScanDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 2,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Product Thumbnail
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
                      historyItem.productImage ?? '',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.image_not_supported,
                          color: AppColors.textLight,
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
                      Text(
                        historyItem.productName,
                        style: AppStyles.bodyBold,
                      ),
                      SizedBox(height: 4),
                      Text(
                        _formatScanDate(historyItem.createdAt),
                        style: AppStyles.bodyRegular.copyWith(color: AppColors.textLight),
                      ),
                      if ((historyItem.summary?['allergens'] ?? []).isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Row(
                            children: [
                              Icon(Icons.warning, size: 16, color: AppColors.alert),
                              SizedBox(width: 4),
                              Text(
                                '${(historyItem.summary?['allergens'] as List).length} allergen${(historyItem.summary?['allergens'] as List).length > 1 ? 's' : ''}',
                                style: AppStyles.bodyRegular.copyWith(
                                  color: (historyItem.summary?['allergens'] as List).length > 1 ? AppColors.alert : AppColors.warning,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Arrow Icon
                Icon(
                  Icons.arrow_forward_ios,
                  size: 18,
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
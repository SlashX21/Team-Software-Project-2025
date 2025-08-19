import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';
import '../../theme/screen_adapter.dart';
import '../../theme/responsive_layout.dart';
import '../../widgets/adaptive_widgets.dart';
import '../../../domain/entities/scan_history_response.dart';
import '../../../domain/entities/scan_history_item.dart';
import '../../../services/api.dart';
import '../../../services/user_service.dart';
import 'scan_history_detail_page.dart';

class ScanHistoryScreen extends StatefulWidget {
  final int userId;
  
  const ScanHistoryScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _ScanHistoryScreenState createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends State<ScanHistoryScreen> {
  List<ScanHistoryItem> _scanHistoryItems = [];
  bool _isLoading = true;
  String? _error;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _pageSize = 10;
  final ScrollController _scrollController = ScrollController();
  String? _selectedMonth;

  @override
  void initState() {
    super.initState();
    _loadScanHistoryItems();
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

  Future<void> _loadScanHistoryItems() async {
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

      print('🔍 Loading scan history for user $userId');
      final response = await getScanHistoryList(
        userId: userId,
        page: 1,
        limit: _pageSize,
        month: _selectedMonth,
      );

      if (response != null) {
        setState(() {
          _scanHistoryItems = response.items;
          _hasMore = response.pagination.hasNextPage;
          _currentPage = 1;
          _isLoading = false;
        });
        
        print('✅ Scan history loaded successfully: ${_scanHistoryItems.length} records');
      } else {
        setState(() {
          _error = 'Unable to load scan history';
          _isLoading = false;
        });
        print('❌ Scan history API returned null');
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load scan history: $e';
        _isLoading = false;
      });
      print('❌ Error loading scan history: $e');
    }
  }

  Future<void> _loadMoreItems() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    try {
      final userId = await UserService.instance.getCurrentUserId();
      if (userId == null) return;

      final response = await getScanHistoryList(
        userId: userId,
        page: _currentPage + 1,
        limit: _pageSize,
        month: _selectedMonth,
      );

      if (response != null) {
        setState(() {
          _scanHistoryItems.addAll(response.items);
          _hasMore = response.pagination.hasNextPage;
          _currentPage += 1;
          _isLoading = false;
        });
        
        print('✅ Loaded more scan history: +${response.items.length} records');
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('❌ Error loading more scan history: $e');
    }
  }

  Future<void> _refreshScanHistory() async {
    _currentPage = 1;
    _hasMore = true;
    await _loadScanHistoryItems();
  }

  void _onScanHistoryItemTap(ScanHistoryItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScanHistoryDetailPage(scanHistoryItem: item),
      ),
    );
  }

  void _showMonthFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Filter by Month', style: AppStyles.h2),
            SizedBox(height: 16),
            ListTile(
              title: Text('All Months'),
              onTap: () {
                setState(() {
                  _selectedMonth = null;
                });
                Navigator.pop(context);
                _refreshScanHistory();
              },
            ),
            ListTile(
              title: Text('This Month'),
              onTap: () {
                final now = DateTime.now();
                setState(() {
                  _selectedMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
                });
                Navigator.pop(context);
                _refreshScanHistory();
              },
            ),
            ListTile(
              title: Text('Last Month'),
              onTap: () {
                final now = DateTime.now();
                final lastMonth = DateTime(now.year, now.month - 1, 1);
                setState(() {
                  _selectedMonth = '${lastMonth.year}-${lastMonth.month.toString().padLeft(2, '0')}';
                });
                Navigator.pop(context);
                _refreshScanHistory();
              },
            ),
          ],
        ),
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
            icon: Icon(Icons.filter_list, color: AppColors.white),
            onPressed: _showMonthFilter,
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.white),
            onPressed: _refreshScanHistory,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _scanHistoryItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'Loading scan history...',
              style: AppStyles.bodyRegular.copyWith(color: AppColors.textLight),
            ),
          ],
        ),
      );
    }

    if (_error != null && _scanHistoryItems.isEmpty) {
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
              onPressed: _refreshScanHistory,
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

    if (_scanHistoryItems.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshScanHistory,
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
      onRefresh: _refreshScanHistory,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _scanHistoryItems.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < _scanHistoryItems.length) {
            return ScanHistoryListItem(
              scanHistoryItem: _scanHistoryItems[index],
              onTap: () => _onScanHistoryItemTap(_scanHistoryItems[index]),
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
            Icons.qr_code_scanner,
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

class ScanHistoryListItem extends StatelessWidget {
  final ScanHistoryItem scanHistoryItem;
  final VoidCallback onTap;

  const ScanHistoryListItem({
    Key? key,
    required this.scanHistoryItem,
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
                // Scan Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: AppColors.primary.withOpacity(0.1),
                  ),
                  child: Icon(
                    Icons.qr_code_scanner,
                    color: AppColors.primary,
                    size: 30,
                  ),
                ),
                AdaptiveSpacing.horizontal(16),
                
                // Product Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AdaptiveText(
                        text: scanHistoryItem.productName,
                        style: AppStyles.bodySmall.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                          color: AppColors.textDark,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        useResponsiveFontSize: false,
                        useDeviceOptimization: false,
                      ),
                      AdaptiveSpacing.vertical(4),
                      AdaptiveText(
                        text: _formatScanDate(scanHistoryItem.scannedAt),
                        style: AppStyles.bodyRegular.copyWith(color: AppColors.textLight),
                        useResponsiveFontSize: true,
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
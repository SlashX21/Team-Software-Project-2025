import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';
import '../../../domain/entities/receipt_history_item.dart';
import '../../../domain/entities/paged_response.dart';
import 'receipt_detail_page.dart';

class ReceiptHistoryScreen extends StatefulWidget {
  const ReceiptHistoryScreen({Key? key}) : super(key: key);

  @override
  _ReceiptHistoryScreenState createState() => _ReceiptHistoryScreenState();
}

class _ReceiptHistoryScreenState extends State<ReceiptHistoryScreen> {
  List<ReceiptHistoryItem> receipts = [];
  bool isLoading = false;
  bool hasMore = true;
  int currentPage = 1;
  final int pageSize = 10;
  final ScrollController _scrollController = ScrollController();
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadReceiptHistory();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _loadMoreReceipts();
    }
  }

  Future<void> _loadReceiptHistory() async {
    if (isLoading) return;
    
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // TODO: Replace with actual API call
      await Future.delayed(Duration(milliseconds: 1500)); // Simulate API call
      
      // Mock data for demonstration
      final mockReceipts = _generateMockReceipts(currentPage, pageSize);
      
      setState(() {
        if (currentPage == 1) {
          receipts = mockReceipts.data;
        } else {
          receipts.addAll(mockReceipts.data);
        }
        hasMore = mockReceipts.hasMore;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load receipt history. Please try again.';
      });
    }
  }

  Future<void> _loadMoreReceipts() async {
    if (!hasMore || isLoading) return;
    
    currentPage++;
    await _loadReceiptHistory();
  }

  Future<void> _refreshReceipts() async {
    currentPage = 1;
    hasMore = true;
    await _loadReceiptHistory();
  }

  void _navigateToDetails(int receiptId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReceiptDetailPage(receiptId: receiptId),
      ),
    );
  }

  PagedResponse<ReceiptHistoryItem> _generateMockReceipts(int page, int limit) {
    // Mock data generation - replace with actual API call
    final List<ReceiptHistoryItem> mockData = List.generate(limit, (index) {
      final id = (page - 1) * limit + index + 1;
      final now = DateTime.now();
      // Keep dates within current month - limit to max 30 days ago
      final daysAgo = id % 30; // Use modulo to cycle through 0-29 days
      final scanTime = now.subtract(Duration(days: daysAgo, hours: id % 24));
      
      final products = [
        'Sprite Lemon 330ml',
        'Oreo Original Cookies',
        'Fresh Apple',
        'Whole Milk 1L',
        'Banana Organic',
        'Coca Cola 500ml',
        'Bread Whole Wheat',
        'Chicken Breast 500g',
        'Rice Jasmine 1kg',
        'Orange Juice 1L'
      ];
      
      final itemCount = (id % 5) + 1;
      final selectedProducts = products.take(itemCount).toList();
      
      return ReceiptHistoryItem(
        receiptId: id,
        scanTime: scanTime,
        displayTitle: selectedProducts.join(', '),
        itemCount: itemCount,
        hasRecommendations: id % 3 == 0, // Every 3rd receipt has recommendations
      );
    });

    return PagedResponse(
      data: mockData,
      pagination: PaginationInfo(
        currentPage: page,
        totalPages: 5, // Mock total pages
        totalItems: 95, // Mock total items
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Receipt History',
          style: AppStyles.h2.copyWith(color: AppColors.white),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: AppColors.background,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading && receipts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'Loading receipt history...',
              style: TextStyle(
                color: AppColors.textLight,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (errorMessage != null && receipts.isEmpty) {
      return _buildErrorWidget();
    }

    if (receipts.isEmpty) {
      return _buildEmptyWidget();
    }

    return RefreshIndicator(
      onRefresh: _refreshReceipts,
      color: AppColors.primary,
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.all(16),
        itemCount: receipts.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == receipts.length) {
            return _buildLoadingIndicator();
          }
          return ReceiptHistoryCard(
            receipt: receipts[index],
            onTap: () => _navigateToDetails(receipts[index].receiptId),
          );
        },
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
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
              'Error Loading Receipts',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: 8),
            Text(
              errorMessage ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textLight,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _refreshReceipts,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: AppColors.textLight,
            ),
            SizedBox(height: 16),
            Text(
              'No Receipt History',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Upload your first receipt to start tracking your nutrition journey!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textLight,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }
}

class ReceiptHistoryCard extends StatelessWidget {
  final ReceiptHistoryItem receipt;
  final VoidCallback onTap;

  const ReceiptHistoryCard({
    Key? key,
    required this.receipt,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          receipt.formattedTitle,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                            color: AppColors.textDark,
                            height: 1.2,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 8),
                        Text(
                          DateFormat('MMM dd, yyyy HH:mm').format(receipt.scanTime),
                          style: TextStyle(
                            color: AppColors.textLight,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Icon(
                        Icons.chevron_right,
                        color: AppColors.textLight,
                      ),
                      SizedBox(height: 4),
                      if (receipt.hasRecommendations)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Recommendations',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 16,
                    color: AppColors.textLight,
                  ),
                  SizedBox(width: 4),
                  Text(
                    '${receipt.itemCount} items',
                    style: TextStyle(
                      color: AppColors.textLight,
                      fontSize: 12,
                    ),
                  ),
                  Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Receipt',
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';
import '../scanner/barcode_scanner_screen.dart';
import '../sugar_tracking/sugar_tracking_page.dart';
import '../monthly_overview/monthly_overview_screen.dart';
import '../history/history_screen.dart';
import '../history/history_detail_page.dart';
import '../profile/profile_screen.dart';
import '../../../services/user_service.dart';
import 'receipt_upload_screen.dart';
import '../../../domain/entities/history_response.dart';

class HomeTabScreen extends StatefulWidget {
  final int userId;

  const HomeTabScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _HomeTabScreenState createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends State<HomeTabScreen> {
  String? _userName;
  List<HistoryItem> _recentActivities = [];

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadRecentActivities();
  }

  Future<void> _loadUserName() async {
    final name = await UserService.instance.getUserName();
    setState(() {
      _userName = name;
    });
  }

  Future<void> _loadRecentActivities() async {
    // Implement the logic to load recent activities
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: AppColors.primary,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Grocery Guardian',
                  style: AppStyles.h1.copyWith(color: AppColors.white, fontSize: 20),
                ),
                titlePadding: EdgeInsets.only(left: 20, bottom: 16),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withOpacity(0.8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeCard(),
                    SizedBox(height: 24),
                    _buildAnalyticsCard(context),
                    SizedBox(height: 16),
                    _buildReceiptUploadCard(context),
                    SizedBox(height: 24),
                    _buildRecentActivity(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.primary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.eco,
              size: 32,
              color: AppColors.primary,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userName != null && _userName!.isNotEmpty
                      ? 'Welcome back, $_userName!'
                      : 'Welcome back!',
                  style: AppStyles.h2.copyWith(color: AppColors.primary),
                ),
                SizedBox(height: 4),
                Text(
                  'Track your nutrition and make healthier choices',
                  style: AppStyles.bodyRegular.copyWith(color: AppColors.textLight),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MonthlyOverviewScreen(),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.insights, color: AppColors.primary, size: 32),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Analytics', style: AppStyles.bodyBold),
                  SizedBox(height: 4),
                  Text('Monthly overview and insights', style: AppStyles.bodyRegular.copyWith(color: AppColors.textLight)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: AppColors.textLight, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptUploadCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReceiptUploadScreen(),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.receipt_long, color: AppColors.primary, size: 32),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Upload Receipt', style: AppStyles.bodyBold),
                  SizedBox(height: 4),
                  Text('Upload your grocery receipt for analysis', style: AppStyles.bodyRegular.copyWith(color: AppColors.textLight)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: AppColors.textLight, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activity',
              style: AppStyles.h2.copyWith(color: AppColors.textDark),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HistoryScreen(userId: widget.userId),
                  ),
                );
              },
              child: Text(
                'View All',
                style: AppStyles.bodyRegular.copyWith(color: AppColors.primary),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Container(
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
          child: ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _recentActivities.length,
            separatorBuilder: (context, index) => Divider(height: 24),
            itemBuilder: (context, index) {
              final item = _recentActivities[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HistoryDetailPage(historyItem: item),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        item.scanType == 'barcode'
                            ? Icons.qr_code_scanner
                            : item.scanType == 'receipt'
                                ? Icons.receipt_long
                                : Icons.monitor_heart,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.productName, style: AppStyles.bodyBold),
                          SizedBox(height: 2),
                          Text(
                            _formatScanDate(item.createdAt),
                            style: AppStyles.bodyRegular.copyWith(color: AppColors.textLight),
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
              );
            },
          ),
        ),
      ],
    );
  }

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
}
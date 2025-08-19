import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';
import '../monthly_overview/monthly_overview_screen.dart';
import '../sugar_tracking/sugar_tracking_page.dart';
import '../loyalty/loyalty_points_screen.dart';
import '../../../services/user_service.dart';
import '../../../services/api.dart';
import '../../../domain/entities/daily_sugar_intake.dart';
import '../../../domain/entities/sugar_goal.dart';
import 'receipt_upload_screen.dart';

class HomeTabScreen extends StatefulWidget {
  final int userId;

  const HomeTabScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _HomeTabScreenState createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends State<HomeTabScreen> {
  String? _userName;
  DailySugarIntake? _dailySugarIntake;
  SugarGoal? _sugarGoal;
  bool _isLoadingSugar = true;
  DateTime? _lastDataLoadTime;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadSugarData();
  }

  Future<void> _loadUserName() async {
    final name = await UserService.instance.getUserName();
    setState(() {
      _userName = name;
    });
  }

  Future<void> _loadSugarData() async {
    try {
      final userId = await UserService.instance.getCurrentUserId();
      if (userId == null) return;

      final today = DateTime.now().toIso8601String().split('T')[0];
      final futures = await Future.wait([
        getDailySugarIntake(userId, today),
        getSugarGoal(userId),
      ]);

      final dailyIntake = futures[0] as DailySugarIntake?;
      final sugarGoal = futures[1] as SugarGoal?;

      DailySugarIntake? finalDailyIntake = dailyIntake;
      if (dailyIntake == null && sugarGoal != null) {
        finalDailyIntake = DailySugarIntake(
          currentIntakeMg: 0.0,
          dailyGoalMg: sugarGoal.dailyGoalMg,
          progressPercentage: 0.0,
          status: 'good',
          topContributors: [],
          date: DateTime.now(),
        );
      } else if (dailyIntake == null && sugarGoal == null) {
        finalDailyIntake = DailySugarIntake(
          currentIntakeMg: 0.0,
          dailyGoalMg: 50000.0,
          progressPercentage: 0.0,
          status: 'good',
          topContributors: [],
          date: DateTime.now(),
        );
      }

      setState(() {
        _dailySugarIntake = finalDailyIntake;
        _sugarGoal = sugarGoal;
        _isLoadingSugar = false;
        _lastDataLoadTime = DateTime.now();
      });
    } catch (e) {
      setState(() {
        _isLoadingSugar = false;
      });
    }
  }

  void _checkAndRefreshData() {
    // 如果数据超过30秒未刷新，或者还没有加载过数据，则刷新
    final now = DateTime.now();
    if (_lastDataLoadTime == null || 
        now.difference(_lastDataLoadTime!).inSeconds > 30) {
      print('🔄 Home page: Refreshing sugar data (last update: $_lastDataLoadTime)');
      _loadSugarData();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 当页面重新获得焦点时检查是否需要刷新数据
    _checkAndRefreshData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 90,
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
                    _buildSugarCard(context),
                    SizedBox(height: 16),
                    _buildLoyaltyCard(context),
                    SizedBox(height: 16),
                    _buildReceiptUploadCard(context),
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
            builder: (context) => MonthlyOverviewScreen(userId: widget.userId),
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




  Widget _buildSugarCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SugarTrackingPage(),
          ),
        ).then((_) {
          // Refresh sugar data when returning from sugar tracking
          _loadSugarData();
        });
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
            Icon(Icons.monitor_heart, color: AppColors.primary, size: 32),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sugar Tracking', style: AppStyles.bodyBold),
                  SizedBox(height: 4),
                  _isLoadingSugar
                      ? Text('Loading...', style: AppStyles.bodyRegular.copyWith(color: AppColors.textLight))
                      : _dailySugarIntake != null
                          ? Text(
                              '${(_dailySugarIntake!.currentIntakeMg / 1000).toStringAsFixed(1)}g / ${(_dailySugarIntake!.dailyGoalMg / 1000).toStringAsFixed(1)}g',
                              style: AppStyles.bodyRegular.copyWith(color: AppColors.textLight),
                            )
                          : Text('Track your daily sugar intake', style: AppStyles.bodyRegular.copyWith(color: AppColors.textLight)),
                ],
              ),
            ),
            if (!_isLoadingSugar && _dailySugarIntake != null)
              Container(
                width: 40,
                height: 40,
                child: Stack(
                  children: [
                    CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 6,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[300]!),
                    ),
                    CircularProgressIndicator(
                      value: (_dailySugarIntake!.progressPercentage / 100).clamp(0.0, 1.0),
                      strokeWidth: 6,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(_dailySugarIntake!.progressColor),
                    ),
                  ],
                ),
              ),
            Icon(Icons.arrow_forward_ios, color: AppColors.textLight, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildLoyaltyCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LoyaltyPointsScreen(userId: widget.userId),
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
            Icon(Icons.stars, color: AppColors.primary, size: 32),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Loyalty Points', style: AppStyles.bodyBold),
                  SizedBox(height: 4),
                  Text('Earn and redeem points for rewards', style: AppStyles.bodyRegular.copyWith(color: AppColors.textLight)),
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


}
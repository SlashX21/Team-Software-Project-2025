import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';
import '../../../domain/entities/daily_sugar_intake.dart';
import '../../../domain/entities/sugar_contributor.dart';
import '../../../domain/entities/sugar_goal.dart';
import '../../../services/api.dart';
import '../../../services/user_service.dart';
import 'add_sugar_record_dialog.dart';
import 'sugar_goal_setting_page.dart';
import 'monthly_summary_page.dart';

class SugarTrackingPage extends StatefulWidget {
  @override
  _SugarTrackingPageState createState() => _SugarTrackingPageState();
}

class _SugarTrackingPageState extends State<SugarTrackingPage> {
  SugarTrackingPageState _pageState = SugarTrackingPageState();
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _loadSugarData();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (!_disposed && mounted) {
      setState(fn);
    }
  }

  void _loadSugarData() async {
    _safeSetState(() {
      _pageState = _pageState.copyWith(isLoading: true);
    });

    try {
      final userId = await UserService.instance.getCurrentUserId();
      if (userId == null) {
        _safeSetState(() {
          _pageState = _pageState.copyWith(
            isLoading: false,
            error: 'User not logged in',
          );
        });
        return;
      }

      // 并行加载当日数据和目标设置
      final today = DateTime.now().toIso8601String().split('T')[0];
      final futures = await Future.wait([
        getDailySugarIntake(userId, today),
        getSugarGoal(userId),
      ]);

      final dailyIntake = futures[0] as DailySugarIntake?;
      final sugarGoal = futures[1] as SugarGoal?;

      // 如果API返回null但有糖分目标，创建默认的DailySugarIntake对象
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
        // 如果连目标都没有，使用默认目标值
        finalDailyIntake = DailySugarIntake(
          currentIntakeMg: 0.0,
          dailyGoalMg: 50000.0, // 默认50g目标
          progressPercentage: 0.0,
          status: 'good',
          topContributors: [],
          date: DateTime.now(),
        );
      }

      _safeSetState(() {
        _pageState = _pageState.copyWith(
          isLoading: false,
          dailyIntake: finalDailyIntake,
          sugarGoal: sugarGoal,
        );
      });
    } catch (e) {
      // 即使出错，也提供默认数据以确保圆环可以显示
      final defaultDailyIntake = DailySugarIntake(
        currentIntakeMg: 0.0,
                  dailyGoalMg: 50000.0, // 默认50g目标
        progressPercentage: 0.0,
        status: 'good',
        topContributors: [],
        date: DateTime.now(),
      );

      _safeSetState(() {
        _pageState = _pageState.copyWith(
          isLoading: false,
          dailyIntake: defaultDailyIntake,
          error: 'Failed to load sugar tracking data. Showing default values.',
        );
      });
    }
  }

  void _showAddSugarDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AddSugarRecordDialog(),
    );

    if (result == true) {
      // 重新加载数据
      _loadSugarData();
    }
  }

  void _navigateToGoalSetting() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => SugarGoalSettingPage(
          currentGoal: _pageState.sugarGoal,
        ),
      ),
    );

    if (result == true) {
      // 重新加载数据
      _loadSugarData();
    }
  }

  void _navigateToMonthlySummary() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MonthlySummaryPage(),
      ),
    ).then((_) {
      // Refresh data when returning from monthly summary (user might have deleted records in daily detail)
      _loadSugarData();
    });
  }

  void _onDeleteContributor(int contributorId) async {
    // 显示确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Record'),
        content: Text('Are you sure you want to delete this sugar intake record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.alert),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _safeSetState(() {
        _pageState = _pageState.copyWith(isAddingRecord: true);
      });

      final userId = await UserService.instance.getCurrentUserId();
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in')),
        );
        return;
      }

      final success = await deleteSugarIntakeRecord(
        userId: userId,
        recordId: contributorId,
      );

      _safeSetState(() {
        _pageState = _pageState.copyWith(isAddingRecord: false);
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sugar record deleted'),
            duration: Duration(seconds: 2),
          ),
        );
        _loadSugarData(); // 重新加载数据
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete record'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Sugar Tracking', style: AppStyles.h2.copyWith(color: AppColors.white)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _navigateToMonthlySummary,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.analytics_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
          SizedBox(width: 0),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: _navigateToGoalSetting,
          ),
        ],
      ),
      body: _pageState.isLoading
          ? Center(child: CircularProgressIndicator())
          : _buildContent(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSugarDialog,
        backgroundColor: AppColors.primary,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }


  Widget _buildContent() {
    final dailyIntake = _pageState.dailyIntake;
    // 现在dailyIntake总是有值（通过默认数据保证）
    if (dailyIntake == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.no_food, size: 64, color: AppColors.textLight),
            SizedBox(height: 16),
            Text('No sugar data available', style: AppStyles.h2),
            SizedBox(height: 8),
            Text('Add your first sugar intake record', style: AppStyles.bodyRegular),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // 显示错误消息（如果有的话）
          if (_pageState.error != null) ...[
            Container(
              margin: EdgeInsets.only(bottom: 16),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _pageState.error!,
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          Center(
            child: _buildProgressCard(dailyIntake),
          ),
          SizedBox(height: 24),
          _buildDailyIntakeRecords(dailyIntake),
          SizedBox(height: 80), // 为FloatingActionButton留出空间
        ],
      ),
    );
  }

  Widget _buildProgressCard(DailySugarIntake dailyIntake) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            // 环形进度条
            SizedBox(
              width: 200,
              height: 200,
              child: Stack(
                children: [
                  // 背景圆环
                  SizedBox(
                    width: 200,    
                    height: 200,
                    child: CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 24,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[300]!),
                    ),
                  ),
                  // 进度圆环
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: CircularProgressIndicator(
                      value: (dailyIntake.progressPercentage / 100).clamp(0.0, 1.0),
                      strokeWidth: 24,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(dailyIntake.progressColor),
                    ),
                  ),
                  // 中心内容
                  Positioned.fill(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${dailyIntake.currentIntakeMg.toInt()}',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            '/ ${dailyIntake.dailyGoalMg.toInt()}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            'mg',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            
            // 进度百分比
            Text(
              '${dailyIntake.progressPercentage.toInt()}% of daily goal',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 12),
            
            // 状态文字
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: dailyIntake.statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                dailyIntake.statusText,
                style: TextStyle(
                  fontSize: 16,
                  color: dailyIntake.statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyIntakeRecords(DailySugarIntake dailyIntake) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题区域
        Container(
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
                child: Icon(Icons.receipt_long, color: AppColors.primary, size: 24),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Today\'s Intake Records', style: AppStyles.bodyBold),
                    SizedBox(height: 4),
                    Text(
                      'View your daily sugar intake details',
                      style: AppStyles.bodyRegular.copyWith(
                        color: AppColors.textLight,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${dailyIntake.topContributors.length} items',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        
        // 摄入记录列表
        if (dailyIntake.topContributors.isEmpty)
          _buildEmptyIntakeState()
        else
          _buildIntakeRecordsList(dailyIntake.topContributors),
      ],
    );
  }

  Widget _buildEmptyIntakeState() {
    return Container(
      padding: EdgeInsets.all(40),
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
      child: Center(
        child: Column(
          children: [
            Icon(Icons.no_food, size: 64, color: AppColors.textLight),
            SizedBox(height: 16),
            Text('No intake records', style: AppStyles.h2.copyWith(color: AppColors.textLight)),
            SizedBox(height: 8),
            Text(
              'Tap the + button to add your first sugar intake record',
              style: AppStyles.bodyRegular.copyWith(color: AppColors.textLight),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntakeRecordsList(List<SugarContributor> contributors) {
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
      child: Column(
        children: [
          // 列表标题
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Food Name',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Intake Time',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Sugar Amount',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(width: 40), // 为删除按钮预留空间
              ],
            ),
          ),
          
          // 记录列表
          ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: contributors.length,
            separatorBuilder: (context, index) => Divider(height: 1, color: AppColors.background),
            itemBuilder: (context, index) {
              return _buildIntakeRecordItem(contributors[index], index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIntakeRecordItem(SugarContributor contributor, int index) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          // 食品名称
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getFoodIcon(contributor.foodName),
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contributor.foodName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (contributor.quantity > 1) ...[
                        SizedBox(height: 2),
                        Text(
                          'Qty: ${contributor.quantity.toInt()}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // 摄入时间
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Text(
                  _formatIntakeTime(contributor.formattedConsumedTime),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  _formatIntakeDate(contributor.formattedConsumedTime),
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textLight,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          // 糖含量
          Expanded(
            flex: 2,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getSugarAmountColor(contributor.totalSugarAmount).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                contributor.formattedTotalSugarAmount,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _getSugarAmountColor(contributor.totalSugarAmount),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          
          // 删除按钮
          SizedBox(width: 8),
          GestureDetector(
            onTap: () => _onDeleteContributor(contributor.id),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.alert.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.delete_outline,
                color: AppColors.alert,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatIntakeTime(String timeString) {
    try {
      // 假设时间格式是 "2 hours ago" 或具体时间
      if (timeString.contains('ago')) {
        return timeString;
      }
      // 如果是具体时间，提取时分
      final time = DateTime.tryParse(timeString);
      if (time != null) {
        return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      }
      return timeString;
    } catch (e) {
      return timeString;
    }
  }

  String _formatIntakeDate(String timeString) {
    try {
      if (timeString.contains('ago')) {
        return 'Today';
      }
      final time = DateTime.tryParse(timeString);
      if (time != null) {
        final now = DateTime.now();
        if (time.year == now.year && time.month == now.month && time.day == now.day) {
          return 'Today';
        }
        return '${time.month}/${time.day}';
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  Color _getSugarAmountColor(double sugarAmountMg) {
    if (sugarAmountMg <= 5000) return Colors.green; // ≤5g
    if (sugarAmountMg <= 10000) return Colors.orange; // ≤10g
    return Colors.red; // >10g
  }


  IconData _getFoodIcon(String foodName) {
    final name = foodName.toLowerCase();
    if (name.contains('juice') || name.contains('drink')) {
      return Icons.local_drink;
    } else if (name.contains('cookie') || name.contains('chocolate')) {
      return Icons.cookie;
    } else if (name.contains('apple') || name.contains('fruit')) {
      return Icons.apple;
    } else if (name.contains('yogurt') || name.contains('milk')) {
      return Icons.icecream;
    } else {
      return Icons.fastfood;
    }
  }
}

class SugarTrackingPageState {
  final bool isLoading;
  final DailySugarIntake? dailyIntake;
  final SugarGoal? sugarGoal;
  final String? error;
  final bool isAddingRecord;

  SugarTrackingPageState({
    this.isLoading = false,
    this.dailyIntake,
    this.sugarGoal,
    this.error,
    this.isAddingRecord = false,
  });

  SugarTrackingPageState copyWith({
    bool? isLoading,
    DailySugarIntake? dailyIntake,
    SugarGoal? sugarGoal,
    String? error,
    bool? isAddingRecord,
  }) {
    return SugarTrackingPageState(
      isLoading: isLoading ?? this.isLoading,
      dailyIntake: dailyIntake ?? this.dailyIntake,
      sugarGoal: sugarGoal ?? this.sugarGoal,
      error: error ?? this.error,
      isAddingRecord: isAddingRecord ?? this.isAddingRecord,
    );
  }
}
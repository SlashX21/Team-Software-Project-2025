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

      _safeSetState(() {
        _pageState = _pageState.copyWith(
          isLoading: false,
          dailyIntake: dailyIntake,
          sugarGoal: sugarGoal,
        );
      });
    } catch (e) {
      _safeSetState(() {
        _pageState = _pageState.copyWith(
          isLoading: false,
          error: 'Failed to load sugar tracking data',
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

  void _onDeleteContributor(String contributorId) async {
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
        recordId: int.parse(contributorId),
      );

      _safeSetState(() {
        _pageState = _pageState.copyWith(isAddingRecord: false);
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sugar record deleted')),
        );
        _loadSugarData(); // 重新加载数据
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete record')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Sugar Tracking', style: AppStyles.h2),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: _navigateToGoalSetting,
          ),
        ],
      ),
      body: _pageState.isLoading
          ? Center(child: CircularProgressIndicator())
          : _pageState.error != null
              ? _buildErrorState()
              : _buildContent(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSugarDialog,
        backgroundColor: AppColors.primary,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.alert),
          SizedBox(height: 16),
          Text(_pageState.error!, style: AppStyles.bodyRegular),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadSugarData,
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final dailyIntake = _pageState.dailyIntake;
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
          _buildProgressCard(dailyIntake),
          SizedBox(height: 24),
          if (dailyIntake.topContributors.isNotEmpty)
            _buildContributorsSection(dailyIntake.topContributors),
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
                      strokeWidth: 12,
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
                      strokeWidth: 12,
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

  Widget _buildContributorsSection(List<SugarContributor> contributors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Highest Contributors',
              style: AppStyles.h2,
            ),
            TextButton(
              onPressed: () {
                // TODO: Navigate to full contributors list
              },
              child: Text('View All', style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
        SizedBox(height: 16),
        ...contributors.map((contributor) => _buildContributorItem(contributor)),
      ],
    );
  }

  Widget _buildContributorItem(SugarContributor contributor) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // 食品图标
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
              size: 24,
            ),
          ),
          SizedBox(width: 12),
          
          // 食品信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contributor.foodName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '${contributor.formattedConsumedTime}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // 糖分数值
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                contributor.formattedTotalSugarAmount,
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFFFF9800),
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (contributor.quantity > 1)
                Text(
                  'x${contributor.quantity.toInt()}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
          
          // 删除按钮
          SizedBox(width: 8),
          GestureDetector(
            onTap: () => _onDeleteContributor(contributor.id),
            child: Container(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.delete_outline,
                color: Colors.grey[500],
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
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
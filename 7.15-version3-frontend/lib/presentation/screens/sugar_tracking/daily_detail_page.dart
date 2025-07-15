import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../widgets/sugar_progress_ring.dart';
import '../../../domain/entities/daily_sugar_intake.dart';
import '../../../domain/entities/sugar_contributor.dart';
import '../../../services/api.dart';
import '../../../services/user_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';
import 'add_sugar_record_dialog.dart';

class DailyDetailPage extends StatefulWidget {
  final DateTime date;
  final bool fromMonthlySummary;

  const DailyDetailPage({
    Key? key,
    required this.date,
    this.fromMonthlySummary = false,
  }) : super(key: key);

  @override
  _DailyDetailPageState createState() => _DailyDetailPageState();
}

class _DailyDetailPageState extends State<DailyDetailPage> {
  DailySugarIntake? _dailyData;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDailyData();
  }

  Future<void> _loadDailyData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userId = await UserService.instance.getCurrentUserId();
      if (userId == null) {
        throw Exception('用户未登录');
      }

      final dateString = widget.date.toIso8601String().split('T')[0];
      final data = await getDailySugarIntake(userId, dateString);

      setState(() {
        _dailyData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateString = DateFormat('MMM d').format(widget.date);
    final isToday = _isToday(widget.date);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('$dateString Sugar Details'),
        centerTitle: true,
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black26,
      ),
      body: _buildContent(),
      floatingActionButton: isToday ? FloatingActionButton.extended(
        onPressed: _onAddRecord,
        backgroundColor: AppColors.primary,
        icon: Icon(Icons.add, color: Colors.white),
        label: Text(
          'Add Record',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ) : null,
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'Loading...',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'Failed to load',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDailyData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDailyProgressCard(),
          SizedBox(height: 24),
          _buildIntakeRecordsList(),
          SizedBox(height: 100), // 为FAB留出空间
        ],
      ),
    );
  }

  Widget _buildDailyProgressCard() {
    if (_dailyData == null) {
      return _buildEmptyProgressCard();
    }

    final data = _dailyData!;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 进度环
          SugarProgressRing(
            progressPercentage: data.progressPercentage,
            status: data.status,
            size: 120,
            strokeWidth: 8,
            showPercentage: true,
          ),
          SizedBox(height: 20),
          // 摄入量显示
          Text(
            '${data.formattedCurrentIntake} / ${data.formattedDailyGoal}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '${data.progressPercentage.toInt()}% of daily goal',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 16),
          // 状态标签
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: data.statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              data.statusText,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: data.statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyProgressCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey[300]!, width: 8),
            ),
            child: Center(
              child: Text(
                '0\nmg',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ),
          SizedBox(height: 20),
          Text(
            'No intake records',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntakeRecordsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📝 Intake Records',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 16),
        _buildRecordsContent(),
      ],
    );
  }

  Widget _buildRecordsContent() {
    if (_dailyData == null || _dailyData!.topContributors.isEmpty) {
      return _buildEmptyRecordsCard();
    }

    return Column(
      children: _dailyData!.topContributors
          .map((record) => _buildRecordItem(record))
          .toList(),
    );
  }

  Widget _buildRecordItem(SugarContributor record) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // 食物图标
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getFoodIcon(record.foodName),
              color: AppColors.primary,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          // 食物信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.foodName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '${record.formattedConsumedTime} • Qty: ${record.quantity}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          // 糖分含量
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                record.formattedTotalSugarAmount,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange[700],
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Total Sugar',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
          SizedBox(width: 8),
          // 删除按钮
          if (_isToday(widget.date))
            IconButton(
              onPressed: () => _onDeleteRecord(record),
              icon: Icon(
                Icons.delete_outline,
                color: Colors.red[400],
                size: 20,
              ),
              style: IconButton.styleFrom(
                backgroundColor: Colors.red[50],
                minimumSize: Size(32, 32),
                shape: CircleBorder(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyRecordsCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No intake records',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          if (_isToday(widget.date)) ...[
            SizedBox(height: 8),
            Text(
              'Tap the button below to add your first record',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getFoodIcon(String foodName) {
    final name = foodName.toLowerCase();
    if (name.contains('苹果') || name.contains('apple')) return Icons.apple;
    if (name.contains('可乐') || name.contains('cola')) return Icons.local_drink;
    if (name.contains('巧克力') || name.contains('chocolate')) return Icons.cake;
    if (name.contains('牛奶') || name.contains('酸奶') || name.contains('milk')) return Icons.local_drink;
    if (name.contains('糖') || name.contains('candy')) return Icons.cookie;
    return Icons.restaurant;
  }

  Future<void> _onDeleteRecord(SugarContributor record) async {
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final userId = await UserService.instance.getCurrentUserId();
        final success = await deleteSugarIntakeRecord(
          userId: userId!,
          recordId: record.id,
        );

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Record deleted successfully'),
              backgroundColor: AppColors.success,
            ),
          );
          _loadDailyData(); // 重新加载数据
        } else {
          throw Exception('Failed to delete');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delete failed: ${e.toString()}'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    }
  }

  void _onAddRecord() {
    showDialog(
      context: context,
      builder: (context) => AddSugarRecordDialog(
        initialDate: widget.date, // 传入当前日期
      ),
    ).then((result) {
      if (result == true) {
        _loadDailyData(); // 重新加载数据
      }
    });
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }
}
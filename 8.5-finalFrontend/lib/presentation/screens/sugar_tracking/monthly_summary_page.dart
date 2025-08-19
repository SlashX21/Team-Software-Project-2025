import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../widgets/sugar_progress_ring.dart';
import 'daily_detail_page.dart';
import '../../../domain/entities/monthly_sugar_calendar.dart';
import '../../../domain/entities/daily_sugar_summary.dart';
import '../../../services/api.dart';
import '../../../services/user_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';

class MonthlySummaryPage extends StatefulWidget {
  @override
  _MonthlySummaryPageState createState() => _MonthlySummaryPageState();
}

class _MonthlySummaryPageState extends State<MonthlySummaryPage> {
  DateTime _selectedMonth = DateTime.now();
  MonthlySugarCalendar? _calendarData;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMonthlyData();
  }

  Future<void> _loadMonthlyData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get user ID from UserService
      final userId = await UserService.instance.getCurrentUserId();
      if (userId == null) {
        setState(() {
          _error = 'User not logged in';
          _isLoading = false;
        });
        return;
      }
      
      // Call the actual API
      final response = await getMonthlySugarCalendar(
        userId: userId,
        year: _selectedMonth.year,
        month: _selectedMonth.month,
      );
      
      if (response != null) {
        _calendarData = MonthlySugarCalendar.fromJson(response);
      } else {
        // Fallback to sample data for development
        _calendarData = _createSampleCalendarData();
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  MonthlySugarCalendar _createSampleCalendarData() {
    final daysInMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    final dailySummaries = <DailySugarSummary>[];
    
    // For fallback data, only create summary for today if it's in the current month
    final now = DateTime.now();
    final isCurrentMonth = _selectedMonth.year == now.year && _selectedMonth.month == now.month;
    
    if (isCurrentMonth) {
      // Only add today's data with 0 intake if it's the current month
      final todaySummary = DailySugarSummary(
        userId: 1, // Will be updated once backend is connected
        date: DateTime(now.year, now.month, now.day),
        totalIntakeMg: 0.0, // Start with 0 intake
                  dailyGoalMg: 50000.0, // Default 50g goal
        progressPercentage: 0.0,
        status: 'good',
        recordCount: 0,
        createdAt: now,
        updatedAt: now,
      );
      dailySummaries.add(todaySummary);
    }
    
    // All historical dates should have NO data, so they appear as empty circles
    
    return MonthlySugarCalendar(
      year: _selectedMonth.year,
      month: _selectedMonth.month,
      dailySummaries: dailySummaries,
      monthlyAverageIntake: dailySummaries.isEmpty ? 0 : 
        dailySummaries.map((s) => s.totalIntakeMg).reduce((a, b) => a + b) / dailySummaries.length,
      daysTracked: dailySummaries.length,
      daysOverGoal: dailySummaries.where((s) => s.progressPercentage > 100).length,
      overallAchievementRate: dailySummaries.isEmpty ? 0 :
        dailySummaries.where((s) => s.progressPercentage <= 100).length / dailySummaries.length * 100,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Monthly Sugar Statistics',
          style: AppStyles.h2.copyWith(color: AppColors.white),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black26,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildMonthSelector(),
            if (_calendarData != null) _buildMonthlyStatsCard(),
            _buildCalendarContent(),
            SizedBox(height: 20), // Bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              final prevMonth = DateTime(
                _selectedMonth.year,
                _selectedMonth.month - 1,
              );
              setState(() => _selectedMonth = prevMonth);
              _loadMonthlyData();
            },
            icon: Icon(Icons.chevron_left, size: 28),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey[100],
              shape: CircleBorder(),
            ),
          ),
          Text(
            _isCurrentMonth()
                ? 'This Month'
                : DateFormat('MMM yyyy').format(_selectedMonth),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          IconButton(
            onPressed: _canGoToNextMonth() ? () {
              final nextMonth = DateTime(
                _selectedMonth.year,
                _selectedMonth.month + 1,
              );
              setState(() => _selectedMonth = nextMonth);
              _loadMonthlyData();
            } : null,
            icon: Icon(Icons.chevron_right, size: 28),
            style: IconButton.styleFrom(
              backgroundColor: _canGoToNextMonth() 
                  ? Colors.grey[100] 
                  : Colors.grey[50],
              shape: CircleBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyStatsCard() {
    final data = _calendarData!;
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📊 Monthly Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Tracked Days',
                  '${data.daysTracked}/${data.totalDaysInMonth}',
                  Colors.blue[600]!,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Avg Intake',
                  data.formattedAverageIntake,
                  Colors.orange[600]!,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Over Goal',
                  '${data.daysOverGoal} days',
                  Colors.red[600]!,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Success Rate',
                  '${data.overallAchievementRate.toInt()}%',
                  Colors.green[600]!,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarContent() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.green[600]),
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
              onPressed: _loadMonthlyData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
              ),
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    return _buildCalendarGrid();
  }

  Widget _buildCalendarGrid() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildWeekdayHeaders(),
          SizedBox(height: 8),
          _buildDateGrid(),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeaders() {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Row(
      children: weekdays.map((day) => Expanded(
        child: Center(
          child: Text(
            day,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildDateGrid() {
    final calendarGrid = _calendarData!.generateCalendarGrid();
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate cell size based on available width
        final cellSize = (constraints.maxWidth - (6 * 8)) / 7; // 8 is crossAxisSpacing
        final gridHeight = cellSize * 6 + (5 * 8); // 6 rows + spacing
        
        return SizedBox(
          height: gridHeight,
          child: GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.0,
            ),
            itemCount: 42, // Fixed 42 positions (6 weeks × 7 days)
            itemBuilder: (context, index) {
              // Add boundary check to prevent index out of range
              if (index >= calendarGrid.length) {
                return Container(); // Safety fallback
              }
              
              final date = calendarGrid[index];
              if (date == null) {
                return Container(); // Empty position
              }
              
              final summary = _calendarData!.getSummaryForDate(date);
              return _buildDateCell(date, summary);
            },
          ),
        );
      },
    );
  }

  Widget _buildDateCell(DateTime date, DailySugarSummary? summary) {
    final isToday = _isToday(date);
    final isFutureDate = date.isAfter(DateTime.now());
    final isCurrentMonth = date.month == _selectedMonth.month;
    
    
    return GestureDetector(
      onTap: (isFutureDate || !isCurrentMonth) ? null : () => _navigateToDailyDetail(date),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: isToday 
              ? Border.all(color: Colors.blue[600]!, width: 2) 
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Progress ring or empty ring
            if (summary != null && !isFutureDate && isCurrentMonth)
              SugarProgressRing(
                progressPercentage: summary.progressPercentage,
                status: summary.status,
                size: 36, // Reduced size to avoid overflow
                strokeWidth: 5,
              )
            else
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: (!isCurrentMonth || isFutureDate)
                        ? Colors.grey[300]! 
                        : Colors.grey[400]!,
                    width: 2,
                  ),
                ),
              ),
            // Date number
            Text(
              '${date.day}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: !isCurrentMonth
                    ? Colors.grey[400] // Non-current month dates are gray
                    : isFutureDate
                        ? Colors.grey[500]
                        : (summary != null ? Colors.white : Colors.grey[700]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDailyDetail(DateTime date) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DailyDetailPage(
          date: date,
          fromMonthlySummary: true,
        ),
      ),
    ).then((_) {
      // Refresh data when returning from detail page
      _loadMonthlyData();
    });
  }

  bool _isCurrentMonth() {
    final now = DateTime.now();
    return _selectedMonth.year == now.year && _selectedMonth.month == now.month;
  }

  bool _canGoToNextMonth() {
    final now = DateTime.now();
    final nextMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    return nextMonth.isBefore(now) || 
           (nextMonth.year == now.year && nextMonth.month == now.month);
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }
}
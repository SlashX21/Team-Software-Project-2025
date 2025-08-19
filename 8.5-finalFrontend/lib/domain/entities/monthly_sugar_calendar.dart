import 'daily_sugar_summary.dart';

class MonthlySugarCalendar {
  final int year;
  final int month;
  final List<DailySugarSummary> dailySummaries;
  final double monthlyAverageIntake;
  final int daysTracked;
  final int daysOverGoal;
  final double overallAchievementRate;
  
  MonthlySugarCalendar({
    required this.year,
    required this.month,
    required this.dailySummaries,
    required this.monthlyAverageIntake,
    required this.daysTracked,
    required this.daysOverGoal,
    required this.overallAchievementRate,
  });
  
  factory MonthlySugarCalendar.fromJson(Map<String, dynamic> json) {
    // 适配后端返回的数据结构 - 使用 dailySummaries 而不是 monthlySummaries
    final summaries = (json['dailySummaries'] as List?)
        ?.map((item) => DailySugarSummary.fromJson(item))
        .toList() ?? [];
    
    // 直接使用后端返回的年月和统计数据
    return MonthlySugarCalendar(
      year: json['year'] ?? DateTime.now().year,
      month: json['month'] ?? DateTime.now().month,
      dailySummaries: summaries,
      monthlyAverageIntake: json['monthlyAverageIntake']?.toDouble() ?? 0.0,
      daysTracked: json['daysTracked'] ?? 0,
      daysOverGoal: json['daysOverGoal'] ?? 0,
      overallAchievementRate: json['overallAchievementRate']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'month': month,
      'dailySummaries': dailySummaries.map((summary) => summary.toJson()).toList(),
      'monthlyAverageIntake': monthlyAverageIntake,
      'daysTracked': daysTracked,
      'daysOverGoal': daysOverGoal,
      'overallAchievementRate': overallAchievementRate,
    };
  }
  
  // 计算属性
  String get monthDisplayName {
    final months = ['', 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return '${months[month]} $year';
  }
  
  int get totalDaysInMonth => DateTime(year, month + 1, 0).day;
  String get formattedAverageIntake => _formatSugarAmount(monthlyAverageIntake);

  // 获取指定日期的汇总数据
  DailySugarSummary? getSummaryForDate(DateTime date) {
    try {
      final result = dailySummaries.firstWhere(
        (summary) => summary.date.day == date.day && 
                    summary.date.month == date.month && 
                    summary.date.year == date.year
      );
      return result;
    } catch (e) {
      return null;
    }
  }
  
  // 生成日历网格数据
  List<DateTime?> generateCalendarGrid() {
    final firstDayOfMonth = DateTime(year, month, 1);
    final firstWeekday = firstDayOfMonth.weekday;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    
    final calendarGrid = <DateTime?>[];
    
    // 添加月初空白日期 (Monday = 1, Sunday = 7)
    for (int i = 1; i < firstWeekday; i++) {
      calendarGrid.add(null);
    }
    
    // 添加月份中的日期
    for (int day = 1; day <= daysInMonth; day++) {
      calendarGrid.add(DateTime(year, month, day));
    }
    
    // 补齐到42个位置 (6周 × 7天)
    while (calendarGrid.length < 42) {
      calendarGrid.add(null);
    }
    
    return calendarGrid;
  }
  
  String _formatSugarAmount(double amountMg) {
    if (amountMg >= 1000) {
      return '${(amountMg / 1000).toStringAsFixed(1)}g';
    } else {
      return '${amountMg.toInt()}mg';
    }
  }
}
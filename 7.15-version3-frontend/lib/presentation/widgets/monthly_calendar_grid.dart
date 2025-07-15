import 'package:flutter/material.dart';
import '../../domain/entities/monthly_sugar_calendar.dart';
import '../../domain/entities/daily_sugar_summary.dart';
import 'sugar_progress_ring.dart';

class MonthlyCalendarGrid extends StatelessWidget {
  final MonthlySugarCalendar calendarData;
  final Function(DateTime) onDateTap;
  
  const MonthlyCalendarGrid({
    Key? key,
    required this.calendarData,
    required this.onDateTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final calendarGrid = calendarData.generateCalendarGrid();
    
    return Column(
      children: [
        // 星期标题
        _buildWeekdayHeaders(),
        SizedBox(height: 16),
        // 日历网格
        GridView.builder(
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
              return Container(); // Empty date
            }
            
            final summary = calendarData.getSummaryForDate(date);
            return _buildDateCell(date, summary);
          },
        ),
      ],
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
              color: Colors.grey[600],
            ),
          ),
        ),
      )).toList(),
    );
  }
  
  Widget _buildDateCell(DateTime date, DailySugarSummary? summary) {
    final isToday = date.day == DateTime.now().day &&
                   date.month == DateTime.now().month &&
                   date.year == DateTime.now().year;
    
    return GestureDetector(
      onTap: () => onDateTap(date),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: isToday ? Border.all(color: Colors.blue, width: 2) : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 进度环（如果有数据）
            if (summary != null)
              SugarProgressRing(
                progressPercentage: summary.progressPercentage,
                status: summary.status,
                size: 36,
                strokeWidth: 3,
              )
            else
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
              ),
            // 日期数字
            Text(
              '${date.day}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: summary != null ? Colors.white : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
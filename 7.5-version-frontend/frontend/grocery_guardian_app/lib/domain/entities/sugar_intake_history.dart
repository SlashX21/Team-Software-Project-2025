class SugarIntakeHistory {
  final List<DailySugarData> dailyData;
  final double averageDailyIntake;
  final double totalIntake;
  final int daysOverGoal;
  final List<String> topFoodSources;

  SugarIntakeHistory({
    required this.dailyData,
    required this.averageDailyIntake,
    required this.totalIntake,
    required this.daysOverGoal,
    required this.topFoodSources,
  });

  factory SugarIntakeHistory.fromJson(Map<String, dynamic> json) {
    return SugarIntakeHistory(
      dailyData: (json['dailyData'] as List? ?? [])
          .map((item) => DailySugarData.fromJson(item))
          .toList(),
      averageDailyIntake: json['averageDailyIntake']?.toDouble() ?? 0.0,
      totalIntake: json['totalIntake']?.toDouble() ?? 0.0,
      daysOverGoal: json['daysOverGoal'] ?? 0,
      topFoodSources: List<String>.from(json['topFoodSources'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dailyData': dailyData.map((data) => data.toJson()).toList(),
      'averageDailyIntake': averageDailyIntake,
      'totalIntake': totalIntake,
      'daysOverGoal': daysOverGoal,
      'topFoodSources': topFoodSources,
    };
  }

  // 格式化平均摄入量
  String get formattedAverageIntake {
    if (averageDailyIntake >= 1000) {
      return '${(averageDailyIntake / 1000).toStringAsFixed(1)}g';
    } else {
      return '${averageDailyIntake.toInt()}mg';
    }
  }

  // 格式化总摄入量
  String get formattedTotalIntake {
    if (totalIntake >= 1000) {
      return '${(totalIntake / 1000).toStringAsFixed(1)}g';
    } else {
      return '${totalIntake.toInt()}mg';
    }
  }

  // 计算达标率
  double get goalAchievementRate {
    if (dailyData.isEmpty) return 0.0;
    final daysWithGoal = dailyData.length;
    final daysOnTarget = daysWithGoal - daysOverGoal;
    return (daysOnTarget / daysWithGoal) * 100;
  }
}

class DailySugarData {
  final DateTime date;
  final double intakeMg;
  final double goalMg;

  DailySugarData({
    required this.date,
    required this.intakeMg,
    required this.goalMg,
  });

  factory DailySugarData.fromJson(Map<String, dynamic> json) {
    return DailySugarData(
      date: DateTime.parse(json['date']),
      intakeMg: json['intakeMg']?.toDouble() ?? 0.0,
      goalMg: json['goalMg']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'intakeMg': intakeMg,
      'goalMg': goalMg,
    };
  }

  // 计算当日进度百分比
  double get progressPercentage {
    if (goalMg == 0) return 0.0;
    return (intakeMg / goalMg) * 100;
  }

  // 判断是否超标
  bool get isOverGoal => intakeMg > goalMg;

  // 格式化摄入量显示
  String get formattedIntake {
    if (intakeMg >= 1000) {
      return '${(intakeMg / 1000).toStringAsFixed(1)}g';
    } else {
      return '${intakeMg.toInt()}mg';
    }
  }

  // 格式化目标显示
  String get formattedGoal {
    if (goalMg >= 1000) {
      return '${(goalMg / 1000).toStringAsFixed(1)}g';
    } else {
      return '${goalMg.toInt()}mg';
    }
  }

  // 格式化日期显示
  String get formattedDate {
    return '${date.month}/${date.day}';
  }
}
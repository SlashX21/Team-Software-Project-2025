import 'package:flutter/material.dart';
import 'sugar_contributor.dart';

class DailySugarIntake {
  final double currentIntakeMg;
  final double dailyGoalMg;
  final double progressPercentage;
  final String status; // 'good', 'warning', 'over_limit'
  final List<SugarContributor> topContributors;
  final DateTime date;

  DailySugarIntake({
    required this.currentIntakeMg,
    required this.dailyGoalMg,
    required this.progressPercentage,
    required this.status,
    required this.topContributors,
    required this.date,
  });

  factory DailySugarIntake.fromJson(Map<String, dynamic> json) {
    return DailySugarIntake(
      currentIntakeMg: json['currentIntakeMg']?.toDouble() ?? 0.0,
      dailyGoalMg: json['dailyGoalMg']?.toDouble() ?? 0.0,
      progressPercentage: json['progressPercentage']?.toDouble() ?? 0.0,
      status: json['status'] ?? 'good',
      topContributors: (json['topContributors'] as List? ?? [])
          .map((item) => SugarContributor.fromJson(item))
          .toList(),
      date: DateTime.parse(json['date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentIntakeMg': currentIntakeMg,
      'dailyGoalMg': dailyGoalMg,
      'progressPercentage': progressPercentage,
      'status': status,
      'topContributors': topContributors.map((contributor) => contributor.toJson()).toList(),
      'date': date.toIso8601String(),
    };
  }

  // 获取状态显示文字
  String get statusText {
    switch (status) {
      case 'good':
        return 'Good Progress';
      case 'warning':
        return 'Warning';
      case 'over_limit':
        return 'Over Limit';
      default:
        return 'Unknown';
    }
  }

  // 获取状态颜色
  Color get statusColor {
    switch (status) {
      case 'good':
        return Color(0xFF4CAF50); // 绿色
      case 'warning':
        return Color(0xFFFF9800); // 橙色
      case 'over_limit':
        return Color(0xFFF44336); // 红色
      default:
        return Color(0xFF757575); // 灰色
    }
  }

  // 获取进度条颜色
  Color get progressColor {
    if (progressPercentage <= 70) {
      return Color(0xFF4CAF50); // 绿色
    } else if (progressPercentage <= 100) {
      return Color(0xFFFF9800); // 橙色
    } else {
      return Color(0xFFF44336); // 红色
    }
  }

  // 格式化显示的摄入量文本
  String get formattedCurrentIntake {
    if (currentIntakeMg >= 1000) {
      return '${(currentIntakeMg / 1000).toStringAsFixed(1)}g';
    } else {
      return '${currentIntakeMg.toInt()}mg';
    }
  }

  // 格式化显示的目标文本
  String get formattedDailyGoal {
    if (dailyGoalMg >= 1000) {
      return '${(dailyGoalMg / 1000).toStringAsFixed(1)}g';
    } else {
      return '${dailyGoalMg.toInt()}mg';
    }
  }
}
import 'package:flutter/material.dart';

class DailySugarSummary {
  final int userId;
  final DateTime date;
  final double totalIntakeMg;
  final double dailyGoalMg;
  final double progressPercentage;
  final String status;
  final int recordCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  DailySugarSummary({
    required this.userId,
    required this.date,
    required this.totalIntakeMg,
    required this.dailyGoalMg,
    required this.progressPercentage,
    required this.status,
    required this.recordCount,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory DailySugarSummary.fromJson(Map<String, dynamic> json) {
    return DailySugarSummary(
      userId: json['userId'] ?? 0,
      date: DateTime.parse(json['date']),
      totalIntakeMg: json['totalIntakeMg']?.toDouble() ?? 0.0,
      dailyGoalMg: json['dailyGoalMg']?.toDouble() ?? 0.0,
      progressPercentage: json['progressPercentage']?.toDouble() ?? 0.0,
      status: json['status'] ?? 'unknown',
      recordCount: json['recordCount'] ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'date': date.toIso8601String(),
      'totalIntakeMg': totalIntakeMg,
      'dailyGoalMg': dailyGoalMg,
      'progressPercentage': progressPercentage,
      'status': status,
      'recordCount': recordCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
  
  // 计算属性
  Color get statusColor {
    // 优先基于progressPercentage计算颜色，因为后端status可能不准确
    if (progressPercentage > 100) {
      return Colors.red;    // 超过100%为红色
    } else if (progressPercentage > 70) {
      return Colors.orange; // 70%-100%为橙色
    } else {
      return Colors.green;  // 70%以下为绿色
    }
  }
  
  String get formattedTotalIntake => _formatSugarAmount(totalIntakeMg);
  String get formattedDailyGoal => _formatSugarAmount(dailyGoalMg);
  bool get hasRecords => recordCount > 0;
  bool get isGoalAchieved => progressPercentage <= 100;
  
  // 获取状态显示文字
  String get statusText {
    // 优先基于progressPercentage计算状态文字，因为后端status可能不准确
    if (progressPercentage > 100) {
      return 'Over Limit';
    } else if (progressPercentage > 70) {
      return 'Warning';
    } else {
      return 'Good Progress';
    }
  }
  
  String _formatSugarAmount(double amountMg) {
    if (amountMg >= 1000) {
      return '${(amountMg / 1000).toStringAsFixed(1)}g';
    } else {
      return '${amountMg.toInt()}mg';
    }
  }
}
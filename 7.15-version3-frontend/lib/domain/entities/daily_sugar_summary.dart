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
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
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
    switch (status) {
      case 'good':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'over_limit':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  String get formattedTotalIntake => _formatSugarAmount(totalIntakeMg);
  String get formattedDailyGoal => _formatSugarAmount(dailyGoalMg);
  bool get hasRecords => recordCount > 0;
  bool get isGoalAchieved => progressPercentage <= 100;
  
  String _formatSugarAmount(double amountMg) {
    if (amountMg >= 1000) {
      return '${(amountMg / 1000).toStringAsFixed(1)}g';
    } else {
      return '${amountMg.toInt()}mg';
    }
  }
}
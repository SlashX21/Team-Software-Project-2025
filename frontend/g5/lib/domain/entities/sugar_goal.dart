class SugarGoal {
  final double dailyGoalMg;
  final DateTime createdAt;
  final DateTime updatedAt;

  SugarGoal({
    required this.dailyGoalMg,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SugarGoal.fromJson(Map<String, dynamic> json) {
    return SugarGoal(
      dailyGoalMg: json['dailyGoalMg']?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dailyGoalMg': dailyGoalMg,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // 格式化目标显示
  String get formattedGoal {
    if (dailyGoalMg >= 1000) {
      return '${(dailyGoalMg / 1000).toStringAsFixed(1)}g';
    } else {
      return '${dailyGoalMg.toInt()}mg';
    }
  }

  // 目标等级描述
  String get goalLevelDescription {
    if (dailyGoalMg <= 600) {
      return 'Strict';
    } else if (dailyGoalMg <= 1000) {
      return 'Moderate';
    } else if (dailyGoalMg <= 1500) {
      return 'Relaxed';
    } else {
      return 'Flexible';
    }
  }

  // 目标健康评级
  String get healthRating {
    if (dailyGoalMg <= 600) {
      return 'Excellent';
    } else if (dailyGoalMg <= 1000) {
      return 'Good';
    } else if (dailyGoalMg <= 1500) {
      return 'Fair';
    } else {
      return 'Needs Improvement';
    }
  }

  // 获取推荐目标范围提示
  String get recommendationHint {
    if (dailyGoalMg < 600) {
      return 'Very strict goal. Consider 600-1000mg for balance.';
    } else if (dailyGoalMg <= 1000) {
      return 'Great goal! This aligns with health recommendations.';
    } else if (dailyGoalMg <= 1500) {
      return 'Moderate goal. Consider reducing to 1000mg or less.';
    } else {
      return 'Consider lowering your goal for better health benefits.';
    }
  }

  // 是否为新目标（24小时内设置）
  bool get isNewGoal {
    final now = DateTime.now();
    return now.difference(createdAt).inHours < 24;
  }

  // 目标设置了多长时间
  String get goalAge {
    final now = DateTime.now();
    final age = now.difference(createdAt);
    
    if (age.inDays > 0) {
      return '${age.inDays} days ago';
    } else if (age.inHours > 0) {
      return '${age.inHours} hours ago';
    } else {
      return 'Just now';
    }
  }
}
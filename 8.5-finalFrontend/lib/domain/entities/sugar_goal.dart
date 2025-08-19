enum GoalLevel {
  strict('STRICT', 25000.0),
  moderate('MODERATE', 40000.0),
  relaxed('RELAXED', 50000.0),
  custom('CUSTOM', 0.0);

  const GoalLevel(this.value, this.defaultMg);
  final String value;
  final double defaultMg;

  static GoalLevel fromValue(String value) {
    return GoalLevel.values.firstWhere(
      (level) => level.value == value,
      orElse: () => GoalLevel.custom,
    );
  }
}

class SugarGoal {
  final double dailyGoalMg;
  final String? goalLevel;
  final DateTime createdAt;
  final DateTime updatedAt;

  SugarGoal({
    required this.dailyGoalMg,
    this.goalLevel,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SugarGoal.fromJson(Map<String, dynamic> json) {
    return SugarGoal(
      dailyGoalMg: json['dailyGoalMg']?.toDouble() ?? 0.0,
      goalLevel: json['goalLevel'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dailyGoalMg': dailyGoalMg,
      'goalLevel': goalLevel,
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
    if (goalLevel != null) {
      return goalLevel!;
    }
    // 向后兼容，基于目标值推断
    if (dailyGoalMg <= 25000) {
      return 'STRICT';
    } else if (dailyGoalMg <= 40000) {
      return 'MODERATE';
    } else if (dailyGoalMg <= 50000) {
      return 'RELAXED';
    } else {
      return 'CUSTOM';
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

  // 获取目标等级枚举
  GoalLevel get goalLevelEnum {
    if (goalLevel != null) {
      return GoalLevel.fromValue(goalLevel!);
    }
    // 向后兼容，基于目标值推断
    if (dailyGoalMg <= 25000) {
      return GoalLevel.strict;
    } else if (dailyGoalMg <= 40000) {
      return GoalLevel.moderate;
    } else if (dailyGoalMg <= 50000) {
      return GoalLevel.relaxed;
    } else {
      return GoalLevel.custom;
    }
  }
}
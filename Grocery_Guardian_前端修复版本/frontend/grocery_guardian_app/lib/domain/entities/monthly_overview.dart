import 'package:flutter/material.dart';

class MonthlyOverview {
  final int year;
  final int month;
  final int receiptUploads;
  final int totalProducts;
  final double totalSpent;
  final String monthName;

  MonthlyOverview({
    required this.year,
    required this.month,
    required this.receiptUploads,
    required this.totalProducts,
    required this.totalSpent,
    required this.monthName,
  });

  factory MonthlyOverview.fromJson(Map<String, dynamic> json) {
    return MonthlyOverview(
      year: json['year'] ?? 0,
      month: json['month'] ?? 0,
      receiptUploads: json['receiptUploads'] ?? 0,
      totalProducts: json['totalProducts'] ?? 0,
      totalSpent: json['totalSpent']?.toDouble() ?? 0.0,
      monthName: json['monthName'] ?? '',
    );
  }

  String get formattedMonth => '$monthName $year';
  String get formattedSpent => '\$${totalSpent.toStringAsFixed(2)}';
}

class MonthlypurchaseSummary {
  final List<CategorySummary> categoryBreakdown;
  final List<PopularProduct> popularProducts;
  final Map<String, double> spendingByCategory;
  final int uniqueProducts;
  final double averageReceiptValue;

  MonthlypurchaseSummary({
    required this.categoryBreakdown,
    required this.popularProducts,
    required this.spendingByCategory,
    required this.uniqueProducts,
    required this.averageReceiptValue,
  });

  factory MonthlypurchaseSummary.fromJson(Map<String, dynamic> json) {
    return MonthlypurchaseSummary(
      categoryBreakdown: (json['categoryBreakdown'] as List? ?? [])
          .map((item) => CategorySummary.fromJson(item))
          .toList(),
      popularProducts: (json['popularProducts'] as List? ?? [])
          .map((item) => PopularProduct.fromJson(item))
          .toList(),
      spendingByCategory: Map<String, double>.from(json['spendingByCategory'] ?? {}),
      uniqueProducts: json['uniqueProducts'] ?? 0,
      averageReceiptValue: json['averageReceiptValue']?.toDouble() ?? 0.0,
    );
  }
}

class CategorySummary {
  final String categoryName;
  final int productCount;
  final double percentage;
  final double totalSpent;
  final String iconName;

  CategorySummary({
    required this.categoryName,
    required this.productCount,
    required this.percentage,
    required this.totalSpent,
    required this.iconName,
  });

  factory CategorySummary.fromJson(Map<String, dynamic> json) {
    return CategorySummary(
      categoryName: json['categoryName'] ?? '',
      productCount: json['productCount'] ?? 0,
      percentage: json['percentage']?.toDouble() ?? 0.0,
      totalSpent: json['totalSpent']?.toDouble() ?? 0.0,
      iconName: json['iconName'] ?? '📦',
    );
  }
}

class PopularProduct {
  final String productName;
  final int purchaseCount;
  final String barcode;
  final double averagePrice;
  final String categoryName;

  PopularProduct({
    required this.productName,
    required this.purchaseCount,
    required this.barcode,
    required this.averagePrice,
    required this.categoryName,
  });

  factory PopularProduct.fromJson(Map<String, dynamic> json) {
    return PopularProduct(
      productName: json['productName'] ?? '',
      purchaseCount: json['purchaseCount'] ?? 0,
      barcode: json['barcode'] ?? '',
      averagePrice: json['averagePrice']?.toDouble() ?? 0.0,
      categoryName: json['categoryName'] ?? '',
    );
  }
}

class MonthlyNutritionInsights {
  final Map<String, NutritionMetric> nutritionBreakdown;
  final double overallNutritionScore;
  final Map<String, String> nutritionGoalsStatus;

  MonthlyNutritionInsights({
    required this.nutritionBreakdown,
    required this.overallNutritionScore,
    required this.nutritionGoalsStatus,
  });

  factory MonthlyNutritionInsights.fromJson(Map<String, dynamic> json) {
    final nutritionMap = <String, NutritionMetric>{};
    if (json['nutritionBreakdown'] != null) {
      (json['nutritionBreakdown'] as Map<String, dynamic>).forEach((key, value) {
        nutritionMap[key] = NutritionMetric.fromJson(value);
      });
    }

    return MonthlyNutritionInsights(
      nutritionBreakdown: nutritionMap,
      overallNutritionScore: json['overallNutritionScore']?.toDouble() ?? 0.0,
      nutritionGoalsStatus: Map<String, String>.from(json['nutritionGoalsStatus'] ?? {}),
    );
  }
}

class NutritionMetric {
  final double currentValue;
  final double targetValue;
  final double percentage;
  final String unit;
  final String status;

  NutritionMetric({
    required this.currentValue,
    required this.targetValue,
    required this.percentage,
    required this.unit,
    required this.status,
  });

  factory NutritionMetric.fromJson(Map<String, dynamic> json) {
    return NutritionMetric(
      currentValue: json['currentValue']?.toDouble() ?? 0.0,
      targetValue: json['targetValue']?.toDouble() ?? 0.0,
      percentage: json['percentage']?.toDouble() ?? 0.0,
      unit: json['unit'] ?? '',
      status: json['status'] ?? 'unknown',
    );
  }

  Color get statusColor {
    switch (status) {
      case 'excellent':
        return Color(0xFF4CAF50);
      case 'good':
        return Color(0xFF8BC34A);
      case 'low':
        return Color(0xFFFF9800);
      case 'high':
        return Color(0xFFF44336);
      default:
        return Color(0xFF757575);
    }
  }

  String get statusText {
    switch (status) {
      case 'excellent':
        return 'Excellent';
      case 'good':
        return 'Good';
      case 'low':
        return 'Low';
      case 'high':
        return 'High';
      default:
        return 'Unknown';
    }
  }
}

class HealthInsight {
  final String id;
  final String title;
  final String description;
  final String category;
  final String priority;
  final String iconName;
  final DateTime createdAt;

  HealthInsight({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.iconName,
    required this.createdAt,
  });

  factory HealthInsight.fromJson(Map<String, dynamic> json) {
    return HealthInsight(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? 'nutrition',
      priority: json['priority'] ?? 'medium',
      iconName: json['iconName'] ?? '💡',
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Color get priorityColor {
    switch (priority) {
      case 'high':
        return Color(0xFFF44336);
      case 'medium':
        return Color(0xFFFF9800);
      case 'low':
        return Color(0xFF4CAF50);
      default:
        return Color(0xFF757575);
    }
  }
}

class MonthlyComparison {
  final ComparisonMetrics currentMonth;
  final ComparisonMetrics previousMonth;
  final Map<String, double> changePercentages;
  final List<String> improvements;
  final List<String> regressions;

  MonthlyComparison({
    required this.currentMonth,
    required this.previousMonth,
    required this.changePercentages,
    required this.improvements,
    required this.regressions,
  });

  factory MonthlyComparison.fromJson(Map<String, dynamic> json) {
    return MonthlyComparison(
      currentMonth: ComparisonMetrics.fromJson(json['currentMonth'] ?? {}),
      previousMonth: ComparisonMetrics.fromJson(json['previousMonth'] ?? {}),
      changePercentages: Map<String, double>.from(json['changePercentages'] ?? {}),
      improvements: List<String>.from(json['improvements'] ?? []),
      regressions: List<String>.from(json['regressions'] ?? []),
    );
  }
}

class ComparisonMetrics {
  final double healthScore;
  final int totalScans;
  final double totalSpent;
  final Map<String, double> nutritionAverages;

  ComparisonMetrics({
    required this.healthScore,
    required this.totalScans,
    required this.totalSpent,
    required this.nutritionAverages,
  });

  factory ComparisonMetrics.fromJson(Map<String, dynamic> json) {
    return ComparisonMetrics(
      healthScore: json['healthScore']?.toDouble() ?? 0.0,
      totalScans: json['totalScans'] ?? 0,
      totalSpent: json['totalSpent']?.toDouble() ?? 0.0,
      nutritionAverages: Map<String, double>.from(json['nutritionAverages'] ?? {}),
    );
  }
}
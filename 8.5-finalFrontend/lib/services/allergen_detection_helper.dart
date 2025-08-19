import '../domain/entities/product_analysis.dart';
import '../presentation/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// 过敏原匹配结果类 - 包含严重性等级信息
class AllergenMatch {
  final String allergenName;
  final String severityLevel;
  final String productAllergen;
  final Map<String, dynamic> userAllergenData;
  
  AllergenMatch({
    required this.allergenName,
    required this.severityLevel,
    required this.productAllergen,
    required this.userAllergenData,
  });
}

/// 可复用的过敏原检测助手类
/// 支持单产品和小票批量检测，为扫描页面和小票分析提供统一的检测逻辑
class AllergenDetectionHelper {
  
  /// 单产品过敏原检测 - 修复：使用ingredients而非allergens字段进行精确匹配
  static List<AllergenMatch> detectSingleProduct({
    required ProductAnalysis product,
    required List<Map<String, dynamic>> userAllergens,
  }) {
    if (userAllergens.isEmpty) {
      return [];
    }
    
    List<AllergenMatch> matches = [];
    String ingredientsLower = product.ingredients.join(' ').toLowerCase();
    
    // 对每个用户过敏原检查是否在实际成分中出现
    for (Map<String, dynamic> userAllergen in userAllergens) {
      String userAllergenName = (userAllergen['name'] ?? userAllergen['allergenName'] ?? '').toString();
      String userAllergenLower = userAllergenName.toLowerCase();
      
      // 检查是否在实际成分中匹配
      String? matchedIngredient = _findAllergenInIngredients(ingredientsLower, userAllergenLower);
      
      if (matchedIngredient != null) {
        matches.add(AllergenMatch(
          allergenName: userAllergenName,
          severityLevel: userAllergen['severityLevel'] ?? 'MILD',
          productAllergen: matchedIngredient,
          userAllergenData: userAllergen,
        ));
      }
    }
    
    // 按严重性等级排序：SEVERE > MODERATE > MILD
    matches.sort((a, b) {
      const severityOrder = {'SEVERE': 0, 'MODERATE': 1, 'MILD': 2};
      int orderA = severityOrder[a.severityLevel] ?? 3;
      int orderB = severityOrder[b.severityLevel] ?? 3;
      return orderA.compareTo(orderB);
    });
    
    return matches;
  }
  
  /// 批量产品过敏原检测 - 为小票分析准备
  static Map<ProductAnalysis, List<AllergenMatch>> detectBatchProducts({
    required List<ProductAnalysis> products,
    required List<Map<String, dynamic>> userAllergens,
  }) {
    Map<ProductAnalysis, List<AllergenMatch>> results = {};
    
    for (ProductAnalysis product in products) {
      results[product] = detectSingleProduct(
        product: product,
        userAllergens: userAllergens,
      );
    }
    
    return results;
  }
  
  /// 获取批量检测的统计摘要 - 为小票摘要准备
  static AllergenBatchSummary getBatchSummary(Map<ProductAnalysis, List<AllergenMatch>> batchResults) {
    int totalProducts = batchResults.length;
    int productsWithAllergens = batchResults.values.where((matches) => matches.isNotEmpty).length;
    
    // 收集所有匹配的过敏原，按严重性分组
    Map<String, int> severityCount = {'SEVERE': 0, 'MODERATE': 0, 'MILD': 0};
    Set<String> allMatchedAllergens = {};
    
    for (List<AllergenMatch> matches in batchResults.values) {
      for (AllergenMatch match in matches) {
        allMatchedAllergens.add(match.allergenName);
        severityCount[match.severityLevel] = (severityCount[match.severityLevel] ?? 0) + 1;
      }
    }
    
    return AllergenBatchSummary(
      totalProducts: totalProducts,
      productsWithAllergens: productsWithAllergens,
      totalUniqueAllergens: allMatchedAllergens.length,
      severityBreakdown: severityCount,
      mostSevereLevel: _getMostSevereLevel(severityCount),
    );
  }
  
  /// 在成分列表中精确查找过敏原匹配 - 修复后的核心逻辑
  static String? _findAllergenInIngredients(String ingredientsLower, String userAllergenLower) {
    // 定义过敏原及其在成分中的可能表现形式
    const Map<String, List<String>> allergenPatterns = {
      'cinnamon': ['cinnamon'],
      'milk': ['milk', 'dairy', 'lactose', 'casein', 'whey', 'butter', 'cream'],
      'wheat': ['wheat', 'flour', 'gluten'],
      'egg': ['egg', 'eggs', 'albumin'],
      'soy': ['soy', 'soya', 'soybean'],
      'peanut': ['peanut', 'peanuts', 'groundnut'],
      'tree-nuts': ['almond', 'walnut', 'cashew', 'pecan', 'hazelnut', 'brazil nut', 'macadamia'],
      'fish': ['fish', 'salmon', 'tuna', 'cod'],
      'shellfish': ['crab', 'lobster', 'shrimp', 'prawns', 'shellfish'],
    };
    
    // 首先检查直接匹配
    if (ingredientsLower.contains(userAllergenLower)) {
      return userAllergenLower;
    }
    
    // 然后检查已知的过敏原模式
    List<String>? patterns = allergenPatterns[userAllergenLower];
    if (patterns != null) {
      for (String pattern in patterns) {
        if (ingredientsLower.contains(pattern)) {
          return pattern;
        }
      }
    }
    
    // 检查所有模式，寻找可能的匹配
    for (String baseAllergen in allergenPatterns.keys) {
      List<String> patterns = allergenPatterns[baseAllergen]!;
      
      if (patterns.contains(userAllergenLower)) {
        for (String pattern in patterns) {
          if (ingredientsLower.contains(pattern)) {
            return pattern;
          }
        }
      }
    }
    
    return null;
  }
  
  /// 已弃用的旧匹配逻辑 - 保留以防兼容性问题
  static bool _isAllergenMatch(String productAllergen, String userAllergen) {
    return false; // 不再使用这个方法
  }
  
  /// 获取最严重的等级
  static String _getMostSevereLevel(Map<String, int> severityCount) {
    if ((severityCount['SEVERE'] ?? 0) > 0) return 'SEVERE';
    if ((severityCount['MODERATE'] ?? 0) > 0) return 'MODERATE';
    if ((severityCount['MILD'] ?? 0) > 0) return 'MILD';
    return 'NONE';
  }
  
  /// 获取严重性等级颜色 - 复用管理页面的方案
  static Color getSeverityColor(String severity) {
    switch (severity.toUpperCase()) {
      case 'MILD':
        return AppColors.warning;
      case 'MODERATE':
        return Colors.orange;
      case 'SEVERE':
        return AppColors.alert;
      default:
        return Colors.grey;
    }
  }
  
  /// 获取严重性等级文本 - 复用管理页面的方案
  static String getSeverityText(String severity) {
    switch (severity.toUpperCase()) {
      case 'MILD':
        return 'Mild';
      case 'MODERATE':
        return 'Moderate';
      case 'SEVERE':
        return 'Severe';
      default:
        return 'Unknown';
    }
  }
}

/// 批量过敏原检测摘要类 - 为小票分析准备
class AllergenBatchSummary {
  final int totalProducts;
  final int productsWithAllergens;
  final int totalUniqueAllergens;
  final Map<String, int> severityBreakdown;
  final String mostSevereLevel;
  
  AllergenBatchSummary({
    required this.totalProducts,
    required this.productsWithAllergens,
    required this.totalUniqueAllergens,
    required this.severityBreakdown,
    required this.mostSevereLevel,
  });
  
  /// 是否有过敏原风险
  bool get hasAllergenRisk => productsWithAllergens > 0;
  
  /// 过敏原产品比例
  double get allergenProductRatio => totalProducts > 0 ? productsWithAllergens / totalProducts : 0.0;
  
  /// 获取风险等级描述
  String get riskDescription {
    if (!hasAllergenRisk) return 'No allergen risks detected';
    
    if (mostSevereLevel == 'SEVERE') {
      return 'High risk: Severe allergens detected';
    } else if (mostSevereLevel == 'MODERATE') {
      return 'Moderate risk: Some allergens detected';
    } else {
      return 'Low risk: Mild allergens detected';
    }
  }
}
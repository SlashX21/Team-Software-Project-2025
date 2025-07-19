// lib/domain/entities/recommendation_response.dart

// =========================================================================
// 主响应类 - 匹配 API 的最外层结构
// =========================================================================
class RecommendationResponse {
  final bool success;
  final String message;
  final RecommendationData? data; // data 可能为空，所以设为可空

  RecommendationResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory RecommendationResponse.fromJson(Map<String, dynamic> json) {
    return RecommendationResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? 'No message received',
      // 安全地解析 'data' 对象，如果不存在或为null，则data字段也为null
      data: json['data'] != null ? RecommendationData.fromJson(json['data']) : null,
    );
  }
}

// =========================================================================
// Data 对象类 - 匹配 API 的 "data" 字段内容
// =========================================================================
class RecommendationData {
  final String recommendationId;
  final String scanType;
  final UserProfileSummary userProfileSummary;
  final List<RecommendedProduct> recommendations;
  final LLMAnalysis llmInsights;

  RecommendationData({
    required this.recommendationId,
    required this.scanType,
    required this.userProfileSummary,
    required this.recommendations,
    required this.llmInsights,
  });

  factory RecommendationData.fromJson(Map<String, dynamic> json) {
    // 安全地处理 recommendations 列表，如果不存在或为null，则返回空列表
    var recommendationsList = json['recommendations'] as List? ?? [];

    return RecommendationData(
      recommendationId: json['recommendationId'] ?? 'N/A',
      scanType: json['scanType'] ?? 'N/A',
      userProfileSummary: UserProfileSummary.fromJson(json['userProfileSummary'] ?? {}),
      recommendations: recommendationsList
          .map((item) => RecommendedProduct.fromJson(item))
          .toList(),
      llmInsights: LLMAnalysis.fromJson(json['llmInsights'] ?? {}),
    );
  }
}

// =========================================================================
// 推荐商品类 - 匹配 "recommendations" 列表中的每个对象
// =========================================================================
class RecommendedProduct {
  final int rank;
  final ProductInfo productInfo; // 保持这个名字，但在fromJson中从'product'解析
  final double score;
  final String reason; // 保持这个名字，但在fromJson中从'reasoning'解析

  RecommendedProduct({
    required this.rank,
    required this.productInfo,
    required this.score,
    required this.reason,
  });

  factory RecommendedProduct.fromJson(Map<String, dynamic> json) {
    return RecommendedProduct(
      rank: json['rank'] ?? 0,
      // **核心修复1**: 从名为 'product' 的嵌套对象解析
      productInfo: ProductInfo.fromJson(json['product'] ?? {}),
      // **核心修复2**: 从名为 'recommendationScore' 的字段解析
      score: (json['recommendationScore'] as num?)?.toDouble() ?? 0.0,
      // **核心修复3**: 从名为 'reasoning' 的字段解析
      reason: json['reasoning'] ?? 'No reason provided.',
    );
  }
}

// =========================================================================
// 商品信息类 - 匹配 "product" 嵌套对象的内容
// =========================================================================
class ProductInfo {
  final String barcode;
  final String name;
  final String? brand; // brand 在示例中不存在，保持可空
  // 注意：API示例中没有 nutritionInfo，为保持兼容性，设为可空
  final NutritionInfo? nutritionInfo;

  ProductInfo({
    required this.barcode,
    required this.name,
    this.brand,
    this.nutritionInfo,
  });

  factory ProductInfo.fromJson(Map<String, dynamic> json) {
    return ProductInfo(
      // **核心修复4**: 使用正确的键名 'barCode' 和 'productName'
      barcode: json['barCode'] ?? '',
      name: json['productName'] ?? 'Unnamed Product',
      brand: json['brand'], // brand 在示例中没有，直接赋值，如果不存在就是null
      // API示例中没有 nutritionInfo，所以做安全处理
      nutritionInfo: json['nutritionInfo'] != null
          ? NutritionInfo.fromJson(json['nutritionInfo'])
          : null,
    );
  }

  // 用于UI显示的辅助方法
  String getSummaryText() {
    if (nutritionInfo == null) return 'No nutrition info';
    return nutritionInfo!.getSummaryText();
  }
}

// =========================================================================
// 营养信息类 - 这个类在你的API示例中不存在于推荐项里，但为了兼容性保留
// =========================================================================
class NutritionInfo {
  final double? calories;
  final double? sugar;
  final double? protein;
  final double? fat;

  NutritionInfo({
    this.calories,
    this.sugar,
    this.protein,
    this.fat,
  });

  factory NutritionInfo.fromJson(Map<String, dynamic> json) {
    return NutritionInfo(
      calories: (json['energyKcal100g'] as num?)?.toDouble(), // 匹配API示例
      protein: (json['proteins100g'] as num?)?.toDouble(), // 匹配API示例
      sugar: (json['sugar'] as num?)?.toDouble(), // 假设的键名
      fat: (json['fat'] as num?)?.toDouble(), // 假设的键名
    );
  }

  String getSummaryText() {
    List<String> summaryParts = [];
    if (calories != null) summaryParts.add('${calories!.toStringAsFixed(1)}kcal');
    if (protein != null) summaryParts.add('Protein ${protein!.toStringAsFixed(1)}g');
    if (sugar != null) summaryParts.add('Sugar ${sugar!.toStringAsFixed(1)}g');
    if (fat != null) summaryParts.add('Fat ${fat!.toStringAsFixed(1)}g');
    return summaryParts.isEmpty ? 'Nutrition info unavailable' : summaryParts.join(' | ');
  }
}

// =========================================================================
// LLM分析结果类
// =========================================================================
class LLMAnalysis {
  final String summary;
  final String detailedAnalysis;
  final List<String> actionSuggestions;

  LLMAnalysis({
    required this.summary,
    required this.detailedAnalysis,
    required this.actionSuggestions,
  });

  factory LLMAnalysis.fromJson(Map<String, dynamic> json) {
    var suggestionsList = json['actionSuggestions'] as List? ?? [];
    return LLMAnalysis(
      summary: json['summary'] ?? 'No analysis summary available.',
      detailedAnalysis: json['detailedAnalysis'] ?? 'No detailed analysis available.',
      actionSuggestions: suggestionsList.map((item) => item.toString()).toList(),
    );
  }
}

// =========================================================================
// 用户画像摘要类
// =========================================================================
class UserProfileSummary {
  final int userId;
  final String nutritionGoal;
  final int allergensCount;

  UserProfileSummary({
    required this.userId,
    required this.nutritionGoal,
    required this.allergensCount,
  });

  factory UserProfileSummary.fromJson(Map<String, dynamic> json) {
    return UserProfileSummary(
      userId: json['user_id'] ?? 0,
      nutritionGoal: json['nutrition_goal'] ?? 'N/A',
      allergensCount: json['allergens_count'] ?? 0,
    );
  }
}
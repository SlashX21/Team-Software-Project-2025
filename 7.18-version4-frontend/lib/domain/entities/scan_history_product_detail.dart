class ProductInfo {
  final String barcode;
  final String name;
  final String? brand;
  final String? category;
  final List<String> allergens;
  final String? ingredients;
  
  ProductInfo({
    required this.barcode,
    required this.name,
    this.brand,
    this.category,
    required this.allergens,
    this.ingredients,
  });
  
  factory ProductInfo.fromJson(Map<String, dynamic> json) {
    return ProductInfo(
      barcode: json['barcode'] as String,
      name: json['name'] as String,
      brand: json['brand'] as String?,
      category: json['category'] as String?,
      allergens: (json['allergens'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      ingredients: json['ingredients'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'barcode': barcode,
      'name': name,
      'brand': brand,
      'category': category,
      'allergens': allergens,
      'ingredients': ingredients,
    };
  }
}

class AIAnalysis {
  final String summary;
  final String detailedAnalysis;
  final List<String> actionSuggestions;
  
  AIAnalysis({
    required this.summary,
    required this.detailedAnalysis,
    required this.actionSuggestions,
  });
  
  factory AIAnalysis.fromJson(Map<String, dynamic> json) {
    return AIAnalysis(
      summary: json['summary'] as String,
      detailedAnalysis: json['detailedAnalysis'] as String,
      actionSuggestions: (json['actionSuggestions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'summary': summary,
      'detailedAnalysis': detailedAnalysis,
      'actionSuggestions': actionSuggestions,
    };
  }
}

class NutritionImprovement {
  final String proteinIncrease;
  final String sugarReduction;
  final String calorieChange;
  
  NutritionImprovement({
    required this.proteinIncrease,
    required this.sugarReduction,
    required this.calorieChange,
  });
  
  factory NutritionImprovement.fromJson(Map<String, dynamic> json) {
    return NutritionImprovement(
      proteinIncrease: json['proteinIncrease'] as String,
      sugarReduction: json['sugarReduction'] as String,
      calorieChange: json['calorieChange'] as String,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'proteinIncrease': proteinIncrease,
      'sugarReduction': sugarReduction,
      'calorieChange': calorieChange,
    };
  }
}

class RecommendationItem {
  final int rank;
  final ProductInfo product;
  final double recommendationScore;
  final NutritionImprovement nutritionImprovement;
  final String reasoning;
  
  RecommendationItem({
    required this.rank,
    required this.product,
    required this.recommendationScore,
    required this.nutritionImprovement,
    required this.reasoning,
  });
  
  factory RecommendationItem.fromJson(Map<String, dynamic> json) {
    return RecommendationItem(
      rank: json['rank'] as int,
      product: ProductInfo.fromJson(json['product'] as Map<String, dynamic>),
      recommendationScore: (json['recommendationScore'] as num).toDouble(),
      nutritionImprovement: NutritionImprovement.fromJson(json['nutritionImprovement'] as Map<String, dynamic>),
      reasoning: json['reasoning'] as String,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'rank': rank,
      'product': product.toJson(),
      'recommendationScore': recommendationScore,
      'nutritionImprovement': nutritionImprovement.toJson(),
      'reasoning': reasoning,
    };
  }
}

class ScanHistoryProductDetail {
  final int scanId;
  final String recommendationId;
  final ProductInfo productInfo;
  final AIAnalysis aiAnalysis;
  final List<RecommendationItem> recommendations;
  final DateTime scannedAt;
  
  ScanHistoryProductDetail({
    required this.scanId,
    required this.recommendationId,
    required this.productInfo,
    required this.aiAnalysis,
    required this.recommendations,
    required this.scannedAt,
  });
  
  factory ScanHistoryProductDetail.fromJson(Map<String, dynamic> json) {
    return ScanHistoryProductDetail(
      scanId: json['scanId'] as int,
      recommendationId: json['recommendationId'] as String,
      productInfo: ProductInfo.fromJson(json['productInfo'] as Map<String, dynamic>),
      aiAnalysis: AIAnalysis.fromJson(json['aiAnalysis'] as Map<String, dynamic>),
      recommendations: (json['recommendations'] as List<dynamic>?)
          ?.map((item) => RecommendationItem.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
      scannedAt: DateTime.parse(json['scannedAt'] as String),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'scanId': scanId,
      'recommendationId': recommendationId,
      'productInfo': productInfo.toJson(),
      'aiAnalysis': aiAnalysis.toJson(),
      'recommendations': recommendations.map((item) => item.toJson()).toList(),
      'scannedAt': scannedAt.toIso8601String(),
    };
  }
}
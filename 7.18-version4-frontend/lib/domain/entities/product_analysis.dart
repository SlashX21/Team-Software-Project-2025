class ProductAnalysis {
  final String name;
  final String imageUrl;
  final List<String> ingredients;
  final List<String> detectedAllergens;
  final String summary;
  final String detailedAnalysis;
  final List<String> actionSuggestions;
  
  // 新增属性以支持推荐功能
  final String? barcode;
  final List<ProductAnalysis> recommendations;
  final Map<String, dynamic>? llmAnalysis;

  ProductAnalysis({
    required this.name,
    required this.imageUrl,
    required this.ingredients,
    required this.detectedAllergens,
    this.summary = '',
    this.detailedAnalysis = '',
    this.actionSuggestions = const [],
    this.barcode,
    this.recommendations = const [],
    this.llmAnalysis,
  });

  factory ProductAnalysis.fromJson(Map<String, dynamic> json) {
    // 处理 ingredients，可能是字符串数组或逗号分隔的字符串
    List<String> parseIngredients(dynamic ingredientsData) {
      if (ingredientsData == null) return [];
      if (ingredientsData is List) {
        return List<String>.from(ingredientsData);
      }
      if (ingredientsData is String) {
        return ingredientsData
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
      return [];
    }

    // 处理 allergens，可能是字符串数组或逗号分隔的字符串
    List<String> parseAllergens(dynamic allergensData) {
      if (allergensData == null) return [];
      if (allergensData is List) {
        return List<String>.from(allergensData);
      }
      if (allergensData is String) {
        return allergensData
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
      return [];
    }

    // 处理推荐列表
    List<ProductAnalysis> parseRecommendations(dynamic recommendationsData) {
      if (recommendationsData == null) return [];
      if (recommendationsData is List) {
        return recommendationsData
            .map((item) => ProductAnalysis.fromJson(item))
            .toList();
      }
      return [];
    }

    return ProductAnalysis(
      name: json['name'] ?? json['productName'] ?? '',
      imageUrl: json['imageUrl'] ?? json['image'] ?? '',
      ingredients: parseIngredients(json['ingredients']),
      detectedAllergens: parseAllergens(json['detectedAllergens'] ?? json['allergens']),
      summary: json['summary'] ?? '',
      detailedAnalysis: json['detailedAnalysis'] ?? json['analysis'] ?? '',
      actionSuggestions: List<String>.from(json['actionSuggestions'] ?? json['suggestions'] ?? []),
      barcode: json['barcode'] ?? json['barCode'],
      recommendations: parseRecommendations(json['recommendations']),
      llmAnalysis: json['llmAnalysis'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'ingredients': ingredients,
      'detectedAllergens': detectedAllergens,
      'summary': summary,
      'detailedAnalysis': detailedAnalysis,
      'actionSuggestions': actionSuggestions,
      'barcode': barcode,
      'recommendations': recommendations.map((r) => r.toJson()).toList(),
      'llmAnalysis': llmAnalysis,
    };
  }

  ProductAnalysis copyWith({
    String? name,
    String? imageUrl,
    List<String>? ingredients,
    List<String>? detectedAllergens,
    String? summary,
    String? detailedAnalysis,
    List<String>? actionSuggestions,
    String? barcode,
    List<ProductAnalysis>? recommendations,
    Map<String, dynamic>? llmAnalysis,
  }) {
    return ProductAnalysis(
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      ingredients: ingredients ?? this.ingredients,
      detectedAllergens: detectedAllergens ?? this.detectedAllergens,
      summary: summary ?? this.summary,
      detailedAnalysis: detailedAnalysis ?? this.detailedAnalysis,
      actionSuggestions: actionSuggestions ?? this.actionSuggestions,
      barcode: barcode ?? this.barcode,
      recommendations: recommendations ?? this.recommendations,
      llmAnalysis: llmAnalysis ?? this.llmAnalysis,
  );
  }
}